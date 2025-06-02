import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Theme/AppTheme.dart';
import '../models/models.dart';
import '../screens/ProfileScreenAss.dart';
import 'ModernCard.dart';

class InternshipApplicationCard extends StatelessWidget {
  final InternshipApplication application;

  const InternshipApplicationCard({Key? key, required this.application}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: () {
        // Show details if needed
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    application.title ?? application.internshipTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusBadge(
                  text: application.status,
                  color: _getStatusColor(application.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (application.company != null)
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: AppTheme.subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    application.company!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            if (application.location != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    application.location!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            if (application.type != null)
              Row(
                children: [
                  const Icon(Icons.work, size: 16, color: AppTheme.subtitleColor),
                  const SizedBox(width: 6),
                  Text(
                    application.type!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.subtitleColor,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.subtitleColor),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy').format(application.appliedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.subtitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return AppTheme.statusAccepted;
      case 'rejected':
        return AppTheme.statusRejected;
      case 'pending':
        return AppTheme.statusPending;
      default:
        return AppTheme.statusDefault;
    }
  }
}
