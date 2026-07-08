import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color backgroundColor;
  final Color titleColor;
  final VoidCallback? onBackPress;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor = Colors.transparent,
    this.titleColor = Colors.white,
    this.onBackPress,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null
          ? Text(
              title!,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null),
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0, // prevents Material 3 tint on scroll
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: titleColor,
                size: 20,
              ),
              onPressed: onBackPress ?? () => Navigator.pop(context),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
