import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

/// কিস্তিতে পণ্য: Google Apps Script / Google Sheets backed implementation.
class InstallmentProductScreen extends StatefulWidget {
  final String userRole;
  const InstallmentProductScreen({super.key, required this.userRole});

  @override
  State<InstallmentProductScreen> createState() => _InstallmentProductScreenState();
}

class _InstallmentProductScreenState extends State<InstallmentProductScreen> {
  static const navy = Color(0xFF142F52);
  static const gold = Color(0xFFD0A522);
  static const canvas = Color(0xFFF5F3EE);
  final _money = NumberFormat('#,##0.##', 'en_US');
  List<Map<String, dynamic>> _contracts = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _linkedMembers = [];
  String _actorPhone = '';
  String? _loadError;
  bool _loading = true;
  int _tab = 0;
  String _query = '';
  bool get _isAdmin => widget.userRole.trim().toLowerCase() == 'admin';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _loadError = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      _actorPhone = prefs.getString('userPhone') ?? '';
      final raw = await ApiService.getInstallmentData();
      if (raw is! Map || raw['error'] != null) {
        throw Exception(raw is Map ? (raw['message'] ?? raw['error'] ?? 'Backend থেকে তথ্য পাওয়া যায়নি') : 'Backend response invalid');
      }
      final contracts = (raw['contracts'] as List? ?? []).map((e) => Map<String,dynamic>.from(e as Map)).map((c) {
        final id = (c['ContractID'] ?? '').toString();
        final payments = (raw['payments'] as List? ?? []).where((p) => (p as Map)['ContractID'].toString() == id).map((p) {
          final x = Map<String,dynamic>.from(p as Map);
          return {'id': x['PaymentID'], 'amount': x['Amount'], 'date': x['PaymentDate'], 'note': x['Note'] ?? '', 'monthNo': x['MonthNo'] ?? ''};
        }).toList();
        return <String,dynamic>{
          'id': id, 'memberId': c['MemberID'], 'productId': c['ProductID'], 'memberType': c['MemberType'] ?? 'external',
          'memberName': c['MemberName'], 'memberPhone': c['MemberPhone'], 'address': c['Address'],
          'guarantorName': c['GuarantorName'], 'guarantorPhone': c['GuarantorPhone'], 'productName': c['ProductName'],
          'months': c['Months'], 'costPrice': c['CostPrice'], 'salePrice': c['SalePrice'], 'downPayment': c['DownPayment'],
          'startDate': c['StartDate'], 'status': c['Status'], 'note': c['Note'] ?? '', 'payments': payments,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _contracts = contracts;
        _expenses = (raw['expenses'] as List? ?? []).map((e) => Map<String,dynamic>.from(e as Map)).toList();
        _linkedMembers = (raw['linkedMembers'] as List? ?? []).map((e) => Map<String,dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _loadError = e.toString(); });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('কিস্তির তথ্য লোড হয়নি: $e')));
    }
  }

  String _m(num n) => '৳ ${_money.format(n)}';
  num _n(dynamic v) => num.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;
  DateTime _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
  String _dateText(dynamic v) => DateFormat('dd MMM yyyy', 'en').format(_date(v));
  num _paid(Map<String, dynamic> c) => (c['payments'] as List? ?? []).fold<num>(0, (s, p) => s + _n((p as Map)['amount']));
  num _sale(Map<String, dynamic> c) => _n(c['salePrice']);
  num _balance(Map<String, dynamic> c) => (_sale(c) - _n(c['downPayment']) - _paid(c)).clamp(0, double.infinity);
  num _profit(Map<String, dynamic> c) => _sale(c) - _n(c['costPrice']);
  int _months(Map<String, dynamic> c) => (_n(c['months'])).toInt();
  num _monthly(Map<String, dynamic> c) => _months(c) == 0 ? 0 : (_sale(c) - _n(c['downPayment'])) / _months(c);
  bool _isComplete(Map<String, dynamic> c) => _balance(c) <= 0;
  int _overdue(Map<String, dynamic> c) {
    if (_isComplete(c)) return 0;
    final start = _date(c['startDate']);
    final now = DateTime.now();
    final due = (now.year - start.year) * 12 + now.month - start.month + 1;
    final shouldHavePaid = due.clamp(0, _months(c));
    final paidInstallments = _paid(c) / (_monthly(c) == 0 ? 1 : _monthly(c));
    return (shouldHavePaid - paidInstallments.floor()).clamp(0, _months(c)).toInt();
  }

  Future<void> _openContractForm({Map<String, dynamic>? existing}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context, barrierDismissible: false,
      builder: (_) => _ContractDialog(existing: existing, money: _money, linkedMembers: _linkedMembers),
    );
    if (result == null) return;
    final payload = <String,dynamic>{
      'actorPhone': _actorPhone,
      'contractId': existing?['id'] ?? '', 'memberId': existing?['memberId'] ?? '',
      'productId': existing?['productId'] ?? '', 'memberType': result['memberType'] ?? 'external',
      'linkedMemberPhone': result['linkedMemberPhone'] ?? '', 'memberName': result['memberName'],
      'memberPhone': result['memberPhone'], 'email': result['email'] ?? '', 'address': result['address'],
      'nid': result['nid'] ?? '', 'guarantorName': result['guarantorName'], 'guarantorPhone': result['guarantorPhone'],
      'guarantorAddress': result['guarantorAddress'] ?? '', 'productName': result['productName'],
      'productCategory': result['productCategory'] ?? '', 'productDescription': result['productDescription'] ?? '',
      'months': result['months'].toString(), 'costPrice': result['costPrice'].toString(),
      'salePrice': result['salePrice'].toString(), 'downPayment': result['downPayment'].toString(),
      'startDate': result['startDate'], 'note': result['note'] ?? '',
    };
    final response = await ApiService.saveInstallmentContract(payload);
    if (response['status'] != 'success') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'চুক্তি সংরক্ষণ হয়নি')));
      return;
    }
    await _load();

  }

  Future<void> _addPayment(Map<String, dynamic> contract) async {
    final amount = TextEditingController(text: _monthly(contract).toStringAsFixed(0));
    final note = TextEditingController();
    DateTime paidDate = DateTime.now();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
      title: const Text('কিস্তি আদায়'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${contract['memberName']} • ${contract['productName']}'),
        const SizedBox(height: 12),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'আদায়কৃত টাকা (৳)')),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: ctx, initialDate: paidDate, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) refresh(() => paidDate = d); }, icon: const Icon(Icons.calendar_month), label: Text(_dateText(paidDate))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('আদায় সংরক্ষণ'))],
    )));
    final value = _n(amount.text);
    if (ok != true || value <= 0) return;
    if (value > _balance(contract)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বকেয়ার চেয়ে বেশি টাকা গ্রহণ করা যাবে না।')));
      return;
    }
    final response = await ApiService.addInstallmentPayment({
      'actorPhone': _actorPhone, 'contractId': contract['id'], 'amount': value.toString(),
      'paymentDate': DateFormat('yyyy-MM-dd').format(paidDate), 'paymentType': 'মাসিক কিস্তি',
      'note': note.text.trim(),
    });
    if (response['status'] != 'success') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'কিস্তি সংরক্ষণ হয়নি')));
      return;
    }
    await _load();

  }

  Future<void> _addExpense() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final category = TextEditingController(text: 'পণ্য/পরিবহন');
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('নতুন ব্যবসায়িক ব্যয়'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'ব্যয়ের বিবরণ')),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'টাকার পরিমাণ')),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'খাত')),
        TextField(controller: note, decoration: const InputDecoration(labelText: 'নোট (ঐচ্ছিক)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('সংরক্ষণ'))],
    ));
    final value = _n(amount.text);
    if (ok != true || title.text.trim().isEmpty || value <= 0) return;
    final response = await ApiService.saveInstallmentExpense({
      'actorPhone': _actorPhone, 'title': title.text.trim(), 'amount': value.toString(),
      'category': category.text.trim(), 'note': note.text.trim(),
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
    if (response['status'] != 'success') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'ব্যয় সংরক্ষণ হয়নি')));
      return;
    }
    await _load();
  }

  Future<void> _deleteExpense(Map<String,dynamic> expense) async {
    final response = await ApiService.deleteInstallmentExpense(expenseId: (expense['ExpenseID'] ?? '').toString(), actorPhone: _actorPhone);
    if (response['status'] != 'success') {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'ব্যয় মুছতে ব্যর্থ')));
      return;
    }
    await _load();
  }

  Future<void> _deleteContract(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('চুক্তি মুছে ফেলবেন?'),
      content: Text('${c['memberName']} - ${c['productName']} এবং এর সব আদায়ের রেকর্ড মুছে যাবে।'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন', style: TextStyle(color: Colors.red)))],
    ));
    if (ok != true) return;
    final response = await ApiService.deleteInstallmentContract(contractId: c['id'].toString(), actorPhone: _actorPhone);
    if (response['status'] != 'success') { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'মুছতে ব্যর্থ'))); return; }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final active = _contracts.where((c) => !_isComplete(c)).toList();
    final due = active.where((c) => _overdue(c) > 0).toList();
    final totalSale = _contracts.fold<num>(0, (s, c) => s + _sale(c));
    final totalPaid = _contracts.fold<num>(0, (s, c) => s + _n(c['downPayment']) + _paid(c));
    final totalProfit = _contracts.fold<num>(0, (s, c) => s + _profit(c));
    final filtered = _contracts.where((c) => '${c['memberName']} ${c['productName']} ${c['guarantorName']}'.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, elevation: 0,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('কিস্তিতে পণ্য', style: TextStyle(fontWeight: FontWeight.bold)), Text('মাসিক কিস্তি আদায় • Google Sheets-এ সংরক্ষিত', style: TextStyle(fontSize: 12, color: Colors.white70))]),
        actions: [IconButton(tooltip: 'রিফ্রেশ', onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : (_loadError != null && _contracts.isEmpty ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 42), const SizedBox(height: 12), Text('Backend সংযোগে সমস্যা\n$_loadError', textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('আবার চেষ্টা করুন'))]))) : RefreshIndicator(onRefresh: _load, child: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Container(color: navy, padding: const EdgeInsets.fromLTRB(16, 4, 16, 20), child: Column(children: [
          Row(children: [ _statCard('চলমান চুক্তি', '${active.length}টি', Colors.white), const SizedBox(width: 9), _statCard('বকেয়া সদস্য', '${due.length} জন', const Color(0xFFFFC15A)), const SizedBox(width: 9), _statCard('মোট মুনাফা', _m(totalProfit), const Color(0xFF64DCA9)) ]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _darkInfo('সর্বমোট আদায়', _m(totalPaid))), const SizedBox(width: 10), Expanded(child: _darkInfo('মোট বিক্রয়', _m(totalSale)))])
        ]))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 18, 16, 8), child: Row(children: [const Expanded(child: Text('কিস্তি ব্যবস্থাপনা', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: navy))), if (_isAdmin) FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: navy), onPressed: () => _openContractForm(), icon: const Icon(Icons.add), label: const Text('নতুন চুক্তি'))]))),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _tabs())),
        if (_tab == 0) ...[
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'সদস্য বা পণ্য খুঁজুন', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))))),
          _contractList(filtered),
        ] else if (_tab == 1) _collectionSliver()
        else if (_tab == 2) _contractList(due)
        else SliverToBoxAdapter(child: _report(totalSale, totalPaid, totalProfit, due.length)),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ]))),
      floatingActionButton: _isAdmin && _tab == 0 ? FloatingActionButton.extended(backgroundColor: gold, foregroundColor: navy, onPressed: () => _openContractForm(), icon: const Icon(Icons.add), label: const Text('সদস্য / পণ্য যোগ')) : null,
    );
  }

  Widget _statCard(String label, String value, Color valueColor) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(.10), borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 8), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: valueColor, fontSize: 17, fontWeight: FontWeight.bold))])));
  Widget _darkInfo(String label, String value) => Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(13)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]));

  Widget _tabs() {
    const labels = ['সব চুক্তি', 'আদায় তালিকা', 'বকেয়া', 'আয়-ব্যয়'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: List.generate(labels.length, (i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              decoration: BoxDecoration(color: _tab == i ? navy : Colors.transparent, borderRadius: BorderRadius.circular(10)),
              child: Text(labels[i], textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _tab == i ? Colors.white : Colors.blueGrey)),
            ),
          ),
        )),
      ),
    );
  }

  Widget _contractList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(35), child: Center(child: Text('এখনো কোনো তথ্য নেই'))));
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
      final c = list[i]; final total = _sale(c); final down = _n(c['downPayment']); final paid = _paid(c); final bal = _balance(c); final complete = _isComplete(c); final progress = total <= 0 ? 0.0 : ((down + paid) / total).clamp(0.0, 1.0);
      return Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 4), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _overdue(c) > 0 ? const Color(0xFFFFD0C8) : Colors.white), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.035), blurRadius: 12, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [CircleAvatar(backgroundColor: const Color(0xFFF0E6C9), foregroundColor: navy, child: Text((c['memberName'] ?? 'স').toString().characters.first)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['memberName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('${c['productName']} • ${c['months']} মাস', style: const TextStyle(color: Colors.blueGrey, fontSize: 12))])), _statusChip(complete ? 'সম্পন্ন' : _overdue(c) > 0 ? '${_overdue(c)} মাস বকেয়া' : 'নিয়মিত', complete ? Colors.blue : _overdue(c) > 0 ? Colors.red : Colors.green)]),
        const SizedBox(height: 15), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0xFFECEFF2), color: _overdue(c) > 0 ? Colors.red : gold)),
        const SizedBox(height: 8), Row(children: [Expanded(child: Text('${(progress * 100).round()}% আদায়', style: const TextStyle(color: Colors.blueGrey, fontSize: 12))), Text('বাকি ${_m(bal)}', style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 12))]),
        const SizedBox(height: 10), Wrap(spacing: 12, runSpacing: 5, children: [Text('জামিনদার: ${c['guarantorName']}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)), Text('কিস্তি: ${_m(_monthly(c))}/মাস', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)), Text('মুনাফা: ${_m(_profit(c))}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey))]),
        const Divider(height: 20), Row(children: [Expanded(child: Text('আদায় ${_m(down + paid)} / ${_m(total)}', style: const TextStyle(fontWeight: FontWeight.bold, color: navy, fontSize: 12))), if (_isAdmin && !complete) TextButton.icon(onPressed: () => _addPayment(c), icon: const Icon(Icons.payments_outlined, size: 17), label: const Text('কিস্তি আদায়')),
          if (_isAdmin) PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _openContractForm(existing: c); if (v == 'delete') _deleteContract(c); if (v == 'history') _showHistory(c); }, itemBuilder: (_) => const [PopupMenuItem(value: 'history', child: Text('আদায়ের ইতিহাস')), PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')), PopupMenuItem(value: 'delete', child: Text('ডিলেট'))]) else IconButton(onPressed: () => _showHistory(c), icon: const Icon(Icons.history))])
      ]));
    }, childCount: list.length));
  }

  Widget _collectionSliver() {
    final rows = <Map<String, dynamic>>[];
    for (final c in _contracts) {
      final dp = _n(c['downPayment']);
      if (dp > 0) rows.add({'member': c['memberName'], 'product': c['productName'], 'amount': dp, 'date': c['startDate'], 'note': 'ডাউনপেমেন্ট'});
      for (final p in (c['payments'] as List? ?? [])) {
        rows.add({'member': c['memberName'], 'product': c['productName'], 'amount': _n(p['amount']), 'date': p['date'], 'note': p['note'] ?? 'মাসিক কিস্তি'});
      }
    }
    rows.sort((a,b) => _date(b['date']).compareTo(_date(a['date'])));
    if (rows.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(35), child: Center(child: Text('এখনো কোনো আদায় হয়নি'))));
    final grouped = <String, List<Map<String,dynamic>>>{};
    for (final row in rows) { final key = DateFormat('yyyy-MM').format(_date(row['date'])); grouped.putIfAbsent(key, () => []).add(row); }
    final keys = grouped.keys.toList()..sort((a,b) => b.compareTo(a));
    return SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
      final key = keys[i]; final items = grouped[key]!; final sum = items.fold<num>(0, (v,r) => v + _n(r['amount']));
      final date = DateTime.tryParse('$key-01') ?? DateTime.now();
      return Container(margin: const EdgeInsets.fromLTRB(16, 8, 16, 4), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(DateFormat('MMMM yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, color: navy))), Text(_m(sum), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15965B)))]),
        const Divider(),
        ...items.map((r) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const CircleAvatar(backgroundColor: Color(0xFFE7F4EC), child: Icon(Icons.payments, color: Color(0xFF15965B), size: 18)), title: Text('${r['member']} • ${r['product']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), subtitle: Text('${r['note']} • ${_dateText(r['date'])}'), trailing: Text(_m(_n(r['amount'])), style: const TextStyle(fontWeight: FontWeight.bold, color: navy))))
      ]));
    }, childCount: keys.length));
  }

  Widget _statusChip(String text, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(30)), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)));

  Widget _report(num sale, num collected, num profit, int overdue) {
    final productCost = _contracts.fold<num>(0, (s,c) => s + _n(c['costPrice']));
    final otherExpenses = _expenses.fold<num>(0, (s,e) => s + _n(e['Amount']));
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      if (_isAdmin) Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _addExpense, icon: const Icon(Icons.add), label: const Text('ব্যয় যোগ করুন'))),
      _reportRow('মোট পণ্য বিক্রয়', _m(sale)),
      _reportRow('ডাউনপেমেন্ট ও কিস্তি আদায়', _m(collected)),
      _reportRow('অবশিষ্ট পাওনা', _m(sale - collected)),
      _reportRow('মোট সম্ভাব্য মুনাফা', _m(profit)),
      _reportRow('বকেয়া চুক্তি', '$overdue টি'),
      _reportRow('পণ্য ক্রয়মূল্য', _m(productCost)),
      _reportRow('অন্যান্য ব্যবসায়িক ব্যয়', _m(otherExpenses)),
      _reportRow('মোট ব্যয়', _m(productCost + otherExpenses)),
      _reportRow('ব্যবসার সম্ভাব্য নিট মুনাফা', _m(profit - otherExpenses)),
      const SizedBox(height: 8),
      const Align(alignment: Alignment.centerLeft, child: Text('ব্যয়ের তালিকা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      if (_expenses.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('এখনো কোনো ব্যয় যোগ করা হয়নি')),
      ..._expenses.reversed.map((e) => Card(child: ListTile(title: Text((e['Title'] ?? '').toString()), subtitle: Text('${e['Category'] ?? ''} • ${e['ExpenseDate'] ?? ''}'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(_m(_n(e['Amount']))), if (_isAdmin) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteExpense(Map<String,dynamic>.from(e))) ])))),
    ]));
  }
  Widget _reportRow(String a, String b) => Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)), child: Row(children: [Expanded(child: Text(a, style: const TextStyle(color: Colors.blueGrey))), Text(b, style: const TextStyle(color: navy, fontWeight: FontWeight.bold))]));

  Future<void> _deletePayment(Map<String, dynamic> contract, Map payment) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('আদায়ের রেকর্ড মুছবেন?'), content: const Text('এই পেমেন্টটি স্থায়ীভাবে মুছে যাবে।'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন'))]));
    if (yes != true) return;
    final response = await ApiService.deleteInstallmentPayment(paymentId: payment['id'].toString(), actorPhone: _actorPhone);
    if (response['status'] != 'success') { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'পেমেন্ট মুছতে ব্যর্থ'))); return; }
    await _load();

  }

  void _showHistory(Map<String, dynamic> c) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (sheetContext) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${c['memberName']} - আদায়ের ইতিহাস', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 12),
    if ((c['payments'] as List? ?? []).isEmpty) const Text('এখনো কোনো কিস্তি আদায় হয়নি') else ...((c['payments'] as List).reversed.map((p) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.check_circle, color: Colors.green), title: Text(_m(_n(p['amount']))), subtitle: Text('${_dateText(p['date'])} ${p['note'] ?? ''}'), trailing: _isAdmin ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { Navigator.pop(sheetContext); _deletePayment(c, Map<String,dynamic>.from(p)); }) : null))),
    const SizedBox(height: 10)
  ]))));
}

class _ContractDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final NumberFormat money;
  final List<Map<String,dynamic>> linkedMembers;
  const _ContractDialog({this.existing, required this.money, required this.linkedMembers});
  @override
  State<_ContractDialog> createState() => _ContractDialogState();
}

class _ContractDialogState extends State<_ContractDialog> {
  final _form = GlobalKey<FormState>();
  String memberType = 'external';
  String linkedMemberPhone = '';
  late final TextEditingController member, phone, address, guarantor, guarantorPhone, product, months, cost, sale, down, start;
  @override
  void initState() {
    super.initState(); final e = widget.existing ?? {};
    memberType = (e['memberType'] ?? 'external').toString(); linkedMemberPhone = (e['memberPhone'] ?? '').toString();
    member = TextEditingController(text: e['memberName'] ?? ''); phone = TextEditingController(text: e['memberPhone'] ?? ''); address = TextEditingController(text: e['address'] ?? '');
    guarantor = TextEditingController(text: e['guarantorName'] ?? ''); guarantorPhone = TextEditingController(text: e['guarantorPhone'] ?? ''); product = TextEditingController(text: e['productName'] ?? '');
    months = TextEditingController(text: e['months']?.toString() ?? '12'); cost = TextEditingController(text: e['costPrice']?.toString() ?? ''); sale = TextEditingController(text: e['salePrice']?.toString() ?? ''); down = TextEditingController(text: e['downPayment']?.toString() ?? ''); start = TextEditingController(text: e['startDate']?.toString() ?? DateTime.now().toIso8601String().substring(0,10));
  }
  @override
  void dispose() { for (final c in [member, phone, address, guarantor, guarantorPhone, product, months, cost, sale, down, start]) { c.dispose(); } super.dispose(); }
  InputDecoration _dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: const Color(0xFFF6F7F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
  String? _required(String? v) => v == null || v.trim().isEmpty ? 'এই তথ্যটি প্রয়োজন' : null;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.existing == null ? 'নতুন কিস্তি চুক্তি' : 'চুক্তি সম্পাদনা'),
    content: SizedBox(width: 440, child: Form(key: _form, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Align(alignment: Alignment.centerLeft, child: Text('সদস্যের প্রোফাইল', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF142F52)))), const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: memberType, decoration: _dec('ক্রেতার ধরন', Icons.people), items: const [DropdownMenuItem(value: 'member', child: Text('বিদ্যমান সমিতির সদস্য')), DropdownMenuItem(value: 'external', child: Text('বাইরের নতুন ক্রেতা'))], onChanged: (v) => setState(() { memberType = v ?? 'external'; if (memberType == 'external') linkedMemberPhone = ''; })), const SizedBox(height: 8),
      if (memberType == 'member' && widget.linkedMembers.isNotEmpty) DropdownButtonFormField<String>(value: widget.linkedMembers.any((m) => (m['phone'] ?? '').toString() == linkedMemberPhone) ? linkedMemberPhone : null, decoration: _dec('সমিতির সদস্য নির্বাচন', Icons.person_search), items: widget.linkedMembers.map((m) => DropdownMenuItem(value: (m['phone'] ?? '').toString(), child: Text('${m['name']} (${m['phone']})', overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) { final m = widget.linkedMembers.firstWhere((x) => (x['phone'] ?? '').toString() == v); setState(() { linkedMemberPhone = v ?? ''; member.text = (m['name'] ?? '').toString(); phone.text = (m['phone'] ?? '').toString(); }); }), const SizedBox(height: 8),
      TextFormField(controller: member, validator: _required, decoration: _dec('সদস্যের পূর্ণ নাম *', Icons.person)), const SizedBox(height: 8),
      TextFormField(controller: phone, keyboardType: TextInputType.phone, validator: _required, decoration: _dec('মোবাইল নম্বর *', Icons.phone)), const SizedBox(height: 8),
      TextFormField(controller: address, validator: _required, maxLines: 2, decoration: _dec('ঠিকানা *', Icons.location_on)), const SizedBox(height: 14),
      Align(alignment: Alignment.centerLeft, child: Text('জামিনদারের তথ্য (বাধ্যতামূলক)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF142F52)))), const SizedBox(height: 8),
      TextFormField(controller: guarantor, validator: _required, decoration: _dec('জামিনদারের নাম *', Icons.verified_user)), const SizedBox(height: 8),
      TextFormField(controller: guarantorPhone, keyboardType: TextInputType.phone, validator: _required, decoration: _dec('জামিনদারের মোবাইল *', Icons.phone_android)), const SizedBox(height: 14),
      Align(alignment: Alignment.centerLeft, child: Text('পণ্যের ও কিস্তির বিবরণ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF142F52)))), const SizedBox(height: 8),
      TextFormField(controller: product, validator: _required, decoration: _dec('পণ্যের নাম *', Icons.inventory_2)), const SizedBox(height: 8),
      TextFormField(controller: months, keyboardType: TextInputType.number, validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'মেয়াদ মাসে লিখুন' : null, decoration: _dec('মেয়াদ (মাস) *', Icons.calendar_month)), const SizedBox(height: 8),
      TextFormField(controller: cost, keyboardType: TextInputType.number, validator: (v) => (num.tryParse(v ?? '') ?? -1) < 0 ? 'সঠিক ক্রয়মূল্য লিখুন' : null, decoration: _dec('পণ্যের ক্রয়মূল্য / ব্যয় (৳) *', Icons.shopping_cart)), const SizedBox(height: 8),
      TextFormField(controller: sale, keyboardType: TextInputType.number, validator: (v) => (num.tryParse(v ?? '') ?? 0) <= 0 ? 'সঠিক বিক্রয়মূল্য লিখুন' : null, decoration: _dec('কিস্তিতে মোট বিক্রয়মূল্য (৳) *', Icons.sell)), const SizedBox(height: 8),
      TextFormField(controller: down, keyboardType: TextInputType.number, decoration: _dec('ডাউনপেমেন্ট (ঐচ্ছিক)', Icons.payments)), const SizedBox(height: 8),
      TextFormField(controller: start, readOnly: true, decoration: _dec('কিস্তি শুরুর তারিখ', Icons.event), onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.tryParse(start.text) ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100)); if (d != null) setState(() => start.text = d.toIso8601String().substring(0,10)); }),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')), FilledButton(onPressed: () { if (!_form.currentState!.validate()) return; final cp = num.tryParse(cost.text) ?? 0, sp = num.tryParse(sale.text) ?? 0, dp = num.tryParse(down.text.isEmpty ? '0' : down.text) ?? 0, m = int.tryParse(months.text) ?? 0; if (sp < cp || dp > sp) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বিক্রয়মূল্য ক্রয়মূল্যের কম হতে পারবে না এবং ডাউনপেমেন্ট বিক্রয়মূল্যের বেশি নয়।'))); return; } Navigator.pop(context, {'memberType': memberType, 'linkedMemberPhone': linkedMemberPhone, 'memberName': member.text.trim(), 'memberPhone': phone.text.trim(), 'address': address.text.trim(), 'guarantorName': guarantor.text.trim(), 'guarantorPhone': guarantorPhone.text.trim(), 'productName': product.text.trim(), 'months': m, 'costPrice': cp, 'salePrice': sp, 'downPayment': dp, 'startDate': start.text}); }, child: const Text('সংরক্ষণ'))],
  );
}
