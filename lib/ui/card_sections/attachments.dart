import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/planka_api.dart';
import '../../l10n/gen/app_localizations.dart';

class CardAttachmentsSection extends StatelessWidget {
  const CardAttachmentsSection({
    super.key,
    required this.attachments,
    required this.token,
    required this.coverAttachmentId,
    required this.onUpload,
    required this.onDelete,
    required this.onSetCover,
    required this.onOpen,
  });

  final List<PlankaAttachment> attachments;
  final String? token;
  final String? coverAttachmentId;
  final void Function(String filePath, String name) onUpload;
  final ValueChanged<String> onDelete;

  /// Called with the attachment id to set as cover, or null to clear the cover.
  final ValueChanged<String?> onSetCover;

  /// Called when the user taps an attachment to download and open it.
  final ValueChanged<PlankaAttachment> onOpen;

  Future<void> _pick() async {
    final file = await openFile();
    if (file != null) onUpload(file.path, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            subtitle:
                a.id == coverAttachmentId ? Text(l10n.attachmentCover) : null,
            onTap: () => onOpen(a),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => switch (action) {
                'cover' => onSetCover(a.id),
                'uncover' => onSetCover(null),
                _ => onDelete(a.id),
              },
              itemBuilder: (_) => [
                if (a.id == coverAttachmentId)
                  PopupMenuItem(
                      value: 'uncover', child: Text(l10n.attachmentRemoveCover))
                else if (thumb != null)
                  PopupMenuItem(
                      value: 'cover', child: Text(l10n.attachmentSetAsCover)),
                PopupMenuItem(value: 'delete', child: Text(l10n.actionDelete)),
              ],
            ),
          );
        }),
        TextButton.icon(
          icon: const Icon(Icons.attach_file, size: 18),
          label: Text(l10n.attachmentAdd),
          onPressed: _pick,
        ),
      ],
    );
  }
}
