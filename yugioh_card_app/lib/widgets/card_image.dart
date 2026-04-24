import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Cross-platform card image widget.
/// - Web: uses Image.network (works with --disable-web-security in dev,
///        and ygoprodeck CDN supports CORS in production builds)
/// - Mobile/Desktop: uses CachedNetworkImage for disk caching
class CardNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CardNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return _placeholder();

    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _shimmer();
        },
        errorBuilder: (context, error, stack) => _errorWidget(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, url) => _shimmer(),
      errorWidget: (context, url, error) => _errorWidget(),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(color: Colors.white, width: width, height: height),
  );

  Widget _placeholder() => Container(
    color: Colors.grey[200],
    width: width,
    height: height,
    child: const Icon(Icons.image_not_supported, color: Colors.grey),
  );

  Widget _errorWidget() => Container(
    color: Colors.grey[200],
    width: width,
    height: height,
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );
}
