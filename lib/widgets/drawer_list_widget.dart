import 'package:dashboard_clone/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:rsw_portal/constants/constants.dart';

class DrawerItem extends StatelessWidget {
  final String title;
  final String iconAsset;
  final List<bool>? permissions;
  final VoidCallback? onCreateTap;
  final VoidCallback? onViewTap;
  final VoidCallback? onTileTap;
  final bool isSelected;

  const DrawerItem({
    super.key,
    required this.title,
    required this.iconAsset,
    this.permissions,
    this.onCreateTap,
    this.onViewTap,
    this.onTileTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? const Color(0xFFF4747E) : Colors.grey;

    return ListTile(
      onTap: onTileTap,
      tileColor: isSelected ? Colors.white.withOpacity(0.2) : null,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      selectedTileColor: isSelected ? primaryColor1 : Colors.grey,
      leading: SizedBox(
        height: 24,
        width: 24,
        child: SvgPicture.asset(
          iconAsset,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if ((permissions?[0] ?? false) && onCreateTap != null)
            GestureDetector(
              onTap: (onCreateTap),
              child: Icon(Icons.library_add, color: color, size: 20),
            ),
          if ((permissions?[1] ?? false) && onViewTap != null)
            GestureDetector(
              onTap: (onViewTap),
              child: Icon(Icons.list, color: color, size: 20),
            ),
        ],
      ),
    );
  }
}