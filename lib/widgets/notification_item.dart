import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  final String initials;
  final String message;
  final String timeAgo;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? initialsColor;
  final Color? initialsBackgroundColor;

  const NotificationItem({
    Key? key,
    required this.initials,
    required this.message,
    required this.timeAgo,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.initialsColor,
    this.initialsBackgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: initialsBackgroundColor ?? Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: initialsColor ?? Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: Colors.grey,
                        size: 15,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        timeAgo,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
