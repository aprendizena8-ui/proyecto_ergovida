import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      "00:30",
      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
    );
  }
}
