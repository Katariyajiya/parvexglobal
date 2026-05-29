// lib/widgets/alert_banner.dart
//
// An in-app overlay banner shown when a price alert fires.
// It auto-dismisses after 5 seconds.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parvexglobal/alert/AlertDirection.dart';
import 'package:parvexglobal/alert/PriceAlert.dart';
import 'package:parvexglobal/pages/AlertHistoryScreen.dart';

import 'alert_service.dart';

class AlertBannerOverlay {
  static OverlayEntry? _entry;
  static Timer? _dismissTimer;

  /// Show a transient banner at the top of the screen.
  static void show(BuildContext context, PriceAlert alert) {
    // Dismiss any existing banner first.
    _dismiss();

    final overlay = Overlay.of(context);

    _entry = OverlayEntry(
      builder: (_) => _AlertBannerWidget(
        alert: alert,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_entry!);

    _dismissTimer = Timer(const Duration(seconds: 5), _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _AlertBannerWidget extends StatefulWidget {
  final PriceAlert alert;
  final VoidCallback onDismiss;

  const _AlertBannerWidget({required this.alert, required this.onDismiss});

  @override
  State<_AlertBannerWidget> createState() => _AlertBannerWidgetState();
}

class _AlertBannerWidgetState extends State<_AlertBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAbove = widget.alert.direction == AlertDirection.above;
    final accentColor = isAbove ? const Color(0xFF1B8B4B) : const Color(0xFFD93025);
    final arrow = isAbove ? '▲' : '▼';
    final top = MediaQuery.of(context).padding.top + 8;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: EdgeInsets.only(bottom: 10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.notifications_active,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🔔 Price Alert Triggered',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12),
                          children: [
                            TextSpan(
                              text: widget.alert.symbol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black),
                            ),
                            TextSpan(
                              text:
                                  ' crossed $arrow ₹${widget.alert.targetPrice.toStringAsFixed(2)}',
                              style:
                                  TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dismiss
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Icon(Icons.close,
                      size: 18, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
