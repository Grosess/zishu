import 'package:flutter/material.dart';

class ChangelogDialog extends StatelessWidget {
  final String version;

  const ChangelogDialog({
    super.key,
    required this.version,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.celebration,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text('What\'s New in $version'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'New Features'),
            _buildFeatureItem(context, 'New types of handwriting mode'),
            _buildFeatureItem(context, 'Black/white duotone theme option'),
            _buildFeatureItem(context, 'Most missed words statistics tracking'),
            _buildFeatureItem(context, 'Smaller device compatibility improvements'),
            const SizedBox(height: 16),
            _buildSectionTitle(context, 'Bug Fixes'),
            _buildFeatureItem(context, 'Fixed endless practice bug'),
            _buildFeatureItem(context, 'Fixed practice incorrect bug'),
            _buildFeatureItem(context, 'Other minor changes and improvements'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
