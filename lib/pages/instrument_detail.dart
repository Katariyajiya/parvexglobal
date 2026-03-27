import 'package:flutter/material.dart';

class InstrumentDetailScreen extends StatefulWidget {
  const InstrumentDetailScreen({super.key});

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  String selectedTimeframe = '1W';
  final List<String> timeframes = ['1D', '1W', '1M', '3M', '1Y'];

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF0D1B3E);
    const Color textGrey = Color(0xFF8E99AF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D1B3E), Color(0xFF1A2A4D)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Navigation Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const Text('MCX · Commodity', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.star, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('GOLD', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const Text(
                  'Multi Commodity Exchange of India · Lot Size: 100g',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTag('MCX', Colors.white.withOpacity(0.1), Colors.white),
                    const SizedBox(width: 8),
                    _buildTag('Commodity', Colors.white.withOpacity(0.1), Colors.white),
                    const SizedBox(width: 8),
                    _buildTag('Expiry: Dec 28, 2025', Colors.white.withOpacity(0.1), Colors.white),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('₹62,840', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('▼ ₹204', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('▼ 0.32%', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.58,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeframe Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: timeframes.map((t) => _buildTimeframeBtn(t)).toList(),
                    ),
                    const SizedBox(height: 20),


                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(Icons.show_chart, size: 100, color: Colors.blue.withOpacity(0.2)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('PRICE INFORMATION', style: TextStyle(color: textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 20),

                    // Data Grid
                    _buildPriceRow('LTP (Last Traded)', '₹62,840', 'Previous Close', '₹63,044'),
                    const SizedBox(height: 20),
                    _buildPriceRow('Open Price', '₹62,950', 'Change (₹)', '▼ ₹204'),
                    const SizedBox(height: 20),
                    _buildPriceRow('Day High', '₹63,120', 'Day Low', '₹62,610'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String txt, Color bg, Color txtColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(txt, style: TextStyle(color: txtColor, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTimeframeBtn(String label) {
    bool isSelected = selectedTimeframe == label;
    return GestureDetector(
      onTap: () => setState(() => selectedTimeframe = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2979FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label1, String val1, String label2, String val2) {
    return Row(
      children: [
        Expanded(child: _buildPriceItem(label1, val1)),
        Expanded(child: _buildPriceItem(label2, val2)),
      ],
    );
  }

  Widget _buildPriceItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8E99AF), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF0D1B3E), fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}