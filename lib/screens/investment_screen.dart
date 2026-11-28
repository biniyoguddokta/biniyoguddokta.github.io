import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'add_investment_screen.dart';

class InvestmentScreen extends StatefulWidget {
  final String userRole;
  const InvestmentScreen({super.key, required this.userRole});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  List<dynamic> investments = [];
  List<Map<String, dynamic>> installmentContracts = [];
  bool isLoading = true;
  String selectedTab = "সক্রিয়";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    final results = await Future.wait([
      ApiService.getInvestments(),
      ApiService.getInstallmentData(),
    ]);
    if (!mounted) return;
    final investmentResult = results[0];
    final installmentResult = results[1];
    setState(() {
      if (investmentResult is List) investments = investmentResult;
      if (installmentResult is Map && installmentResult['contracts'] is List) {
        installmentContracts = (installmentResult['contracts'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      isLoading = false;
    });
  }

  // 🔥 প্রজেক্ট সম্পূর্ণ করার ডায়ালগ
  void _showCompleteDialog(String rowIndex, String currentProfit) {
    TextEditingController profitController = TextEditingController(text: currentProfit != "0" ? currentProfit : "");
    TextEditingController noteController = TextEditingController();
    TextEditingController dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("প্রজেক্ট সম্পূর্ণ করুন"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: profitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "মোট লাভ (৳)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "সম্পূর্ণ হওয়ার তারিখ"),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context, 
                    initialDate: DateTime.now(), 
                    firstDate: DateTime(2020), 
                    lastDate: DateTime(2030)
                  );
                  if (picked != null) {
                    dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: "নোট (মেয়াদ, বিবরণ ইত্যাদি)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("বাতিল")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF142F52)),
            onPressed: () async {
              if (profitController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("লাভের পরিমাণ দিন!"), backgroundColor: Colors.red));
                return;
              }
              
              Navigator.pop(context);
              setState(() => isLoading = true);
              
              var res = await ApiService.completeInvestment(
                rowIndex: rowIndex,
                profitAmount: profitController.text.trim(),
                completionDate: dateController.text,
                note: noteController.text.trim(),
              );

              if (res['status'] == "success" || res['message'] == "Success (302)") {
                _fetchData();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("প্রজেক্ট সম্পূর্ণ হয়েছে এবং লাভ আয়-তে যুক্ত হয়েছে!"), backgroundColor: Colors.green));
              } else {
                setState(() => isLoading = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? "সমস্যা হয়েছে"), backgroundColor: Colors.red));
              }
            },
            child: const Text("সম্পূর্ণ করুন", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Map investment) async {
    final project = (investment['ProjectName'] ?? 'এই প্রজেক্ট').toString();
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('প্রজেক্ট ডিলেট করবেন?'),
        content: Text('“$project” প্রজেক্টটি বিনিয়োগ তালিকা থেকে মুছে যাবে। পূর্বের লেনদেন/হিসাব মুছে ফেলা হবে না।'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ডিলেট করুন'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => isLoading = true);
    final result = await ApiService.deleteInvestment(rowIndex: (investment['RowIndex'] ?? '').toString());
    if (!mounted) return;
    if (result['status'] == 'success') {
      await _fetchData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রজেক্ট ডিলেট করা হয়েছে')));
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((result['message'] ?? 'ডিলেট করা যায়নি').toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = investments.where((inv) => (inv['Status'] ?? 'সক্রিয়').toString() == selectedTab).toList();
    final projectInvestment = investments.fold<double>(
      0,
      (sum, item) => sum +
          (double.tryParse('${item['InvestAmount'] ?? 0}'.replaceAll(',', '')) ?? 0),
    );
    // কিস্তির পণ্যে বিনিয়োগ হিসেবে ক্রয়মূল্য (CostPrice) গণনা হবে;
    // বিক্রয়মূল্যকে বিনিয়োগ হিসেবে দেখানো হবে না।
    final installmentInvestment = installmentContracts.fold<double>(
      0,
      (sum, contract) => sum +
          (double.tryParse('${contract['CostPrice'] ?? 0}'.replaceAll(',', '')) ?? 0),
    );
    final total = projectInvestment + installmentInvestment;
    final projectProfit = investments.fold<double>(
      0,
      (sum, item) => sum +
          (double.tryParse('${item['ProfitAmount'] ?? 0}'.replaceAll(',', '')) ?? 0),
    );
    final installmentProfit = installmentContracts.fold<double>(
      0,
      (sum, contract) {
        final sale = double.tryParse('${contract['SalePrice'] ?? 0}'.replaceAll(',', '')) ?? 0;
        final cost = double.tryParse('${contract['CostPrice'] ?? 0}'.replaceAll(',', '')) ?? 0;
        return sum + (sale - cost).clamp(0, double.infinity);
      },
    );
    final profit = projectProfit + installmentProfit;
    final activeInstallments = installmentContracts.where((c) {
      final status = (c['Status'] ?? 'চলমান').toString().trim();
      return !['সম্পন্ন', 'বাতিল', 'cancelled', 'completed'].contains(status.toLowerCase());
    }).length;
    final completedInstallments = installmentContracts.length - activeInstallments;
    final isAdmin = widget.userRole.trim().toLowerCase() == 'admin';
    final money = NumberFormat('#,##0.##');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FB),
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF4F46A5),
        title: const Text('বিনিয়োগ ব্যবস্থাপনা', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5146A5), Color(0xFF8175D8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: [BoxShadow(color: const Color(0xFF5146A5).withOpacity(.22), blurRadius: 20, offset: const Offset(0, 9))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [Icon(Icons.account_balance_wallet_rounded, color: Colors.white70), SizedBox(width: 8), Text('মোট বিনিয়োগ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600))]),
                      const SizedBox(height: 8),
                      Text('৳ ${money.format(total)}', style: const TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 14),
                      Row(children: [
                        _heroMetric('${investments.length + installmentContracts.length}', 'মোট বিনিয়োগ'),
                        const SizedBox(width: 22),
                        _heroMetric('${investments.where((e) => (e['Status'] ?? '') == 'সক্রিয়').length + activeInstallments}', 'চলমান'),
                        const SizedBox(width: 22),
                        _heroMetric('${investments.where((e) => (e['Status'] ?? '') == 'সম্পন্ন').length + completedInstallments}', 'সম্পন্ন'),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 13),
                  Row(children: [
                    Expanded(child: _summaryTile('মোট সম্ভাব্য লাভ', profit, const Color(0xFF16865A), Icons.trending_up_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _summaryTile('কিস্তি চুক্তি', installmentContracts.length.toDouble(), const Color(0xFF3975C6), Icons.shopping_bag_outlined, isCount: true)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [const Expanded(child: Text('বিনিয়োগ প্রজেক্ট', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF20233A)))), if (isAdmin) TextButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen())); _fetchData(); }, icon: const Icon(Icons.add_circle_outline), label: const Text('নতুন প্রজেক্ট'))]),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: ['সক্রিয়', 'সম্পন্ন', 'বাতিল'].map((tab) {
                        final selected = selectedTab == tab;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedTab = tab),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF5146A5) : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(tab, style: TextStyle(
                                  color: selected ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                )),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filtered.isEmpty) _emptyProjects() else ...filtered.map((inv) => _projectCard(inv, isAdmin, money)),
                  if (installmentContracts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text('কিস্তিতে পণ্যের বিনিয়োগ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF20233A))),
                    const SizedBox(height: 8),
                    ...installmentContracts.map(_buildInstallmentInvestmentCard),
                  ],
                ],
              ),
            ),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5146A5), foregroundColor: Colors.white,
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvestmentScreen())); _fetchData(); },
        icon: const Icon(Icons.add), label: const Text('নতুন প্রজেক্ট'),
      ) : null,
    );
  }

  Widget _heroMetric(String value, String label) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))]);

  Widget _summaryTile(String title, double value, Color color, IconData icon, {bool isCount = false}) => Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(.12))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color), const SizedBox(height: 8), Text(isCount ? value.toStringAsFixed(0) : '৳ ${NumberFormat('#,##0.##').format(value)}', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)), Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54))]));

  Widget _emptyProjects() => Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Column(children: [Icon(Icons.work_outline_rounded, size: 42, color: Color(0xFFAAA9C5)), SizedBox(height: 9), Text('এই বিভাগে কোনো প্রজেক্ট নেই', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))]));

  Widget _projectCard(Map inv, bool isAdmin, NumberFormat money) {
    final status = (inv['Status'] ?? 'অজানা').toString();
    final active = status == 'সক্রিয়';
    final amount = double.tryParse('${inv['InvestAmount'] ?? 0}'.replaceAll(',', '')) ?? 0;
    final expectedProfit = double.tryParse('${inv['ProfitAmount'] ?? 0}'.replaceAll(',', '')) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 11), padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9E9F2)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.025), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFF5146A5).withOpacity(.09), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.business_center_rounded, color: Color(0xFF5146A5))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((inv['ProjectName'] ?? 'নাম উল্লেখ নেই').toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), const SizedBox(height: 3), Text((inv['Sector'] ?? 'বিনিয়োগ প্রকল্প').toString(), style: const TextStyle(color: Colors.black54, fontSize: 12))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: active ? const Color(0xFFE7F6EE) : const Color(0xFFEDEBFA), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: active ? const Color(0xFF16865A) : const Color(0xFF5146A5), fontSize: 11, fontWeight: FontWeight.w700)))]),
        const SizedBox(height: 14), Row(children: [Expanded(child: _projectValue('বিনিয়োগ', '৳ ${money.format(amount)}')), Expanded(child: _projectValue('সম্ভাব্য লাভ', '৳ ${money.format(expectedProfit)}'))]),
        const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 8),
        Row(children: [Expanded(child: Text('${inv['StartDate'] ?? '—'}  →  ${inv['EndDate'] ?? '—'}', style: const TextStyle(color: Colors.black54, fontSize: 11))), if (isAdmin && active) TextButton.icon(onPressed: () => _showCompleteDialog((inv['RowIndex'] ?? '').toString(), (inv['ProfitAmount'] ?? '0').toString()), icon: const Icon(Icons.check_circle_outline, size: 17), label: const Text('সম্পন্ন')), if (isAdmin) IconButton(tooltip: 'প্রজেক্ট ডিলেট', onPressed: () => _confirmDelete(inv), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red))]),
      ]),
    );
  }

  Widget _projectValue(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54, fontSize: 11)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF292B45)))]);


  Widget _buildInstallmentInvestmentCard(Map<String, dynamic> contract) {
    final sale = num.tryParse((contract['SalePrice'] ?? '0').toString()) ?? 0;
    final cost = num.tryParse((contract['CostPrice'] ?? '0').toString()) ?? 0;
    final expectedProfit = (sale - cost).clamp(0, double.infinity);
    final down = num.tryParse((contract['DownPayment'] ?? '0').toString()) ?? 0;
    final months = num.tryParse((contract['Months'] ?? '0').toString()) ?? 0;
    final money = NumberFormat('#,##0.##');
    final contractId = (contract['ContractID'] ?? '').toString();
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (installmentContracts.first['ContractID'] == contractId)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('কিস্তিতে পণ্যের বিনিয়োগ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF142F52))),
            ),
          Row(children: [
            const Icon(Icons.shopping_bag_outlined, color: Color(0xFF142F52)),
            const SizedBox(width: 8),
            Expanded(child: Text((contract['ProductName'] ?? 'কিস্তির পণ্য').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Text((contract['Status'] ?? 'চলমান').toString(), style: const TextStyle(color: Color(0xFF142F52), fontSize: 12)),
          ]),
          const SizedBox(height: 7),
          Text('ক্রেতা: ${(contract['MemberName'] ?? '').toString()}'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _projectValue('পণ্যের বিনিয়োগ', '৳ ${money.format(cost)}')),
            Expanded(child: _projectValue('সম্ভাব্য লাভ', '৳ ${money.format(expectedProfit)}')),
          ]),
          const SizedBox(height: 6),
          Text('বিক্রয়মূল্য: ৳ ${money.format(sale)}  •  মেয়াদ: ${months.toStringAsFixed(0)} মাস'),
          Text('ডাউনপেমেন্ট: ৳ ${money.format(down)}'),
        ]),
      ),
    );
  }

  Widget _buildTab(String title) {
    bool isSelected = selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFF142F52) : Colors.transparent, borderRadius: BorderRadius.circular(15)),
          child: Center(child: Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }
}
