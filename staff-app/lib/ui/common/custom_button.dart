import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// A reusable button wrapper used across the app.
class CustomButton extends StatelessWidget {
  final String? text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  const CustomButton({
    super.key,
    this.text,
    this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.isLoading = false,
    this.padding,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Constants.primaryColor,
        foregroundColor: textColor ?? Colors.white,
        padding: padding,
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : child ??
              (icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon),
                        if (text != null) ...[
                          const SizedBox(width: 8),
                          Text(text!),
                        ],
                      ],
                    )
                  : Text(text ?? 'Button')),
    );
  }
}