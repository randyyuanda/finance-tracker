import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool loading;
  final double height;
  final List<Color>? colors;

  const GradientButton({
    super.key,
    required this.onTap,
    required this.label,
    this.loading = false,
    this.height = 52,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final gradColors = colors ?? const [Color(0xFF1677FF), Color(0xFF0050CC)];
    final active = onTap != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: active ? LinearGradient(colors: gradColors) : null,
          color: active ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
          boxShadow: active
              ? [BoxShadow(color: gradColors.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 5))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        color: active ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
