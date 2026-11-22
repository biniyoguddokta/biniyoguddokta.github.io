import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/pdf_document_service.dart';

class PledgeDocumentsScreen extends StatefulWidget {
  const PledgeDocumentsScreen({super.key});
  @override
  State<PledgeDocumentsScreen> createState() => _PledgeDocumentsScreenState();
}

class _PledgeDocumentsScreenState extends State<PledgeDocumentsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _purpose = TextEditingController();
  final _terms = TextEditingController();
  XFile? _attachment;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose(); _phone.dispose(); _purpose.dispose(); _terms.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800, maxHeight: 1800);
    if (image != null && mounted) setState(() => _attachment = image);
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _terms.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সদস্যের নাম ও অঙ্গীকারের শর্ত লিখুন')));
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = _attachment == null ? null : await File(_attachment!.path).readAsBytes();
      final document = await PdfDocumentService.create(
        type: 'pledge', title: 'অঙ্গীকারনামা',
        rows: [
          ['সদস্যের নাম', _name.text.trim()], ['মোবাইল', _phone.text.trim()],
          ['উদ্দেশ্য', _purpose.text.trim()], ['তারিখ', '${DateTime.now()}'],
        ],
        note: _terms.text.trim(), attachmentImageBytes: bytes,
        attachmentLabel: 'সদস্যের সংযুক্ত ছবি / নথির ছবি',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('অঙ্গীকারনামা ও সংযুক্ত ছবি PDF-এ সংরক্ষিত হয়েছে')));
      await showModalBottomSheet(context: context, builder: (c) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('PDF প্রিভিউ / প্রিন্ট'), onTap: () { Navigator.pop(c); PdfDocumentService.preview(document); }),
        ListTile(leading: const Icon(Icons.share), title: const Text('PDF শেয়ার'), onTap: () { Navigator.pop(c); PdfDocumentService.share(document); }),
      ])));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('নথি তৈরি করা যায়নি: $e')));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F3EE),
    appBar: AppBar(title: const Text('অঙ্গীকারনামা'), backgroundColor: const Color(0xFF142F52), foregroundColor: Colors.white),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('নতুন অঙ্গীকারনামা', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19, color: Color(0xFF142F52))),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'সদস্যের নাম *')),
        const SizedBox(height: 10), TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'মোবাইল')),
        const SizedBox(height: 10), TextField(controller: _purpose, decoration: const InputDecoration(labelText: 'উদ্দেশ্য')),
        const SizedBox(height: 10), TextField(controller: _terms, minLines: 4, maxLines: 8, decoration: const InputDecoration(labelText: 'শর্তাবলি / অঙ্গীকার *')),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: _pickAttachment, icon: const Icon(Icons.add_photo_alternate_outlined), label: Text(_attachment == null ? 'ছবি / নথি সংযুক্ত করুন' : 'ছবি পরিবর্তন করুন')),
        if (_attachment != null) ...[
          const SizedBox(height: 8), ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_attachment!.path), height: 170, width: double.infinity, fit: BoxFit.contain)),
          TextButton.icon(onPressed: () => setState(() => _attachment = null), icon: const Icon(Icons.delete_outline), label: const Text('ছবি বাদ দিন')),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _create, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.picture_as_pdf), label: Text(_busy ? 'PDF তৈরি হচ্ছে...' : 'অঙ্গীকারনামা PDF তৈরি ও সংরক্ষণ'))),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PledgeSavedDocumentsScreen())), icon: const Icon(Icons.folder_open), label: const Text('সংরক্ষিত নথি দেখুন')),
      ]))),
      const Padding(padding: EdgeInsets.all(8), child: Text('সংযুক্ত ছবি PDF ফাইলের ভেতরে থাকবে। নথি বর্তমানে এই ডিভাইসে সংরক্ষিত হয়; অনলাইন সার্ভারে সদস্যভিত্তিক আপলোড Backend সংযোগের অপেক্ষায়।', style: TextStyle(color: Colors.deepOrange, fontSize: 12))),
    ]),
  );
}

class PledgeSavedDocumentsScreen extends StatefulWidget {
  const PledgeSavedDocumentsScreen({super.key});
  @override State<PledgeSavedDocumentsScreen> createState() => _PledgeSavedDocumentsScreenState();
}
class _PledgeSavedDocumentsScreenState extends State<PledgeSavedDocumentsScreen> {
  List<SavedDocument> _docs = []; bool _loading = true;
  Future<void> _load() async { final docs = await PdfDocumentService.list(); if (mounted) setState(() { _docs = docs.where((d) => d.type == 'pledge').toList(); _loading = false; }); }
  @override void initState() { super.initState(); _load(); }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('সংরক্ষিত অঙ্গীকারনামা'), backgroundColor: const Color(0xFF142F52), foregroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _docs.isEmpty ? const Center(child: Text('কোনো অঙ্গীকারনামা পাওয়া যায়নি')) : ListView.builder(padding: const EdgeInsets.all(12), itemCount: _docs.length, itemBuilder: (context, index) { final doc = _docs[index]; return Card(child: ListTile(leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF142F52)), title: Text(doc.title), subtitle: Text(doc.createdAt), onTap: () => PdfDocumentService.preview(doc), trailing: PopupMenuButton<String>(onSelected: (v) async { if (v == 'share') await PdfDocumentService.share(doc); if (v == 'print') await PdfDocumentService.printDocument(doc); if (v == 'delete') { await PdfDocumentService.delete(doc); await _load(); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'share', child: Text('শেয়ার')), PopupMenuItem(value: 'print', child: Text('প্রিন্ট')), PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন'))]))); }),
  );
}
