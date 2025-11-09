/// File: mock_destinations.dart
/// Description: Mock data cho 10 điểm đến du lịch nổi bật Việt Nam.
///
/// Cung cấp dữ liệu giả lập cho các điểm đến du lịch, bao gồm thông tin chi tiết
/// về địa điểm, hình ảnh, đánh giá và mô tả. Dữ liệu này được sử dụng để hiển thị
/// trong ứng dụng du lịch và không thay thế cho dữ liệu thực tế từ API.

import '../models/destination.dart';

final List<Destination> mockDestinations = [
  Destination(
    id: '1',
    name: 'Đà Nẵng',
    province: 'Đà Nẵng',
    imagePath: 'assets/images/danang.jpg',
    tags: ['Biển', 'Thành phố', 'Giải trí'],
    location: 'việt nam',
    description: 'Thành phố đáng sống nhất Việt Nam, nổi tiếng với biển Mỹ Khê, cầu Rồng, Bà Nà Hills và Sơn Trà.',
    cityId: 'danang',
  ),
  Destination(
    id: '2',
    name: 'Đà Lạt',
    province: 'Lâm Đồng',
    imagePath: 'assets/images/dalat.jpg',
    tags: ['Nghỉ dưỡng', 'Lãng mạn', 'Văn hóa'],
    location: 'việt nam',
    description: '“Thành phố ngàn hoa” với khí hậu mát mẻ quanh năm, hồ Xuân Hương, thung lũng Tình Yêu, và phong cách châu Âu lãng mạn.',
    cityId: 'dalat',
  ),
  Destination(
    id: '3',
    name: 'Nha Trang',
    province: 'Khánh Hòa',
    imagePath: 'assets/images/nhatrang.jpg',
    tags: ['Biển', 'Lặn', 'Giải trí'],
    location: 'việt nam',
    description: 'Trung tâm du lịch biển miền Trung, nổi bật với vịnh Nha Trang, đảo Hòn Mun, VinWonders và lặn ngắm san hô.',
    cityId: 'nhatrang',
  ),
  Destination(
    id: '4',
    name: 'Phú Quốc',
    province: 'Kiên Giang',
    imagePath: 'assets/images/phuquoc.jpg',
    tags: ['Biển', 'Nghỉ dưỡng', 'Khám phá'],
    location: 'việt nam',
    description: 'Hòn đảo lớn nhất Việt Nam, nổi tiếng với bãi Sao, bãi Dài, Sunset Town, cáp treo Hòn Thơm, và resort sang trọng.',
    cityId: 'phuquoc',
  ),
  Destination(
    id: '5',
    name: 'Hà Nội',
    province: 'Hà Nội',
    imagePath: 'assets/images/hanoi.jpg',
    tags: ['Thủ đô', 'Ẩm thực', 'Lịch sử'],
    location: 'việt nam',
    description: 'Thủ đô nghìn năm văn hiến, kết hợp giữa nét cổ kính của phố cổ và hiện đại; đặc biệt nổi bật với ẩm thực đường phố.',
    cityId: 'hanoi',
  ),
  Destination(
    id: '6',
    name: 'Hội An',
    province: 'Quảng Nam',
    imagePath: 'assets/images/hoian.jpg',
    tags: ['Di sản', 'Văn hóa', 'Ẩm thực'],
    location: 'việt nam',
    description: 'Phố cổ di sản UNESCO, lung linh đèn lồng, kiến trúc pha trộn Việt – Hoa – Nhật, ẩm thực phong phú.',
    cityId: 'hoian',
  ),
  Destination(
    id: '7',
    name: 'Huế',
    province: 'Thừa Thiên Huế',
    imagePath: 'assets/images/hue.jpg',
    tags: ['Cố đô', 'Văn hóa', 'Lịch sử'],
    location: 'việt nam',
    description: 'Cố đô hoàng gia với quần thể di tích triều Nguyễn, sông Hương, núi Ngự, và văn hóa cung đình độc đáo.',
    cityId: 'hue',
  ),
  Destination(
    id: '8',
    name: 'TP. Hồ Chí Minh',
    province: 'TP. Hồ Chí Minh',
    imagePath: 'assets/images/saigon.jpg',
    tags: ['Thành phố', 'Ẩm thực', 'Giải trí'],
    location: 'việt nam',
    description: 'Trung tâm kinh tế sôi động, giao thoa Đông – Tây, nổi bật với ẩm thực đường phố, chợ Bến Thành, và đời sống về đêm.',
    cityId: 'hochiminh',
  ),
  Destination(
    id: '9',
    name: 'Sa Pa',
    province: 'Lào Cai',
    imagePath: 'assets/images/sapa.jpg',
    tags: ['Nghỉ dưỡng', 'Khám phá', 'Văn hóa'],
    location: 'việt nam',
    description: 'Nổi tiếng với ruộng bậc thang, Fansipan – “nóc nhà Đông Dương”, văn hóa dân tộc thiểu số và khí hậu lạnh quanh năm.',
    cityId: 'sapa',
  ),
  Destination(
    id: '10',
    name: 'Vịnh Hạ Long',
    province: 'Quảng Ninh',
    imagePath: 'assets/images/halongbay.jpg',
    tags: ['Thiên nhiên', 'Khám phá', 'Di sản'],
    location: 'việt nam',
    description: 'Di sản thiên nhiên thế giới UNESCO, với hàng nghìn đảo đá vôi trên vịnh xanh ngọc tuyệt đẹp.',
    cityId: 'halong',
  ),
];

// Danh sách riêng cho phần điểm đến đề xuất trên trang chủ
final List<Destination> recommendedDestinations = [
  mockDestinations.firstWhere((d) => d.name == 'Sa Pa'),
  mockDestinations.firstWhere((d) => d.name == 'Đà Lạt'),
  mockDestinations.firstWhere((d) => d.name == 'Hội An'),
];