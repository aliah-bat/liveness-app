import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}