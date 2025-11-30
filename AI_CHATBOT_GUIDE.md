# ✅ AI CHATBOT - Hướng dẫn sử dụng

## 🎯 Tính năng mới

Đã tích hợp **AI Travel Assistant** (Gemini 2.5 Flash) vào app!

### Đặc điểm:
- 🤖 Chat với AI về du lịch
- 💾 Lưu lịch sử chat tự động
- 🔄 Realtime response từ Gemini
- 📱 Hiển thị trong Messages Screen như một conversation
- 🧹 Có thể xóa lịch sử chat

---

## 📂 Files đã tạo/sửa

### Files mới:
1. ✅ **lib/models/ai_message.dart** - Model cho AI messages
2. ✅ **lib/screens/ai_chatbot_screen.dart** - Màn hình chat với AI

### Files đã sửa:
1. ✅ **lib/config/api_config.dart** - Thêm AI endpoints
2. ✅ **lib/screens/messages_screen.dart** - Hiển thị AI conversation
3. ✅ **assets/translations/en.json** - Thêm translations
4. ✅ **assets/translations/vi.json** - Thêm translations

---

## 🔧 Cách hoạt động

### 1. Khởi tạo Session

Khi lần đầu mở AI Chatbot:
```dart
POST /ai/new_session
→ Response: { "session_id": "abc123..." }
→ Lưu vào SharedPreferences
```

### 2. Gửi tin nhắn

```dart
POST /ai/send
Body: {
  "session_id": "abc123...",
  "message": "Tư vấn địa điểm du lịch Đà Nẵng"
}
→ Response: { "response": "Đà Nẵng có nhiều địa điểm..." }
```

### 3. Lưu lịch sử

Tất cả tin nhắn (user + AI) được lưu vào:
```
SharedPreferences:
- Key: "ai_chat_session_id"
- Key: "ai_chat_messages" → JSON array
```

### 4. Hiển thị trong Messages

Messages Screen **LUÔN LUÔN** hiển thị:
1. **AI Chatbot** (ở đầu danh sách, luôn có)
   - Nếu chưa chat: Hiện "Nhấn để bắt đầu chat với AI!"
   - Nếu đã chat: Hiện tin nhắn gần nhất
2. **Group Chat** (nếu đã tham gia nhóm)

---

## 📱 Giao diện

### Messages Screen
```
┌─────────────────────────────┐
│ Messages                    │
├─────────────────────────────┤
│ 🤖 AI Chatbot               │ ← LUÔN CÓ
│    Nhấn để bắt đầu...       │ ← (hoặc tin nhắn gần nhất)
├─────────────────────────────┤
│ 👥 Nhóm chat                │ ← Chỉ hiện nếu đã join group
│    Chào mọi người!     14:25│
└─────────────────────────────┘
```

### AI Chatbot Screen
```
┌──────────────────────────────────┐
│   🤖 AI Travel Assistant    🗑️  │
├──────────────────────────────────┤
│         Trò chuyện với AI        │
├──────────────────────────────────┤
│ 🤖 Xin chào! Tôi là trợ lý      │
│    du lịch...                    │
│                                   │
│              Tư vấn Đà Nẵng 👤  │
│                                   │
│ 🤖 Đà Nẵng có nhiều điểm đến    │
│    tuyệt vời như...              │
└──────────────────────────────────┘
│ [Hỏi tôi về du lịch...] [📤]    │
```

---

## 🎨 Màu sắc

| Element | Màu | Code |
|---------|-----|------|
| User message | Nâu đậm | #8A724C |
| AI message | Nâu nhạt | #B99668 |
| Background | Be | #EBE3D7 |

---

## 🔑 API Endpoints

### 1. Tạo Session
```
POST /ai/new_session
Response:
{
  "session_id": "string"
}
```

### 2. Gửi tin nhắn
```
POST /ai/send
Body:
{
  "session_id": "string",
  "message": "string"
}
Response:
{
  "response": "string"
}
```

---

## 📋 Translations

### English (en.json)
```json
{
  "ai_chat_title": "AI Travel Assistant",
  "ai_chat_bot_name": "AI Chatbot",
  "ai_chat_welcome": "Hi! I'm your travel assistant.\nAsk me anything about travel!",
  "ai_chat_input_hint": "Ask me about travel...",
  "ai_chat_clear_title": "Clear Chat History",
  "ai_chat_clear_message": "Are you sure you want to clear all chat history with AI?"
}
```

### Vietnamese (vi.json)
```json
{
  "ai_chat_title": "Trợ lý AI Du lịch",
  "ai_chat_bot_name": "AI Chatbot",
  "ai_chat_welcome": "Xin chào! Tôi là trợ lý du lịch của bạn.\nHãy hỏi tôi bất cứ điều gì về du lịch!",
  "ai_chat_input_hint": "Hỏi tôi về du lịch...",
  "ai_chat_clear_title": "Xóa lịch sử chat",
  "ai_chat_clear_message": "Bạn có chắc muốn xóa toàn bộ lịch sử chat với AI?"
}
```

---

## 🚀 Cách sử dụng

### 1. Mở AI Chatbot

**Cách 1**: Từ Messages Screen (KHUYẾN NGHỊ)
```
1. Vào tab Messages
2. AI Chatbot LUÔN LUÔN ở đầu danh sách
3. Tap vào "AI Chatbot" để mở
```

**Cách 2**: Direct navigation (nếu cần)
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AiChatbotScreen(),
  ),
);
```

### 2. Chat với AI

```
1. Nhập câu hỏi: "Tư vấn địa điểm Đà Nẵng"
2. Bấm Send hoặc Enter
3. Đợi AI trả lời (có loading indicator)
4. Xem response từ AI
```

### 3. Xóa lịch sử

```
1. Trong AI Chatbot Screen
2. Bấm icon 🗑️ ở góc trên phải
3. Xác nhận
4. Lịch sử chat bị xóa, tạo session mới
```

---

## 🔍 Debug

### Kiểm tra Session ID
```dart
final prefs = await SharedPreferences.getInstance();
final sessionId = prefs.getString('ai_chat_session_id');
print('AI Session ID: $sessionId');
```

### Kiểm tra Messages
```dart
final messages = prefs.getString('ai_chat_messages');
print('AI Messages: $messages');
```

### Log trong code
```
✅ Created new AI session: abc123...
❌ Error creating AI session: ...
❌ Error sending AI message: ...
```

---

## ⚠️ Lưu ý

### 1. Backend phải chạy
```bash
cd backend
.\run_server.bat
```

### 2. Gemini API Key
Backend cần có `GEMINI_API_KEY` trong `config.py`:
```python
GEMINI_API_KEY = "AIza..."
```

### 3. Session timeout
Session lưu vĩnh viễn trong app cho đến khi:
- User xóa lịch sử
- Uninstall app
- Clear app data

### 4. Offline mode
- Không có auto-refresh như Group Chat
- Phải có internet để gọi API
- Messages được lưu local, có thể xem offline

---

## 🐛 Xử lý lỗi

### Lỗi: "Failed to create AI session"
**Nguyên nhân**: Backend không chạy hoặc API endpoint sai

**Giải pháp**:
1. Check backend đang chạy
2. Check IP trong `api_config.dart`
3. Check log backend

### Lỗi: "Failed to send message to AI"
**Nguyên nhân**: Session không tồn tại hoặc Gemini API lỗi

**Giải pháp**:
1. Xóa lịch sử chat (tạo session mới)
2. Check log backend
3. Check Gemini API key

### Conversation không hiện trong Messages
**Câu hỏi**: AI Chatbot không hiện?

**Giải pháp**: AI Chatbot LUÔN LUÔN hiển thị ở đầu danh sách Messages. Nếu không thấy:
1. Reload app
2. Check code đã update chưa
3. Check translation files có key `ai_chat_bot_name` chưa

---

## 📊 Luồng dữ liệu

```
User nhập tin nhắn
    ↓
Lưu vào _messages (UI update)
    ↓
POST /ai/send (với session_id + message)
    ↓
Backend → Gemini API
    ↓
AI response trả về
    ↓
Lưu vào _messages (UI update)
    ↓
Lưu vào SharedPreferences (persist)
    ↓
Messages Screen tự động load tin mới nhất
```

---

## 🎯 Test Case

### Test 1: Tạo session mới
```
1. Chưa từng mở AI Chat
2. Mở AI Chatbot Screen
3. → Tự động tạo session
4. → Hiển thị welcome message
```

### Test 2: Gửi tin nhắn
```
1. Nhập: "Gợi ý địa điểm Hà Nội"
2. Bấm Send
3. → Loading indicator hiện
4. → AI response hiển thị sau vài giây
```

### Test 3: Lưu lịch sử
```
1. Gửi vài tin nhắn
2. Thoát app
3. Mở lại app
4. Vào AI Chatbot
5. → Lịch sử chat vẫn còn
```

### Test 4: Hiển thị trong Messages
```
1. Gửi tin nhắn với AI: "Hello"
2. Quay về Messages Screen
3. → "AI Chatbot" hiện với tin "Hello"
```

### Test 5: Xóa lịch sử
```
1. Bấm icon 🗑️
2. Xác nhận
3. → Lịch sử bị xóa
4. → Tạo session mới
```

---

## 🚀 Tính năng có thể mở rộng

- [ ] Voice input (speech to text)
- [ ] Suggest quick questions
- [ ] Share AI response
- [ ] Export chat history
- [ ] AI avatar animation
- [ ] Typing indicator
- [ ] Multi-language AI (auto detect)
- [ ] Context-aware responses (based on user profile)

---

**Hoàn thành**: 25/11/2025 ✅

