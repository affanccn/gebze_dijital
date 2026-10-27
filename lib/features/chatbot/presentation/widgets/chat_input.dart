import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;

  const ChatInput({super.key, required this.onSend});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();

  void _submit() {
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0A1F44),
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF5F6F8A),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.transparent,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: const BorderSide(
                      color: Color(0xFF38BDF8),
                      width: 1.4,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.grey.withValues(alpha: 0.1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF0B5FA5),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
