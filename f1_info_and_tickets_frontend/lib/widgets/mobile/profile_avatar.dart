import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../app_image.dart';

/// User's profile photo, a newly picked file ([filePath]) or, without a photo, the initials.
class ProfileAvatar extends StatelessWidget {
  final User user;
  final double radius;
  final String? filePath;

  const ProfileAvatar({super.key, required this.user, this.radius = 34, this.filePath});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    if (filePath != null) {
      return ClipOval(
        child: Image.file(File(filePath!), width: size, height: size, fit: BoxFit.cover),
      );
    }
    if (user.photoUrl != null) {
      return AppImage(path: user.photoUrl, size: size, circle: true, fallback: Icons.person);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.red,
      child: Text(
        user.initials,
        style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
