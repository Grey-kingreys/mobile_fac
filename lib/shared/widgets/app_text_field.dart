import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:djoulagest_mobile/core/constants/app_colors.dart';
import 'package:djoulagest_mobile/core/constants/app_sizes.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.inputFormatters,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      maxLines: obscureText ? 1 : maxLines,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: AppSizes.iconMd)
            : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ── Variante montant GNF ──────────────────────────────────────────────────────

class AmountTextField extends StatelessWidget {
  const AmountTextField({
    super.key,
    required this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.currency = 'GNF',
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hint: '0',
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      textInputAction: TextInputAction.next,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: AppSizes.md),
        child: Center(
          widthFactor: 1,
          child: Text(
            currency,
            style: const TextStyle(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.fontSm,
            ),
          ),
        ),
      ),
    );
  }
}
