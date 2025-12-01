# 🚀 AI Chatbot Screen - Complete Fix Guide

## 📌 Overview

Đã sửa AI Chatbot screen để:
1. ✅ **Lưu lịch sử nhắn tin với AI vào Database** (backend)
2. ✅ **Upload được ảnh khi nhắn với AI**
3. ✅ **Thêm nút scroll to bottom ở góc dưới phải** (như chatbox_screen)

---

## 🔄 Architecture Changes

### Before (Old)
```
User → [Session-based] → Message sent to API → Message saved locally
                         ✗ No history persistence
```

### After (New)
```
User → [User ID based] → Message sent to API → Auto-saved to DB
                         ✓ Full history persistence
                         ✓ Multi-device sync capable
```

---

## 📝 Detailed Changes

### 1️⃣ History Saving to Backend

#### API Endpoints Used

**POST /ai/send** - Send message (auto-saves)
```bash
curl -X POST "http://192.168.1.9:8000/ai/send?user_id=USER_UUID" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello AI"}'
```

Response:
```json
{
  "response": "AI response here",
  "message_id": 123
}
```

**GET /ai/chat-history** - Load history on init
```bash
curl -X GET "http://192.168.1.9:8000/ai/chat-history?user_id=USER_UUID&limit=50"
```

Response:
```json
{
  "user_id": "uuid-string",
  "messages": [
    {
      "id": 1,
      "role": "user",
      "content": "Hello",
      "message_type": "text",
      "image_url": null,
      "created_at": "2024-12-01T10:30:00Z"
    },
    {
      "id": 2,
      "role": "model",
      "content": "Hi there!",
      "message_type": "text",
      "image_url": null,
      "created_at": "2024-12-01T10:30:05Z"
    }
  ]
}
```

**DELETE /ai/clear-chat** - Clear history
```bash
curl -X DELETE "http://192.168.1.9:8000/ai/clear-chat?user_id=USER_UUID"
```

---

### 2️⃣ Image Upload Support

#### Image Upload Flow

```
User taps image button
    ↓
Shows bottom sheet (Gallery / Camera)
    ↓
User selects image
    ↓
Upload to Supabase Storage ("chat_images" bucket)
    ↓
Get public URL
    ↓
Send to AI with image_url
    ↓
Display in chat bubble with loading state
```

#### Code Example
```dart
// 1. Select image
final XFile? pickedFile = await _imagePicker.pickImage(
  source: ImageSource.gallery, // or .camera
  imageQuality: 85,
);

// 2. Upload to Supabase
await supabase.storage
    .from('chat_images')
    .upload('ai_chat_${timestamp}.jpg', file);

// 3. Get public URL
final imageUrl = supabase.storage
    .from('chat_images')
    .getPublicUrl(fileName);

// 4. Send to AI
await _sendImageMessage(imageUrl);
```

#### Message Structure
```json
{
  "message": "",
  "image_url": "https://meuqntvawakdzntewscp.supabase.co/storage/v1/object/public/chat_images/ai_chat_1701420600000.jpg"
}
```

---

### 3️⃣ Scroll-to-Bottom Button Position

#### Position Change
```dart
// Before: Center position
Center(
  child: Material(...),
)

// After: Bottom-right corner (Positioned)
Positioned(
  bottom: 80,    // 80px from bottom (above input bar)
  right: 16,     // 16px from right edge
  child: Material(...),
)
```

#### Visibility Logic
```dart
// Show button when scrolled up more than 200px from bottom
final show = currentPos < (maxScroll - 200);
```

---

## 🔧 Code Structure Changes

### State Variables
```dart
// Removed
String? _sessionId;
bool _showScrollToBottom;

// Added/Changed
String? _userId;
bool _showScrollToBottomButton;
bool _isAutoScrolling;
Map<int, GlobalKey> _messageKeys;
```

### Key Functions

#### _initializeChat()
```dart
Future<void> _initializeChat() async {
  // Get user_id from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  
  setState(() => _userId = userId);
  
  // Load history from backend
  await _loadChatHistory();
}
```

#### _loadChatHistory()
```dart
Future<void> _loadChatHistory() async {
  final url = '${ApiConfig.baseUrl}/ai/chat-history?user_id=$_userId&limit=50';
  
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    setState(() {
      _messages = data['messages']
          .map((m) => AiMessage(
            role: m['role'],
            text: m['content'],
            time: _formatTime(m['created_at']),
            imageUrl: m['image_url'],
          ))
          .toList();
    });
  }
}
```

#### _sendMessage()
```dart
Future<void> _sendMessage() async {
  // 1. Add to UI immediately
  setState(() => _messages.add(userMessage));
  
  // 2. Send to backend
  final response = await http.post(
    '${ApiConfig.baseUrl}/ai/send?user_id=$_userId',
    body: jsonEncode({"message": text}),
  );
  
  // 3. Backend automatically saves & returns response
  final aiResponse = response['response'];
  
  // 4. Display AI response
  setState(() => _messages.add(aiMessage));
}
```

#### _sendImageMessage()
```dart
Future<void> _sendImageMessage(String imageUrl) async {
  // Send to AI with image_url
  final response = await http.post(
    '${ApiConfig.baseUrl}/ai/send?user_id=$_userId',
    body: jsonEncode({
      "message": "",
      "image_url": imageUrl,
    }),
  );
}
```

---

## ✅ Testing Checklist

### Basic Functionality
- [ ] App starts and loads chat history from backend
- [ ] Can send text messages
- [ ] AI responses appear in chat
- [ ] Messages persist after app restart
- [ ] Old chat history loads on next launch

### Image Features
- [ ] Image button appears in input bar
- [ ] Can select image from gallery
- [ ] Can take photo from camera
- [ ] Image uploads to Supabase
- [ ] Sent image displays in chat bubble
- [ ] Progress indicator shows while uploading
- [ ] Image messages are saved in history

### Scroll Behavior
- [ ] Scroll-to-bottom button appears when scrolling up
- [ ] Button is positioned at bottom-right corner
- [ ] Button disappears when at bottom of list
- [ ] Clicking button scrolls to latest message

### Clear History
- [ ] Can open delete confirmation dialog
- [ ] Clearing history removes all messages
- [ ] Can send new messages after clearing
- [ ] History is empty on next app launch

### Error Handling
- [ ] Network error shows user-friendly message
- [ ] Image upload failure shows error
- [ ] Message send failure shows error
- [ ] Failed message is removed from UI

---

## 🐛 Common Issues & Solutions

### Issue: "User not authenticated"
**Solution**: Ensure user_id is saved in SharedPreferences during login
```dart
// In login.dart / signup.dart
await prefs.setString('user_id', user['id']);
```

### Issue: Images not uploading
**Solution**: Verify Supabase configuration
```
1. Check 'chat_images' bucket exists in Supabase Storage
2. Check bucket is public (not private)
3. Check Supabase keys are correct in api_config.dart
```

### Issue: Chat history not loading
**Solution**: Check backend API is running
```bash
curl http://192.168.1.9:8000/ai/chat-history?user_id=test
```

### Issue: Scroll button not showing
**Solution**: Ensure _scrollController is properly listening
```dart
// In initState
_scrollController.addListener(() {
  final show = pos < (max - 200);
  if (show != _showScrollToBottomButton) {
    setState(() => _showScrollToBottomButton = show);
  }
});
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing
  http: ^1.1.0
  shared_preferences: ^2.1.0
  image_picker: ^1.0.0
  supabase_flutter: ^1.10.0
  intl: ^0.19.0
  easy_localization: ^3.0.0
  
  # No new dependencies needed! ✅
```

---

## 🎯 Performance Considerations

### Chat History Loading
- Limit: 50 messages by default
- Pagination: Can be added if needed
- Lazy loading: Can be implemented for large histories

### Image Upload
- Max width: 1920px
- Max height: 1920px
- Quality: 85% (good balance of size/quality)
- Storage: Supabase (no local storage needed)

### Memory Usage
- Messages loaded on demand from backend
- Images cached by Flutter automatically
- No local database overhead

---

## 🚀 Future Enhancements

1. **Message Pagination**
   - Load older messages when scrolling up to top
   - Show loading indicator for older messages

2. **Message Search**
   - Search through chat history
   - Filter by date range

3. **Message Reactions**
   - Add emoji reactions to messages
   - Like/dislike AI responses

4. **Rich Text Support**
   - Code formatting
   - Markdown support
   - Link previews

5. **Message Editing**
   - Edit sent messages
   - Delete individual messages

6. **Typing Indicator**
   - Show when AI is generating response
   - Animated dots

---

## 📞 Support

If you encounter any issues:

1. Check the debugging logs in console
2. Verify all backend APIs are running
3. Ensure user is logged in (user_id exists)
4. Check network connectivity
5. Verify Supabase configuration for images

---

## ✨ Summary

| Feature | Status | Details |
|---------|--------|---------|
| History Saving | ✅ | Backend auto-save via /ai/send |
| Image Upload | ✅ | Supabase Storage integration |
| Image Display | ✅ | Chat bubbles with loading state |
| Scroll Button | ✅ | Bottom-right positioned (Positioned widget) |
| User Auth | ✅ | user_id based (from SharedPreferences) |
| Error Handling | ✅ | User-friendly error messages |
| Performance | ✅ | Optimized loading (50 message limit) |

---

**Last Updated**: December 1, 2025
**Frontend File**: `lib/screens/ai_chatbot_screen.dart`
**Status**: ✅ Complete & Ready for Testing

