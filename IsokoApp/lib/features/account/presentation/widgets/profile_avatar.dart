import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.displayName,
    required this.size,
    this.imageUrl,
    super.key,
  });

  final String displayName;
  final double size;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl;

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppTheme.primaryGreen),
          child: image == null || image.isEmpty
              ? _Initials(displayName: displayName)
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _Initials(displayName: displayName),
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials(displayName),
        maxLines: 1,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) {
    return words.first.substring(0, 1).toUpperCase();
  }
  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}
