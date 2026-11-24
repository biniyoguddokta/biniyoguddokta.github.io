import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../controllers/report_controller.dart';
import '../models/report_model.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const Color navy = Color(0xFF142F52);
  static const Color blue = Color(0xFF246BCE);
  static const Color green = Color(0xFF159B69);
  static const Color red = Color(0xFFD94C59);
  static const Color purple = Color(0xFF7755C8);
  static const Color canvas = Color(0xFFF3F6FB);
  late final ReportController controller;
  final money = NumberFormat('#,##,##0.##', 'en_US');

  @override
  void initState() {
    super.initState();
    controller = ReportController()..load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String taka(double value) => '৳ ${money.format(value)}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.summary;
        return Scaffold(
          backgroundColor: canvas,
          appBar: AppBar(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('রিপোর্ট ও বিশ্লেষণ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('সকল মডিউলের আর্থিক সারসংক্ষেপ', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
            actions: [
              IconButton(tooltip: 'রিফ্রেশ', onPressed: () => controller.load(forceRefresh: true), icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
          body: controller.loading && summary == null
              ? const Center(child: CircularProgressIndicator())
              : controller.error != null && summary == null
                  ? _errorView(controller.error!)
                  : summary == null
                      ? const Center(child: Text('রিপোর্ট ডেটা পাওয়া যায়নি।'))
                      : RefreshIndicator(
                          onRefresh: () => controller.load(forceRefresh: true),
                          child: _reportBody(summary),
                        ),
        );
      },
    );
  }

  Widget _errorView(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_rounded, color: red, size: 44),
            const SizedBox(height: 12),
            const Text('রিপোর্ট লোড করা যায়নি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () => controller.load(forceRefresh: true), icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন')),
          ]),
        ),
      );

  Widget _reportBody(ReportSummary s) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        children: [
          _periodPicker(),
          const SizedBox(height: 12),
          _heroCard(s),
          const SizedBox(height: 12),
          _sectionTitle('আর্থিক সারাংশ'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _metric('মোট আয়', taka(s.income), Icons.trending_up, green),
              _metric('মোট ব্যয়', taka(s.expenses), Icons.trending_down, red),
              _metric('নিট লাভ/ক্ষতি', taka(s.net), Icons.account_balance_wallet, s.net >= 0 ? blue : red),
              _metric('মোট সদস্য', '${s.totalMembers}', Icons.groups_rounded, purple, subtitle: 'সক্রিয় ${s.activeMembers}'),
            ],
          ),
          const SizedBox(height: 18),
          _sectionTitle('আয় ও ব্যয়ের তুলনা'),
          _panel(child: SizedBox(height: 190, child: _incomeExpenseChart(s))),
          const SizedBox(height: 18),
          _sectionTitle('মডিউলভিত্তিক রিপোর্ট'),
          _moduleCard('বিনিয়োগ', Icons.business_center_outlined, blue, [
            _line('মোট বিনিয়োগ মূলধন', taka(s.investedPrincipal)),
            _line('সম্পন্ন প্রকল্পের লাভ', taka(s.investmentProfit)),
            const _lineNote('বিনিয়োগের মূলধনকে আয় হিসেবে গণনা করা হয়নি।'),
          ]),
          _moduleCard('কিস্তি', Icons.event_repeat_rounded, purple, [
            _line('চুক্তির মোট বিক্রয়মূল্য', taka(s.installmentContractValue)),
            _line('এই সময়ে আদায়', taka(s.installmentCollected)),
            _line('বর্তমান বকেয়া', taka(s.installmentOutstanding)),
          ]),
          _moduleCard('স্টক ব্যবসা', Icons.inventory_2_outlined, green, [
            _line('বর্তমান স্টক মূল্য', taka(s.stockValue)),
            _line('এই সময়ে বিক্রয়', taka(s.stockSales)),
            _line('এই সময়ে ক্রয়', taka(s.stockPurchases)),
            _line('সাধারণ স্টক খরচ', taka(s.stockOperatingExpenses)),
            const _lineNote('স্টক ক্রয়কে সরাসরি সম্পূর্ণ ব্যয় হিসেবে ধরা হয়নি; বর্তমান মজুত সম্পদ হিসেবে দেখানো হয়েছে।'),
          ]),
          _moduleCard('লস প্রজেক্ট', Icons.trending_down_rounded, red, [
            _line('মোট ক্ষতি', taka(s.totalLoss)),
            _line('উদ্ধারকৃত', taka(s.recoveredLoss)),
            _line('অবশিষ্ট ক্ষতি', taka(s.remainingLoss)),
            const _lineNote('এই ডেটা বর্তমান ডিভাইসের লোকাল স্টোরেজ থেকে এসেছে।'),
          ]),
          _moduleCard('স্যালারি', Icons.payments_outlined, const Color(0xFFB47A22), [
            _line('রিপোর্ট সংযোগ', s.data.salaryConnected ? 'সংযুক্ত' : 'সংযুক্ত নয়'),
            Text(s.data.salaryMessage.isEmpty ? 'Salary module-এর payroll ডেটা রিপোর্ট API-তে নেই।' : s.data.salaryMessage,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ]),
          const SizedBox(height: 18),
          _sectionTitle('সাম্প্রতিক লেনদেন'),
          _transactions(s),
          const SizedBox(height: 10),
          Text('সার্ভার আপডেট: ${DateFormat('dd MMM yyyy, hh:mm a').format(s.data.generatedAt)}',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45, fontSize: 11)),
        ],
      );

  Widget _periodPicker() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE4EAF2))),
        child: Row(children: [
          const Icon(Icons.calendar_month_outlined, color: navy),
          const SizedBox(width: 10),
          const Expanded(child: Text('রিপোর্টের সময়সীমা', style: TextStyle(fontWeight: FontWeight.w600))),
          DropdownButtonHideUnderline(child: DropdownButton<String>(
            value: controller.selectedPeriod,
            items: const ['আজ', 'গত ৭ দিন', 'এই মাস', 'গত মাস', 'এই বছর', 'সব সময়'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) { if (v != null) controller.setPeriod(v); },
          )),
        ]),
      );

  Widget _heroCard(ReportSummary s) => Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF285987)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(21), boxShadow: [BoxShadow(color: navy.withOpacity(.16), blurRadius: 18, offset: const Offset(0, 7))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('নিট আর্থিক ফলাফল', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 7),
          Text(taka(s.net), style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            _heroMini('আয়', taka(s.income), green),
            const SizedBox(width: 22),
            _heroMini('ব্যয়', taka(s.expenses), const Color(0xFFFF8991)),
          ]),
        ]),
      );

  Widget _heroMini(String label, String value, Color color) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)), Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15))]));

  Widget _metric(String label, String value, IconData icon, Color color, {String? subtitle}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5EBF3))),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 21)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ])),
        ]),
      );

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(title, style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.bold)));
  Widget _panel({required Widget child}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE5EBF3))), child: child);

  Widget _incomeExpenseChart(ReportSummary s) {
    if (s.income == 0 && s.expenses == 0) return const Center(child: Text('এই সময়সীমায় আয় বা ব্যয়ের তথ্য নেই', style: TextStyle(color: Colors.black45)));
    return Row(children: [
      Expanded(child: PieChart(PieChartData(centerSpaceRadius: 42, sectionsSpace: 3, sections: [
        if (s.income > 0) PieChartSectionData(value: s.income, color: green, radius: 24, title: 'আয়', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        if (s.expenses > 0) PieChartSectionData(value: s.expenses, color: red, radius: 24, title: 'ব্যয়', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
      ]))),
      const SizedBox(width: 12),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _legend(green, 'আয়', taka(s.income)), const SizedBox(height: 14), _legend(red, 'ব্যয়', taka(s.expenses)),
      ])),
    ]);
  }

  Widget _legend(Color color, String label, String value) => Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 7), Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54))), Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis))]);

  Widget _moduleCard(String title, IconData icon, Color color, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: color), const SizedBox(width: 9), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
          const Divider(height: 20),
          ...children,
        ])),
      );

  Widget _line(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))), Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))]));

  Widget _transactions(ReportSummary s) {
    final rows = s.filteredTransactions.reversed.take(12).toList();
    if (rows.isEmpty) return _panel(child: const Center(child: Text('এই সময়সীমায় কোনো লেনদেন নেই', style: TextStyle(color: Colors.black45))));
    return _panel(child: Column(children: rows.map((r) {
      final type = (r['Type'] ?? r['type'] ?? '').toString();
      final amount = ReportSummary.number(r['Amount'] ?? r['amount']);
      final date = (r['Date'] ?? r['date'] ?? '').toString();
      final note = (r['Note'] ?? r['note'] ?? r['MemberName'] ?? '').toString();
      final isIncome = type.toLowerCase().contains('আয়') || type.toLowerCase() == 'income' || type.toLowerCase().contains('জমা');
      return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: (isIncome ? green : red).withOpacity(.1), borderRadius: BorderRadius.circular(10)), child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? green : red, size: 18)),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(note.isEmpty ? type : note, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)), Text('$type • $date', style: const TextStyle(color: Colors.black45, fontSize: 10))])),
        Text(taka(amount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isIncome ? green : red)),
      ]));
    }).toList()));
  }
}

class _lineNote extends StatelessWidget {
  const _lineNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 7), child: Text(text, style: const TextStyle(color: Colors.black45, fontSize: 10, fontStyle: FontStyle.italic)));
}
