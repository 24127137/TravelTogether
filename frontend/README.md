# Travel Together - Flutter App

## 📱 Giới thiệu dự án

**Travel Together** là một ứng dụng du lịch được phát triển bằng Flutter, cho phép người dùng khám phá các điểm đến du lịch tại Việt Nam, tìm kiếm địa điểm, quản lý lịch trình và giao tiếp với các thành viên trong nhóm du lịch.

### ✨ Tính năng chính

- 🏠 **Trang chủ**: Hiển thị top 5 điểm đến hàng đầu, tìm kiếm điểm đến, chọn ngày du lịch
- 🔍 **Khám phá**: Duyệt danh sách các điểm đến ở Việt Nam với bộ lọc
- 💬 **Tin nhắn**: Giao tiếp với các thành viên nhóm
- ⚙️ **Cài đặt**: Thay đổi ngôn ngữ (Tiếng Việt/English), quản lý tài khoản
- 🌐 **Đa ngôn ngữ**: Hỗ trợ Tiếng Việt và English

---

## 🛠️ Công nghệ sử dụng

### Framework & Ngôn ngữ
- **Flutter**: SDK 3.0.0+
- **Dart**: 3.0.0+

### Thư viện chính

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8       # Icons iOS
  intl: ^0.20.2                  # Định dạng ngày tháng
  table_calendar: ^3.0.9         # Lịch chọn ngày
  easy_localization: ^3.0.8      # Đa ngôn ngữ
```

### Dev Dependencies

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0          # Linting rules
```

---

## 📂 Cấu trúc dự án

```
frontend/
├── assets/                      # Tài nguyên tĩnh
│   ├── fonts/                   # Font chữ
│   │   ├── Poppins-Regular.ttf
│   │   ├── Inter-VariableFont_opsz,wght.ttf
│   │   └── ...
│   ├── images/                  # Hình ảnh
│   │   ├── avatar.jpg
│   │   ├── danang.jpg
│   │   ├── dalat.jpg
│   │   └── ...
│   └── translations/            # File đa ngôn ngữ
│       ├── en.json              # Tiếng Anh
│       └── vi.json              # Tiếng Việt
│
├── lib/                         # Mã nguồn chính
│   ├── main.dart                # Entry point
│   ├── screens/                 # Các màn hình
│   │   ├── main_app_screen.dart
│   │   ├── home_page.dart
│   │   ├── messages_screen.dart
│   │   ├── chatbox_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── destination_detail_screen.dart
│   │   ├── destination_explore_screen.dart
│   │   ├── destination_search_screen.dart
│   │   └── before_group_screen.dart
│   │
│   ├── widgets/                 # Các widget tái sử dụng
│   │   ├── custom_bottom_nav_bar.dart
│   │   ├── destination_card.dart
│   │   └── destination_search_modal.dart
│   │
│   ├── models/                  # Data models
│   │   ├── destination.dart
│   │   ├── destination_explore_item.dart
│   │   └── message.dart
│   │
│   └── data/                    # Mock data
│       ├── mock_destinations.dart
│       ├── mock_explore_items.dart
│       └── mock_messages.dart
│
├── android/                     # Cấu hình Android
├── ios/                         # Cấu hình iOS
├── web/                         # Cấu hình Web
├── pubspec.yaml                 # Dependencies
└── analysis_options.yaml        # Linting rules
```

---

## 🎨 Quy ước thiết kế UI/UX

### Màu sắc chính (Color Palette)

```dart
// Màu cam chủ đạo
Color(0xFFA15C20)  // Cam đậm - Header, buttons
Color(0xFFFF6B00)  // Cam sáng - Accent, borders
Color(0xFFB64B12)  // Cam đỏ - Logout button

// Màu nền
Color(0xFFEDE2CC)  // Kem/be - Background, cards
Color(0xFFF7F7F7)  // Xám nhạt - Screen background

// Màu text
Color(0xFFFFFFFF)  // Trắng - Text trên nền tối
Color(0xFF8A724C)  // Nâu nhạt - Title text
Color(0xFF7B4A22)  // Nâu đậm - Background tối
```

### Font chữ

- **Poppins**: Sử dụng chủ yếu cho tiêu đề và buttons
- **Inter**: Sử dụng cho nội dung text thông thường
- **Alegreya, Bangers**: Dự phòng cho các màn hình đặc biệt

### Kích thước chuẩn

```dart
// Border radius
BorderRadius.circular(20)  // Cards
BorderRadius.circular(30)  // Buttons, containers lớn

// Padding & Spacing
EdgeInsets.all(20)         // Container padding
SizedBox(height: 12-20)    // Vertical spacing
SizedBox(width: 12-16)     // Horizontal spacing

// Font sizes
fontSize: 32               // Screen titles
fontSize: 20               // Section headers
fontSize: 17-18            // Normal text
fontSize: 14               // Secondary text
```

---

## 📝 Quy ước code

### 1. Cấu trúc File

Mỗi file **PHẢI BẮT ĐẦU** với comment mô tả:

```dart
/// File: tên_file.dart
/// Mô tả: Mô tả ngắn gọn về chức năng của file
```

**Ví dụ:**

```dart
/// File: settings_screen.dart
/// Mô tả: Màn hình cài đặt với giao diện tiếng Việt
```

### 2. Import statements

Thứ tự import:

1. Flutter core packages
2. External packages
3. Internal imports (models, widgets, screens)

```dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/destination.dart';
import '../widgets/custom_bottom_nav_bar.dart';
```

### 3. Comment code

- **Tiếng Việt** cho inline comments
- **English** cho doc comments (///)
- Sử dụng comments để giải thích logic phức tạp

```dart
// Bấm < = chuyển về tiếng Việt
onLeftTap: () {
context.setLocale(const Locale('vi'));
},

// Bấm > = chuyển sang tiếng Anh
onRightTap: () {
context.setLocale(const Locale('en'));
},
```

### 4. Naming conventions

```dart
// Class names: PascalCase
class SettingsScreen extends StatefulWidget {}

// Variables: camelCase
int _selectedIndex = 0;
bool _showGroupFeedback = true;

// Private variables: prefix với _
bool _isCalendarVisible = false;

// Constants: camelCase hoặc UPPERCASE
const Color primaryColor = Color(0xFFA15C20);
static const String API_URL = 'https://api.example.com';

// Functions: camelCase
void _onItemTapped(int index) {}
Widget _buildSettingTile() {}
```

### 5. Widget Organization

Tất cả screens **PHẢI** có:

- `onBack` callback (nếu có navigation)
- SafeArea wrapper
- Consistent color scheme

```dart
class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Widget content
        ],
      ),
    );
  }
}
```

### 6. Tách helper methods

Tạo các helper methods bắt đầu với `_build` cho reusable UI components:

```dart
Widget _buildSettingTile({
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  VoidCallback? onLeftTap,
  VoidCallback? onRightTap,
  bool hideArrows = false,
}) {
  return Container(
    // ... widget implementation
  );
}
```

---

## 🌐 Đa ngôn ngữ (Internationalization)

### Thiết lập trong main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('vi'),  // Mặc định tiếng Việt
      useOnlyLangCode: true,
      child: const MyApp(),
    ),
  );
}
```

### Sử dụng translation

```dart
// Trong widget
Text('settings'.tr()),  // Sẽ hiển thị "Cài đặt" (vi) hoặc "Settings" (en)

// Kiểm tra ngôn ngữ hiện tại
context.locale.languageCode == 'en' ? 'english'.tr() : 'vietnamese'.tr()

// Thay đổi ngôn ngữ
context.setLocale(const Locale('vi'));  // Chuyển sang tiếng Việt
context.setLocale(const Locale('en'));  // Chuyển sang tiếng Anh
```

### Thêm translation mới

**Bước 1:** Mở `assets/translations/vi.json`:

```json
{
  "settings": "Cài đặt",
  "new_key": "Giá trị mới"
}
```

**Bước 2:** Mở `assets/translations/en.json`:

```json
{
  "settings": "Settings",
  "new_key": "New value"
}
```

**Bước 3:** Sử dụng trong code:

```dart
Text('new_key'.tr())
```

---

## 🗂️ Models & Data

### Tạo Model mới

```dart
/// File: model_name.dart
/// Description: Mô tả model

class ModelName {
  final String id;
  final String name;
  // ... other properties

  const ModelName({
    required this.id,
    required this.name,
    // ... other properties
  });

  // copyWith method để tạo instance mới với properties đã update
  ModelName copyWith({
    String? id,
    String? name,
  }) {
    return ModelName(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
```

### Mock Data

Tạo file trong `lib/data/`:

```dart
/// File: mock_data_name.dart
/// Description: Mock data cho [feature]

import '../models/model_name.dart';

final List<ModelName> mockDataName = [
  ModelName(
    id: '1',
    name: 'Item 1',
    // ...
  ),
  // ... more items
];
```

---

## 🔄 State Management

### Sử dụng setState

Dự án này sử dụng **StatefulWidget** với **setState** để quản lý state:

```dart
class _MyScreenState extends State<MyScreen> {
  bool _isVisible = false;

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVisibility,
      child: _isVisible ? Widget1() : Widget2(),
    );
  }
}
```

### Navigation giữa screens

Sử dụng callbacks thông qua parent widget (MainAppScreen):

```dart
// Trong MainAppScreen
void _openDestinationDetail(Destination dest) {
  setState(() {
    _selectedDestination = dest;
    _showDetail = true;
  });
}

// Truyền callback cho child
HomePage(
onDestinationTap: _openDestinationDetail,
)
```

---

## 🎯 Hướng dẫn thêm tính năng mới

### 1. Thêm màn hình mới

**Bước 1:** Tạo file trong `lib/screens/`:

```dart
/// File: new_screen.dart
/// Mô tả: Màn hình mới cho [feature]

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NewScreen extends StatefulWidget {
  final VoidCallback onBack;

  const NewScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header với nút back
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Icon(Icons.arrow_back),
              ),
              Text('new_screen_title'.tr()),
            ],
          ),
          // Nội dung màn hình
        ],
      ),
    );
  }
}
```

**Bước 2:** Thêm translations:

```json
// vi.json
{
  "new_screen_title": "Tiêu đề màn hình mới"
}

// en.json
{
  "new_screen_title": "New Screen Title"
}
```

**Bước 3:** Tích hợp vào MainAppScreen (nếu cần):

```dart
class _MainAppScreenState extends State<MainAppScreen> {
  bool _showNewScreen = false;

  void _openNewScreen() {
    setState(() {
      _showNewScreen = true;
    });
  }

  void _closeNewScreen() {
    setState(() {
      _showNewScreen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showNewScreen) {
      return NewScreen(onBack: _closeNewScreen);
    }
    // ... existing code
  }
}
```

### 2. Thêm Widget tái sử dụng

Tạo file trong `lib/widgets/`:

```dart
/// File: custom_widget.dart
/// Mô tả: Widget tái sử dụng cho [purpose]

import 'package:flutter/material.dart';

class CustomWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const CustomWidget({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Widget implementation
        child: Text(title),
      ),
    );
  }
}
```

### 3. Thêm Model & Mock Data

**Model:**

```dart
/// File: new_model.dart
/// Description: Data model for [feature]

class NewModel {
  final String id;
  final String name;

  const NewModel({
    required this.id,
    required this.name,
  });
}
```

**Mock Data:**

```dart
/// File: mock_new_data.dart
/// Description: Mock data for [feature]

import '../models/new_model.dart';

final List<NewModel> mockNewData = [
  NewModel(id: '1', name: 'Item 1'),
  NewModel(id: '2', name: 'Item 2'),
];
```

---

## 🚀 Chạy dự án

### Yêu cầu hệ thống

- Flutter SDK: >=3.0.0
- Dart SDK: >=3.0.0
- Android Studio / VS Code
- Git

### Cài đặt

**Bước 1:** Clone repository:

```bash
cd D:\TDTT TRAVEL PROJECT\my_travel_app\TravelTogether\frontend
```

**Bước 2:** Cài đặt dependencies:

```bash
flutter pub get
```

**Bước 3:** Chạy app:

```bash
# Debug mode
flutter run

# Release mode (Android)
flutter run --release

# Chọn device cụ thể
flutter run -d chrome        # Web
flutter run -d android       # Android
flutter run -d ios           # iOS
```

### Debug

```bash
# Kiểm tra lỗi
flutter analyze

# Format code
flutter format lib/

# Clean build
flutter clean
flutter pub get
```

---

## 📱 Build & Deploy

### Android APK

```bash
# Build APK
flutter build apk --release

# Build App Bundle (cho Google Play)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

Output: `build/web/`

---

## ✅ Checklist khi code tính năng mới

- [ ] File có comment mô tả đầy đủ
- [ ] Import statements được sắp xếp đúng thứ tự
- [ ] Sử dụng const constructor khi có thể
- [ ] Variables private bắt đầu với `_`
- [ ] Naming conventions đúng chuẩn
- [ ] Thêm translations cho cả vi.json và en.json
- [ ] Sử dụng color palette đã định nghĩa
- [ ] SafeArea wrapper cho screens
- [ ] Có callback onBack (nếu có navigation)
- [ ] Format code: `flutter format .`
- [ ] Chạy `flutter analyze` không có lỗi
- [ ] Test trên cả tiếng Việt và English
- [ ] Test responsive trên nhiều kích thước màn hình

---

## 🐛 Troubleshooting

### Lỗi thường gặp

**1. Translation không hiển thị:**

```dart
// Đảm bảo đã wrap MaterialApp với localizationsDelegates
MaterialApp(
localizationsDelegates: context.localizationDelegates,
supportedLocales: context.supportedLocales,
locale: context.locale,
)
```

**2. Asset không load được:**

```yaml
# Kiểm tra pubspec.yaml
flutter:
  assets:
    - assets/images/
    - assets/translations/
```

Sau đó chạy:

```bash
flutter clean
flutter pub get
```

**3. Font không hiển thị:**

```yaml
# Kiểm tra pubspec.yaml có khai báo font
fonts:
  - family: Poppins
    fonts:
      - asset: assets/fonts/Poppins-Regular.ttf
```

**4. Build lỗi:**

```bash
flutter clean
flutter pub cache repair
flutter pub get
flutter run
```

---

## 📚 Tài liệu tham khảo

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Easy Localization Package](https://pub.dev/packages/easy_localization)
- [Table Calendar Package](https://pub.dev/packages/table_calendar)
- [Material Design Guidelines](https://material.io/design)

---

## 👥 Team & Contact

- **Project Name**: Travel Together
- **Framework**: Flutter
- **Version**: 1.0.0+1

### Quy trình làm việc

1. Tạo branch mới cho mỗi tính năng
2. Follow coding conventions trong README
3. Test kỹ trước khi commit
4. Tạo Pull Request để review
5. Merge sau khi được approve

---

## 📝 Notes quan trọng

### Color System

- **KHÔNG** hardcode màu trực tiếp trong widget
- Sử dụng Color palette đã định nghĩa
- Maintain consistency across app

### Translations

- **LUÔN LUÔN** thêm key mới vào CẢ `vi.json` VÀ `en.json`
- Test app với cả 2 ngôn ngữ
- Sử dụng `.tr()` cho mọi text hiển thị

### Navigation

- Sử dụng callback pattern qua MainAppScreen
- KHÔNG dùng `Navigator.push` trực tiếp (trừ modal/dialog)
- Maintain single source of truth cho navigation state

### State Management

- Sử dụng `setState` cho local state
- Pass callbacks từ parent xuống child
- Tránh deep nesting callbacks (max 2-3 levels)

---

## 🎓 Học Flutter nhanh

### Concepts cơ bản cần nắm

**1. StatelessWidget vs StatefulWidget**

- StatelessWidget: UI không thay đổi
- StatefulWidget: UI có thể thay đổi với setState

**2. Widget Tree & Build Context**

- Hiểu cách Flutter build UI
- Context để truy cập theme, navigation, etc.

**3. Layout Widgets**

- Column, Row, Stack
- Container, Padding, SizedBox
- Expanded, Flexible

**4. State Management**

- setState cho simple state
- Callbacks để communicate giữa widgets

**5. Navigation**

- Navigator.push/pop
- Callback pattern (dự án này dùng)

### Resources học Flutter

- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Widget Catalog](https://docs.flutter.dev/development/ui/widgets)
- [Dart Pad](https://dartpad.dev/) - Online editor

---

## 📅 Changelog

### Version 1.0.0 (Current)

- ✅ Home page with top destinations
- ✅ Destination search & detail
- ✅ Messages & chatbox
- ✅ Settings with language switch
- ✅ Multi-language support (vi/en)
- ✅ Bottom navigation bar
- ✅ Calendar picker for travel dates

### Planned Features

- [ ] User authentication
- [ ] Backend API integration
- [ ] Group travel management
- [ ] Booking integration
- [ ] Push notifications
- [ ] User reviews & ratings

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Happy Coding! 🚀**

Nếu có bất kỳ câu hỏi nào, hãy tham khảo code examples trong dự án hoặc liên hệ team leader.