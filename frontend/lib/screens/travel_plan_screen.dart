import 'package:flutter/material.dart';

class TravelPlanScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const TravelPlanScreen({super.key, this.onBack});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  List<Map<String, String>> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTravelPlanData();
  }

  Future<void> _loadTravelPlanData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // TODO: Thay thế bằng API call thực tế
      // final response = await ApiService.getUserTravelPlan();
      // final places = response.data.map((place) => {
      //   'image': place.imageUrl,
      //   'name': place.name,
      // }).toList();

      // Mock data tạm thời - thay thế bằng API call thực
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      final places = [
        {"image": "https://placehold.co/300x200", "name": "Đỉnh Langbiang"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        {"image": "https://placehold.co/300x200", "name": "Hồ Xuân Hương"},
        // Data sẽ được load từ API dựa trên nhóm user đang tham gia
      ];

      setState(() {
        _places = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải dữ liệu: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TravelPlanContent(
      onBack: widget.onBack,
      places: _places,
      isLoading: _isLoading,
      error: _error,
      onRefresh: _loadTravelPlanData,
    );
  }
}

class _TravelPlanContent extends StatelessWidget {
  final VoidCallback? onBack;
  final List<Map<String, String>> places;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRefresh;

  const _TravelPlanContent({
    this.onBack,
    required this.places,
    required this.isLoading,
    this.error,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive scaling dựa trên chiều cao màn hình
          final screenHeight = constraints.maxHeight;
          final scaleFactor = (screenHeight / 800).clamp(0.7, 1.0);

          final horizontalPadding = 16.0 * scaleFactor;
          final topOffset = MediaQuery.of(context).padding.top + 32.0 * scaleFactor;
          final bottomOffset = 80.0 * scaleFactor;
          final spacing = 12.0 * scaleFactor;
          final backButtonSize = 44.0 * scaleFactor;
          final iconSize = 24.0 * scaleFactor;

        return SafeArea(
         child: Stack(
           children: [
             // Background
             Positioned.fill(
               child: Image.asset(
                 'assets/images/travel_plan.png',
                 fit: BoxFit.cover,
                 errorBuilder: (_, __, ___) =>
                     Container(color: const Color(0xFF12202F)),
               ),
             ),

             // Content frame
             Positioned(
               top: topOffset, // dynamic top offset using SafeArea
               left: horizontalPadding,
               right: horizontalPadding,
               bottom: bottomOffset,
               child: Container(
                 width: double.infinity,
                 // height intentionally omitted so it stretches between top & bottom
                 decoration: BoxDecoration(
                   color: Colors.black.withValues(alpha: 0.40),
                   border: Border.all(color: Colors.black, width: 2),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Padding(
                   padding: EdgeInsets.all(spacing),
                  child: _buildContent(scaleFactor, spacing),
                 ),
               ),
             ),

             // Back button
             Positioned(
              top: 16 * scaleFactor,
              left: 16 * scaleFactor,
               child: GestureDetector(
                 onTap: () {
                   if (onBack != null) {
                     onBack!();
                   } else {
                     Navigator.of(context).pop();
                   }
                 },
                 child: Container(
                  width: backButtonSize,
                  height: backButtonSize,
                   decoration: const BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                     Icons.arrow_back,
                     color: Colors.black,
                    size: iconSize,
                   ),
                 ),
               ),
             ),
           ],
         ),
        );
        },
      ),
     );
   }

  Widget _buildContent(double scaleFactor, double spacing) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
               Icons.error_outline,
               color: Colors.white,
              size: 64 * scaleFactor,
             ),
            SizedBox(height: 16 * scaleFactor),
             Text(
               error!,
              style: TextStyle(
                 color: Colors.white,
                fontSize: 16 * scaleFactor,
               ),
               textAlign: TextAlign.center,
             ),
            SizedBox(height: 16 * scaleFactor),
             ElevatedButton(
               onPressed: onRefresh,
               child: Text('Thử lại', style: TextStyle(fontSize: 14 * scaleFactor)),
             ),
           ],
         ),
       );
    }

    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              color: Colors.white,
              size: 64 * scaleFactor,
            ),
            SizedBox(height: 16 * scaleFactor),
            Text(
              'Chưa có kế hoạch du lịch nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8 * scaleFactor),
            Text(
              'Hãy tạo hoặc tham gia một nhóm để bắt đầu',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14 * scaleFactor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
       onRefresh: () async {
         if (onRefresh != null) onRefresh!();
       },
       child: GridView.builder(
         physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
           crossAxisCount: 2,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
           childAspectRatio: 0.72,
         ),
         itemCount: places.length,
         itemBuilder: (context, index) {
           final place = places[index];
          return _PlaceCard(place: place, scaleFactor: scaleFactor);
         },
       ),
     );
   }
 }

 class _PlaceCard extends StatelessWidget {
   final Map<String, String> place;
  final double scaleFactor;

  const _PlaceCard({required this.place, this.scaleFactor = 1.0});

   @override
   Widget build(BuildContext context) {
     return Column(
       children: [
         AspectRatio(
           aspectRatio: 1,
           child: ClipRRect(
             borderRadius: BorderRadius.circular(12),
             child: Image.network(
               place['image']!,
               fit: BoxFit.cover,
               width: double.infinity,
               loadingBuilder: (context, child, loadingProgress) {
                 if (loadingProgress == null) return child;
                 return Container(
                   color: Colors.grey[300],
                   child: const Center(
                     child: CircularProgressIndicator(strokeWidth: 2),
                   ),
                 );
               },
               errorBuilder: (_, __, ___) => Container(
                 color: Colors.grey,
                child: Icon(
                   Icons.broken_image,
                   color: Colors.white,
                   size: 40 * scaleFactor,
                 ),
               ),
             ),
           ),
         ),
        SizedBox(height: 6 * scaleFactor),
         Text(
           place['name']!,
           textAlign: TextAlign.center,
           style: TextStyle(
             color: Colors.white,
            fontSize: 14 * scaleFactor,
             fontWeight: FontWeight.w700,
           ),
           maxLines: 2,
           overflow: TextOverflow.ellipsis,
         ),
       ],
     );
   }
 }
