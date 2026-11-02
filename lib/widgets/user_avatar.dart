import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/models/user_model.dart';
import 'avatar_badge.dart';

class UserAvatar extends StatelessWidget {
  final UserModel? usuario;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? ringColor;
  final double ringWidth;

  const UserAvatar({
    super.key,
    required this.usuario,
    this.radius = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.ringColor,
    this.ringWidth = 0,
  });

  ImageProvider? _photoProvider() {
    final foto = (usuario?.fotoPerfil ?? '').trim();
    if (foto.isEmpty) return null;

    if (foto.startsWith('http://') || foto.startsWith('https://')) {
      return NetworkImage(foto);
    }

    final base64Text = foto.contains(',') ? foto.split(',').last : foto;
    try {
      return MemoryImage(
        base64Decode(base64Text.replaceAll(RegExp(r'\s'), '')),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final provider = _photoProvider();

    if (provider != null) {
      final avatar = SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image(
            image: provider,
            fit: BoxFit.cover,
            width: size,
            height: size,
            errorBuilder: (context, error, stackTrace) =>
                AvatarBadge(avatarId: usuario?.avatar, size: size),
          ),
        ),
      );

      if (ringWidth <= 0 && ringColor == null) return avatar;

      return Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor ?? Theme.of(context).colorScheme.primary,
            width: ringWidth,
          ),
        ),
        child: avatar,
      );
    }

    final avatarBadge = AvatarBadge(avatarId: usuario?.avatar, size: size);

    if (ringWidth <= 0 && ringColor == null) return avatarBadge;

    return Container(
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringColor ?? Theme.of(context).colorScheme.primary,
          width: ringWidth,
        ),
      ),
      child: avatarBadge,
    );
  }
}
