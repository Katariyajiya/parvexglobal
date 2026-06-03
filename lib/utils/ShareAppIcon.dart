import 'package:flutter/material.dart';

class ShareAppIcon extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  
  /// If true, the background is solid blue with a white icon.
  /// If false, the background is soft/translucent blue with a blue icon.
  final bool isSolid; 

  const ShareAppIcon({
    super.key,
    required this.onTap,
    this.size = 34.0, // Default size, matches your profile header buttons
    this.isSolid = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color brandBlue = Color(0xFF1F63FF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          margin: EdgeInsets.only(top: 6.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSolid ? brandBlue : brandBlue.withOpacity(0.08),
            border: isSolid
                ? null
                : Border.all(color: brandBlue.withOpacity(0.15), width: 1),
            boxShadow: isSolid ? [
              BoxShadow(
                color: brandBlue.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Icon(
            // Using ios_share for a modern look, or you can use Icons.share_outlined
            Icons.share,
            color: isSolid ? Colors.white : brandBlue,
            size: size * 0.45, // Keeps the icon proportionally sized
          ),
        ),
      ),
    );
  }
}