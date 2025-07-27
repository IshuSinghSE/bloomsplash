import 'package:flutter/material.dart';


class InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final double width;
  final double height;

  const InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.width = 220,
    this.height = 110,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Tooltip(
                message: value,
                waitDuration: Duration(milliseconds: 400),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  // softWrap: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
