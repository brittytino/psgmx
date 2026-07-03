import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverallTab extends StatelessWidget {
  const OverallTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insights, size: 16, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Overall Batch Attendance',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(height: 8),
          Text(
            'Detailed batch statistics and exports will be available here.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
