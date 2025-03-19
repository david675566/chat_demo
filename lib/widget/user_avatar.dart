import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as chat_types;

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.from, this.radius = 24, this.isGuardian = false});
  final chat_types.User from;
  final double radius;
  final bool isGuardian;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: (from.imageUrl?.isNotEmpty ?? false) ? CachedNetworkImageProvider(from.imageUrl!) : null,
      // child:
      //     (from.imageUrl?.isNotEmpty ?? false)
      //         ? const SizedBox()
      //         : Stack(
      //           children: [
      //             Image.asset(from.defaultIconPath),
      //             if (isGuardian) const Text("守護", style: TextStyle(color: Colors.white)),
      //           ],
      //         ),
    );
  }
}
