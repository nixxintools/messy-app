import 'package:flutter/material.dart';

import 'web_logo.dart';

/// App-bar title: the Messy logo followed by the screen name, top-left.
class MessyTitle extends StatelessWidget {
  const MessyTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const WebLogo(size: 26),
        const SizedBox(width: 10),
        Flexible(
          child: Text(text, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
