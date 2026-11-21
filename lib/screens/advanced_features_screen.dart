import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/pdf_document_service.dart';
import '../services/reminder_service.dart';
import '../services/backup_service.dart';
import '../services/audit_log_service.dart';

const _teal = Color(0xFF00796B);

class AdvancedFeaturesScreen extends StatelessWidget {
  const AdvancedFeaturesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('উন্নত ফিচারসমূহ'), backgroundColor: _teal, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(14), children: [
      _FeatureTile(Icons.receipt_long, 'ডিজিটাল রসিদ PDF', 'লেনদেনের রসিদ তৈরি ও প্রিন্ট', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DigitalReceiptScreen()))),
      _FeatureTile(Icons.badge_outlined, 'সদস্য 360° ও স্মার্ট সার্চ', 'সদস্য, লেনদেন ও বিনিয়োগ একসঙ্গে খুঁজুন', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartSearchScreen()))),
      _FeatureTile(Icons.description_outlined, 'অঙ্গীকারনামা ও নথি', 'সদস্যভিত্তিক নথির খসড়া সংরক্ষণ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PledgeDocumentsScreen()))),
      _FeatureTile(Icons.analytics_outlined, 'উন্নত আর্থিক রিপোর্ট', 'আয়, জমা, ব্যয় ও বকেয়ার সারাংশ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedReportsScreen()))),
      _FeatureTile(Icons.notifications_active_outlined, 'রিমাইন্ডার সেটিংস', 'রিমাইন্ডার পছন্দ সংরক্ষণ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderPreferencesScreen()))),
      _FeatureTile(Icons.cloud_sync_outlined, 'Cloud Backup', 'ব্যাকআপ ফিচারের প্রস্তুতি ও অবস্থা', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupStatusScreen()))),
      _FeatureTile(Icons.history, 'অ্যাক্টিভিটি লগ', 'এই ডিভাইসে সংরক্ষিত স্থানীয় কার্যকলাপ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalAuditScreen()))),
      _FeatureTile(Icons.language, 'ভাষা নির্বাচন', 'বাংলা / English পছন্দ সংরক্ষণ', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguagePreferenceScreen()))),
      const SizedBox(height: 10),
      const Text('নোট: Cloud Backup, সার্ভার Audit Log, Push Notification delivery এবং সম্পূর্ণ অ্যাপের অনুবাদ Backend/Integration ধাপে সংযুক্ত করতে হবে।', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
    ]),
  );
}

class _FeatureTile extends StatelessWidget {
  final IconData icon; final String title, subtitle; final VoidCallback onTap;
  const _FeatureTile(this.icon, this.title, this.subtitle, this.onTap);
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(backgroundColor: _teal.withOpacity(.1), child: Icon(icon, color: _teal)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}


class SmartSearchScreen extends StatefulWidget {
  const SmartSearchScreen({super.key});
  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  final _query = TextEditingController();
  bool _loading = true;
  String? _error;
  String _kind = 'সব';
  DateTimeRange? _range;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _asRows(dynamic value, String kind) {
    if (value is! List) return [];
    return value.whereType<Map>().map((e) {
      final row = Map<String, dynamic>.from(e);
      row['_recordType'] = kind;
      return row;
    }).toList();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final responses = await Future.wait([
        ApiService.getAllMembers(),
        ApiService.getTransactions(),
        ApiService.getInvestments(),
      ]);
      final rows = <Map<String, dynamic>>[
        ..._asRows(responses[0], 'সদস্য'),
        ..._asRows(responses[1], 'লেনদেন'),
        ..._asRows(responses[2], 'বিনিয়োগ'),
      ];
      if (mounted) setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'তথ্য লোড করা যায়নি: $e'; _loading = false; });
    }
  }

  DateTime? _dateOf(Map<String, dynamic> row) {
    for (final key in ['Date', 'date', 'StartDate', 'startDate', 'CreatedAt', 'createdAt']) {
      final value = row[key];
      if (value == null || value.toString().trim().isEmpty) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) return parsed;
      final parts = value.toString().split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        final a = int.tryParse(parts[0]), b = int.tryParse(parts[1]), c = int.tryParse(parts[2]);
        if (a != null && b != null && c != null) {
          try { return a > 999 ? DateTime(a, b, c) : DateTime(c, b, a); } catch (_) {}
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _rows.where((row) {
      if (_kind != 'সব' && row['_recordType'] != _kind) return false;
      if (q.isNotEmpty && !row.entries.any((e) =>
          !e.key.startsWith('_') && e.value.toString().toLowerCase().contains(q))) return false;
      if (_range != null) {
        final date = _dateOf(row);
        if (date == null) return false;
        final from = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
        final to = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);
        if (date.isBefore(from) || date.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  String _title(Map<String, dynamic> row) =>
      (row['Name'] ?? row['MemberName'] ?? row['ProjectName'] ??
       row['Phone'] ?? row['Type'] ?? 'রেকর্ড').toString();

  Future<void> _chooseRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _range,
      helpText: 'সার্চের তারিখসীমা নির্বাচন',
    );
    if (mounted) setState(() => _range = selected);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('স্মার্ট সার্চ'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [IconButton(tooltip: 'রিফ্রেশ', onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'নাম, ফোন, লেনদেন বা প্রকল্প লিখুন',
              suffixIcon: IconButton(onPressed: () { _query.clear(); setState(() {}); }, icon: const Icon(Icons.clear)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          child: Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _kind,
              decoration: const InputDecoration(labelText: 'রেকর্ডের ধরন', border: OutlineInputBorder(), isDense: true),
              items: ['সব', 'সদস্য', 'লেনদেন', 'বিনিয়োগ'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _kind = v ?? 'সব'),
            )),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _chooseRange,
              icon: const Icon(Icons.date_range),
              label: Text(_range == null ? 'তারিখ' : 'তারিখ নির্বাচিত'),
            ),
            if (_range != null)
              IconButton(onPressed: () => setState(() => _range = null), icon: const Icon(Icons.close)),
          ]),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Align(alignment: Alignment.centerLeft, child: Text('ফলাফল: ${filtered.length} / ${_rows.length}', style: const TextStyle(fontWeight: FontWeight.bold))),
        ),
        Expanded(child: _loading && _rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
            ? const Center(child: Text('কোনো মিল পাওয়া যায়নি'))
            : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = filtered[index];
                  final details = row.entries.where((e) => !e.key.startsWith('_')).take(5)
                      .map((e) => '${e.key}: ${e.value}').join(' • ');
                  return ListTile(
                    leading: CircleAvatar(child: Icon(row['_recordType'] == 'সদস্য'
                      ? Icons.person_outline : row['_recordType'] == 'বিনিয়োগ'
                      ? Icons.trending_up : Icons.receipt_long)),
                    title: Text(_title(row)),
                    subtitle: Text('${row['_recordType']}  •  $details', maxLines: 2, overflow: TextOverflow.ellipsis),
                  );
                },
              )),
      ]),
    );
  }
}

class AdvancedReportsScreen extends StatefulWidget {
  const AdvancedReportsScreen({super.key});
  @override
  State<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends State<AdvancedReportsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];
  DateTimeRange? _range;
  String _status = 'সব';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await ApiService.getTransactions();
      if (response is List) {
        _transactions = response.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        _error = response is Map ? (response['error'] ?? 'সার্ভার থেকে রিপোর্ট পাওয়া যায়নি').toString() : 'রিপোর্ট পাওয়া যায়নি';
      }
    } catch (e) { _error = e.toString(); }
    if (mounted) setState(() => _loading = false);
  }

  DateTime? _date(Map<String, dynamic> row) {
    final raw = row['Date'] ?? row['date'];
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed != null) return parsed;
    final parts = raw.toString().split(RegExp(r'[/.-]'));
    if (parts.length == 3) {
      final a = int.tryParse(parts[0]), b = int.tryParse(parts[1]), c = int.tryParse(parts[2]);
      if (a != null && b != null && c != null) {
        try { return a > 999 ? DateTime(a, b, c) : DateTime(c, b, a); } catch (_) {}
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _filtered {
    return _transactions.where((row) {
      final status = (row['Status'] ?? 'Paid').toString();
      if (_status == 'পরিশোধিত' && status.toLowerCase() != 'paid' && status != 'পরিশোধিত') return false;
      if (_status == 'বকেয়া' && status.toLowerCase() != 'pending' && status != 'বকেয়া') return false;
      if (_range != null) {
        final date = _date(row);
        if (date == null) return false;
        final from = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
        final to = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59);
        if (date.isBefore(from) || date.isAfter(to)) return false;
      }
      return true;
    }).toList();
  }

  double _amount(Map<String, dynamic> row) =>
      double.tryParse('${row['Amount'] ?? row['amount'] ?? 0}'.replaceAll(',', '')) ?? 0;

  double _sum(List<Map<String, dynamic>> rows, List<String> types) {
    return rows.where((r) => types.contains((r['Type'] ?? r['type'] ?? '').toString()))
        .fold<double>(0, (sum, row) => sum + _amount(row));
  }

  String _csv() {
    String esc(dynamic value) => '"${(value ?? '').toString().replaceAll('"', '""')}"';
    final rows = <String>['ধরন,পরিমাণ,সদস্য,তারিখ,অবস্থা,বিবরণ'];
    for (final row in _filtered) {
      rows.add([
        esc(row['Type'] ?? row['type']), esc(row['Amount'] ?? row['amount']),
        esc(row['MemberName'] ?? row['memberName']), esc(row['Date'] ?? row['date']),
        esc(row['Status'] ?? row['status']), esc(row['Note'] ?? row['note']),
      ].join(','));
    }
    // UTF-8 BOM helps Excel detect Bengali text correctly.
    return '\uFEFF${rows.join('\r\n')}';
  }

  Future<void> _exportCsv() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/somiti_report_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(_csv(), encoding: utf8, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: 'সমিতির আর্থিক রিপোর্ট (CSV)');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Export ব্যর্থ: $e')));
    }
  }

  Future<void> _exportPdf() async {
    try {
      final rows = <List<String>>[
        ['রিপোর্ট সময়সীমা', _range == null ? 'সব তারিখ' : '${_range!.start.toLocal().toString().split(' ').first} থেকে ${_range!.end.toLocal().toString().split(' ').first}'],
        ['রেকর্ড সংখ্যা', '${_filtered.length}'],
        ['মোট জমা', '৳ ${_sum(_filtered, ['জমা']).toStringAsFixed(2)}'],
        ['মোট আয়', '৳ ${_sum(_filtered, ['আয়', 'আয়']).toStringAsFixed(2)}'],
        ['মোট ব্যয়', '৳ ${_sum(_filtered, ['ব্যয়', 'ব্যয়']).toStringAsFixed(2)}'],
        ['মোট বকেয়া', '৳ ${_sum(_filtered, ['বকেয়া', 'বকেয়া']).toStringAsFixed(2)}'],
      ];
      final doc = await PdfDocumentService.create(
        type: 'report', title: 'উন্নত আর্থিক রিপোর্ট', rows: rows,
        note: 'এই রিপোর্ট অ্যাপে বর্তমানে API থেকে পাওয়া লেনদেনের ভিত্তিতে তৈরি। এটি সার্ভার-স্বাক্ষরিত বা নিরীক্ষিত রিপোর্ট নয়।',
      );
      await PdfDocumentService.preview(doc);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF Export ব্যর্থ: $e')));
    }
  }

  Future<void> _chooseRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context, firstDate: DateTime(2000), lastDate: DateTime(now.year + 5),
      initialDateRange: _range, helpText: 'রিপোর্টের সময়সীমা নির্বাচন',
    );
    if (mounted) setState(() => _range = selected);
  }

  Widget _card(String title, double value, IconData icon) => Card(
    child: ListTile(
      leading: CircleAvatar(backgroundColor: _teal.withOpacity(.1), child: Icon(icon, color: _teal)),
      title: Text(title),
      trailing: Text('৳ ${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: _teal)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('উন্নত আর্থিক রিপোর্ট'),
        backgroundColor: _teal, foregroundColor: Colors.white,
        actions: [
          IconButton(tooltip: 'CSV / Excel Export', onPressed: _loading ? null : _exportCsv, icon: const Icon(Icons.table_view)),
          IconButton(tooltip: 'PDF Export', onPressed: _loading ? null : _exportPdf, icon: const Icon(Icons.picture_as_pdf)),
          IconButton(tooltip: 'রিফ্রেশ', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_error != null) Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _chooseRange, icon: const Icon(Icons.date_range),
              label: Text(_range == null ? 'তারিখসীমা নির্বাচন' : 'তারিখসীমা পরিবর্তন'),
            )),
            if (_range != null) IconButton(onPressed: () => setState(() => _range = null), icon: const Icon(Icons.clear)),
          ]),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'পেমেন্ট অবস্থা'),
            items: ['সব', 'পরিশোধিত', 'বকেয়া'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _status = v ?? 'সব'),
          ),
          const SizedBox(height: 8),
          _card('মোট জমা', _sum(rows, ['জমা']), Icons.savings_outlined),
          _card('মোট আয়', _sum(rows, ['আয়', 'আয়']), Icons.trending_up),
          _card('মোট ব্যয়', _sum(rows, ['ব্যয়', 'ব্যয়']), Icons.trending_down),
          _card('মোট বকেয়া', _sum(rows, ['বকেয়া', 'বকেয়া']), Icons.pending_actions),
          Card(child: ListTile(
            title: const Text('ফিল্টারকৃত লেনদেন'),
            trailing: Text('${rows.length} / ${_transactions.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          )),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('CSV ফাইল Excel-এ খোলা যাবে। PDF ও CSV এই ডিভাইসে পাওয়া API ডেটা থেকে তৈরি। সার্ভার-সাইড ফিল্টার, ভূমিকা-ভিত্তিক অনুমতি, পেজিনেশন ও নিরীক্ষিত হিসাব Backend ধাপে প্রয়োজন।', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class DigitalReceiptScreen extends StatefulWidget{const DigitalReceiptScreen({super.key});@override State<DigitalReceiptScreen> createState()=>_DigitalReceiptScreenState();}
class _DigitalReceiptScreenState extends State<DigitalReceiptScreen>{
 final member=TextEditingController(),phone=TextEditingController(),amount=TextEditingController(),note=TextEditingController(); String type='জমা'; bool busy=false;
 Future<void> _create() async {final value=double.tryParse(amount.text.trim().replaceAll(',',''));if(member.text.trim().isEmpty||value==null||value<=0){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সদস্যের নাম ও সঠিক টাকার পরিমাণ দিন')));return;}setState(()=>busy=true);try{final d=await PdfDocumentService.create(type:'receipt',title:'ডিজিটাল রসিদ',rows:[['রসিদ নম্বর','LOCAL-${DateTime.now().microsecondsSinceEpoch}'],['সদস্যের নাম',member.text.trim()],['মোবাইল',phone.text.trim()],['লেনদেনের ধরন',type],['পরিমাণ','৳ ${value.toStringAsFixed(2)}'],['তারিখ','${DateTime.now()}']],note:note.text.trim());if(!mounted)return;await showModalBottomSheet(context:context,builder:(c)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(Icons.picture_as_pdf),title:const Text('PDF প্রিভিউ / প্রিন্ট'),onTap:(){Navigator.pop(c);PdfDocumentService.preview(d);}),ListTile(leading:const Icon(Icons.share),title:const Text('PDF শেয়ার'),onTap:(){Navigator.pop(c);PdfDocumentService.share(d);}),ListTile(leading:const Icon(Icons.folder_open),title:const Text('সংরক্ষিত নথি দেখুন'),onTap:(){Navigator.pop(c);Navigator.push(context,MaterialPageRoute(builder:(_)=>const SavedDocumentsScreen()));})]))); }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('PDF তৈরি করা যায়নি: $e')));}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ডিজিটাল রসিদ PDF'),backgroundColor:_teal,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(16),children:[TextField(controller:member,decoration:const InputDecoration(labelText:'সদস্যের নাম *')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল নম্বর')),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'টাকার পরিমাণ *')),DropdownButtonFormField<String>(value:type,items:['জমা','আয়','আয়','ব্যয়','ব্যয়','বিলম্ব ফী','কিস্তি'].map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(),onChanged:(v)=>setState(()=>type=v??'জমা'),decoration:const InputDecoration(labelText:'লেনদেনের ধরন')),TextField(controller:note, minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'বিবরণ')),const SizedBox(height:16),ElevatedButton.icon(onPressed:busy?null:_create,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.picture_as_pdf),label:Text(busy?'PDF তৈরি হচ্ছে...':'PDF রসিদ তৈরি করুন')),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SavedDocumentsScreen())),icon:const Icon(Icons.folder_open),label:const Text('সংরক্ষিত রসিদ / নথি')),const Text('রসিদটি এই ডিভাইসে PDF হিসেবে সংরক্ষিত হবে। LOCAL নম্বরটি ডিভাইস-ভিত্তিক; সার্ভার যাচাইকৃত রসিদ নম্বর নয়।',style:TextStyle(color:Colors.deepOrange,fontSize:12))]));
}

class PledgeDocumentsScreen extends StatefulWidget { const PledgeDocumentsScreen({super.key}); @override State<PledgeDocumentsScreen> createState()=>_PledgeDocumentsScreenState(); }
class _PledgeDocumentsScreenState extends State<PledgeDocumentsScreen>{final name=TextEditingController(),phone=TextEditingController(),purpose=TextEditingController(),terms=TextEditingController();bool busy=false;Future<void> _create()async{if(name.text.trim().isEmpty||terms.text.trim().isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সদস্যের নাম ও অঙ্গীকারের শর্ত লিখুন')));return;}setState(()=>busy=true);try{final d=await PdfDocumentService.create(type:'pledge',title:'অঙ্গীকারনামা',rows:[['সদস্যের নাম',name.text.trim()],['মোবাইল',phone.text.trim()],['উদ্দেশ্য',purpose.text.trim()],['তারিখ','${DateTime.now()}']],note:terms.text.trim());if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('অঙ্গীকারনামার PDF তৈরি ও সংরক্ষণ হয়েছে')));await showModalBottomSheet(context:context,builder:(c)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(Icons.picture_as_pdf),title:const Text('PDF প্রিভিউ / প্রিন্ট'),onTap:(){Navigator.pop(c);PdfDocumentService.preview(d);}),ListTile(leading:const Icon(Icons.share),title:const Text('PDF শেয়ার'),onTap:(){Navigator.pop(c);PdfDocumentService.share(d);})]))); }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('নথি তৈরি করা যায়নি: $e')));}finally{if(mounted)setState(()=>busy=false);}}
@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('অঙ্গীকারনামা ও নথি'),backgroundColor:_teal,foregroundColor:Colors.white),body:ListView(padding:const EdgeInsets.all(16),children:[const Text('নতুন অঙ্গীকারনামা',style:TextStyle(fontWeight:FontWeight.bold,fontSize:18)),TextField(controller:name,decoration:const InputDecoration(labelText:'সদস্যের নাম *')),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'মোবাইল')),TextField(controller:purpose,decoration:const InputDecoration(labelText:'উদ্দেশ্য')),TextField(controller:terms,minLines:4,maxLines:8,decoration:const InputDecoration(labelText:'শর্তাবলি / অঙ্গীকার *')),const SizedBox(height:12),ElevatedButton.icon(onPressed:busy?null:_create,icon:const Icon(Icons.picture_as_pdf),label:Text(busy?'PDF তৈরি হচ্ছে...':'অঙ্গীকারনামা PDF তৈরি ও সংরক্ষণ')),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SavedDocumentsScreen())),icon:const Icon(Icons.folder_open),label:const Text('সংরক্ষিত নথি দেখুন')),const Text('নথি স্থানীয়ভাবে সংরক্ষিত হবে। স্বাক্ষর, সাক্ষী যাচাই, অনুমোদন, ক্লাউড আপলোড ও সার্ভার-রেকর্ড Backend ধাপে যুক্ত হবে।',style:TextStyle(color:Colors.deepOrange,fontSize:12))]));}

class SavedDocumentsScreen extends StatefulWidget{const SavedDocumentsScreen({super.key});@override State<SavedDocumentsScreen> createState()=>_SavedDocumentsScreenState();}
class _SavedDocumentsScreenState extends State<SavedDocumentsScreen>{List<SavedDocument> docs=[];bool loading=true;Future<void> _load()async{final x=await PdfDocumentService.list();if(mounted)setState((){docs=x;loading=false;});}@override void initState(){super.initState();_load();}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('সংরক্ষিত PDF নথি'),backgroundColor:_teal,foregroundColor:Colors.white,actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:loading?const Center(child:CircularProgressIndicator()):docs.isEmpty?const Center(child:Text('কোনো PDF নথি পাওয়া যায়নি')):ListView.builder(itemCount:docs.length,itemBuilder:(c,i){final d=docs[i];return Card(child:ListTile(leading:const Icon(Icons.picture_as_pdf,color:_teal),title:Text(d.title),subtitle:Text('${d.type=='receipt'?'রসিদ':'অঙ্গীকারনামা'} • ${d.createdAt}'),onTap:()=>PdfDocumentService.preview(d),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='share')await PdfDocumentService.share(d);if(v=='print')await PdfDocumentService.printDocument(d);if(v=='delete'){await PdfDocumentService.delete(d);await _load();}},itemBuilder:(_)=>const [PopupMenuItem(value:'share',child:Text('শেয়ার')),PopupMenuItem(value:'print',child:Text('প্রিন্ট')),PopupMenuItem(value:'delete',child:Text('মুছে ফেলুন'))]))); }));}


class ReminderPreferencesScreen extends StatefulWidget {
  const ReminderPreferencesScreen({super.key});
  @override
  State<ReminderPreferencesScreen> createState() => _ReminderPreferencesScreenState();
}

class _ReminderPreferencesScreenState extends State<ReminderPreferencesScreen> {
  List<ReminderItem> _items = [];
  bool _loading = true;
  bool _permission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ReminderService.instance.initialize();
      final enabled = await ReminderService.instance.areNotificationsEnabled();
      final items = await ReminderService.instance.getAll();
      if (!mounted) return;
      setState(() { _permission = enabled; _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _permissionRequest() async {
    final ok = await ReminderService.instance.requestPermission();
    if (!mounted) return;
    setState(() => _permission = ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification permission পাওয়া যায়নি। Android Settings থেকে অনুমতি দিন।'),
      ));
    } else {
      await _load();
    }
  }

  Future<void> _edit([ReminderItem? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    DateTime date = existing?.scheduledAt ?? DateTime.now().add(const Duration(hours: 1));
    TimeOfDay time = TimeOfDay.fromDateTime(date);
    String repeat = existing?.repeat ?? 'none';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<ReminderItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialog) => AlertDialog(
        title: Text(existing == null ? 'নতুন রিমাইন্ডার' : 'রিমাইন্ডার সম্পাদনা'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, decoration: const InputDecoration(labelText: 'শিরোনাম'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'শিরোনাম লিখুন' : null),
            TextFormField(controller: body, decoration: const InputDecoration(labelText: 'বিস্তারিত / নোট')),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('তারিখ'),
              subtitle: Text('${date.day}/${date.month}/${date.year}'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: date,
                  firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setDialog(() => date = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('সময়'),
              subtitle: Text(time.format(context)),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: time);
                if (picked != null) setDialog(() {
                  time = picked;
                  date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: repeat,
              decoration: const InputDecoration(labelText: 'পুনরাবৃত্তি'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('একবার')),
                DropdownMenuItem(value: 'daily', child: Text('প্রতিদিন')),
                DropdownMenuItem(value: 'weekly', child: Text('প্রতি সপ্তাহে')),
              ],
              onChanged: (v) => setDialog(() => repeat = v ?? 'none'),
            ),
            const SizedBox(height: 6),
            const Text('নোট: দৈনিক ও সাপ্তাহিক রিমাইন্ডার নির্বাচিত সময় ধরে পুনরাবৃত্তি হবে।', style: TextStyle(fontSize: 11, color: Colors.black54)),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('বাতিল')),
          ElevatedButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
            Navigator.pop(dialogContext, ReminderItem(
              id: existing?.id ?? 'rem_${DateTime.now().microsecondsSinceEpoch}',
              title: title.text.trim(),
              body: body.text.trim().isEmpty ? 'আপনার নির্ধারিত কাজের সময় হয়েছে।' : body.text.trim(),
              scheduledAt: scheduled,
              repeat: repeat,
              enabled: true,
            ));
          }, child: const Text('সংরক্ষণ')),
        ],
      )),
    );
    title.dispose(); body.dispose();
    if (result == null) return;
    try {
      if (!_permission) {
        final granted = await ReminderService.instance.requestPermission();
        if (!granted) { _permissionRequest(); return; }
      }
      await ReminderService.instance.save(result);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('রিমাইন্ডার সেট করা যায়নি: $e')));
    }
  }

  Future<void> _delete(ReminderItem item) async {
    await ReminderService.instance.delete(item.id);
    await _load();
  }

  String _repeatText(String value) => value == 'daily' ? 'প্রতিদিন' : value == 'weekly' ? 'প্রতি সপ্তাহে' : 'একবার';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('রিমাইন্ডার ও নোটিফিকেশন'),
      backgroundColor: _teal, foregroundColor: Colors.white,
      actions: [IconButton(tooltip: 'Refresh', onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _edit(), backgroundColor: _teal,
      icon: const Icon(Icons.add, color: Colors.white), label: const Text('রিমাইন্ডার যোগ', style: TextStyle(color: Colors.white)),
    ),
    body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_permission ? Icons.notifications_active : Icons.notifications_off, color: _permission ? Colors.green : Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(_permission ? 'Notification permission চালু' : 'Notification permission প্রয়োজন', style: const TextStyle(fontWeight: FontWeight.bold))),
            if (!_permission) TextButton(onPressed: _permissionRequest, child: const Text('অনুমতি দিন')),
          ]),
          const Text('Android Settings-এ এই অ্যাপের Notifications বন্ধ থাকলে নির্ধারিত Reminder দেখা যাবে না।', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _permission ? () async {
              try { await ReminderService.instance.showTestNotification(); }
              catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test notification ব্যর্থ: $e'))); }
            } : _permissionRequest,
            icon: const Icon(Icons.notifications), label: const Text('Test Notification'),
          ),
        ]))),
        if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red)))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('আপনার রিমাইন্ডার', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
        if (_items.isEmpty) const Card(child: ListTile(leading: Icon(Icons.event_available), title: Text('কোনো রিমাইন্ডার নেই'), subtitle: Text('নিচের বাটন দিয়ে নতুন রিমাইন্ডার যোগ করুন।'))),
        ..._items.map((item) => Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.notifications_active_outlined)),
          title: Text(item.title),
          subtitle: Text('${item.scheduledAt.day}/${item.scheduledAt.month}/${item.scheduledAt.year}  ${TimeOfDay.fromDateTime(item.scheduledAt).format(context)} • ${_repeatText(item.repeat)}'),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _edit(item);
              if (v == 'delete') _delete(item);
              if (v == 'toggle') ReminderService.instance.setEnabled(item, !item.enabled).then((_) => _load());
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'toggle', child: Text(item.enabled ? 'বন্ধ করুন' : 'চালু করুন')),
              const PopupMenuItem(value: 'edit', child: Text('সম্পাদনা')),
              const PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন')),
            ],
          ),
          isThreeLine: true,
        ))),
        const SizedBox(height: 8),
        const Text('সতর্কতা: Android ব্যাটারি সেভার, নির্মাতার background restriction বা ব্যবহারকারীর permission পরিবর্তনের কারণে notification দেরিতে আসতে পারে। এই সংস্করণে battery optimization বন্ধ করার অনুমতি স্বয়ংক্রিয়ভাবে নেওয়া হয় না।', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
        const SizedBox(height: 12),
        const Text('Push Notification delivery, server-side due detection এবং সদস্যভিত্তিক স্বয়ংক্রিয় কিস্তি reminder Backend/FCM সংযোগের অপেক্ষায়।', style: TextStyle(color: Colors.deepOrange, fontSize: 12)),
      ],
    ),
  );
}

class BackupStatusScreen extends StatefulWidget {
  const BackupStatusScreen({super.key});
  @override
  State<BackupStatusScreen> createState() => _BackupStatusScreenState();
}

class _BackupStatusScreenState extends State<BackupStatusScreen> {
  bool _busy = false;
  String? _status;

  Future<void> _export() async {
    setState(() { _busy = true; _status = null; });
    try {
      final file = await BackupService.createAndShareBackup();
      if (mounted) setState(() => _status = 'Backup তৈরি হয়েছে: ${file.path.split('/').last}');
    } catch (e) {
      if (mounted) setState(() => _status = 'Backup তৈরি করা যায়নি: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _restore() async {
    setState(() { _busy = true; _status = null; });
    try {
      final inspection = await BackupService.pickAndInspectBackup();
      if (!mounted) return;
      final counts = inspection.counts.entries.map((e) => '${e.key}: ${e.value}').join('\n');
      final local = inspection.document['localData'];
      final reminderCount = local is Map && local['reminders'] is List ? (local['reminders'] as List).length : 0;
      final approved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('Backup যাচাই'),
        content: SingleChildScrollView(child: Text('তৈরির সময়: ${inspection.document['createdAt'] ?? 'অজানা'}\n\nRemote ডেটা (শুধু ফাইলে সংরক্ষিত, সার্ভারে Restore হবে না):\n${counts.isEmpty ? 'কোনো রেকর্ড নেই' : counts}\n\nLocal reminder: $reminderCount টি\n\nআপনি কি শুধু এই ডিভাইসের Settings, Reminder ও Audit Log Restore করতে চান?')),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('বাতিল')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Local Restore'))],
      ));
      if (approved == true) {
        await BackupService.restoreLocalData(inspection);
        if (mounted) setState(() => _status = 'Local Restore সম্পন্ন। Google Sheets-এর সদস্য/লেনদেন/কিস্তি ডেটা এই সংস্করণে Restore হয়নি।');
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Restore করা যায়নি: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Backup ও Restore'), backgroundColor: _teal, foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.backup, color: _teal), title: const Text('Local JSON Backup'), subtitle: const Text('Google Sheets-এর ডেটা ও ডিভাইসের প্রয়োজনীয় সেটিংস একটি JSON ফাইলে Export করুন।'))),
      FilledButton.icon(onPressed: _busy ? null : _export, icon: const Icon(Icons.share), label: const Text('Backup তৈরি ও Share করুন')),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: _busy ? null : _restore, icon: const Icon(Icons.restore), label: const Text('Backup ফাইল থেকে Local Restore')),
      if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      if (_status != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: SelectableText(_status!))),
      const Divider(height: 28),
      const Card(child: ListTile(leading: Icon(Icons.cloud_outlined), title: Text('Google Drive'), subtitle: Text('OAuth/Cloud Storage সংযোগ Pending'))),
      const Card(child: ListTile(leading: Icon(Icons.cloud_outlined), title: Text('OneDrive'), subtitle: Text('Microsoft OAuth সংযোগ Pending'))),
      const Text('সীমাবদ্ধতা: এই Batch-এ JSON Backup/Share এবং Local Settings, Reminder ও Audit Log Restore কার্যকর। সদস্য, লেনদেন, বিনিয়োগ ও কিস্তির ডেটা Backup ফাইলে থাকবে; কিন্তু Google Sheets-এ ফেরত লেখার নিরাপদ Backend Import API এখনো নেই। Cloud Sync চালু নয়।', style: TextStyle(color: Colors.deepOrange)),
      const SizedBox(height: 8),
      const Text('Backup ফাইলে ব্যক্তিগত ও আর্থিক তথ্য থাকতে পারে। এটি শুধু বিশ্বস্ত স্থানে সংরক্ষণ/শেয়ার করুন।', style: TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );
}

class LocalAuditScreen extends StatefulWidget {
  const LocalAuditScreen({super.key});
  @override
  State<LocalAuditScreen> createState() => _LocalAuditScreenState();
}

class _LocalAuditScreenState extends State<LocalAuditScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = '';

  Future<void> _load() async {
    final rows = await AuditLogService.read();
    if (mounted) setState(() { _logs = rows; _loading = false; });
  }

  Future<void> _export() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/somiti_audit_log_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_logs), flush: true);
      await Share.shareXFiles([XFile(file.path)], text: 'সমিতি অ্যাপের Local Activity Log');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export ব্যর্থ: $e')));
    }
  }

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    final visible = _logs.where((e) => '${e['actor']} ${e['action']} ${e['details']} ${e['status']}'.toLowerCase().contains(_filter.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাক্টিভিটি লগ'), backgroundColor: _teal, foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh)), IconButton(onPressed: _logs.isEmpty ? null : _export, icon: const Icon(Icons.ios_share))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'কাজ / ব্যবহারকারী দিয়ে খুঁজুন', border: OutlineInputBorder()), onChanged: (v) => setState(() => _filter = v))),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('এটি ডিভাইসে সংরক্ষিত Local Activity Log। ব্যবহারকারী ডিভাইসের ডেটা পরিবর্তন করতে পারেন; তাই এটি tamper-proof বা আইনগত Financial Audit Trail নয়। Server-side Audit Log Backend-এ Pending।', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : visible.isEmpty ? const Center(child: Text('কোনো Activity Log পাওয়া যায়নি')) : ListView.builder(itemCount: visible.length, itemBuilder: (context, index) {
          final e = visible[index];
          final date = DateTime.tryParse(e['at']?.toString() ?? '');
          final dateText = date == null ? 'সময় অজানা' : '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          return Card(child: ListTile(leading: Icon(e['status'] == 'error' ? Icons.error_outline : Icons.history, color: e['status'] == 'error' ? Colors.red : _teal), title: Text(e['action']?.toString() ?? 'Activity'), subtitle: Text('$dateText • ${e['actor'] ?? 'Unknown'}\n${e['details'] ?? ''}'), isThreeLine: true, trailing: Text(e['status']?.toString() ?? '')));
        })),
      ]),
    );
  }
}

class LanguagePreferenceScreen extends StatefulWidget{const LanguagePreferenceScreen({super.key});@override State<LanguagePreferenceScreen> createState()=>_LanguagePreferenceScreenState();}
class _LanguagePreferenceScreenState extends State<LanguagePreferenceScreen> {
  String lang = 'বাংলা';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => lang = prefs.getString('app_language') ?? 'বাংলা');
  }

  Future<void> _save(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
    if (!mounted) return;
    setState(() => lang = value);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('ভাষা নির্বাচন'),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            RadioListTile<String>(
              title: const Text('বাংলা'),
              value: 'বাংলা',
              groupValue: lang,
              onChanged: _save,
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: 'English',
              groupValue: lang,
              onChanged: _save,
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'ভাষার পছন্দ সংরক্ষণ করা হচ্ছে। সম্পূর্ণ অ্যাপের সব স্ক্রিনে অনুবাদ প্রয়োগ করতে আলাদা localization refactor প্রয়োজন।',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        ),
      );
}
