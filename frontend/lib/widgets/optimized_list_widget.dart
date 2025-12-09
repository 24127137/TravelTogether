/// File: optimized_list_widget.dart
/// Description: Widget tối ưu hóa hiệu suất cho danh sách tin nhắn/thông báo
///
/// Bao gồm:
/// - MessageItem: StatelessWidget hiển thị từng tin nhắn với const optimization
/// - LoadingSkeleton: Placeholder UI khi đang tải dữ liệu
/// - OptimizedMessageList: Widget chính với FutureBuilder và ListView.builder

import 'package:flutter/material.dart';
import '../models/message.dart';

// ============================================================================
// PART 1: MESSAGE ITEM (StatelessWidget - Tối ưu rendering)
// ============================================================================

/// Widget hiển thị một tin nhắn đơn lẻ
/// Sử dụng StatelessWidget và const constructor để tối ưu hiệu suất
class MessageItem extends StatelessWidget {
  final Message message;
  final String? senderAvatarUrl;
  final String? currentUserId;
  final bool shouldShowAvatar;
  final bool shouldShowSenderName;

  const MessageItem({
    Key? key,
    required this.message,
    this.senderAvatarUrl,
    this.currentUserId,
    this.shouldShowAvatar = true,
    this.shouldShowSenderName = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Xác định tin nhắn của ai
    final bool isUser = (currentUserId != null && currentUserId!.isNotEmpty)
        ? (message.sender.toString().trim().toLowerCase() ==
            currentUserId!.toString().trim().toLowerCase())
        : message.isUser;

    // Màu sắc theo người gửi
    final bubbleColor = isUser
        ? const Color(0xFF8A724C)
        : const Color(0xFFB99668);
    final textColor = Colors.white;

    // Hiển thị avatar chỉ khi cần
    final showAvatar = !isUser && shouldShowAvatar;

    return Padding(
      padding: EdgeInsets.only(
        top: 2.0,
        bottom: shouldShowAvatar ? 6.0 : 2.0,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Hiển thị tên người gửi nếu là tin nhắn đầu tiên trong nhóm
          if (!isUser &&
              shouldShowSenderName &&
              message.senderName != null &&
              message.senderName!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56.0, bottom: 4.0),
              child: Text(
                message.senderName!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A724C),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              // Avatar hoặc khoảng trống
              if (!isUser) ...[
                SizedBox(
                  width: 48,
                  child: showAvatar
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _AvatarWidget(avatarUrl: senderAvatarUrl),
                        )
                      : const SizedBox(),
                ),
              ],
              // Bubble tin nhắn
              Flexible(
                child: _MessageBubbleContent(
                  message: message,
                  isUser: isUser,
                  bubbleColor: bubbleColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget avatar nhỏ - tách riêng để const optimization
class _AvatarWidget extends StatelessWidget {
  final String? avatarUrl;

  const _AvatarWidget({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFD9CBB3),
      backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
          ? NetworkImage(avatarUrl!)
          : null,
      child: avatarUrl == null || avatarUrl!.isEmpty
          ? const Icon(Icons.person, size: 24, color: Colors.white)
          : null,
    );
  }
}

/// Nội dung bubble tin nhắn - tách riêng để tối ưu rebuild
class _MessageBubbleContent extends StatelessWidget {
  final Message message;
  final bool isUser;
  final Color bubbleColor;
  final Color textColor;

  const _MessageBubbleContent({
    required this.message,
    required this.isUser,
    required this.bubbleColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isUser
              ? const Radius.circular(20)
              : const Radius.circular(0),
          bottomRight: isUser
              ? const Radius.circular(0)
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hiển thị ảnh nếu là tin nhắn ảnh
          if (message.messageType == 'image' && message.imageUrl != null) ...[
            _MessageImageWidget(
              imageUrl: message.imageUrl!,
              bubbleColor: bubbleColor,
            ),
            if (message.message.isNotEmpty) const SizedBox(height: 8),
          ],
          // Hiển thị text
          if (message.message.isNotEmpty)
            Text(
              message.message,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: !isUser && !message.isSeen
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 6),
          // Thời gian
          _MessageTimeWidget(
            time: message.time,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị ảnh trong tin nhắn
class _MessageImageWidget extends StatelessWidget {
  final String imageUrl;
  final Color bubbleColor;

  const _MessageImageWidget({
    required this.imageUrl,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: MediaQuery.of(context).size.width * 0.6,
        // Sử dụng cacheWidth để tối ưu memory
        cacheWidth: (MediaQuery.of(context).size.width * 0.6 * MediaQuery.of(context).devicePixelRatio).toInt(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 200,
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: bubbleColor,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
          );
        },
      ),
    );
  }
}

/// Widget hiển thị thời gian tin nhắn
class _MessageTimeWidget extends StatelessWidget {
  final String time;
  final Color textColor;

  const _MessageTimeWidget({
    required this.time,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          time,
          style: TextStyle(
            color: textColor.withAlpha(179),
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.done_all,
          size: 14,
          color: textColor.withAlpha(179),
        ),
      ],
    );
  }
}

// ============================================================================
// PART 2: LOADING SKELETON (Placeholder UI)
// ============================================================================

/// Widget skeleton loading cho một mục tin nhắn
/// Hiển thị placeholder UI trong khi đang tải dữ liệu
class LoadingSkeleton extends StatelessWidget {
  /// Xác định skeleton này là của người dùng hay người khác
  /// để hiển thị vị trí phù hợp (trái/phải)
  final bool isUser;

  /// Chiều rộng của skeleton (tạo variation)
  final double widthFactor;

  const LoadingSkeleton({
    Key? key,
    this.isUser = false,
    this.widthFactor = 0.6,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar skeleton (chỉ cho tin nhắn của người khác)
          if (!isUser) ...[
            const _SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: 20,
            ),
            const SizedBox(width: 8),
          ],
          // Message bubble skeleton
          _SkeletonBox(
            width: MediaQuery.of(context).size.width * widthFactor,
            height: 50,
            borderRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// Widget skeleton với hiệu ứng shimmer
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget skeleton cho loading notification
class NotificationLoadingSkeleton extends StatelessWidget {
  const NotificationLoadingSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Avatar skeleton
          const _SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: 24,
          ),
          const SizedBox(width: 12),
          // Content skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 14,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                _SkeletonBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  height: 12,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                const _SkeletonBox(
                  width: 60,
                  height: 10,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PART 3: OPTIMIZED MESSAGE LIST (Main Widget với FutureBuilder)
// ============================================================================

/// Typedef cho hàm fetch messages
typedef FetchMessagesFunction = Future<List<Message>> Function();

/// Widget tối ưu hóa hiển thị danh sách tin nhắn
/// Sử dụng FutureBuilder + ListView.builder cho hiệu suất tối đa
class OptimizedMessageList extends StatefulWidget {
  /// Hàm để fetch danh sách tin nhắn
  final FetchMessagesFunction fetchMessages;

  /// Callback khi scroll đến cuối (load more)
  final VoidCallback? onLoadMore;

  /// ScrollController (optional - có thể dùng external controller)
  final ScrollController? scrollController;

  /// Current user ID để xác định tin nhắn của ai
  final String? currentUserId;

  /// Callback khi cần hiển thị avatar
  final String? Function(String senderId)? getAvatarUrl;

  /// Số lượng skeleton items hiển thị khi loading
  final int skeletonCount;

  /// Widget hiển thị khi danh sách trống
  final Widget? emptyWidget;

  /// Padding của list
  final EdgeInsets padding;

  const OptimizedMessageList({
    Key? key,
    required this.fetchMessages,
    this.onLoadMore,
    this.scrollController,
    this.currentUserId,
    this.getAvatarUrl,
    this.skeletonCount = 12,
    this.emptyWidget,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
  }) : super(key: key);

  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> {
  late Future<List<Message>> _messagesFuture;
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _messagesFuture = widget.fetchMessages();

    // Listener cho infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Chỉ dispose nếu controller được tạo internal
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    // Load more khi scroll gần đến đầu danh sách
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 100 &&
        !_isLoadingMore &&
        widget.onLoadMore != null) {
      setState(() => _isLoadingMore = true);
      widget.onLoadMore!();
      setState(() => _isLoadingMore = false);
    }
  }

  /// Refresh danh sách tin nhắn
  Future<void> refresh() async {
    setState(() {
      _messagesFuture = widget.fetchMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Message>>(
      future: _messagesFuture,
      builder: (context, snapshot) {
        // TRẠNG THÁI LOADING: Hiển thị Skeleton UI
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonList();
        }

        // TRẠNG THÁI LỖI
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        // KHÔNG CÓ DỮ LIỆU
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return widget.emptyWidget ?? _buildEmptyWidget();
        }

        // CÓ DỮ LIỆU: Hiển thị danh sách tin nhắn
        final messages = snapshot.data!;
        return _buildMessageList(messages);
      },
    );
  }

  /// Build skeleton loading list với shimmer effect
  Widget _buildSkeletonList() {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      // Sử dụng itemCount cố định cho skeleton
      itemCount: widget.skeletonCount,
      // Reverse để hiển thị từ dưới lên như chat thật
      reverse: false,
      itemBuilder: (context, index) {
        // Tạo variation cho skeleton (xen kẽ trái/phải, width khác nhau)
        final isUser = index % 3 == 0;
        final widthFactor = 0.4 + (index % 4) * 0.1; // 0.4 - 0.7

        return LoadingSkeleton(
          isUser: isUser,
          widthFactor: widthFactor,
        );
      },
    );
  }

  /// Build danh sách tin nhắn thực
  Widget _buildMessageList(List<Message> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      // Lazy loading: chỉ build items đang hiển thị
      itemCount: messages.length,
      // addAutomaticKeepAlives: false để tối ưu memory
      addAutomaticKeepAlives: false,
      // addRepaintBoundaries: true để tối ưu repaint
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        final message = messages[index];

        // Tính toán các flags cho UI
        final shouldShowAvatar = _shouldShowAvatar(messages, index);
        final shouldShowSenderName = _shouldShowSenderName(messages, index);
        final senderAvatarUrl = widget.getAvatarUrl?.call(message.sender);

        // Kiểm tra system message
        if (message.isSystemMessage) {
          return _SystemMessageItem(message: message);
        }

        // Sử dụng RepaintBoundary để tối ưu repaint
        return RepaintBoundary(
          child: MessageItem(
            message: message,
            senderAvatarUrl: senderAvatarUrl,
            currentUserId: widget.currentUserId,
            shouldShowAvatar: shouldShowAvatar,
            shouldShowSenderName: shouldShowSenderName,
          ),
        );
      },
    );
  }

  /// Widget khi danh sách trống
  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Color(0xFFB99668),
          ),
          SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy bắt đầu cuộc trò chuyện!',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget khi có lỗi
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Đã xảy ra lỗi',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB99668),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Kiểm tra có nên hiển thị avatar không (tin nhắn cuối cùng trong nhóm)
  bool _shouldShowAvatar(List<Message> messages, int index) {
    if (index >= messages.length) return false;

    final currentMsg = messages[index];
    final isUser = _isSenderMe(currentMsg.sender);

    // Tin nhắn của mình không hiển thị avatar
    if (isUser) return false;

    // Tin nhắn cuối cùng luôn hiển thị avatar
    if (index == messages.length - 1) return true;

    // Kiểm tra tin nhắn tiếp theo
    final nextMsg = messages[index + 1];

    // Nếu người gửi khác nhau, hiển thị avatar
    if (currentMsg.sender != nextMsg.sender) return true;

    // Nếu cùng người gửi, kiểm tra khoảng thời gian
    if (currentMsg.createdAt != null && nextMsg.createdAt != null) {
      final timeDiff = nextMsg.createdAt!.difference(currentMsg.createdAt!);
      // Nếu cách nhau > 2 phút, hiển thị avatar
      if (timeDiff.inMinutes >= 2) return true;
    }

    return false;
  }

  /// Kiểm tra có nên hiển thị tên người gửi không (tin nhắn đầu tiên trong nhóm)
  bool _shouldShowSenderName(List<Message> messages, int index) {
    if (index >= messages.length) return false;

    final currentMsg = messages[index];
    final isUser = _isSenderMe(currentMsg.sender);

    // Tin nhắn của mình không hiển thị tên
    if (isUser) return false;

    // Tin nhắn đầu tiên luôn hiển thị tên
    if (index == 0) return true;

    // Kiểm tra tin nhắn trước đó
    final prevMsg = messages[index - 1];

    // Nếu người gửi khác nhau, hiển thị tên
    if (currentMsg.sender != prevMsg.sender) return true;

    // Nếu cùng người gửi, kiểm tra khoảng thời gian
    if (currentMsg.createdAt != null && prevMsg.createdAt != null) {
      final timeDiff = currentMsg.createdAt!.difference(prevMsg.createdAt!);
      // Nếu cách nhau > 2 phút, hiển thị tên
      if (timeDiff.inMinutes.abs() >= 2) return true;
    }

    return false;
  }

  /// Helper kiểm tra có phải current user không
  bool _isSenderMe(String? senderId) {
    if (senderId == null || widget.currentUserId == null) return false;
    return senderId.toString().trim().toLowerCase() ==
        widget.currentUserId!.toString().trim().toLowerCase();
  }
}

/// Widget hiển thị system message
class _SystemMessageItem extends StatelessWidget {
  final Message message;

  const _SystemMessageItem({required this.message});

  @override
  Widget build(BuildContext context) {
    String displayText = message.message;
    IconData icon = Icons.info_outline;
    Color bgColor = const Color(0xFFEBE3D7);
    Color textColor = Colors.black54;

    switch (message.messageType) {
      case 'leave_group':
        icon = Icons.exit_to_app;
        bgColor = const Color(0xFFFFF3E0);
        textColor = Colors.orange.shade700;
        break;
      case 'join_group':
        icon = Icons.person_add;
        bgColor = const Color(0xFFE8F5E9);
        textColor = Colors.green.shade700;
        break;
      case 'kick_member':
        icon = Icons.person_remove;
        bgColor = const Color(0xFFFFEBEE);
        textColor = Colors.red.shade700;
        break;
      case 'system':
      default:
        if (displayText.isEmpty) displayText = 'Thông báo hệ thống';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PART 4: OPTIMIZED NOTIFICATION LIST (Tương tự cho màn hình thông báo)
// ============================================================================

/// Model đơn giản cho notification (có thể customize theo nhu cầu)
class NotificationItemData {
  final String id;
  final String title;
  final String body;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final String? payloadId;

  const NotificationItemData({
    required this.id,
    required this.title,
    required this.body,
    this.avatarUrl,
    required this.createdAt,
    this.isRead = false,
    this.type = 'general',
    this.payloadId,
  });
}

/// Widget hiển thị một notification item
class NotificationItem extends StatelessWidget {
  final NotificationItemData notification;
  final VoidCallback? onTap;

  const NotificationItem({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFFFF8E1),
          border: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _NotificationAvatar(
              avatarUrl: notification.avatarUrl,
              type: notification.type,
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFB99668),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

/// Avatar cho notification với icon theo loại
class _NotificationAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String type;

  const _NotificationAvatar({
    this.avatarUrl,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    // Icon theo loại notification
    IconData typeIcon = Icons.notifications;
    Color bgColor = const Color(0xFFB99668);

    switch (type) {
      case 'message':
        typeIcon = Icons.chat_bubble;
        bgColor = const Color(0xFF4CAF50);
        break;
      case 'group_request':
        typeIcon = Icons.group_add;
        bgColor = const Color(0xFF2196F3);
        break;
      case 'group_dissolved':
        typeIcon = Icons.group_off;
        bgColor = const Color(0xFFF44336);
        break;
      default:
        break;
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFD9CBB3),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? const Icon(Icons.person, size: 24, color: Colors.white)
              : null,
        ),
        // Type badge
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(
              typeIcon,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Typedef cho hàm fetch notifications
typedef FetchNotificationsFunction = Future<List<NotificationItemData>> Function();

/// Widget tối ưu hiển thị danh sách thông báo
class OptimizedNotificationList extends StatefulWidget {
  final FetchNotificationsFunction fetchNotifications;
  final void Function(NotificationItemData)? onNotificationTap;
  final int skeletonCount;
  final Widget? emptyWidget;

  const OptimizedNotificationList({
    Key? key,
    required this.fetchNotifications,
    this.onNotificationTap,
    this.skeletonCount = 10,
    this.emptyWidget,
  }) : super(key: key);

  @override
  State<OptimizedNotificationList> createState() =>
      _OptimizedNotificationListState();
}

class _OptimizedNotificationListState extends State<OptimizedNotificationList> {
  late Future<List<NotificationItemData>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = widget.fetchNotifications();
  }

  Future<void> refresh() async {
    setState(() {
      _notificationsFuture = widget.fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItemData>>(
      future: _notificationsFuture,
      builder: (context, snapshot) {
        // Loading state với skeleton
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: widget.skeletonCount,
            itemBuilder: (context, index) => const NotificationLoadingSkeleton(),
          );
        }

        // Error state
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        // Empty state
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return widget.emptyWidget ??
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Color(0xFFB99668),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Không có thông báo nào',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
        }

        // Data state với ListView.builder
        final notifications = snapshot.data!;
        return ListView.builder(
          itemCount: notifications.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return RepaintBoundary(
              child: NotificationItem(
                notification: notification,
                onTap: () => widget.onNotificationTap?.call(notification),
              ),
            );
          },
        );
      },
    );
  }
}

