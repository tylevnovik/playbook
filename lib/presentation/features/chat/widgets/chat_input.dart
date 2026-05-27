import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';

class ChatInput extends StatefulWidget {
  final Function(String, List<String>) onSend;
  final bool isSending;

  const ChatInput({super.key, required this.onSend, this.isSending = false});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final List<String> _selectedAttachmentPaths = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedAttachmentPaths.add(image.path);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedAttachmentPaths.removeAt(index);
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty || _selectedAttachmentPaths.isNotEmpty) {
      widget.onSend(text, List.from(_selectedAttachmentPaths));
      _controller.clear();
      setState(() {
        _selectedAttachmentPaths.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Attachment list
        if (_selectedAttachmentPaths.isNotEmpty)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedAttachmentPaths.length,
              itemBuilder: (context, index) {
                final path = _selectedAttachmentPaths[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _removeAttachment(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        // Input row
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: loc.get('attachImage'),
                onPressed: widget.isSending ? null : _pickImage,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: loc.get('typeMessage'),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: widget.isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: widget.isSending ? null : _handleSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
