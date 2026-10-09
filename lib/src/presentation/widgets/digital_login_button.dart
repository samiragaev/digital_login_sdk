import 'package:flutter/material.dart';

/// A ready made sign-in button.
///
/// It only renders the button; wire [onPressed] to `DigitalLogin.authorize`.
/// While [isLoading] is `true` the button is disabled and shows a progress
/// indicator, which prevents double taps from starting a second flow.
class DigitalLoginButton extends StatelessWidget {
  /// Creates the button.
  const DigitalLoginButton({
    required this.onPressed,
    super.key,
    this.label = 'DigitalLogin ilə daxil ol',
    this.isLoading = false,
    this.icon,
    this.style,
  });

  /// Called when the button is tapped. `null` disables the button.
  final VoidCallback? onPressed;

  /// The button text.
  final String label;

  /// Whether a sign-in is in progress.
  final bool isLoading;

  /// An optional leading icon.
  final Widget? icon;

  /// Overrides the default [FilledButton] style.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    final Widget leading = isLoading
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : icon ?? const Icon(Icons.verified_user_outlined, size: 20);

    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: label,
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style:
            style ??
            FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
        icon: leading,
        label: Text(label),
      ),
    );
  }
}
