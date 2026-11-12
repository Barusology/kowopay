import 'package:flutter/material.dart';
import 'package:kowopay/theme/app_theme.dart';
import 'package:kowopay/utils/validators.dart';

/// Avatar that only renders image URLs from our Firebase Storage bucket.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.photoUrl,
    required this.email,
    this.radius = 22,
  });

  final String? photoUrl;
  final String email;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = Validators.isSafeImageUrl(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.lilac,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              email.isNotEmpty ? email[0].toUpperCase() : 'U',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}
