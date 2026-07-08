import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../theme/planka_gradients.dart';

/// Picker for a project's background: one of Planka's named gradients, an
/// uploaded image, or none. Fires the matching callback and closes itself.
Future<void> showProjectBackgroundDialog(
  BuildContext context, {
  required ValueChanged<String> onGradient,
  required void Function(String filePath, String name) onImage,
  required VoidCallback onClear,
}) =>
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Project background'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in plankaGradientNames())
                        Tooltip(
                          message: name,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              Navigator.pop(ctx);
                              onGradient(name);
                            },
                            child: Container(
                              width: 56,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: plankaGradient(name),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Upload image'),
                    onPressed: () async {
                      final file = await openFile();
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (file != null) onImage(file.path, file.name);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.format_color_reset_outlined,
                        size: 18),
                    label: const Text('None'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onClear();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
