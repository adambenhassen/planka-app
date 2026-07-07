import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../api/models.dart';
import '../../api/planka_api.dart';
import '../theme/app_theme.dart';
import '../theme/planka_gradients.dart';

/// A resolved project background: always a gradient (real or deterministic),
/// plus an image URL when the project uses an uploaded image background.
class BoardBackground {
  final Gradient gradient;
  final String? imageUrl;
  const BoardBackground(this.gradient, this.imageUrl);

  /// A representative solid color for tinting chrome (the gradient's first stop).
  Color get tint => gradient.colors.first;
}

/// Resolve [project]'s background. Falls back to a deterministic gradient from
/// [fallbackSeed] when the project has none. [large] picks a bigger thumbnail
/// for a full board background vs. the smaller project tiles.
BoardBackground resolveBoardBackground(
  PlankaProject? project,
  List<PlankaBackgroundImage> images,
  String fallbackSeed, {
  bool large = false,
}) {
  final gradient =
      projectGradient(project?.backgroundType, project?.backgroundGradient) ??
          boardGradient(fallbackSeed);

  String? imageUrl;
  final imageId = project?.backgroundImageId;
  if (project?.backgroundType == 'image' && imageId != null) {
    for (final img in images) {
      if (img.id != imageId) continue;
      final thumbs = img.thumbnailUrls;
      if (thumbs != null) {
        imageUrl =
            (large ? thumbs['outside720'] : thumbs['outside360']) as String?;
      }
      imageUrl ??= img.url;
      break;
    }
  }
  return BoardBackground(gradient, imageUrl);
}

/// Paints a board background: the uploaded image (authenticated with the
/// session cookie, like card covers) when present, otherwise the gradient.
/// Any image load failure falls back to the gradient.
class BoardBackgroundView extends StatelessWidget {
  const BoardBackgroundView({
    super.key,
    required this.background,
    required this.token,
  });

  final BoardBackground background;
  final String? token;

  @override
  Widget build(BuildContext context) {
    final url = background.imageUrl;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: background.gradient),
    );
    if (url == null || token == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: imageAuthHeaders(token!),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
