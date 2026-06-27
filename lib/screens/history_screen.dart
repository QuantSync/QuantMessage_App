import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../core/app_theme.dart';

class HistoryItem {
  final String query;
  final String date;
  final String time;
  final String modelName;
  final IconData icon;

  HistoryItem({
    required this.query,
    required this.date,
    required this.time,
    required this.modelName,
    required this.icon,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Mock data representing a user's search/chat history
  final List<HistoryItem> _historyItems = [
    HistoryItem(
      query: "Analyze this data: 98452-QR-DATA",
      date: "Today",
      time: "2:45 PM",
      modelName: "Scanner Engine",
      icon: Icons.qr_code_scanner_rounded,
    ),
    HistoryItem(
      query: "Generate a high-quality AI image: A futuristic neon city",
      date: "Today",
      time: "1:15 PM",
      modelName: "IMAGE ENGINE",
      icon: Icons.brush_rounded,
    ),
    HistoryItem(
      query: "Tell me the current weather and forecast for my location.",
      date: "Yesterday",
      time: "6:30 PM",
      modelName: "Gemini 1.5 Flash",
      icon: Icons.wb_sunny_rounded,
    ),
    HistoryItem(
      query: "What are the latest updates on quantum computing?",
      date: "Yesterday",
      time: "10:05 AM",
      modelName: "Claude 3.5 Sonnet",
      icon: Icons.chat_bubble_outline_rounded,
    ),
    HistoryItem(
      query: "Write a python script to parse a CSV file and output JSON.",
      date: "Oct 24",
      time: "4:20 PM",
      modelName: "GPT-4o",
      icon: Icons.code_rounded,
    ),
    HistoryItem(
      query: "Perform a multi-point technical analysis on this chart image.",
      date: "Oct 22",
      time: "9:10 AM",
      modelName: "Vision Engine",
      icon: Icons.analytics_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Search History",
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.primaryRed, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.surfaceMedium,
                    content: Text("History cleared", style: GoogleFonts.outfit(color: AppTheme.textPrimary)),
                    duration: const Duration(seconds: 2),
                  )
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _historyItems.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        itemCount: _historyItems.length,
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          return FadeInUp(
            // Dynamic delay for a cascading list animation
            duration: Duration(milliseconds: 400 + (index * 100).clamp(0, 800)),
            child: _buildHistoryCard(item),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Logic to restore this specific search session
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon representing the search type
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryRed.withOpacity(0.2)),
                  ),
                  child: Icon(item.icon, color: AppTheme.primaryRed, size: 22),
                ),
                const SizedBox(width: 16),

                // Query Text and Meta Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.query,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.modelName,
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${item.date} • ${item.time}",
                            style: GoogleFonts.outfit(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              "No Search History",
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your past conversations will appear here.",
              style: GoogleFonts.outfit(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}