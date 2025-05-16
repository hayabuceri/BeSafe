import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    Key? key,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.black,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Image.asset(
        'assets/applogo.png',
        height: 40, // Adjust size as needed
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 