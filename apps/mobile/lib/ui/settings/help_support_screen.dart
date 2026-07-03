import 'package:flutter/material.dart';
import '../../core/theme/app_dimens.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support")),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _buildSectionTitle(context, "About PSGMX Placement"),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "This application is the official placement management tool for the Class of 2026. "
            "It tracks your daily task completion, attendance, and LeetCode progress to ensure placement readiness.",
          ),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSectionTitle(context, "Frequently Asked Questions"),
          const SizedBox(height: AppSpacing.md),
          _buildFaqItem(
            context,
            "Why is my LeetCode not updating?", 
            "Stats are refreshed every 12 hours to prevent server overload. If you just solved a problem, please wait for the next cycle.",
          ),
          _buildFaqItem(
            context,
            "How is attendance calculated?", 
            "Attendance percent is based strictly on 'Class Days' (Mon, Tue, Thu, Odd Saturdays). Non-class days do not affect your score.",
          ),
          _buildFaqItem(
             context,
            "I missed marking attendance.", 
            "Contact your Team Leader or Placement Rep immediately. Only Reps can override past attendance.",
          ),

          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle(context, "Support Contacts"),
          const SizedBox(height: AppSpacing.sm),
          const ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text("Placement Coordinator"),
            subtitle: Text("coordinator@psgmx.edu"),
          ),
          const ListTile(
             leading: Icon(Icons.bug_report_outlined),
             title: Text("Report a Bug"),
             subtitle: Text("dev-team@psgmx.edu"),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          Center(
             child: Text(
               "Version 1.0.0 (Production)",
               style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
             ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(answer, style: TextStyle(color: Colors.grey[700], height: 1.4)),
        ],
      ),
    );
  }
}
