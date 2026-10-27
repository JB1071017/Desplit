import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF131126),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFocused ? AppColors.accentHover : const Color(0xFF2B284C),
            width: _isFocused ? 1.5 : 1.0,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.brandAccent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: AppColors.accentHover,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.55),
              fontSize: 13.5,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              size: 19,
              color: _isFocused
                  ? AppColors.accentHover
                  : AppColors.textSecondary.withValues(alpha: 0.65),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}
