import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

enum StatusBadgeType {
  urgent,
  dueSoon,
  upcoming,
  settled,
  overdue,
  activeTreatment,
  regularPatient,
  ongoing,
  scheduled,
  completed,
  paid,
  concernTag,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  factory StatusBadge.fromStatusString(String status) {
    final lower = status.toLowerCase().trim();
    if (lower.contains('urgent')) {
      return StatusBadge(label: status, type: StatusBadgeType.urgent);
    } else if (lower.contains('due soon') || lower.contains('soon')) {
      return StatusBadge(label: status, type: StatusBadgeType.dueSoon);
    } else if (lower.contains('upcoming')) {
      return StatusBadge(label: status, type: StatusBadgeType.upcoming);
    } else if (lower.contains('settled')) {
      return StatusBadge(label: status, type: StatusBadgeType.settled);
    } else if (lower.contains('overdue')) {
      return StatusBadge(label: status, type: StatusBadgeType.overdue);
    } else if (lower.contains('ongoing')) {
      return StatusBadge(label: status, type: StatusBadgeType.ongoing);
    } else if (lower.contains('scheduled')) {
      return StatusBadge(label: status, type: StatusBadgeType.scheduled);
    } else if (lower.contains('completed') || lower.contains('paid')) {
      return StatusBadge(label: status, type: StatusBadgeType.completed);
    }
    return StatusBadge(label: status, type: StatusBadgeType.settled);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Widget? prefixIcon;

    switch (type) {
      case StatusBadgeType.urgent:
        bg = AppColors.statusUrgentBg;
        text = AppColors.statusUrgent;
        break;
      case StatusBadgeType.dueSoon:
        bg = AppColors.statusDueSoonBg;
        text = AppColors.statusDueSoon;
        break;
      case StatusBadgeType.upcoming:
      case StatusBadgeType.completed:
      case StatusBadgeType.paid:
      case StatusBadgeType.ongoing:
        bg = AppColors.statusUpcomingBg;
        text = AppColors.statusUpcoming;
        break;
      case StatusBadgeType.overdue:
        bg = AppColors.statusOverdueBg;
        text = AppColors.statusOverdue;
        break;
      case StatusBadgeType.settled:
        bg = AppColors.statusSettledBg;
        text = AppColors.statusSettled;
        break;
      case StatusBadgeType.activeTreatment:
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF15803D);
        prefixIcon = Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
        );
        break;
      case StatusBadgeType.regularPatient:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        prefixIcon = const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.person, size: 12, color: Color(0xFF0284C7)),
        );
        break;
      case StatusBadgeType.scheduled:
        bg = const Color(0xFFE0F2FE);
        text = const Color(0xFF0284C7);
        break;
      case StatusBadgeType.concernTag:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ?prefixIcon,
          if (icon != null && prefixIcon == null) ...[
            Icon(icon, size: 12, color: text),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: text,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
