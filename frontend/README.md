# Travel Together - Du Lịch Nhóm App 🌍✈️

## 📋 Mục Lục
- [Giới thiệu](#giới-thiệu)
- [Cấu trúc dự án](#cấu-trúc-dự-án)
- [Công nghệ sử dụng](#công-nghệ-sử-dụng)
- [Cài đặt và chạy dự án](#cài-đặt-và-chạy-dự-án)
- [Hướng dẫn phát triển](#hướng-dẫn-phát-triển)
- [Quy ước code](#quy-ước-code)
- [Tính năng đa ngôn ngữ](#tính-năng-đa-ngôn-ngữ)
- [Quản lý dữ liệu](#quản-lý-dữ-liệu)

## 🎯 Giới thiệu

**Travel Together** là ứng dụng mobile du lịch nhóm được xây dựng bằng Flutter, giúp người dùng:
- 🗺️ Khám phá các điểm đến du lịch hấp dẫn tại Việt Nam
- 👥 Tạo và quản lý nhóm du lịch
- 💬 Chat và trao đổi với nhóm
- 📅 Lên kế hoạch du lịch
- 🌐 Hỗ trợ đa ngôn ngữ (Tiếng Việt & English)

## 📁 Cấu trúc dự án

```
lib/
├── main.dart                      # Entry point của ứng dụng
├── data/                          # Mock data cho development
│   ├── mock_destinations.dart     # Dữ liệu điểm đến
│   ├── mock_explore_items.dart    # Dữ liệu khám phá
│   └── mock_messages.dart         # Dữ liệu tin nhắn
├── models/                        # Data models
│   ├── destination.dart           # Model điểm đến
│   ├── destination_explore_item.dart
│   └── message.dart               # Model tin nhắn
├── screens/                       # Các màn hình chính
│   ├── main_app_screen.dart       # Màn hình chính với bottom nav
│   ├── home_page.dart             # Trang chủ
│   ├── destination_search_screen.dart
│   ├── destination_detail_screen.dart
│   ├── destination_explore_screen.dart
│   ├── messages_screen.dart       # Màn hình chat
│   ├── travel_plan_screen.dart    # Lên kế hoạch
│   ├── before_group_screen.dart   # Quản lý nhóm
│   ├── chatbox_screen.dart        # Chi tiết chat
│   ├── private_screen.dart        # Cá nhân
│   └── settings_screen.dart       # Cài đặt
└── widgets/                       # Reusable widgets
    ├── custom_bottom_nav_bar.dart # Bottom navigation
    ├── destination_card.dart      # Card hiển thị điểm đến
    ├── destination_search_modal.dart
    └── KhungCNhN.dart            # Widget khung cá nhân

assets/
├── images/                        # Hình ảnh
│   ├── danang.jpg
│   ├── dalat.jpg
│   └── ...
├── translations/                  # File đa ngôn ngữ
│   ├── en.json                   # Tiếng Anh
│   └── vi.json                   # Tiếng Việt
└── fonts/                        # Fonts chữ
    ├── Poppins-Regular.ttf
    ├── Bangers-Regular.ttf
    └── ...
```

## 🛠 Công nghệ sử dụng

### Framework & Language
- **Flutter SDK**: >=3.0.0 <4.0.0
- **Dart**: Latest stable version

### Dependencies chính
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8        # iOS icons
  intl: ^0.20.2                  # Internationalization
  table_calendar: ^3.0.9         # Calendar widget
  easy_localization: ^3.0.8      # Đa ngôn ngữ
```

### DevDependencies
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0           # Code quality
```

## 🚀 Cài đặt và chạy dự án

### 1. Yêu cầu hệ thống
- Flutter SDK đã cài đặt ([Hướng dẫn cài Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / VS Code với Flutter extension
- Android Emulator hoặc thiết bị thật
- Git

### 2. Clone và setup

```bash
# Di chuyển vào thư mục frontend
cd "D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend"

# Cài đặt dependencies
flutter pub get

# Kiểm tra môi trường Flutter
flutter doctor
```

### 3. Chạy ứng dụng

```bash
# Chạy debug mode
flutter run

# Chạy release mode
flutter run --release

# Chạy trên device cụ thể
flutter run -d <device_id>

# Xem danh sách devices
flutter devices
```

### 4. Build ứng dụng

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS (trên macOS)
flutter build ios --release
```

## 💻 Hướng dẫn phát triển

### 1. Thêm điểm đến mới

**Bước 1:** Thêm hình ảnh vào `assets/images/`

**Bước 2:** Thêm translation keys vào `assets/translations/vi.json` và `en.json`
```json
// vi.json
{
  "dest_yourplace_desc": "Mô tả bằng tiếng Việt"
}

// en.json
{
  "dest_yourplace_desc": "Description in English"
}
```

**Bước 3:** Thêm destination vào `lib/data/mock_destinations.dart`
```dart
Destination(
  id: '11',
  name: 'Tên điểm đến',
  province: 'Tỉnh/Thành phố',
  imagePath: 'assets/images/your_image.jpg',
  tags: ['Tag1', 'Tag2'],
  location: 'việt nam',
  description: 'Mô tả tiếng Việt',
  descriptionKey: 'dest_yourplace_desc', // Translation key
  cityId: 'yourplace',
),
```

### 2. Tạo màn hình mới

**Bước 1:** Tạo file trong `lib/screens/`
```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class YourNewScreen extends StatefulWidget {
  const YourNewScreen({Key? key}) : super(key: key);

  @override
  State<YourNewScreen> createState() => _YourNewScreenState();
}

class _YourNewScreenState extends State<YourNewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('screen_title'.tr()),
      ),
      body: Center(
        child: Text('hello'.tr()),
      ),
    );
  }
}
```

**Bước 2:** Import và sử dụng trong màn hình khác
```dart
import 'screens/your_new_screen.dart';

// Navigate
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const YourNewScreen()),
);
```

### 3. Tạo widget có thể tái sử dụng

Tạo file trong `lib/widgets/`
```dart
import 'package:flutter/material.dart';

class CustomWidget extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  
  const CustomWidget({
    Key? key,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Text(title),
      ),
    );
  }
}
```

### 4. Tạo model mới

Tạo file trong `lib/models/`
```dart
class YourModel {
  final String id;
  final String name;
  // Các fields khác...

  const YourModel({
    required this.id,
    required this.name,
  });

  // copyWith method để tạo instance mới với các giá trị updated
  YourModel copyWith({
    String? id,
    String? name,
  }) {
    return YourModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  // Từ JSON (nếu dùng API)
  factory YourModel.fromJson(Map<String, dynamic> json) {
    return YourModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  // Sang JSON (nếu dùng API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
```

## 📝 Quy ước code

### Naming Convention
- **Files**: `snake_case.dart` (vd: `destination_detail_screen.dart`)
- **Classes**: `PascalCase` (vd: `DestinationDetailScreen`)
- **Variables/Functions**: `camelCase` (vd: `getUserData()`)
- **Constants**: `camelCase` với prefix `k` (vd: `kPrimaryColor`)
- **Private members**: prefix `_` (vd: `_privateMethod()`)

### Code Structure
```dart
// 1. Imports
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// 2. Constants
const kPrimaryColor = Color(0xFF6200EE);

// 3. Class definition
class MyWidget extends StatefulWidget {
  // 4. Constructor
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 5. State variables
  String _data = '';

  // 6. Lifecycle methods
  @override
  void initState() {
    super.initState();
  }

  // 7. Custom methods
  void _handleAction() {
    // Implementation
  }

  // 8. Build method
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### Comments
```dart
/// File-level documentation
/// Description: Brief description of the file's purpose

// Single line comment cho logic phức tạp

/**
 * Multi-line comment
 * cho các phần cần giải thích chi tiết
 */
```

## 🌐 Tính năng đa ngôn ngữ

### Cách hoạt động
App sử dụng package `easy_localization` để hỗ trợ đa ngôn ngữ.

### Cấu hình trong main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('vi'),  // Ngôn ngữ mặc định
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}
```

### Thêm text cần dịch

**Bước 1:** Thêm vào `assets/translations/vi.json`
```json
{
  "welcome_message": "Chào mừng bạn đến với Travel Together",
  "button_continue": "Tiếp tục"
}
```

**Bước 2:** Thêm vào `assets/translations/en.json`
```json
{
  "welcome_message": "Welcome to Travel Together",
  "button_continue": "Continue"
}
```

**Bước 3:** Sử dụng trong code
```dart
import 'package:easy_localization/easy_localization.dart';

Text('welcome_message'.tr()),  // Method 1
Text(tr('button_continue')),   // Method 2
```

### Đổi ngôn ngữ trong app
```dart
// Đổi sang tiếng Anh
context.setLocale(const Locale('en'));

// Đổi sang tiếng Việt
context.setLocale(const Locale('vi'));

// Lấy ngôn ngữ hiện tại
Locale currentLocale = context.locale;
```

### Translation cho Description điểm đến

Trong dự án này, description của các điểm đến được dịch theo cách:

1. **Model có 2 fields:**
   - `description`: Giá trị tiếng Việt (dùng cho search và fallback)
   - `descriptionKey`: Key để lấy translation từ file JSON

2. **Hiển thị sử dụng `descriptionKey`:**
```dart
Text(destination.descriptionKey.tr())  // Tự động lấy theo ngôn ngữ hiện tại
```

3. **Ví dụ trong translation files:**
```json
// vi.json
{
  "dest_danang_desc": "Thành phố đáng sống nhất Việt Nam, nổi tiếng với biển Mỹ Khê, cầu Rồng, Bà Nà Hills và Sơn Trà."
}

// en.json
{
  "dest_danang_desc": "Vietnam's most livable city, famous for My Khe Beach, Dragon Bridge, Ba Na Hills and Son Tra."
}
```

### Translation cho Subtitle trong Explore Items

Tương tự, subtitle của các địa điểm khám phá cũng được dịch:

1. **Model `DestinationExploreItem` có 2 fields:**
   - `subtitle`: Giá trị tiếng Việt gốc
   - `subtitleKey`: Key để lấy translation

2. **Hiển thị:**
```dart
Text(exploreItem.subtitleKey.tr())
```

3. **Ví dụ:**
```json
// vi.json
{
  "subtitle_famous_beach": "Bãi biển nổi tiếng",
  "subtitle_city_symbol": "Biểu tượng thành phố"
}

// en.json
{
  "subtitle_famous_beach": "Famous Beach",
  "subtitle_city_symbol": "City Symbol"
}
```

## 📊 Quản lý dữ liệu

### Mock Data (Development)
Hiện tại app sử dụng mock data trong thư mục `lib/data/`:
- `mock_destinations.dart`: 10 điểm đến nổi tiếng VN
- `mock_explore_items.dart`: Danh sách điểm đến có thể khám phá
- `mock_messages.dart`: Tin nhắn mẫu

### Cấu trúc Destination Model
```dart
class Destination {
  final String id;              // ID unique
  final String name;            // Tên điểm đến
  final String province;        // Tỉnh/Thành phố
  final String imagePath;       // Đường dẫn hình ảnh
  final double rating;          // Đánh giá (0.0 - 5.0)
  final List<String> tags;      // Tags: ['Biển', 'Giải trí']
  final String location;        // 'việt nam'
  final String description;     // Mô tả tiếng Việt
  final String descriptionKey;  // Key translation
  final String cityId;          // ID city để group
}
```

### Sử dụng Mock Data
```dart
import 'package:my_travel_app/data/mock_destinations.dart';

// Lấy tất cả destinations
final allDestinations = mockDestinations;

// Lấy destinations đề xuất
final recommended = recommendedDestinations;

// Filter theo điều kiện
final beachDestinations = mockDestinations
    .where((d) => d.tags.contains('Biển'))
    .toList();

// Tìm destination theo ID
final destination = mockDestinations
    .firstWhere((d) => d.id == '1');
```

### Chuẩn bị cho API Integration
Khi tích hợp API thật, bạn cần:

1. **Tạo service layer** (`lib/services/api_service.dart`)
```dart
class ApiService {
  static const String baseUrl = 'https://api.example.com';
  
  Future<List<Destination>> getDestinations() async {
    // Call API
    // Parse response
    // Return data
  }
}
```

2. **Sử dụng State Management** (Provider, Riverpod, Bloc, etc.)
3. **Replace mock data** bằng API calls

## 🎨 Theme & Styling

### Colors
Định nghĩa trong từng screen (nên tách ra file riêng):
```dart
const kAppBgColor = Color(0xFFE8F5E9);
const kPrimaryColor = Color(0xFF4CAF50);
const kSecondaryColor = Color(0xFF81C784);
```

### Fonts
Đã config trong `pubspec.yaml`:
- **Poppins**: Font chính cho UI
- **Bangers**: Font đặc biệt
- **Alegreya, Inter, AlumniSans**: Fonts bổ sung

Sử dụng:
```dart
Text(
  'Hello',
  style: TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
)
```

## 🐛 Debug & Testing

### Debug Mode
```bash
# Chạy với log chi tiết
flutter run -v

# Clear cache nếu có lỗi
flutter clean
flutter pub get
```

### Hot Reload & Hot Restart
- **Hot Reload**: `r` trong terminal (giữ state)
- **Hot Restart**: `R` trong terminal (reset state)

### Common Issues

**1. Translation không hiển thị:**
- Check file JSON có đúng format không
- Chạy `flutter clean` và `flutter pub get`
- Restart app hoàn toàn

**2. Image không load:**
- Check đường dẫn trong `pubspec.yaml`
- Check file có tồn tại trong `assets/images/`
- Chạy `flutter pub get` sau khi thêm asset mới

**3. Build errors:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

## 📚 Resources hữu ích

### Documentation
- [Flutter Official Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Easy Localization Package](https://pub.dev/packages/easy_localization)

### UI/UX
- [Material Design](https://material.io/)
- [Flutter Widget Catalog](https://flutter.dev/docs/development/ui/widgets)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

## 👥 Team Workflow

### Git Workflow (Recommended)
```bash
# Tạo branch mới cho feature
git checkout -b feature/your-feature-name

# Commit changes
git add .
git commit -m "Add: description of changes"

# Push to remote
git push origin feature/your-feature-name

# Tạo Pull Request để review
```

### Commit Message Convention
```
Add: Thêm tính năng mới
Fix: Sửa bug
Update: Cập nhật code
Refactor: Tái cấu trúc code
Docs: Cập nhật documentation
Style: Format code, không thay đổi logic
```

## 📝 TODO & Future Features

- [ ] Tích hợp API backend thật
- [ ] State management (Provider/Bloc)
- [ ] Authentication & Authorization
- [ ] Real-time chat (Firebase/Socket.io)
- [ ] Push notifications
- [ ] Offline mode với local storage
- [ ] Payment integration
- [ ] Map integration (Google Maps)
- [ ] Social sharing
- [ ] User reviews & ratings

## 📞 Liên hệ & Hỗ trợ

Nếu có câu hỏi hoặc cần hỗ trợ:
- Review code trong Pull Request
- Trao đổi trực tiếp với team
- Tham khảo documentation này

---

**Happy Coding! 🚀**

*Last updated: November 2025*

