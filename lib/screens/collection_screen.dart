import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _isAdmin = false;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _members = [];
  List<dynamic> _transactions = [];
  String? _selectedMember;
  final TextEditingController _amount = TextEditingController();

  static const Color _purple = Color(0xFF6817D8);
  static const Color _green = Color(0xFF159B61);

  String _monthKey(DateTime date) => DateFormat('yyyy-MM').format(date);
  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  String get _monthTitle {
    const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    return '${months[_month.month - 1]} ${_month.year}';
  }
  double _number(dynamic value) =>
      double.tryParse((value ?? '0').toString().replaceAll(',', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final results = await Future.wait([
        ApiService.getAllMembers(),
        ApiService.getTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _isAdmin = (prefs.getString('userRole') ?? '').trim().toLowerCase() == 'admin';
        _members = results[0] is List ? results[0] as List : [];
        _transactions = results[1] is List ? results[1] as List : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _monthDeposits => _transactions.where((tx) {
    if (tx is! Map) return false;
    final date = (tx['Date'] ?? '').toString();
    final type = (tx['Type'] ?? '').toString().trim();
    final status = (tx['Status'] ?? 'Paid').toString().trim().toLowerCase();
    return date.startsWith(_monthKey(_month)) &&
        type == 'জমা' && (status == 'paid' || status == 'পরিশোধিত');
  }).toList().reversed.toList();

  bool _hasPaid(String memberName) => _monthDeposits.any((tx) =>
      (tx['MemberName'] ?? '').toString().trim().toLowerCase() ==
      memberName.trim().toLowerCase());

  double get _monthTotal =>
      _monthDeposits.fold<double>(0, (sum, tx) => sum + _number(tx['Amount']));

  Future<void> _chooseMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'যে মাসের জমা দেখতে চান নির্বাচন করুন',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _month = DateTime(picked.year, picked.month);
      _selectedDate = DateTime(picked.year, picked.month, 1);
      _selectedMember = null;
      _amount.clear();
    });
  }

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
      _selectedDate = DateTime(_month.year, _month.month,
          _selectedDate.day.clamp(1, lastDay).toInt());
      _selectedMember = null;
      _amount.clear();
    });
  }

  Future<void> _saveDeposit() async {
    if (!_isAdmin) return;
    final member = _selectedMember;
    final amount = _amount.text.trim();
    if (member == null || amount.isEmpty || _number(amount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সদস্য নির্বাচন ও সঠিক জমার পরিমাণ লিখুন')),
      );
      return;
    }
    if (_hasPaid(member)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$member এই মাসে ইতিমধ্যে জমা দিয়েছেন')),
      );
      return;
    }
    if (mounted) setState(() => _saving = true);
    try {
      // Save only after a fresh server read, preventing duplicate monthly deposits.
      ApiService.clearCache();
      final latest = await ApiService.getTransactions();
      if (latest is! List) {
        throw Exception('লেনদেন যাচাই করা যায়নি। আবার চেষ্টা করুন।');
      }
      final duplicate = latest.any((tx) {
        if (tx is! Map) return false;
        final txDate = (tx['Date'] ?? '').toString();
        final txType = (tx['Type'] ?? '').toString().trim();
        final txStatus = (tx['Status'] ?? 'Paid').toString().trim().toLowerCase();
        final txName = (tx['MemberName'] ?? '').toString().trim().toLowerCase();
        return txDate.startsWith(_monthKey(_month)) &&
            txType == 'জমা' &&
            (txStatus == 'paid' || txStatus == 'পরিশোধিত') &&
            txName == member.trim().toLowerCase();
      });
      if (duplicate) {
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$member এই মাসে ইতিমধ্যে জমা দিয়েছেন')),
          );
        }
        return;
      }
      final response = await ApiService.addTransaction(
        type: 'জমা',
        amount: amount,
        note: 'মাসিক জমা',
        memberName: member,
        status: 'Paid',
        date: _dateKey(_selectedDate),
        paymentMethod: 'HAND CASH',
      );
      final message = (response['message'] ?? '').toString();
      if (response['status'] == 'success' ||
          message == 'Success' || message == 'Saved' || message.contains('302')) {
        _amount.clear();
        await _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('জমা সফলভাবে সংরক্ষণ হয়েছে'), backgroundColor: _green),
          );
        }
      } else {
        throw Exception(message.isEmpty ? 'জমা সংরক্ষণ করা যায়নি' : message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = <Widget>[];
    const labels = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];
    for (final label in labels) {
      cells.add(Center(child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black54))));
    }
    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= days; day++) {
      final date = DateTime(_month.year, _month.month, day);
      final selected = _dateKey(date) == _dateKey(_selectedDate);
      final isToday = _dateKey(date) == _dateKey(DateTime.now());
      cells.add(InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? _purple : (isToday ? _purple.withOpacity(.09) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: isToday && !selected ? Border.all(color: _purple.withOpacity(.5)) : null,
          ),
          child: Center(child: Text('$day', style: TextStyle(fontWeight: selected || isToday ? FontWeight.w800 : FontWeight.w500, color: selected ? Colors.white : const Color(0xFF263247)))),
        ),
      ));
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(child: InkWell(onTap: _chooseMonth, child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_monthTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF263247))),
            const SizedBox(width: 6), const Icon(Icons.calendar_month, size: 18, color: _purple),
          ])))),
          IconButton(onPressed: () => _moveMonth(1), icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        GridView.count(crossAxisCount: 7, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: cells),
        Align(alignment: Alignment.centerLeft, child: Text('নির্বাচিত তারিখ: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deposits = _monthDeposits;
    final names = _members.whereType<Map>()
        .map((m) => (m['Name'] ?? '').toString().trim())
        .where((n) => n.isNotEmpty).toSet().toList()..sort();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: AppBar(
        title: const Text('জমা ব্যবস্থাপনা', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: _purple,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_isAdmin
              ? const Center(child: Text('শুধুমাত্র Admin জমা দিতে পারবেন'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6817D8), Color(0xFF3422C8)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _purple.withOpacity(.2), blurRadius: 16, offset: const Offset(0, 7))],
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('নির্বাচিত মাসের মোট জমা', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 7),
                          Text('৳ ${_monthTotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('${deposits.length} জন সদস্য জমা দিয়েছেন', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ])),
                        const Icon(Icons.savings_rounded, color: Color(0xFFFFD36A), size: 48),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    _calendar(),
                    const SizedBox(height: 18),
                    const Text('সদস্যের জমা গ্রহণ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF263247))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                      child: Column(children: [
                        DropdownButtonFormField<String>(
                          value: _selectedMember,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'সদস্য নির্বাচন করুন', border: OutlineInputBorder()),
                          items: names.map((name) => DropdownMenuItem(value: name, child: Text(_hasPaid(name) ? '$name — জমা সম্পন্ন' : name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) => setState(() => _selectedMember = value),
                        ),
                        if (_selectedMember != null && _hasPaid(_selectedMember!))
                          const Padding(padding: EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: Text('এই সদস্যের এই মাসের জমা ইতিমধ্যে সম্পন্ন হয়েছে। দ্বিতীয় জমা গ্রহণ করা যাবে না।', style: TextStyle(color: Colors.red, fontSize: 12)))),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'জমার পরিমাণ (৳)', prefixIcon: Icon(Icons.payments_outlined), border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(width: double.infinity, child: FilledButton.icon(
                          onPressed: _saving || _selectedMember == null || _hasPaid(_selectedMember!) ? null : _saveDeposit,
                          style: FilledButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                          label: Text(_saving ? 'সংরক্ষণ হচ্ছে...' : 'জমা সংরক্ষণ করুন'),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      const Expanded(child: Text('এই মাসের জমার তালিকা', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF263247)))),
                      Text('${deposits.length}টি', style: const TextStyle(color: _purple, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 9),
                    if (deposits.isEmpty)
                      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('এই মাসে কোনো জমা পাওয়া যায়নি')))
                    else
                      ...deposits.map((tx) {
                        final amount = _number(tx['Amount']);
                        final date = (tx['Date'] ?? '').toString().split(' ').first;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                          child: Row(children: [
                            const CircleAvatar(backgroundColor: Color(0xFFE7F7EF), child: Icon(Icons.person_rounded, color: _green)),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text((tx['MemberName'] ?? 'সদস্য').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(date, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ])),
                            Text('৳ ${amount.toStringAsFixed(0)}', style: const TextStyle(color: _green, fontWeight: FontWeight.w900)),
                          ]),
                        );
                      }),
                    const SizedBox(height: 12),
                  ]),
                ),
    );
  }
}
