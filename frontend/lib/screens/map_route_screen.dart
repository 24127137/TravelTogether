import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

/// Màn hình hiển thị bản đồ và vẽ lộ trình (Multi-Start Nearest Neighbor)
/// Sử dụng OpenStreetMap với overlay layer hiển thị biên giới Việt Nam (Hoàng Sa, Trường Sa)
class MapRouteScreen extends StatefulWidget {
  final int? groupId;
  final String? cityFilter;

  const MapRouteScreen({
    Key? key,
    this.groupId,
    this.cityFilter
  }) : super(key: key);

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  final MapController _mapController = MapController();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();

  final Distance _distanceCalculator = const Distance();

  // Danh sách các điểm gốc
  List<LatLng> _selectedPoints = [];
  List<String> _locationNames = [];

  // Danh sách các điểm vẽ đường
  List<LatLng> _routePoints = [];

  bool _isLoading = true;
  String _errorMessage = '';

  double _totalDistance = 0.0;
  double _totalDuration = 0.0;

  // Track zoom level for conditional rendering
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (widget.groupId != null && widget.groupId! > 0) {
        await _fetchSpecificGroupPlan(widget.groupId!);
      } 

      else if (widget.cityFilter != null) {
        await _fetchMyPersonalRoute(widget.cityFilter!);
      } 

      else {
        await _fetchGroupPlan();
      }

      if (_selectedPoints.length >= 2) {
        _optimizeRouteMultiStartNN();
        await _fetchRoute();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSpecificGroupPlan(int groupId) async {
    final token = await AuthService.getValidAccessToken();
    if (token == null) throw Exception('Vui lòng đăng nhập');

    final groupPlan = await _groupService.getGroupPlanById(token, groupId);
    if (groupPlan == null) throw Exception('Không tìm thấy kế hoạch nhóm');

    final itineraryData = groupPlan['itinerary'];
    final preferredCity = groupPlan['preferred_city'];

    await _parseItineraryData(itineraryData, preferredCity, true);
  }

  // ===============================================================
  // PHẦN 1: LOGIC LẤY DỮ LIỆU (GIỮ NGUYÊN)
  // ===============================================================

  // === HÀM MỚI: CHỈ PHỤC VỤ LOGIC CỦA BẠN ===
  Future<void> _fetchMyPersonalRoute(String cityName) async {
    // 1. Lấy token và profile như bình thường
    final token = await AuthService.getValidAccessToken();
    if (token == null) throw Exception('Vui lòng đăng nhập');
    final profile = await _userService.getUserProfile();
    if (profile == null) throw Exception('Không lấy được thông tin');

    // 2. Lấy itinerary
    final itineraryData = profile['itinerary'];

    // Vì hàm này chỉ có nhiệm vụ convert text sang tọa độ, dùng chung được.
    // Tham số thứ 2 là cityContext -> truyền cityName vào
    // Tham số thứ 3 là isGroupPlan -> truyền false
    await _parseItineraryData(itineraryData, cityName, false);
  }

  Future<void> _fetchGroupPlan() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception('Vui lòng đăng nhập');

      final profile = await _userService.getUserProfile();
      if (profile == null) throw Exception('Không lấy được thông tin');

      dynamic itineraryData;
      int? groupId;
      String? preferredCity = profile['preferred_city'];
      bool useGroupPlan = false;

      if (widget.groupId != null && widget.groupId! > 0) {
        groupId = widget.groupId;
      } else {
        List owned = profile['owned_groups'] ?? [];
        List joined = profile['joined_groups'] ?? [];
        if (owned.isNotEmpty || joined.isNotEmpty) {
          try {
            final groupDetail = await _groupService.getMyGroupDetail(token);
            if (groupDetail != null && groupDetail['status'] == 'open') {
              groupId = groupDetail['id'];
              useGroupPlan = true;
            }
          } catch (e) {
            print('Check group error: $e');
          }
        }
      }

      if (groupId != null && (useGroupPlan || widget.groupId != null)) {
        final groupPlan = await _groupService.getGroupPlanById(token, groupId);
        if (groupPlan != null) {
          itineraryData = groupPlan['itinerary'];
          preferredCity = groupPlan['preferred_city'] ?? preferredCity;
        }
      } else {
        itineraryData = profile['itinerary'];
      }

      await _parseItineraryData(itineraryData, preferredCity ?? 'Vietnam', useGroupPlan);
    } catch (e) {
      print('Fetch plan error: $e');
      rethrow;
    }
  }

  Future<void> _parseItineraryData(dynamic itineraryData, String cityContext, bool isGroupPlan) async {
    List<LatLng> points = [];
    List<String> names = [];
    List<String> rawNames = [];

    if (itineraryData == null) throw Exception('Không có lịch trình');

    if (itineraryData is Map) {
      var sortedKeys = itineraryData.keys.toList()..sort();
      String prefix = "${cityContext}_";
      for (var key in sortedKeys) {
        String strKey = key.toString();
        if (isGroupPlan || strKey.startsWith(prefix)) {
          if (itineraryData[key] != null) rawNames.add(itineraryData[key].toString());
        }
      }
    } else if (itineraryData is List) {
      rawNames = itineraryData.map((e) => e.toString()).toList();
    }

    if (rawNames.isEmpty) throw Exception('Không tìm thấy địa điểm nào');

    for (String locationName in rawNames) {
      try {
        final coords = await _geocodeLocation(locationName, cityContext);
        if (coords != null) {
          points.add(coords);
          names.add(locationName);
        }
      } catch (e) {
        print('Geocode error: $e');
      }
    }

    if (points.isEmpty) throw Exception('Không tìm thấy tọa độ địa điểm nào');

    setState(() {
      _selectedPoints = points;
      _locationNames = names;
    });
  }

  Future<LatLng?> _geocodeLocation(String locationName, String cityContext) async {
    try {
      final searchQuery = '$locationName, $cityContext';
      final locations = await locationFromAddress(searchQuery);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ===============================================================
  // PHẦN 2: THUẬT TOÁN MULTI-START NEAREST NEIGHBOR (MỚI)
  // ===============================================================

  /// Chạy thuật toán Nearest Neighbor với một điểm bắt đầu cố định
  /// Trả về: (Tổng khoảng cách, Danh sách index đã sắp xếp)
  Map<String, dynamic> _runNearestNeighborFromStart(int startIndex, int totalPoints) {
    List<int> path = [startIndex];
    List<int> unvisited = List.generate(totalPoints, (i) => i)..remove(startIndex);
    double pathDistance = 0.0;
    int current = startIndex;

    while (unvisited.isNotEmpty) {
      int nearest = -1;
      double minD = double.infinity;

      for (int candidate in unvisited) {
        double d = _distanceCalculator.as(LengthUnit.Meter, _selectedPoints[current], _selectedPoints[candidate]);
        if (d < minD) {
          minD = d;
          nearest = candidate;
        }
      }

      if (nearest != -1) {
        pathDistance += minD;
        path.add(nearest);
        unvisited.remove(nearest);
        current = nearest;
      } else {
        break;
      }
    }

    return {
      'distance': pathDistance,
      'path': path
    };
  }

  /// Thử tất cả các điểm làm điểm xuất phát và chọn lộ trình ngắn nhất
  void _optimizeRouteMultiStartNN() {
    int n = _selectedPoints.length;
    if (n < 3) return; // 2 điểm thì không cần tối ưu

    double bestDistance = double.infinity;
    List<int> bestPathIndices = [];

    print('🔄 Bắt đầu Multi-Start NN cho $n điểm...');

    // Vòng lặp thử từng điểm làm điểm xuất phát
    for (int i = 0; i < n; i++) {
      var result = _runNearestNeighborFromStart(i, n);
      double dist = result['distance'];
      List<int> path = result['path'];

      // So sánh để tìm lộ trình ngắn nhất
      if (dist < bestDistance) {
        bestDistance = dist;
        bestPathIndices = path;
      }
    }

    // Cập nhật lại danh sách điểm theo lộ trình tốt nhất tìm được
    List<LatLng> sortedPoints = [];
    List<String> sortedNames = [];

    for (int index in bestPathIndices) {
      sortedPoints.add(_selectedPoints[index]);
      sortedNames.add(_locationNames[index]);
    }

    setState(() {
      _selectedPoints = sortedPoints;
      _locationNames = sortedNames;
    });

    print('✅ Tối ưu hoàn tất. Tổng khoảng cách ước tính: ${bestDistance.toStringAsFixed(0)}m');
    print('📍 Thứ tự tối ưu nhất: ${_locationNames.join(" -> ")}');
  }

  // ===============================================================
  // PHẦN 3: GỌI OSRM ROUTE API (GIỮ NGUYÊN)
  // ===============================================================

  Future<void> _fetchRoute() async {
    try {
      final coordinates = _selectedPoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      // Sử dụng Route API để tôn trọng thứ tự đã tối ưu ở trên
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$coordinates'
            '?overview=full&geometries=polyline',
      );

      print('🚀 Calling OSRM Route: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];

          setState(() {
            _routePoints = _decodePolyline(route['geometry']);
            _totalDistance = (route['distance'] as num).toDouble() / 1000;
            _totalDuration = (route['duration'] as num).toDouble() / 60;
          });
        }
      } else {
        print('❌ OSRM API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Lỗi vẽ đường: $e');
      setState(() {
        _errorMessage = 'Không thể vẽ lộ trình: $e';
      });
    }
  }

  // ===============================================================
  // PHẦN 4: UI & TIỆN ÍCH (GIỮ NGUYÊN)
  // ===============================================================

  String _formatDuration(double minutes) {
    int hours = (minutes / 60).floor();
    int mins = (minutes % 60).round();
    return hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
  }

  String _formatDistance(double km) {
    return '${km.toStringAsFixed(2)} km';
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0; result = 0;
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
        backgroundColor: const Color(0xFFFFF8E7),
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
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoints.isNotEmpty ? _selectedPoints[0] : const LatLng(21.0285, 105.8542),
              initialZoom: 13.0,
              onPositionChanged: (position, hasGesture) {
                if (_currentZoom != position.zoom) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                }
              },
            ),
            children: [
              // Layer 1: OpenStreetMap base map (Dưới cùng)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_travel_app',
              ),

              // ==========================================================
              // LAYER 2: HIỂN THỊ CHỦ QUYỀN HOÀNG SA & TRƯỜNG SA
              // Sử dụng CircleLayer để vẽ vùng lãnh thổ - hiển thị đẹp ở mọi zoom level
              // ==========================================================
              CircleLayer(
                circles: [
                  // Quần đảo Hoàng Sa (Paracel Islands)
                  CircleMarker(
                    point: const LatLng(16.54, 111.75),
                    radius: 8,
                    color: Colors.red.withValues(alpha: 0.6),
                    borderColor: Colors.red,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: false, // Sử dụng pixel để ổn định khi zoom
                  ),
                  // Quần đảo Trường Sa (Spratly Islands)
                  CircleMarker(
                    point: const LatLng(9.95, 114.36),
                    radius: 8,
                    color: Colors.red.withValues(alpha: 0.6),
                    borderColor: Colors.red,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: false,
                  ),
                ],
              ),

              // Layer 2b: Text labels cho Hoàng Sa & Trường Sa (chỉ hiển thị khi zoom < 8)
              if (_currentZoom < 8)
                MarkerLayer(
                  markers: [
                    // Label Hoàng Sa
                    Marker(
                      point: const LatLng(16.54, 111.75),
                      width: 200,
                      height: 60,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🇻🇳 HOÀNG SA',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Label Trường Sa
                    Marker(
                      point: const LatLng(9.95, 114.36),
                      width: 200,
                      height: 60,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🇻🇳 TRƯỜNG SA',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              // ==========================================================

              // Layer 3: Route polyline
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(points: _routePoints, strokeWidth: 4.0, color: Colors.blue),
                  ],
                ),
              // Layer 4: Location markers (Trên cùng)
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
                        onTap: () => _showLocationInfo(index),
                        child: Icon(
                          isFirst ? Icons.location_on : (isLast ? Icons.flag : Icons.place),
                          color: isFirst ? Colors.green : (isLast ? Colors.red : Colors.orange),
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          if (_locationNames.isNotEmpty && _routePoints.isNotEmpty)
            Positioned(
              top: 16, left: 16, right: 16,
              child: Card(
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.route, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lộ trình tối ưu (${_locationNames.length} điểm):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      if (_totalDuration > 0)
                        Container(
                          margin: EdgeInsets.only(top: 8, bottom: 8),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.schedule, color: Colors.blue, size: 18),
                                  Text(_formatDuration(_totalDuration), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                              Container(width: 1, height: 20, color: Colors.grey),
                              Column(
                                children: [
                                  Icon(Icons.straighten, color: Colors.green, size: 18),
                                  Text(_formatDistance(_totalDistance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      Divider(height: 1),
                      SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _locationNames.length,
                          itemBuilder: (context, index) {
                            final isFirst = index == 0;
                            final isLast = index == _locationNames.length - 1;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  Icon(
                                    isFirst ? Icons.location_on : (isLast ? Icons.flag : Icons.place),
                                    color: isFirst ? Colors.green : (isLast ? Colors.red : Colors.orange),
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${_locationNames[index]}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            right: 16, bottom: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
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

  void _showLocationInfo(int index) {
    // Lấy tọa độ của điểm được chọn
    final point = _selectedPoints[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _locationNames[index],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: FutureBuilder<List<Placemark>>(
          // Gọi hàm của gói geocoding để lấy địa chỉ từ tọa độ
          future: placemarkFromCoordinates(point.latitude, point.longitude),
          builder: (context, snapshot) {
            // 1. Đang tải
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 50,
                child: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text("Đang tìm địa chỉ..."),
                  ],
                ),
              );
            }

            // 2. Có lỗi hoặc không có dữ liệu
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(
                  'Không tìm thấy địa chỉ cụ thể.\nTọa độ: ${point.latitude}, ${point.longitude}');
            }

            // 3. Có dữ liệu -> Hiển thị địa chỉ
            final place = snapshot.data![0];

            // Ghép các thành phần địa chỉ lại cho đẹp
            // Các trường thường dùng: street, subAdministrativeArea (quận/huyện), administrativeArea (tỉnh/tp)
            String address = [
              place.street,
              place.subAdministrativeArea,
              place.administrativeArea,
              place.country
            ].where((element) => element != null && element.isNotEmpty).join(", ");

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Địa chỉ:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontSize: 16)),
                const Divider(),
                // Vẫn hiển thị tọa độ nhưng để nhỏ bên dưới cho chuyên nghiệp
                Text(
                  'GPS: ${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  void _fitBounds() {
    if (_selectedPoints.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(_selectedPoints);
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }
}