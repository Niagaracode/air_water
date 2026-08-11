import 'package:air_water/core/app_theme/app_theme.dart';
import 'package:air_water/features/tank/data/model/sent_and_received_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SentReceivedSheet extends StatelessWidget {
  final List<SentAndReceivedModel> messages;

  const SentReceivedSheet({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: Drawer(
        width: isNarrow ? MediaQuery.of(context).size.width : 900,
        backgroundColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isNarrow),

            // Messages list
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No messages',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageItem(message, isNarrow);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isNarrow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sent & Received',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                Text(
                  '${messages.length} messages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Message type filter
          PopupMenuButton<String>(
            onSelected: (value) {
              // Filter messages by type if needed
            },
            icon: Icon(
              Icons.filter_list,
              color: Colors.grey.shade600,
              size: 22,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Messages'),
              ),
              const PopupMenuItem(
                value: 'sent',
                child: Text('Sent Only'),
              ),
              const PopupMenuItem(
                value: 'received',
                child: Text('Received Only'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(SentAndReceivedModel message, bool isNarrow) {
    // Determine if message is sent or received based on messageType
    // Assuming 'S' means sent, 'R' means received
    final bool isSent = message.messageType == 'S';
    final bool isReceived = message.messageType == 'R';

    // Color for sender avatar
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.indigo.shade100,
      Colors.cyan.shade100,
    ];
    final colorIndex = message.sentUser.length % colors.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (isReceived) ...[
            _buildAvatar(message.sentUser, colors[colorIndex]),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name for received messages
                if (isReceived && message.sentUser.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.sentUser,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if (message.sentMobileNumber.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${message.sentMobileNumber})',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                // Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                  ),
                  decoration: BoxDecoration(
                    color: isSent
                        ? const Color(0xFFD3E3FD)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isSent ? 16 : 4),
                      topRight: Radius.circular(isSent ? 4 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: isSent
                        ? null
                        : Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Main message content
                      Text(
                        message.message,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          Text(
                            _formatTime(message.date, message.time),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isSent) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                          if (isReceived && message.messageType == 'R') ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Message type indicator for received
                if (isReceived)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Received',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Avatar for sent messages (only if we want to show the sender)
          if (isSent && message.sentUser.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildAvatar(message.sentUser, Colors.grey.shade300, isSent: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, Color color, {bool isSent = false}) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isSent ? Colors.grey.shade300 : color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSent ? Colors.transparent : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSent
                ? Colors.black54
                : color.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white,
          ),
        ),
      ),
    );
  }

  String _formatTime(String date, String time) {
    try {
      // Parse date and time from the model
      final dateParts = date.split('-'); // Assuming format: YYYY-MM-DD
      final timeParts = time.split(':'); // Assuming format: HH:MM:SS or HH:MM

      if (dateParts.length >= 3 && timeParts.length >= 2) {
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length >= 3 ? int.parse(timeParts[2]) : 0;

        final messageTime = DateTime(year, month, day, hour, minute, second);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);

        if (messageDate == today) {
          return DateFormat('h:mm a').format(messageTime);
        } else if (messageDate == today.subtract(const Duration(days: 1))) {
          return 'Yesterday ${DateFormat('h:mm a').format(messageTime)}';
        } else {
          return DateFormat('MMM d, h:mm a').format(messageTime);
        }
      }

      // Fallback: just combine date and time
      return '$date $time';
    } catch (e) {
      return '$date $time';
    }
  }
}