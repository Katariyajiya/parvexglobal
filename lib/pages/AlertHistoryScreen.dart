import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parvexglobal/alert/AlertCondition.dart';
import 'package:parvexglobal/alert/AlertHistoryEntry.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/alert/alert_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> with SingleTickerProviderStateMixin {
  final _alertService = AlertService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AlertHistoryEntry> get _all => _alertService.history.reversed.toList();

  List<AlertHistoryEntry> get _fired => _all.where((e) => e.fired).toList();

  List<PriceAlert> get _active => _alertService.allAlerts.where((a) => !a.triggered).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryTab(),
                _buildActiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Alert History',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        if (_tabController.index == 0 && _all.isNotEmpty)
          TextButton(
            onPressed: _confirmClearHistory,
            child: const Text(
              'Clear All',
              style: TextStyle(
                color: Color(0xFFCC2929),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _TabChip(
            label: 'Fired  ${_fired.isNotEmpty ? "(${_fired.length})" : ""}',
            selected: _tabController.index == 0,
            onTap: () => _tabController.animateTo(0),
            color: const Color(0xFFCC2929),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: 'Active  ${_active.isNotEmpty ? "(${_active.length})" : ""}',
            selected: _tabController.index == 1,
            onTap: () => _tabController.animateTo(1),
            color: const Color(0xFF1F63FF),
          ),
        ],
      ),
    );
  }

  // ── Fired history tab ──────────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    if (_fired.isEmpty) {
      return _buildEmpty(
        icon: Icons.notifications_off_outlined,
        title: 'No alerts fired yet',
        subtitle: 'Long-press any instrument on the\nwatchlist to set a price alert.',
      );
    }

    // Group by date
    final grouped = <String, List<AlertHistoryEntry>>{};
    for (final e in _fired) {
      final key = _dateLabel(e.firedAt);
      grouped.putIfAbsent(key, () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            ...entry.value.map((e) => _AlertHistoryCard(entry: e)),
          ],
        );
      }).toList(),
    );
  }

  // ── Active alerts tab ──────────────────────────────────────────────────────
  Widget _buildActiveTab() {
    if (_active.isEmpty) {
      return _buildEmpty(
        icon: Icons.add_alert_outlined,
        title: 'No active alerts',
        subtitle: 'Long-press any instrument on the\nwatchlist to set a price alert.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: _active
          .map(
            (a) => _ActiveAlertCard(
              alert: a,
              onDelete: () {
                _alertService.removeAlert(a.id);
                setState(() {});
              },
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    if (d == today) return 'TODAY';
    if (d == today.subtract(const Duration(days: 1))) return 'YESTERDAY';
    return DateFormat('dd MMM yyyy').format(dt).toUpperCase();
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear History', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('All fired alert history will be deleted. Active alerts remain unchanged.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _alertService.clearHistory();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Color(0xFFCC2929))),
          ),
        ],
      ),
    );
  }
}

// ── Fired alert card ─────────────────────────────────────────────────────────
class _AlertHistoryCard extends StatelessWidget {
  const _AlertHistoryCard({required this.entry});

  final AlertHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isAbove = entry.condition == AlertCondition.above;
    final dirColor = isAbove ? const Color(0xFF1E7D3A) : const Color(0xFFCC2929);
    final dirBg = isAbove ? const Color(0xFFD6F3E0) : const Color(0xFFF9D6D6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: dirBg, shape: BoxShape.circle),
            child: Icon(
              isAbove ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: dirColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.symbol,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    children: [
                      TextSpan(text: isAbove ? 'Rose above ' : 'Fell below '),
                      TextSpan(
                        text: '₹${entry.targetPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: dirColor, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' · hit ₹${entry.triggeredPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Time
          Text(
            DateFormat('hh:mm a').format(entry.firedAt),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Active alert card ─────────────────────────────────────────────────────────
class _ActiveAlertCard extends StatelessWidget {
  const _ActiveAlertCard({required this.alert, required this.onDelete});

  final PriceAlert alert;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.condition == AlertCondition.above;
    final dirColor = isAbove ? const Color(0xFF1F63FF) : const Color(0xFFCC2929);
    final dirBg = isAbove ? const Color(0xFFECF1FF) : const Color(0xFFF9D6D6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: dirBg, shape: BoxShape.circle),
            child: Icon(
              isAbove ? Icons.notifications_active_rounded : Icons.notifications_active_rounded,
              color: dirColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.symbol,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    children: [
                      TextSpan(text: isAbove ? 'Alert when above ' : 'Alert when below '),
                      TextSpan(
                        text: '₹${alert.targetPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: dirColor, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade400, size: 20),
            onPressed: onDelete,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────
class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── AlertService ──────────────────────────────────────────────────────────────

