import 'package:flutter/material.dart';
import 'package:sprova/features/admin/app_colors.dart';

class AdminTab extends StatelessWidget {
  final String label;
  final int index, current;
  final void Function(int) onTap;
  const AdminTab({super.key, required this.label, required this.index, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.amber : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.amber : AppColors.txt3,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class AdminFLabel extends StatelessWidget {
  final String text;
  const AdminFLabel({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.txt4,
      fontSize: 9,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class AdminStatPill extends StatelessWidget {
  final String label, value;
  const AdminStatPill({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: AppColors.amber,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      Text(
        label,
        style: const TextStyle(
          color: AppColors.txt4,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    ],
  );
}
