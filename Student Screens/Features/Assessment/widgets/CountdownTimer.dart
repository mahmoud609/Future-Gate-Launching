import 'package:flutter/material.dart';

class CountdownTimer extends StatelessWidget {
  final int secondsRemaining;

  const CountdownTimer({
    Key? key,
    required this.secondsRemaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final minutes = (secondsRemaining / 60).floor();
    final seconds = secondsRemaining % 60;

    final color = secondsRemaining < 60 ? Colors.red : Colors.black;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.timer, size: 16, color: color),
          SizedBox(width: 4),
          Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
