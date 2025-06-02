import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Theme/AppTheme.dart';
import '../models/models.dart';
import '../screens/ProfileScreenAss.dart';
import 'ModernCard.dart';
import '../screens/DetailedResultScreen.dart';

class AssessmentResultCard extends StatelessWidget {
  final AssessmentResult result;

  const AssessmentResultCard({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Directly navigate to DetailedResultScreen with result data
        // The screen will handle fetching questions and answers internally
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedResultScreen(
              assessmentResultId: result.id,
              result: result,
            ),
          ),
        );
      },
      child: ModernCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildLevelAndScoreBox(),
              const SizedBox(height: 12),
              _buildCorrectWrongRow(),
              const SizedBox(height: 8),
              _buildDateRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            result.assessmentName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getScoreColor(result.percentage).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${result.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: _getScoreColor(result.percentage),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelAndScoreBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Level:', result.level),
          const SizedBox(height: 8),
          _buildInfoRow('Score:', '${result.score}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.subtitleColor),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCorrectWrongRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.scoreHigh.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.scoreHigh, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${result.totalCorrectAnswers} Correct',
                  style: const TextStyle(
                    color: AppTheme.scoreHigh,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.scoreLow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, color: AppTheme.scoreLow, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${result.totalWrongAnswers} Wrong',
                  style: const TextStyle(
                    color: AppTheme.scoreLow,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Icon(Icons.calendar_today, size: 14, color: AppTheme.subtitleColor),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM d, yyyy').format(result.timestamp),
          style: const TextStyle(fontSize: 12, color: AppTheme.subtitleColor),
        ),
      ],
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) {
      return AppTheme.scoreHigh;
    } else if (percentage >= 60) {
      return AppTheme.scoreMedium;
    } else {
      return AppTheme.scoreLow;
    }
  }
}
