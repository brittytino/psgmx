import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dicebear_core/dicebear_core.dart';
import 'package:dicebear_styles/lorelei.dart';
import 'package:dicebear_styles/micah.dart';

class AvatarWidget extends StatefulWidget {
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
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  bool _imageFailed = false;

  @override
  void didUpdateWidget(covariant AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      // Give a new URL a fresh chance instead of staying stuck on the
      // fallback from a previously-broken one.
      _imageFailed = false;
    }
  }

  Widget _buildIdenticon(BuildContext context) {
    final isMale = widget.gender?.toLowerCase() == 'male';
    final style = Style.parse(isMale ? micah : lorelei);

    final avatar = Avatar(style, {
      'seed': widget.name.isNotEmpty ? widget.name : 'User',
    });

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ClipOval(
        child: SvgPicture.string(
          avatar.svg,
          width: widget.radius * 2,
          height: widget.radius * 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

    if (hasUrl && !_imageFailed) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(widget.avatarUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // A broken/unreachable avatar URL should degrade gracefully to
          // the same DiceBear identicon used when there's no URL at all,
          // instead of leaving a throwing/broken CircleAvatar on screen.
          if (mounted) {
            setState(() => _imageFailed = true);
          }
        },
      );
    }

    return _buildIdenticon(context);
  }
}
