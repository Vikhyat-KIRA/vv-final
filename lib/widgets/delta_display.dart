import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeltaDisplay extends StatefulWidget {
  final double targetPercentage;

  const DeltaDisplay({
    super.key,
    required this.targetPercentage,
  });

  @override
  State<DeltaDisplay> createState() => _DeltaDisplayState();
}

class _DeltaDisplayState extends State<DeltaDisplay> {
  double _currentPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCurrentPercent();
  }

  Future<void> _loadCurrentPercent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPercent = prefs.getDouble('user_percentage') ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final delta = (widget.targetPercentage - _currentPercent).clamp(0.0, 100.0);
    
    Color textColor;
    if (delta > 30) {
      textColor = const Color(0xFFEF4444); // Red
    } else if (delta >= 15) {
      textColor = const Color(0xFFF59E0B); // Amber
    } else {
      textColor = const Color(0xFF22C55E); // Green
    }

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      child: Text(
        'You need to close ${delta.toInt()}%',
      ),
    );
  }
}
