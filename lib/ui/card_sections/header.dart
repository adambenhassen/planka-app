import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../api/models.dart';

class CardHeaderSection extends StatefulWidget {
  const CardHeaderSection({
    super.key,
    required this.card,
    required this.onRename,
    required this.onDescriptionChanged,
  });

  final PlankaCard card;
  final ValueChanged<String> onRename;
  final ValueChanged<String> onDescriptionChanged;

  @override
  State<CardHeaderSection> createState() => _CardHeaderSectionState();
}

class _CardHeaderSectionState extends State<CardHeaderSection> {
  bool _editingDescription = false;

  @override
  Widget build(BuildContext context) {
    final description = widget.card.description ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: ValueKey('title-${widget.card.id}-${widget.card.name}'),
          initialValue: widget.card.name,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: const InputDecoration(border: InputBorder.none),
          onFieldSubmitted: (v) {
            final name = v.trim();
            if (name.isNotEmpty && name != widget.card.name) {
              widget.onRename(name);
            }
          },
        ),
        if (_editingDescription)
          TextFormField(
            key: ValueKey('desc-${widget.card.id}'),
            initialValue: description,
            autofocus: true,
            maxLines: null,
            minLines: 2,
            decoration: const InputDecoration(
              hintText: 'Add a description…',
              border: InputBorder.none,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onFieldSubmitted: (v) {
              setState(() => _editingDescription = false);
              if (v != description) widget.onDescriptionChanged(v);
            },
          )
        else
          // Rendered markdown; tap to switch into the plain-text editor.
          InkWell(
            onTap: () => setState(() => _editingDescription = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: description.isEmpty
                  ? Text(
                      'Add a description…',
                      style: TextStyle(
                          color: Theme.of(context).hintColor),
                    )
                  : MarkdownBody(data: description),
            ),
          ),
      ],
    );
  }
}
