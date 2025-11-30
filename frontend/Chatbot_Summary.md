# Tóm tắt kỹ thuật — Chat (Travel Together)

Tệp này tóm tắt các kỹ thuật, luồng dữ liệu và những điểm quan trọng trong phần chat của ứng dụng (màn hình `ChatboxScreen` và `AiChatbotScreen`). Mục tiêu: giúp team hiểu cách hoạt động hiện tại, các rủi ro, và đề xuất cải tiến.

---

## 1. Tổng quan kiến trúc
- Chat chính (`ChatboxScreen`): kết hợp HTTP để lấy lịch sử và WebSocket để nhận/gửi tin nhắn thời gian thực.
- Chat với AI (`AiChatbotScreen`): phiên làm việc (session) được tạo qua API, gửi/tải qua HTTP, và lịch sử nhỏ được lưu local (SharedPreferences).
- SharedPreferences được dùng để lưu: access_token, user_id, last_seen_message_id, AI session id và lịch sử AI (json string).
- Image picker + upload: cả hai màn hình hỗ trợ gửi ảnh. `ChatboxScreen` upload bằng HTTP trực tiếp tới Supabase Storage endpoint; `AiChatbotScreen` dùng `supabase_flutter` client để upload và lấy public URL.
- Localization: easy_localization được sử dụng cho chuỗi UI.

## 2. Luồng dữ liệu chính
1. Khi vào `ChatboxScreen`:
   - Lấy `access_token` và `user_id` từ SharedPreferences.
   - Gọi API `chatHistory` (HTTP GET) để lấy lịch sử. Parse created_at (UTC) -> toLocal() và build `Message` model.
   - Gọi API `myGroup` để load thông tin members (dùng để lấy avatar người khác) và cache vào `_groupMembers` / `_userAvatars`.
   - Kết nối WebSocket (`ApiConfig.chatWebSocket?token=...`) cho realtime.
2. Nhận WebSocket message:
   - JSON -> parse -> tạo `Message` (chuyển created_at sang local) -> thêm vào `_messages`.
   - Nếu người dùng đang ở gần dưới cùng (dưới threshold ~200px) thì tự động scroll xuống; nhưng *không tự động mark seen* — user phải scroll thủ công/ gần đáy để mark.
3. Gửi tin nhắn:
   - `ChatboxScreen`: gửi qua WebSocket (sink.add json).
   - `AiChatbotScreen`: gửi qua HTTP `/aiSend` (kèm session_id) và chờ response server.
4. Gửi ảnh:
   - Chọn ảnh qua image_picker, upload lên Supabase. Lấy public URL rồi gửi message dạng `message_type=image` (chatbox qua websocket, AI chat qua API payload chứa image_url).

## 3. Cơ chế xác thực & an toàn
- Access token được lưu trong SharedPreferences.
- WebSocket hiện truyền token trong query string (`?token=...`) — lưu ý: token xuất hiện trong URL có thể bị lộ trong log, proxy hoặc server logs.
- `ChatboxScreen` upload ảnh bằng HTTP POST tới endpoint Supabase với header `Authorization: Bearer $_accessToken` và `apikey: ApiConfig.supabaseAnonKey` — cẩn trọng vì dùng `anon` key trong client dễ lộ.

Khuyến nghị bảo mật ngắn:
- Tránh truyền token trong query string; nếu server hỗ trợ, truyền token qua header khi mở WS hoặc thực hiện handshake xác thực qua message đầu tiên.
- Không in token hoặc payload nhạy cảm vào log trong bản production.

## 4. WebSocket
- Kết nối: `_channel = WebSocketChannel.connect(Uri.parse(wsUrl))`.
- Lắng nghe stream, xử lý `onError`/`onDone` => tự reconnect sau 3s.
- Xử lý message: decode JSON, parse created_at UTC -> local, tạo Message, push vào state.

Rủi ro & cải tiến
- Reconnect chiến lược hiện chỉ cố gắng sau 3s (constant). Nên dùng exponential backoff để tránh vòng lặp reconnect nhanh khi server bận.
- Token trong URL — xem mục bảo mật.
- Cần dedupe messages (nếu server có thể push duplicate), thêm message id check.

## 5. Lưu trạng thái "seen" và scroll behavior
- Phát hiện scroll: listener trên `_scrollController`. Nếu khoảng cách tới đáy < 50px thì `_markAllAsSeen()`.
- Khi nhận message qua WS, code chỉ auto-scroll nếu user đang gần đáy (<200px) và có cờ `_isAutoScrolling` để tránh trigger mark seen do programmatic scroll.
- `last_seen_message_id` được lưu vào SharedPreferences sau khi tải lịch sử, khi dispose, và khi nhận tin nhắn nếu user đang ở đáy.

Edge cases cần kiểm tra
- Tin nhắn không có `created_at` (code đã log và xử lý bằng cách không hiện separator).
- Scroll race: ensureVisible + animateTo có try/catch — tốt.

## 6. UI / Component patterns
- MessageBubble components:
  - `_MessageBubble` cho chat thường, `_AiMessageBubble` cho AI; hai widget tách biệt UX/Avatar.
  - Avatar: chỉ hiển thị cho message của người khác; ảnh lấy từ cache `_userAvatars` hoặc group members.
  - Unread messages (chưa seen) hiển thị bold text (message.isSeen được set khi mark seen).
  - Date separators: `_getDateSeparator(index)` - hiển thị theo kiểu Messenger (ẩn cho hôm nay, hiện "TH 2 LÚC 20:05" nếu trong tuần, hoặc "13 THG 11 LÚC 20:05" nếu cũ hơn).
- Keyboard handling: focus listener + delayed scroll 300ms để chờ keyboard mở.
- Input area: disables send while sending/ uploading (AI chat), hiển thị CircularProgressIndicator nhỏ khi uploading.

## 7. AI chat specifics
- Session management: tạo session qua `aiNewSession` (POST). `session_id` lưu vào SharedPreferences (`ai_chat_session_id`).
- Lịch sử chat AI được lưu local (`ai_chat_messages`) và tái sử dụng khi mở lại màn hình.
- Khi server trả lỗi liên quan session, code có logic bắt lỗi và tạo session mới tự động.

## 8. Image upload flows khác nhau
- ChatboxScreen: upload thủ công qua HTTP POST tới `${supabaseUrl}/storage/v1/object/chat_images/$fileName` với header `Authorization: Bearer $_accessToken` + `apikey` — bucket tên `chat_images`.
- AiChatbotScreen: dùng `Supabase.instance.client.storage.from('chat_images')` để upload; getPublicUrl() để lấy URL — bucket tên `chat_images`.

Điểm cần lưu ý:
- Bucket name: `chat_images` (gạch dưới) - đã thống nhất cho cả 2 screen.
- Việc upload trực tiếp bằng HTTP cần đảm bảo headers và CORS (mobile app hiếm khi gặp CORS, nhưng endpoint cần cho phép request).
- Cần đảm bảo bucket `chat_images` đã được tạo trên Supabase với public access và policies phù hợp (xem SUPABASE_STORAGE_SETUP.md).

## 9. Logging & debug
- File hiện in nhiều debug logs (print) cho thời điểm, content, scroll, createdAt. Tốt khi dev, nhưng cần tắt/giảm cho production.

## 10. Lỗi thường gặp / edge cases đã thấy trong code
- Null created_at (đã kiểm tra nhưng cần robust fallback).
- Token null -> UI hiện lỗi snackbar.
- Khi WebSocket bị đóng: reconnect nhưng không clear channel (đảm bảo old sink closed — code gọi `sink.close()` ở dispose nhưng không khi reconnect). Nên đảm bảo đóng channel trước khi tạo mới.
- Lưu last_seen_message_id có dùng call HTTP GET trên dispose — có thể chậm và gây exception nếu mạng bị đóng khi app background.

## 11. Testing checklist (QA)
- [ ] Mở màn hình chat: lịch sử load đúng, avatar hiện cho người khác.
- [ ] Gửi text: message xuất ở UI ngay và server nhận.
- [ ] Nhận message qua WS: message hiện; nếu đang ở đáy sẽ auto scroll, nếu không sẽ không mark seen.
- [ ] Test mark seen: scroll gần đáy (<50px) => messages của người khác phải chuyển từ bold -> normal.
- [ ] Upload ảnh: thử camera và gallery trên Android; kiểm tra ảnh có xuất trên server và hiển thị trên UI.
- [ ] Test reconnect: tắt mạng -> mở lại -> đảm bảo reconnect với backoff.
- [ ] AI chat session: xóa SharedPreferences `ai_chat_session_id` -> mở AI chat phải tạo session mới.

## 12. Đề xuất cải tiến (ngắn)
1. Bảo mật WS: đổi sang xác thực qua header hoặc initial handshake message thay vì query string.
2. Reconnect backoff: thay vì cố gắng mỗi 3s không đổi, dùng exponential backoff + giới hạn max attempts.
3. Dedupe messages dựa trên message id (khi server gửi id) để tránh duplicate insert.
4. Unify image upload: tạo helper upload service để chuẩn hóa bucket name và headers (hiện có 2 cách khác nhau).
5. Giảm log in production và chuyển sang logger có mức độ (debug/info/error).
6. Xác thực và xử lý lỗi upload (chèn retry cho upload lớn, compress ảnh trước khi upload).
7. Thêm unit/integration tests cho parsing created_at, date separator logic, và mark-as-seen boundary (50px / 200px thresholds).

---

Nếu bạn muốn, tôi có thể tiếp tục và:
- Tạo checklist test script (adb/monkey) để QA trên Android.
- Tạo helper upload service hoặc refactor code để hợp nhất upload flow.
- Sinh thêm tài liệu flow sequence (diagram) cho WebSocket + HTTP.


