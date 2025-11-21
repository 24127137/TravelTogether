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
    final size = MediaQuery.of(context).size;
    final horizontalPadding = 16.0;
    final frameHeight = size.height * 0.75;
    const spacing = 12.0;

    return Scaffold(
      body: SafeArea(
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
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Container(
                  width: double.infinity,
                  height: frameHeight,
                  margin: const EdgeInsets.only(bottom: 80),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.40),
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(spacing),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
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
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              error!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (places.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              color: Colors.white,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có kế hoạch du lịch nào',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Hãy tạo hoặc tham gia một nhóm để bắt đầu',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: places.length,
        itemBuilder: (context, index) {
          final place = places[index];
          return _PlaceCard(place: place);
        },
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Map<String, String> place;

  const _PlaceCard({required this.place});

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
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          place['name']!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}