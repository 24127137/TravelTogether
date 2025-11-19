import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background cố định toàn màn hình
          Positioned.fill(
            child: Image.asset(
              'assets/images/info.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 26, top: 15),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F6F8),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            ),
          ),


          // Content có thể scroll
          CustomScrollView(
            slivers: [
              // Spacer để tạo khoảng trống ban đầu
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                ),
              ),

              // Phần gradient content
              SliverToBoxAdapter(
                child: Container(
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-0.10, -0.05),
                      end: Alignment(1.12, 1.14),
                      colors: [
                        Color(0xFF662704),
                        Color(0xFF832E05),
                        Color(0xFFA5530F),
                        Color(0xFFC6771A),
                        Color(0xFFC27725),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // SECTION 1: Image Grid
                        const SizedBox(height: 23),
                        SizedBox(
                          height: 280,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildImageBox(left: 0, top: 0, width: 127, height: 211, image: 'assets/images/saigon_art.jpg', radius: 15),
                              _buildImageBox(left: 131, top: 0, width: 115, height: 83, image: 'assets/images/hoian_art.jpg', radius: 20),
                              _buildImageBox(left: 255, top: 0, width: 105, height: 105, image: 'assets/images/danang_art.jpg'),
                              _buildImageBox(left: 132, top: 96, width: 92, height: 154, image: 'assets/images/halong_art.jpg'),
                              _buildImageBox(left: 227, top: 115, width: 62, height: 62, image: 'assets/images/dalat_art.jpg'),
                              _buildImageBox(left: 292, top: 110, width: 68, height: 135, image: 'assets/images/hanoi_art.jpg'),
                              _buildImageBox(left: 227, top: 185, width: 62, height: 62, image: 'assets/images/hue_art.jpg'),
                              _buildImageBox(left: 0, top: 217, width: 127, height: 30, image: 'assets/images/hagiang_art.jpg', radius: 5),
                            ],
                          ),
                        ),

                        // Mission label
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          color: Colors.black.withOpacity(0.43),
                          child: const Text(
                            'SỨ MỆNH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontFamily: 'Alumni Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // Mission text
                        const SizedBox(height: 20),
                        Container(
                          width: screenWidth - 32,
                          padding: const EdgeInsets.all(12),
                          child: const Text(
                            '   Bạn đã bao giờ dừng lại để ngắm nhìn những dãy núi hùng vĩ phía Bắc chưa?\n'
                                '   Bạn có từng đắm mình trong làn nước trong xanh của biển miền Trung, hay lặng nhìn cánh đồng lúa vàng óng ở đồng bằng sông Cửu Long?\n'
                                '   Bạn có cảm thấy lòng mình rung động trước vẻ cổ kính của những đô thị nghìn năm tuổi?\n\n'
                                '   Ứng dụng của chúng tôi được tạo ra để giúp bạn khám phá, cảm nhận và lan toả những điều tuyệt vời ấy.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),

                        // SECTION 2: Discovery
                        const SizedBox(height: 50),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.asset(
                                'assets/images/2.jpg',
                                width: 120,
                                height: 240,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Right: Text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    color: Colors.black.withOpacity(0.43),
                                    child: const Text(
                                      'Khám phá những điểm đến và những người có cùng sở thích với bạn.',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontFamily: 'Times New Roman',
                                        fontWeight: FontWeight.w400,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  const Text(
                                    'Mỗi hành trình là cơ hội để bạn tìm thấy không chỉ cảnh đẹp, mà còn những tâm hồn đồng điệu.\n\n'
                                        'Khám phá những vùng đất mới, gặp gỡ những người chia sẻ cùng năng lượng và sở thích.\n\n'
                                        'Hãy để chuyến đi của bạn bắt đầu bằng sự kết nối và cảm hứng.',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

// SECTION 3: Matching
                        const SizedBox(height: 60),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: const Text(
                            '"Matching"',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontFamily: 'Alumni Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
// Left text + Right image (image đè lên text)
                        SizedBox(
                          height: 320,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Text box (nằm phía sau)
                              Positioned(
                                left: -10,
                                top: -20,
                                right: 100, // Để chừa chỗ cho ảnh
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.53),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    '  Du lịch không chỉ là đi, mà còn là cùng nhau trải nghiệm.\n\n'
                                        '  Ứng dụng giúp bạn tìm thấy người có chung phong cách du lịch – thư giãn, khám phá hay phiêu lưu.\n\n'
                                        '  Hãy bắt đầu hành trình với những người thật sự hiểu bạn.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              // Image (đè lên text box)
                              Positioned(
                                right: -80,
                                top: 90,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      'assets/images/4.png',
                                      width: 280,
                                      height: 300,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
// Bottom: Image left (đè lên text) + Text right
                        SizedBox(
                          height: 340,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Text box (nằm phía sau)
                              Positioned(
                                right: -20,
                                top: 40,
                                left: 150, // Để chừa chỗ cho ảnh
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 260, // Đảm bảo chiều cao tối thiểu
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.57),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '  Chia sẻ ý tưởng, lập lịch trình và cùng nhau viết nên câu chuyện hành trình riêng.\n\n'
                                        '  Từng điểm đến sẽ trở nên đáng nhớ hơn khi được đồng hành bởi những người bạn mới.\n\n'
                                        '  Vì niềm vui du lịch không chỉ đến từ nơi ta đến, mà từ người cùng ta đi.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontFamily: 'Times New Roman',
                                      fontWeight: FontWeight.w400,
                                      height: 1.5, // Tăng line height từ 1.4 lên 1.5
                                    ),
                                  ),
                                ),
                              ),
                              // Image (đè lên text box, có xoay nhẹ)
                              Positioned(
                                left: -60,
                                bottom: -30,
                                child: Transform.rotate(
                                  angle: 0.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.asset(
                                        'assets/images/3.png',
                                        width: 280,
                                        height: 280,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageBox({
    required double left,
    required double top,
    required double width,
    required double height,
    required String image,
    double radius = 10,
    BoxFit fit = BoxFit.cover,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          image,
          width: width,
          height: height,
          fit: fit,
        ),
      ),
    );
  }
}
