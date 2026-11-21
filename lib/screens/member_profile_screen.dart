import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MemberProfileScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  const MemberProfileScreen({super.key, required this.member});
  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> investments = [];
  double deposits = 0, dues = 0, income = 0, expenses = 0;
  String get memberName => (widget.member['Name'] ?? '').toString().trim();
  String get memberPhone => (widget.member['Phone'] ?? '').toString().trim();
  double _amount(dynamic v) => double.tryParse((v ?? '0').toString().replaceAll(',', '')) ?? 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait([ApiService.getTransactions(), ApiService.getInvestments()]);
      final txRaw = results[0];
      final invRaw = results[1];
      if (txRaw is Map && txRaw['error'] != null) throw Exception(txRaw['error']);
      final allTx = txRaw is List ? txRaw : <dynamic>[];
      final cleanPhone = memberPhone.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^880'), '').replaceFirst(RegExp(r'^0'), '');
      final filtered = allTx.where((e) {
        if (e is! Map) return false;
        final name = (e['MemberName'] ?? '').toString().trim().toLowerCase();
        final phone = (e['Phone'] ?? e['MemberPhone'] ?? '').toString().replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^880'), '').replaceFirst(RegExp(r'^0'), '');
        return name == memberName.toLowerCase() || (cleanPhone.isNotEmpty && phone == cleanPhone);
      }).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      double d = 0, due = 0, inc = 0, exp = 0;
      for (final tx in filtered) {
        final amount = _amount(tx['Amount']);
        final type = (tx['Type'] ?? '').toString();
        final status = (tx['Status'] ?? 'Paid').toString();
        if (status == 'Paid') {
          if (type == 'জমা') d += amount;
          if (type == 'আয়' || type == 'আয়') inc += amount;
          if (type == 'খরচ' || type == 'ব্যয়' || type == 'ব্যয়') exp += amount;
        }
        if ((type == 'বকেয়া' || type == 'বকেয়া') && status != 'Paid') due += amount;
      }
      final inv = invRaw is List ? invRaw.where((e) => e is Map).map((e) => Map<String,dynamic>.from(e as Map)).toList() : <Map<String,dynamic>>[];
      if (!mounted) return;
      setState(() { transactions = filtered.reversed.toList(); investments = inv; deposits = d; dues = due; income = inc; expenses = exp; loading = false; });
    } catch (e) { if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    final name = memberName.isEmpty ? 'নাম পাওয়া যায়নি' : memberName;
    final role = (widget.member['Designation'] ?? (widget.member['Role'] == 'Admin' ? 'প্রতিষ্ঠাতা / অ্যাডমিন' : 'সদস্য')).toString();
    return Scaffold(backgroundColor: const Color(0xFFF4F7F8), appBar: AppBar(title: const Text('Member 360°'), backgroundColor: const Color(0xFF00796B), foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? _errorView() : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: Row(children: [CircleAvatar(radius: 32, backgroundColor: const Color(0xFF00796B), child: Text(name.isEmpty ? '?' : name.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 24))), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(memberPhone), Text(role, style: const TextStyle(color: Color(0xFF00796B), fontWeight: FontWeight.w600))]))])),
        const SizedBox(height: 14),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.75, children: [
          _stat('মোট জমা', deposits, Colors.green, Icons.south_west), _stat('বকেয়া', dues, Colors.red, Icons.pending_actions), _stat('আয়', income, Colors.blue, Icons.trending_up), _stat('ব্যয়', expenses, Colors.deepOrange, Icons.trending_down),
        ]),
        const SizedBox(height: 16), _sectionTitle('সদস্যের তথ্য'), _info('ফোন', memberPhone), _info('ইমেইল', (widget.member['Email'] ?? '—').toString()), _info('পদবি', role), _info('অ্যাকাউন্টের ধরন', (widget.member['Role'] ?? 'Member').toString()),
        const SizedBox(height: 16), _sectionTitle('সাম্প্রতিক লেনদেন (${transactions.length})'),
        if (transactions.isEmpty) const _Empty(text: 'এই সদস্যের নামে কোনো লেনদেন পাওয়া যায়নি') else ...transactions.take(50).map(_transaction),
        const SizedBox(height: 16), _sectionTitle('বিনিয়োগ প্রকল্প (${investments.length})'),
        if (investments.isEmpty) const _Empty(text: 'বিনিয়োগের তথ্য পাওয়া যায়নি') else ...investments.take(30).map((v) => Card(child: ListTile(leading: const Icon(Icons.business_center, color: Color(0xFF00796B)), title: Text((v['ProjectName'] ?? v['projectName'] ?? 'প্রকল্প').toString()), subtitle: Text('অবস্থা: ${(v['Status'] ?? '—')}'), trailing: Text('৳ ${_amount(v['InvestAmount']).toStringAsFixed(0)}')))),
        const SizedBox(height: 10), const Text('নোট: লেনদেনের সদস্য-ফোন API-তে না থাকলে নামের মিলের ভিত্তিতে তথ্য দেখানো হয়। প্রকল্পের তথ্য বর্তমানে সমিতির সামগ্রিক বিনিয়োগ তালিকা থেকে আসে।', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])));
  }
  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44, color: Colors.red), const SizedBox(height: 12), Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('আবার চেষ্টা করুন'))])));
  Widget _stat(String title, double value, Color color, IconData icon) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color), const SizedBox(height: 5), Text(title, style: const TextStyle(color: Colors.black54)), Text('৳ ${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 19, fontWeight: FontWeight.bold))]));
  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)));
  Widget _info(String k, String v) => Card(margin: const EdgeInsets.only(bottom: 5), child: ListTile(dense: true, title: Text(k, style: const TextStyle(color: Colors.grey)), trailing: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))));
  Widget _transaction(Map<String,dynamic> tx) { final type = (tx['Type'] ?? 'লেনদেন').toString(); final paid = (tx['Status'] ?? 'Paid') == 'Paid'; final amount = _amount(tx['Amount']); final isCredit = type == 'জমা' || type == 'আয়' || type == 'আয়'; return Card(margin: const EdgeInsets.only(bottom: 7), child: ListTile(leading: CircleAvatar(backgroundColor: (isCredit ? Colors.green : Colors.orange).withOpacity(.12), child: Icon(isCredit ? Icons.call_received : Icons.receipt_long, color: isCredit ? Colors.green : Colors.orange)), title: Text(type), subtitle: Text('${tx['Date'] ?? 'তারিখ নেই'} • ${paid ? 'পরিশোধিত' : 'বকেয়া'}'), trailing: Text('৳ ${amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red)))); }
}
class _Empty extends StatelessWidget { final String text; const _Empty({required this.text}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(18), child: Center(child: Text(text, style: const TextStyle(color: Colors.grey)))); }
