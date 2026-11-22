import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/loss_project_service.dart';

class LossProjectScreen extends StatefulWidget {
  const LossProjectScreen({super.key});
  @override
  State<LossProjectScreen> createState() => _LossProjectScreenState();
}

class _LossProjectScreenState extends State<LossProjectScreen> {
  static const navy = Color(0xFF142F52);
  static const gold = Color(0xFFD0A522);
  static const canvas = Color(0xFFF5F3EE);
  final money = NumberFormat('#,##0.##', 'en_US');
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  bool isAdmin = false;
  int tab = 0;
  String query = '';
  int filter = 0;
  int reportMode = 0;
  String m(double v) => '৳ ${money.format(v)}';
  double n(dynamic v) => LossProjectService.number(v);
  double get totalLoss => rows.fold<double>(0, (s, e) => s + n(e['totalLoss']));
  double get recovered => rows.fold<double>(0, (s, e) => s + n(e['recoveredAmount']));
  double get net => (totalLoss - recovered).clamp(0, double.infinity).toDouble();
  double get potential => rows.fold<double>(0, (s, e) => s + n(e['recoverableAmount']));
  double get progress => totalLoss <= 0 ? 0 : (recovered / totalLoss).clamp(0, 1).toDouble();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = await LossProjectService.load();
    if (!mounted) return;
    setState(() { rows = loaded; isAdmin = (prefs.getString('userRole') ?? '').toLowerCase() == 'admin'; loading = false; });
  }

  Future<void> _save(Map<String, dynamic> row) async {
    final index = rows.indexWhere((e) => e['id'] == row['id']);
    setState(() { if (index < 0) { rows.insert(0, row); } else { rows[index] = row; } });
    await LossProjectService.save(rows);
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('ক্ষতির রেকর্ড মুছবেন?'), content: const Text('এই রেকর্ডটি ফোনের লোকাল ডেটা থেকে মুছে যাবে।'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('বাতিল')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('মুছুন'))]));
    if (yes != true) return;
    setState(() => rows.removeWhere((e) => e['id'] == row['id']));
    await LossProjectService.save(rows);
  }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => _LossForm(existing: existing)));
    if (result != null) await _save(result);
  }

  List<Map<String, dynamic>> get filtered {
    return rows.where((r) {
      final text = '${r['projectName']} ${r['category']} ${r['cause']} ${r['responsiblePerson']}'.toLowerCase();
      if (query.isNotEmpty && !text.contains(query.toLowerCase())) return false;
      if (filter == 1 && (r['status'] ?? '') == 'বন্ধ') return false;
      if (filter == 2 && (r['status'] ?? '') != 'বন্ধ') return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRows = rows.where((r) => (r['lossDate'] ?? '').toString().startsWith(DateFormat('yyyy-MM').format(now))).toList();
    final monthLoss = monthRows.fold<double>(0, (s, r) => s + n(r['totalLoss']));
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('লস প্রজেক্ট', style: TextStyle(fontWeight: FontWeight.bold)), Text('ব্যবসায়িক ক্ষতির পূর্ণাঙ্গ ব্যবস্থাপনা', style: TextStyle(fontSize: 11, color: Colors.white70))]), actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
      body: loading ? const Center(child: CircularProgressIndicator()) : IndexedStack(index: tab, children: [_dashboard(monthLoss), _records(), _reports()]),
      bottomNavigationBar: NavigationBar(backgroundColor: Colors.white, selectedIndex: tab, onDestinationSelected: (v) => setState(() => tab = v), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'ড্যাশবোর্ড'), NavigationDestination(icon: Icon(Icons.list_alt), label: 'ক্ষতি তালিকা'), NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'রিপোর্ট')]),
      floatingActionButton: isAdmin ? FloatingActionButton.extended(backgroundColor: navy, foregroundColor: Colors.white, onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('নতুন ক্ষতি যোগ')) : null,
    );
  }

  Widget _dashboard(double monthLoss) => RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navy, Color(0xFF315D89)]), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.trending_down, color: Colors.white, size: 28), const SizedBox(height: 10), const Text('এই মাসে মোট ক্ষতি', style: TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text(m(monthLoss), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text('${rows.length}টি ক্ষতির রেকর্ড', style: const TextStyle(color: Colors.white70, fontSize: 12))])),
    const SizedBox(height: 12), Row(children: [Expanded(child: _metric('মোট ক্ষতি', totalLoss, const Color(0xFFD84B4B), Icons.south_east)), const SizedBox(width: 8), Expanded(child: _metric('উদ্ধারকৃত', recovered, const Color(0xFF239B69), Icons.savings_outlined)), const SizedBox(width: 8), Expanded(child: _metric('নিট ক্ষতি', net, const Color(0xFF7453B6), Icons.balance))]),
    const SizedBox(height: 18), _panel(title: 'খাতভিত্তিক ক্ষতি', child: rows.isEmpty ? const Text('এখনো কোনো ক্ষতির রেকর্ড নেই') : SizedBox(height: 190, child: Row(children: [Expanded(child: PieChart(PieChartData(centerSpaceRadius: 42, sectionsSpace: 3, sections: _categorySections()))), const SizedBox(width: 12), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: _categoryLegend()))]))),
    const SizedBox(height: 14), _panel(title: 'ক্ষতি উদ্ধারের অগ্রগতি', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('উদ্ধার অগ্রগতি'), Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF239B69)))]), const SizedBox(height: 9), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: progress, minHeight: 10, color: const Color(0xFF239B69), backgroundColor: const Color(0xFFE5E9ED))), const SizedBox(height: 8), Text('${m(recovered)} / ${m(totalLoss)} উদ্ধার হয়েছে'), Text('উদ্ধার সম্ভাবনা: ${m(potential)}', style: const TextStyle(color: navy, fontWeight: FontWeight.w600))])),
    const SizedBox(height: 16), Row(children: [const Expanded(child: Text('সাম্প্রতিক ক্ষতির রেকর্ড', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: navy))), TextButton(onPressed: () => setState(() => tab = 1), child: const Text('সব দেখুন'))]),
    if (rows.isEmpty) _empty() else ...rows.take(4).map(_recordCard),
  ]));

  List<PieChartSectionData> _categorySections() {
    final totals = <String, double>{};
    for (final r in rows) { final key = (r['category'] ?? 'অন্যান্য').toString(); totals[key] = (totals[key] ?? 0) + n(r['totalLoss']); }
    const colors = [Color(0xFF315D89), Color(0xFFE59A38), Color(0xFF239B69), Color(0xFF845EC2), Color(0xFFD84B4B)];
    return totals.entries.toList().asMap().entries.map((e) => PieChartSectionData(value: e.value.value, color: colors[e.key % colors.length], radius: 24, title: '')).toList();
  }
  List<Widget> _categoryLegend() {
    final totals = <String, double>{}; for (final r in rows) { final k = (r['category'] ?? 'অন্যান্য').toString(); totals[k] = (totals[k] ?? 0) + n(r['totalLoss']); }
    const colors = [Color(0xFF315D89), Color(0xFFE59A38), Color(0xFF239B69), Color(0xFF845EC2), Color(0xFFD84B4B)];
    return totals.entries.take(5).toList().asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)), const SizedBox(width: 6), Expanded(child: Text(e.value.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))), Text(m(e.value.value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]))).toList();
  }

  Widget _records() => Column(children: [Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), child: TextField(onChanged: (v) => setState(() => query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: 'প্রজেক্ট, খাত বা কারণ খুঁজুন', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)))), Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5), child: SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('সব')), ButtonSegment(value: 1, label: Text('চলমান')), ButtonSegment(value: 2, label: Text('বন্ধ'))], selected: {filter}, onSelectionChanged: (v) => setState(() => filter = v.first))), Expanded(child: filtered.isEmpty ? _empty() : ListView(padding: const EdgeInsets.all(14), children: filtered.map(_recordCard).toList()))]);

  Widget _reports() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      final date = DateTime.tryParse((row['lossDate'] ?? '').toString());
      final key = switch (reportMode) {
        0 => date == null ? 'তারিখ নেই' : DateFormat('yyyy-MM').format(date),
        1 => date == null ? 'বছর নেই' : DateFormat('yyyy').format(date),
        2 => (row['category'] ?? 'অন্যান্য').toString(),
        _ => (row['projectName'] ?? 'অন্যান্য').toString(),
      };
      grouped.putIfAbsent(key, () => []).add(row);
    }
    final entries = grouped.entries.toList();
    if (reportMode < 2) entries.sort((a, b) => b.key.compareTo(a.key));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: navy, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ক্ষতি ও উদ্ধার সারসংক্ষেপ', style: TextStyle(color: Colors.white70)), const SizedBox(height: 10), _reportLine('মোট ক্ষতি', totalLoss), _reportLine('উদ্ধারকৃত অর্থ', recovered), _reportLine('নিট ক্ষতি', net)])),
      const SizedBox(height: 16),
      SegmentedButton<int>(segments: const [ButtonSegment(value: 0, label: Text('মাসিক')), ButtonSegment(value: 1, label: Text('বার্ষিক')), ButtonSegment(value: 2, label: Text('খাত')), ButtonSegment(value: 3, label: Text('প্রজেক্ট'))], selected: {reportMode}, onSelectionChanged: (v) => setState(() => reportMode = v.first)),
      const SizedBox(height: 14),
      Text(switch (reportMode) { 0 => 'মাসভিত্তিক ক্ষতির রিপোর্ট', 1 => 'বছরভিত্তিক ক্ষতির রিপোর্ট', 2 => 'খাতভিত্তিক বিশ্লেষণ', _ => 'প্রজেক্টভিত্তিক বিশ্লেষণ' }, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (entries.isEmpty) _empty() else ...entries.map((entry) {
        final loss = entry.value.fold<double>(0, (sum, row) => sum + n(row['totalLoss']));
        final rec = entry.value.fold<double>(0, (sum, row) => sum + n(row['recoveredAmount']));
        final netLoss = (loss - rec).clamp(0, double.infinity).toDouble();
        final ratio = totalLoss == 0 ? 0.0 : (loss / totalLoss).clamp(0, 1).toDouble();
        return _panel(title: entry.key, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('মোট ক্ষতি: ${m(loss)}')), Text('${(ratio * 100).round()}%', style: const TextStyle(color: navy, fontWeight: FontWeight.bold))]), const SizedBox(height: 7), ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: ratio, color: const Color(0xFFD84B4B), backgroundColor: Colors.black12, minHeight: 7)), const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('উদ্ধার: ${m(rec)}', style: const TextStyle(color: Color(0xFF239B69), fontSize: 12)), Text('নিট: ${m(netLoss)}', style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 12))])]));
      }),
      const SizedBox(height: 12), const Text('নোট: রিপোর্টের তথ্য এই ফোনে সংরক্ষিত ক্ষতির রেকর্ড থেকে তৈরি।', style: TextStyle(color: Colors.grey, fontSize: 12)),
    ]);
  }

  Widget _reportLine(String label, double value) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))), Text(m(value), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]));
  Widget _metric(String label, double value, Color color, IconData icon) => Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(.2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 7), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)), const SizedBox(height: 3), FittedBox(child: Text(m(value), style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)))]));
  Widget _panel({required String title, required Widget child}) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: navy, fontSize: 15)), const SizedBox(height: 13), child]));
  Widget _recordCard(Map<String, dynamic> row) { final netLoss = (n(row['totalLoss']) - n(row['recoveredAmount'])).clamp(0, double.infinity).toDouble(); final status = (row['status'] ?? 'চলমান').toString(); final color = status == 'বন্ধ' ? Colors.grey : status == 'সমাধানাধীন' ? Colors.orange : Colors.red; return Card(color: Colors.white, elevation: 0, margin: const EdgeInsets.only(bottom: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(onTap: () => _showDetails(row), leading: CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(Icons.inventory_2_outlined, color: color)), title: Text((row['projectName'] ?? 'ক্ষতির রেকর্ড').toString(), style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${row['lossDate'] ?? ''} • ${row['category'] ?? ''}\nকারণ: ${row['cause'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis), isThreeLine: true, trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(m(netLoss), style: const TextStyle(color: navy, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))) ]))); }
  void _showDetails(Map<String, dynamic> row) { showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => SafeArea(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text((row['projectName'] ?? '').toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: navy)), const SizedBox(height: 12), _detail('খাত', row['category']), _detail('তারিখ', row['lossDate']), _detail('কারণ', row['cause']), _detail('মোট ক্ষতি', m(n(row['totalLoss']))), _detail('উদ্ধারকৃত', m(n(row['recoveredAmount']))), _detail('নিট ক্ষতি', m((n(row['totalLoss']) - n(row['recoveredAmount'])).clamp(0, double.infinity).toDouble())), _detail('উদ্ধার সম্ভাব্য', m(n(row['recoverableAmount']))), _detail('দায়িত্বপ্রাপ্ত', row['responsiblePerson']), _detail('পরিকল্পনা', row['mitigationPlan']), _detail('স্ট্যাটাস', row['status']), if ((row['recoveryHistory'] as List? ?? []).isNotEmpty) ...[(const Padding(padding: EdgeInsets.only(top: 8, bottom: 5), child: Text('উদ্ধারের ইতিহাস', style: TextStyle(fontWeight: FontWeight.bold, color: navy)))), ...((row['recoveryHistory'] as List).map((h) => _detail('${h['date']}', m(n(h['amount'])))))], if ((row['evidence'] as List? ?? []).isNotEmpty) _detail('প্রমাণপত্র', (row['evidence'] as List).map((e) => e.toString().split('/').last).join(', ')), if (isAdmin) Row(mainAxisAlignment: MainAxisAlignment.end, children: [TextButton.icon(onPressed: () { Navigator.pop(c); _openForm(existing: row); }, icon: const Icon(Icons.edit), label: const Text('সম্পাদনা')), TextButton.icon(onPressed: () { Navigator.pop(c); _delete(row); }, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('মুছুন', style: TextStyle(color: Colors.red)))])])))); }
  Widget _detail(String label, dynamic value) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 115, child: Text(label, style: const TextStyle(color: Colors.black54))), Expanded(child: Text((value ?? '—').toString(), style: const TextStyle(fontWeight: FontWeight.w600)))]));
  Widget _empty() => const Padding(padding: EdgeInsets.all(35), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inventory_2_outlined, size: 42, color: Colors.grey), SizedBox(height: 9), Text('কোনো ক্ষতির রেকর্ড নেই')])));
}

class _LossForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const _LossForm({this.existing});
  @override
  State<_LossForm> createState() => _LossFormState();
}
class _LossFormState extends State<_LossForm> {
  static const navy = Color(0xFF142F52);
  late final TextEditingController project, cause, total, recovered, recoverable, person, plan;
  String category = 'পণ্য বিক্রয়', status = 'চলমান', date = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<String> evidence = [];
  bool saving = false;
  @override
  void initState() { super.initState(); final e = widget.existing ?? {}; project = TextEditingController(text: e['projectName'] ?? ''); cause = TextEditingController(text: e['cause'] ?? ''); total = TextEditingController(text: e['totalLoss']?.toString() ?? ''); recovered = TextEditingController(text: e['recoveredAmount']?.toString() ?? '0'); recoverable = TextEditingController(text: e['recoverableAmount']?.toString() ?? '0'); person = TextEditingController(text: e['responsiblePerson'] ?? ''); plan = TextEditingController(text: e['mitigationPlan'] ?? ''); category = (e['category'] ?? category).toString(); status = (e['status'] ?? status).toString(); date = (e['lossDate'] ?? date).toString(); evidence = List<String>.from(e['evidence'] ?? []); }
  @override
  void dispose() { project.dispose(); cause.dispose(); total.dispose(); recovered.dispose(); recoverable.dispose(); person.dispose(); plan.dispose(); super.dispose(); }
  Future<void> _pickImage() async { final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1600); if (f != null) await _copyEvidence(f.path); }
  Future<void> _pickFile() async { final f = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png'], withData: false); final path = f?.files.single.path; if (path != null) await _copyEvidence(path); }
  Future<void> _copyEvidence(String source) async { final dir = await getApplicationDocumentsDirectory(); final folder = Directory('${dir.path}/loss_evidence'); await folder.create(recursive: true); final ext = source.contains('.') ? source.substring(source.lastIndexOf('.')) : '.bin'; final dest = '${folder.path}/${DateTime.now().microsecondsSinceEpoch}$ext'; await File(source).copy(dest); if (mounted) setState(() => evidence.add(dest)); }
  Future<void> _submit() async { final t = double.tryParse(total.text) ?? 0, r = double.tryParse(recovered.text) ?? 0; if (project.text.trim().isEmpty || cause.text.trim().isEmpty || t <= 0 || r < 0 || r > t) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('প্রজেক্ট, কারণ ও সঠিক ক্ষতির পরিমাণ দিন; উদ্ধারকৃত অর্থ মোট ক্ষতির বেশি হতে পারবে না।'))); return; } setState(() => saving = true); final oldRecovered = double.tryParse((widget.existing?['recoveredAmount'] ?? '0').toString()) ?? 0; final history = List<Map<String,dynamic>>.from((widget.existing?['recoveryHistory'] as List? ?? []).whereType<Map>().map((e) => Map<String,dynamic>.from(e))); if (r > oldRecovered) history.add({'date': DateFormat('yyyy-MM-dd').format(DateTime.now()), 'amount': r - oldRecovered, 'note': 'উদ্ধার আপডেট'}); final row = <String,dynamic>{'recoveryHistory': history, 'id': widget.existing?['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(), 'projectName': project.text.trim(), 'category': category, 'lossDate': date, 'cause': cause.text.trim(), 'totalLoss': t, 'recoveredAmount': r, 'recoverableAmount': double.tryParse(recoverable.text) ?? 0, 'responsiblePerson': person.text.trim(), 'mitigationPlan': plan.text.trim(), 'evidence': evidence, 'status': status, 'updatedAt': DateTime.now().toIso8601String()}; if (mounted) Navigator.pop(context, row); }
  InputDecoration dec(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none));
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF5F3EE), appBar: AppBar(title: Text(widget.existing == null ? 'নতুন ক্ষতি যোগ' : 'ক্ষতি সম্পাদনা'), backgroundColor: navy, foregroundColor: Colors.white), body: Form(child: ListView(padding: const EdgeInsets.all(16), children: [TextField(controller: project, decoration: dec('প্রজেক্ট / ব্যবসার নাম *', Icons.business)), const SizedBox(height: 11), Row(children: [Expanded(child: DropdownButtonFormField<String>(value: category, decoration: dec('ক্ষতির খাত *', Icons.category), items: ['পণ্য বিক্রয়','পরিবহন','উৎপাদন','যন্ত্রপাতি','কর্মচারী','অন্যান্য'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => category = v ?? category))), const SizedBox(width: 9), Expanded(child: OutlinedButton.icon(onPressed: () async { final d = await showDatePicker(context: context, initialDate: DateTime.tryParse(date) ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if (d != null) setState(() => date = DateFormat('yyyy-MM-dd').format(d)); }, icon: const Icon(Icons.calendar_month), label: Text(date))) ]), const SizedBox(height: 11), TextField(controller: cause, decoration: dec('ক্ষতির কারণ *', Icons.warning_amber)), const SizedBox(height: 11), Row(children: [Expanded(child: TextField(controller: total, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: dec('মোট ক্ষতি (৳) *', Icons.money_off))), const SizedBox(width: 9), Expanded(child: TextField(controller: recovered, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: dec('উদ্ধারকৃত অর্থ (৳)', Icons.savings))) ]), const SizedBox(height: 11), TextField(controller: recoverable, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: dec('আরও উদ্ধার সম্ভাবনা (৳)', Icons.trending_up)), const SizedBox(height: 11), TextField(controller: person, decoration: dec('দায়িত্বপ্রাপ্ত ব্যক্তি', Icons.person)), const SizedBox(height: 11), TextField(controller: plan, maxLines: 3, decoration: dec('সমাধানের পরিকল্পনা', Icons.description)), const SizedBox(height: 14), Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('প্রমাণপত্র (ছবি / PDF)', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10), Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.image), label: const Text('ছবি যোগ')), OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.attach_file), label: const Text('PDF / ফাইল'))]), ...evidence.map((e) => ListTile(dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.insert_drive_file), title: Text(e.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: IconButton(onPressed: () => setState(() => evidence.remove(e)), icon: const Icon(Icons.close))))])), const SizedBox(height: 11), DropdownButtonFormField<String>(value: status, decoration: dec('স্ট্যাটাস', Icons.flag), items: ['চলমান','সমাধানাধীন','বন্ধ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => status = v ?? status)), const SizedBox(height: 20), SizedBox(height: 52, child: FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: navy), onPressed: saving ? null : _submit, icon: const Icon(Icons.save), label: const Text('সংরক্ষণ করুন')))])));
}
