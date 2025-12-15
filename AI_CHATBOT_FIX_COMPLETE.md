# AI Chatbot Screen Fix - Complete Summary

## ✅ Changes Made

### 1. **History Saving to Backend (Lưu lịch sử vào Backend)**
   - **Before**: Lịch sử chat chỉ được lưu trên local storage (SharedPreferences)
   - **After**: Lịch sử chat được tự động lưu vào database backend qua API `/ai/send`
   - **Implementation**:
     - Removed: `_saveChatHistory()` function (not needed anymore)
     - Updated: `_sendMessage()` to automatically save via backend
     - Updated: `_sendImageMessage()` to automatically save via backend

### 2. **Image Upload Support (Hỗ trợ upload ảnh)**
   - **Added**: Image picker integration with Supabase Storage
   - **Features**:
     - Upload ảnh lên Supabase Storage
     - Display images in chat bubbles
     - Support for both gallery and camera
     - Progress indicator while uploading
   - **Implementation**:
     - `_showImageSourceSelection()`: Cho phép chọn nguồn ảnh
     - `_pickAndSendImage()`: Pick, upload, and send image
     - `_sendImageMessage()`: Send image message to AI
     - Updated `_AiMessageBubble` to display images

### 3. **Scroll-to-Bottom Button (Nút cuộn xuống)**
   - **Before**: Button ở giữa màn hình khi cuộn lên
   - **After**: Button ở góc dưới phải (bottom-right corner) như trong chatbox_screen
   - **Position**: `Positioned(bottom: 80, right: 16, child: ...)`
   - **Condition**: Hiển thị khi cách đáy > 200px

### 4. **API Integration Changes**
   - **Old Approach**: Sử dụng session_id (`/ai/new_session` + `/ai/send`)
   - **New Approach**: Sử dụng user_id (lấy từ SharedPreferences)
   - **Endpoints Used**:
     - `GET /ai/chat-history?user_id={user_id}&limit=50` - Load chat history on init
     - `POST /ai/send?user_id={user_id}` - Send message (auto-saves)
     - `DELETE /ai/clear-chat?user_id={user_id}` - Clear history

### 5. **Code Structure Changes**
   - **Removed**:
     - `_sessionId` variable
     - `_saveChatHistory()` function
     - `_createNewSession()` function
   
   - **Added**:
     - `_userId` variable
     - `_loadChatHistory()` function
     - `_formatTime()` helper function
     - `_showScrollToBottomButton` variable
   
   - **Updated**:
     - `_initializeChat()`: Now loads user_id and fetches history from backend
     - `_sendMessage()`: Uses user_id instead of session_id
     - `_sendImageMessage()`: Uses user_id, sends image_url + message
     - `_clearHistory()`: Calls backend delete API

## 📝 Frontend Changes Summary

### File: `frontend/lib/screens/ai_chatbot_screen.dart`

#### Variables Changed
```dart
// OLD
String? _sessionId;
bool _showScrollToBottom = false;

// NEW
String? _userId;
bool _showScrollToBottomButton = false;
```

#### Functions Changed
1. **_initializeChat()**: Now loads user_id from SharedPreferences and fetches chat history from backend
2. **_loadChatHistory()**: New function to fetch chat history from backend
3. **_formatTime()**: New helper function to parse backend timestamp
4. **_sendMessage()**: Updated to use user_id, sends to `/ai/send`
5. **_sendImageMessage()**: Updated to use user_id, sends image_url
6. **_showImageSourceSelection()**: Bottom sheet for choosing image source
7. **_pickAndSendImage()**: Uploads to Supabase, then calls _sendImageMessage
8. **_clearHistory()**: Calls backend DELETE API instead of local storage

#### UI Changes
- **Scroll-to-Bottom Button**: Moved from `Center()` to `Positioned(bottom: 80, right: 16)`
- **Message Bubble**: Added image display support with loading/error states
- **Image Button**: Added to input bar for selecting/uploading images

## 🔧 Backend API Requirements

The frontend now depends on these backend endpoints:

### 1. POST /ai/send
```json
Request:
{
  "message": "string",
  "image_url": "string (optional)"
}
Query: user_id (required)

Response:
{
  "response": "string",
  "message_id": 0
}
```

### 2. GET /ai/chat-history
```json
Query: user_id (required), limit (default: 50)

Response:
{
  "user_id": "string",
  "messages": [
    {
      "id": 0,
      "role": "string",
      "content": "string",
      "message_type": "string",
      "image_url": "string",
      "created_at": "string"
    }
  ]
}
```

### 3. DELETE /ai/clear-chat
```json
Query: user_id (required)

Response:
"message": "Lịch sử chat đã được xóa"
```

## 🐛 Testing Checklist

- [ ] Verify user_id is saved in SharedPreferences during login/signup
- [ ] Test loading chat history on app startup
- [ ] Test sending text message with backend save
- [ ] Test picking image from gallery
- [ ] Test taking photo from camera
- [ ] Test image upload to Supabase
- [ ] Test sending image message
- [ ] Test scroll-to-bottom button appears when scrolling up
- [ ] Test scroll-to-bottom button position (bottom-right)
- [ ] Test clearing chat history
- [ ] Verify messages display correctly with timestamps
- [ ] Verify images display in chat bubbles

## 📱 Dependencies Used

- `shared_preferences`: For storing user_id and access tokens
- `image_picker`: For selecting/taking images
- `supabase_flutter`: For uploading images to Supabase Storage
- `http`: For API calls
- `intl`: For date/time formatting
- `easy_localization`: For translations

## ⚠️ Important Notes

1. **User Authentication Required**: App must have user_id in SharedPreferences (set during login/signup)
2. **Supabase Configuration**: Ensure `chat_images` bucket exists in Supabase Storage
3. **Backend Sync**: All messages are now synced to backend automatically
4. **Network Dependency**: Chat history loading requires network connection
5. **Error Handling**: All API calls have proper error handling with user-friendly messages

## 🎉 Result

✅ Chat history is now persistent across app sessions (saved in backend)
✅ Users can upload and send images in AI chat
✅ Scroll-to-bottom button positioned correctly (bottom-right corner)
✅ No more session-based chat (now user_id based)

