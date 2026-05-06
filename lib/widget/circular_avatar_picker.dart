import 'package:flutter/material.dart';

class CircularAvatarPicker extends StatelessWidget {
  final ImageProvider? imageProvider;
  final VoidCallback onTap;
  final double radius;

  const CircularAvatarPicker({
    super.key,
    required this.imageProvider,
    required this.onTap,
    this.radius = 36,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white, // 👈 WHITE like Apple
          image: imageProvider != null
              ? DecorationImage(
                  image: imageProvider!,
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: imageProvider == null
            ? const Icon(
                Icons.camera_alt,
                color: Colors.black54,
                size: 22,
              )
            : null,
      ),
    );
  }
}
