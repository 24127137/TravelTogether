import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';

/// Màn hình hiển thị bản đồ và vẽ lộ trình (Tối ưu Client-side + UI Gốc)
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

  // Dùng để tính khoảng cách cho thuật toán Nearest Neighbor
  final Distance _distanceCalculator = const Distance();

  // Danh sách các điểm (Sẽ được sắp xếp lại bởi Nearest Neighbor)
  List<LatLng> _selectedPoints = [];
  List<String> _locationNames = [];

  // Danh sách các điểm của lộ trình (sau khi giải mã polyline)
  List<LatLng> _routePoints = [];

  // Trạng thái tải dữ liệu
  bool _isLoading = true;
  String _errorMessage = '';

  // Thông tin lộ trình
  double _totalDistance = 0.0;
  double _totalDuration = 0.0;

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
      // 1. Lấy thông tin kế hoạch từ API (Supabase)
      await _fetchGroupPlan();

      // 2. Nếu có ít nhất 2 điểm, tiến hành tối ưu và vẽ
      if (_selectedPoints.length >= 2) {
        // A. Chạy thuật toán tối ưu thứ tự (Client-side)
        _optimizeRouteNearestNeighbor();

        // B. Gọi API vẽ đường theo thứ tự đã tối ưu
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

  // ===============================================================
  // PHẦN 1: LOGIC LẤY DỮ LIỆU (GIỮ NGUYÊN)
  // ===============================================================

  /// Lấy thông tin kế hoạch từ API
  Future<void> _fetchGroupPlan() async {
    try {
      final token = await AuthService.getValidAccessToken();
      if (token == null) throw Exception('Vui lòng đăng nhập');

      final profile = await _userService.getUserProfile();
      if (profile == null) throw Exception('Không lấy được thông tin cá nhân');

      dynamic itineraryData;
      int? groupId;
      String? preferredCity = profile['preferred_city'];
      bool useGroupPlan = false;

      // Logic check group (Giống code cũ)
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
            print('❌ Lỗi check nhóm: $e');
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
      print('❌ Lỗi _fetchGroupPlan: $e');
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

    print('🗺️ Đang geocode ${rawNames.length} địa điểm...');

    for (String locationName in rawNames) {
      try {
        final coords = await _geocodeLocation(locationName, cityContext);
        if (coords != null) {
          points.add(coords);
          names.add(locationName);
        }
      } catch (e) {
        print('❌ Lỗi geocoding $locationName: $e');
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
  // PHẦN 2: THUẬT TOÁN NEAREST NEIGHBOR (TỐI ƯU THỨ TỰ)
  // ===============================================================

  /// Sắp xếp lại _selectedPoints và _locationNames theo thứ tự tối ưu
  void _optimizeRouteNearestNeighbor() {
    if (_selectedPoints.length < 3) return; // Không cần tối ưu nếu chỉ có 2 điểm

    List<LatLng> sortedPoints = [];
    List<String> sortedNames = [];
    List<int> unvisitedIndices = List.generate(_selectedPoints.length, (index) => index);

    // 1. Luôn giữ điểm đầu tiên cố định (Ví dụ: Chợ Bến Thành)
    int currentIndex = 0;
    sortedPoints.add(_selectedPoints[currentIndex]);
    sortedNames.add(_locationNames[currentIndex]);
    unvisitedIndices.remove(0);

    // 2. Vòng lặp tìm điểm gần nhất tiếp theo
    while (unvisitedIndices.isNotEmpty) {
      int nearestIndex = -1;
      double minDistance = double.infinity;

      for (int i in unvisitedIndices) {
        double distance = _distanceCalculator.as(LengthUnit.Meter, _selectedPoints[currentIndex], _selectedPoints[i]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      if (nearestIndex != -1) {
        sortedPoints.add(_selectedPoints[nearestIndex]);
        sortedNames.add(_locationNames[nearestIndex]);
        currentIndex = nearestIndex;
        unvisitedIndices.remove(nearestIndex);
      } else {
        break;
      }
    }

    // 3. Cập nhật lại danh sách chính để UI và API sử dụng
    setState(() {
      _selectedPoints = sortedPoints;
      _locationNames = sortedNames;
    });

    print('✅ Đã tối ưu (Nearest Neighbor): ${_locationNames.join(" -> ")}');
  }

  // ===============================================================
  // PHẦN 3: GỌI OSRM ROUTE API (VẼ ĐƯỜNG THEO THỨ TỰ ĐÃ TỐI ƯU)
  // ===============================================================

  Future<void> _fetchRoute() async {
    try {
      // Vì đã tối ưu thứ tự ở Client, ta gửi list này lên API Route
      final coordinates = _selectedPoints
          .map((point) => '${point.longitude},${point.latitude}')
          .join(';');

      // Sử dụng Route API (Không dùng Trip API nữa) để tránh bị zigzag
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

          final distance = (route['distance'] as num).toDouble() / 1000;
          final duration = (route['duration'] as num).toDouble() / 60;
          final encodedPolyline = route['geometry'] as String;

          setState(() {
            _routePoints = _decodePolyline(encodedPolyline);
            _totalDistance = distance;
            _totalDuration = duration;
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
  // PHẦN 4: UI & TIỆN ÍCH (GIỮ NGUYÊN UI GỐC CỦA BẠN)
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
                  : const LatLng(21.0285, 105.8542),
              initialZoom: 13.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.my_travel_app',
              ),
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
              if (_selectedPoints.isNotEmpty)
                MarkerLayer(
                  markers: _selectedPoints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final isFirst = index == 0;
                    final isLast = index == _selectedPoints.length - 1;

                    // UI Gốc: Sử dụng Icon
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

          // Danh sách địa điểm (Sử dụng _locationNames đã được sort)
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
                          Expanded(
                            child: Text(
                              'Lộ trình tối ưu (${_locationNames.length} điểm):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Hiển thị thông số thời gian/khoảng cách
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isFirst || isLast ? FontWeight.bold : FontWeight.normal,
                                  ),
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