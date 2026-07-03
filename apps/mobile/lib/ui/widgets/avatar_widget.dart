import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/lorelei.dart';
import 'package:dicebear_styles/micah.dart';


class AvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final String? gender;
  final double radius;

  const AvatarWidget({
    super.key,
    this.avatarUrl,
    required this.name,
    this.gender,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final isMale = gender?.toLowerCase() == 'male';
    final style = Style.parse(isMale ? micah : lorelei);

    final avatar = Avatar(style, {
      'seed': name.isNotEmpty ? name : 'User',
    });

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: SvgPicture.string(
          avatar.svg,
          width: radius * 2,
          height: radius * 2,
        ),
      ),
    );
  }
}
