import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/planka_api.dart';

class CardAttachmentsSection extends StatelessWidget {
  const CardAttachmentsSection({
    super.key,
    required this.attachments,
    required this.token,
    required this.onUpload,
    required this.onDelete,
  });

  final List<PlankaAttachment> attachments;
  final String? token;
  final void Function(String filePath, String name) onUpload;
  final ValueChanged<String> onDelete;

  Future<void> _pick() async {
    final file = await openFile();
    if (file != null) onUpload(file.path, file.name);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...attachments.map((a) {
          final thumb = a.listThumbnailUrl;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: thumb != null && token != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: thumb,
                      httpHeaders: imageAuthHeaders(token!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  )
                : const Icon(Icons.insert_drive_file_outlined, size: 32),
            title: Text(a.name, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete attachment',
              onPressed: () => onDelete(a.id),
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('Add attachment'),
          onPressed: _pick,
        ),
      ],
    );
  }
}
