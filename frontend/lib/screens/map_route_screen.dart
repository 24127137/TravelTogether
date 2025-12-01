import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

/// Màn hình hiển thị bản đồ và vẽ lộ trình
class MapRouteScreen extends StatefulWidget {
  final int? groupId;

  const MapRouteScreen({Key? key, this.groupId}) : super(key: key);

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  final MapController _mapController = MapController();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();

  // Danh sách các điểm được chọn (sẽ lấy từ API)
  List<LatLng> _selectedPoints = [];

  // Danh sách các điểm của lộ trình (sau khi giải mã polyline)
  List<LatLng> _routePoints = [];

  // Tên các địa điểm
  List<String> _locationNames = [];

  // Trạng thái tải dữ liệu
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Khởi tạo và tải dữ liệu
  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Lấy thông tin kế hoạch từ API
      await _fetchGroupPlan();

      // Nếu có ít nhất 2 điểm, vẽ lộ trình
      if (_selectedPoints.length >= 2) {
        await _fetchRoute();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải dữ liệu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Lấy thông tin kế hoạch từ API - Logic giống travel_plan_screen
  Future<void> _fetchGroupPlan() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) {
        throw Exception('Vui lòng đăng nhập');
      }

      final profile = await _userService.getUserProfile();
      if (profile == null) {
        throw Exception('Không lấy được thông tin cá nhân');
      }

      dynamic itineraryData;
      int? groupId;
      String? preferredCity = profile['preferred_city'];

      // === LOGIC GIỐNG TRAVEL_PLAN_SCREEN: CHECK STATUS TRƯỚC ===
      bool useGroupPlan = false;

      // Nếu có groupId từ widget, ưu tiên dùng
      if (widget.groupId != null && widget.groupId! > 0) {
        groupId = widget.groupId;
        print('📌 Sử dụng Group ID từ widget: $groupId');
      } else {
        // Kiểm tra xem user có tham gia nhóm nào không
        List owned = profile['owned_groups'] ?? [];
        List joined = profile['joined_groups'] ?? [];

        if (owned.isNotEmpty || joined.isNotEmpty) {
          // Có nhóm -> Gọi API check trạng thái nhóm
          try {
            final groupDetail = await _groupService.getMyGroupDetail(token);

            if (groupDetail != null) {
              groupId = groupDetail['id'];
              String status = groupDetail['status'] ?? 'closed';

              print('🔍 Trạng thái nhóm (ID $groupId): $status');

              if (status == 'open') {
                useGroupPlan = true;
                print('✅ Nhóm OPEN -> Load Group Plan');
              } else {
                print('⚠️ Nhóm $status -> Không sử dụng group plan');
              }
            }
          } catch (e) {
            print('❌ Lỗi check nhóm: $e');
          }
        }
      }

      // Nếu có groupId và quyết định dùng group plan
      if (groupId != null && (useGroupPlan || widget.groupId != null)) {
        try {
          final groupPlan = await _groupService.getGroupPlanById(token, groupId);
          if (groupPlan != null) {
            itineraryData = groupPlan['itinerary'];
            preferredCity = groupPlan['preferred_city'] ?? preferredCity;
            print('✅ Đã lấy Group Plan cho nhóm $groupId');
          }
        } catch (e) {
          print('❌ Lỗi lấy group plan: $e');
          throw Exception('Không thể lấy lịch trình nhóm: $e');
        }
      } else {
        // Dùng personal itinerary
        itineraryData = profile['itinerary'];
        print('👤 Load Personal Itinerary');
      }

      // Parse itinerary thành danh sách địa điểm
      await _parseItineraryData(itineraryData, preferredCity ?? 'Vietnam', useGroupPlan);

    } catch (e) {
      print('❌ Lỗi _fetchGroupPlan: $e');
      rethrow;
    }
  }

  /// Parse itinerary data thành danh sách địa điểm (Logic giống travel_plan_screen)
  Future<void> _parseItineraryData(dynamic itineraryData, String cityContext, bool isGroupPlan) async {
    List<LatLng> points = [];
    List<String> names = [];

    if (itineraryData == null) {
      throw Exception('Không có lịch trình (itinerary) để hiển thị');
    }

    List<String> rawNames = [];

    if (itineraryData is Map) {
      // Sort key để hiển thị đúng thứ tự
      var sortedKeys = itineraryData.keys.toList()..sort();

      String currentCity = cityContext;
      String prefix = "${currentCity}_";

      for (var key in sortedKeys) {
        String strKey = key.toString();

        if (isGroupPlan) {
          // Nếu đang xem Group Plan: Lấy HẾT (vì plan nhóm là duy nhất)
          if (itineraryData[key] != null) {
            rawNames.add(itineraryData[key].toString());
          }
        } else {
          // Nếu đang xem Cá nhân: Chỉ lấy item thuộc CITY hiện tại
          if (strKey.startsWith(prefix)) {
            rawNames.add(itineraryData[key].toString());
          }
        }
      }
    } else if (itineraryData is List) {
      // Fallback cho trường hợp dữ liệu cũ dạng List
      rawNames = itineraryData.map((e) => e.toString()).toList();
    }

    if (rawNames.isEmpty) {
      throw Exception('Không tìm thấy địa điểm nào trong lịch trình');
    }

    print('🗺️ Đang geocode ${rawNames.length} địa điểm...');

    // Geocode từng địa điểm
    for (String locationName in rawNames) {
      try {
        final coords = await _geocodeLocation(locationName, cityContext);
        if (coords != null) {
          points.add(coords);
          names.add(locationName);
          print('✅ Geocoded: $locationName -> $coords');
        } else {
          print('⚠️ Không tìm thấy tọa độ cho: $locationName');
        }
      } catch (e) {
        print('❌ Lỗi geocoding $locationName: $e');
      }
    }

    if (points.isEmpty) {
      throw Exception('Không thể chuyển đổi địa điểm thành tọa độ. Vui lòng kiểm tra tên địa điểm.');
    }

    print('✅ Successfully parsed ${points.length} locations');
    setState(() {
      _selectedPoints = points;
      _locationNames = names;
    });
  }


  /// Geocoding: Chuyển đổi tên địa điểm thành tọa độ
  Future<LatLng?> _geocodeLocation(String locationName, String cityContext) async {
    try {
      // Thêm context thành phố để tăng độ chính xác
      final searchQuery = '$locationName, $cityContext';

      final locations = await locationFromAddress(searchQuery);

      if (locations.isNotEmpty) {
        final location = locations.first;
        return LatLng(location.latitude, location.longitude);
      }
    } catch (e) {
      print('❌ Geocoding error for $locationName: $e');
    }
    return null;
  }


  /// Cập nhật lại _selectedPoints và _locationNames theo thứ tự OSRM tối ưu hóa
  void _updatePointsOrder(List optimizedWaypoints) {
    if (optimizedWaypoints.isEmpty) {
      print('⚠️ Danh sách waypoints rỗng. Bỏ qua cập nhật thứ tự.');
      return;
    }

    try {
      List<LatLng> newPoints = [];
      List<String> newNames = [];

      print('🔄 Reordering ${optimizedWaypoints.length} waypoints...');

      // OSRM waypoints có cấu trúc:
      // [
      //   {"waypoint_index": 0, "trips_index": 0, "location": [lng, lat], ...},
      //   {"waypoint_index": 2, "trips_index": 0, "location": [lng, lat], ...},
      //   {"waypoint_index": 1, "trips_index": 0, "location": [lng, lat], ...}
      // ]
      // waypoint_index cho biết chỉ số gốc của điểm trong input

      for (int i = 0; i < optimizedWaypoints.length; i++) {
        final waypoint = optimizedWaypoints[i];

        if (waypoint is! Map<String, dynamic>) {
          print('⚠️ Waypoint $i không phải Map, bỏ qua.');
          continue;
        }

        // Lấy waypoint_index - chỉ số gốc của điểm trong danh sách input
        int? originalIndex;

        if (waypoint.containsKey('waypoint_index')) {
          originalIndex = waypoint['waypoint_index'] as int?;
        } else if (waypoint.containsKey('trips_index')) {
          originalIndex = waypoint['trips_index'] as int?;
        }

        if (originalIndex == null) {
          print('⚠️ Không tìm thấy index cho waypoint $i. Sử dụng thứ tự hiện tại.');
          originalIndex = i;
        }

        if (originalIndex >= _selectedPoints.length) {
          print('⚠️ Index vượt quá giới hạn: $originalIndex >= ${_selectedPoints.length}');
          continue;
        }

        // Thêm điểm theo thứ tự mới
        newPoints.add(_selectedPoints[originalIndex]);

        if (_locationNames.isNotEmpty && originalIndex < _locationNames.length) {
          newNames.add(_locationNames[originalIndex]);
          print('  [$i] ${_locationNames[originalIndex]} (original index: $originalIndex)');
        } else {
          newNames.add('Điểm ${originalIndex + 1}');
        }
      }

      // Chỉ cập nhật nếu có đủ dữ liệu hợp lệ
      if (newPoints.length >= 2) {
        setState(() {
          _selectedPoints = newPoints;
          _locationNames = newNames;
        });
        print('✅ Đã sắp xếp lại ${newPoints.length} điểm theo OSRM optimization');
      } else {
        print('⚠️ Không đủ điểm hợp lệ (${newPoints.length}). Giữ nguyên thứ tự ban đầu.');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật thứ tự điểm: $e. Giữ nguyên thứ tự ban đầu.');
    }
  }

  /// Gọi API OSRM để lấy lộ trình TỐI ƯU NHẤT (Sử dụng endpoint /trip)
  Future<void> _fetchRoute() async {
    if (_selectedPoints.length < 2) {
      setState(() {
        _errorMessage = 'Cần ít nhất 2 điểm để vẽ lộ trình';
      });
      return;
    }

    try {
      // Tạo chuỗi tọa độ cho OSRM API (OSRM trip sẽ tự sắp xếp thứ tự tối ưu)
      // Dùng Longitude, Latitude
      final coordinates = _selectedPoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      // Sử dụng OSRM /trip để tối ưu hóa thứ tự các điểm
      // roundtrip=false để không quay về điểm xuất phát
      final url = Uri.parse(
        'https://router.project-osrm.org/trip/v1/driving/$coordinates?overview=full&geometries=polyline&source=first&roundtrip=false',
      );

      print('🗺️ Fetching OPTIMIZED route from OSRM: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['trips'] != null && (data['trips'] as List).isNotEmpty) {
          final trip = data['trips'][0];
          final encodedPolyline = trip['geometry'] as String;

          // Giải mã polyline
          final decodedPoints = _decodePolyline(encodedPolyline);

          // Lấy thứ tự các điểm đã được OSRM tối ưu hóa
          final optimizedWaypoints = trip['waypoints'];

          print('🔍 OSRM waypoints data: $optimizedWaypoints');

          // Cập nhật thứ tự điểm theo OSRM optimization
          if (optimizedWaypoints != null && optimizedWaypoints is List && optimizedWaypoints.isNotEmpty) {
            try {
              _updatePointsOrder(optimizedWaypoints);
              print('✅ Points reordered based on OSRM optimization');
            } catch (e) {
              print('⚠️ Could not reorder points: $e. Using original order.');
            }
          } else {
            print('⚠️ No waypoint optimization data available. Using original order.');
          }

          setState(() {
            _routePoints = decodedPoints;
          });

          print('✅ Route decoded and OPTIMIZED: ${_routePoints.length} points');
          print('📍 Optimized order: ${_locationNames.join(" → ")}');
        } else {
          throw Exception('Không tìm thấy lộ trình tối ưu');
        }
      } else {
        throw Exception('OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi khi lấy lộ trình tối ưu: $e');
      setState(() {
        _errorMessage = 'Không thể vẽ lộ trình tối ưu: $e';
      });
    }
  }

  /// Giải mã chuỗi polyline thành danh sách LatLng
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lộ Trình Du Lịch',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFFFF8E7), // Màu kem
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải bản đồ...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeMap,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _selectedPoints.isNotEmpty
                            ? _selectedPoints[0]
                            : const LatLng(21.0285, 105.8542), // Mặc định là Hà Nội
                        initialZoom: 13.0,
                        minZoom: 3.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        // Tile Layer - Bản đồ nền OSM
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.my_travel_app',
                        ),

                        // Polyline Layer - Vẽ lộ trình
                        if (_routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _routePoints,
                                strokeWidth: 4.0,
                                color: Colors.blue,
                              ),
                            ],
                          ),

                        // Marker Layer - Đánh dấu các điểm
                        if (_selectedPoints.isNotEmpty)
                          MarkerLayer(
                            markers: _selectedPoints.asMap().entries.map((entry) {
                              final index = entry.key;
                              final point = entry.value;
                              final isFirst = index == 0;
                              final isLast = index == _selectedPoints.length - 1;

                              return Marker(
                                point: point,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    _showLocationInfo(index);
                                  },
                                  child: Icon(
                                    isFirst
                                        ? Icons.location_on
                                        : isLast
                                            ? Icons.flag
                                            : Icons.place,
                                    color: isFirst
                                        ? Colors.green
                                        : isLast
                                            ? Colors.red
                                            : Colors.orange,
                                    size: 40,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),

                    // Danh sách địa điểm theo thứ tự tối ưu
                    if (_locationNames.isNotEmpty && _routePoints.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          color: Colors.white.withValues(alpha: 0.95),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.route, color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lộ trình đã tối ưu (${_locationNames.length} điểm):',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                ...List.generate(_locationNames.length, (index) {
                                  final isFirst = index == 0;
                                  final isLast = index == _locationNames.length - 1;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isFirst
                                              ? Icons.location_on
                                              : isLast
                                                  ? Icons.flag
                                                  : Icons.place,
                                          color: isFirst
                                              ? Colors.green
                                              : isLast
                                                  ? Colors.red
                                                  : Colors.orange,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${index + 1}. ${_locationNames[index]}',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Legend
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Chú thích:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.green, size: 20),
                                  const SizedBox(width: 4),
                                  const Text('Điểm đầu'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.place, color: Colors.orange, size: 20),
                                  const SizedBox(width: 4),
                                  const Text('Điểm dừng'),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.flag, color: Colors.red, size: 20),
                                  const SizedBox(width: 4),
                                  const Text('Điểm cuối'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Zoom buttons
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            mini: true,
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            onPressed: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            mini: true,
                            onPressed: _fitBounds,
                            child: const Icon(Icons.my_location),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Hiển thị thông tin địa điểm
  void _showLocationInfo(int index) {
    final name = index < _locationNames.length
        ? _locationNames[index]
        : 'Điểm ${index + 1}';
    final point = _selectedPoints[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vĩ độ: ${point.latitude.toStringAsFixed(4)}'),
            Text('Kinh độ: ${point.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 8),
            Text('Thứ tự: ${index + 1}/${_selectedPoints.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Fit bản đồ để hiển thị tất cả các điểm
  void _fitBounds() {
    if (_selectedPoints.isEmpty) return;

    double minLat = _selectedPoints[0].latitude;
    double maxLat = _selectedPoints[0].latitude;
    double minLng = _selectedPoints[0].longitude;
    double maxLng = _selectedPoints[0].longitude;

    for (var point in _selectedPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    _mapController.move(center, 12.0);
  }
}

