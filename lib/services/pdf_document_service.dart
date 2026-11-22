import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedDocument {
  final String id, title, type, path, createdAt;
  const SavedDocument({required this.id, required this.title, required this.type, required this.path, required this.createdAt});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'type':type,'path':path,'createdAt':createdAt};
  factory SavedDocument.fromJson(Map<String,dynamic> m)=>SavedDocument(id:'${m['id']}',title:'${m['title']}',type:'${m['type']}',path:'${m['path']}',createdAt:'${m['createdAt']}');
}

class PdfDocumentService {
  static const _archiveKey='somiti_saved_documents_v1';
  static Future<pw.Font> _font() async => pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'));
  static String _safe(String value)=>value.replaceAll(RegExp(r'[^\w\-]+'), '_').replaceAll(RegExp(r'_+'),'_');

  static Future<SavedDocument> create({required String type, required String title, required List<List<String>> rows, String? note, List<int>? attachmentImageBytes, String? attachmentLabel}) async {
    final font=await _font();
    final doc=pw.Document(theme:pw.ThemeData.withFont(base:font,bold:font));
    doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(34),theme:pw.ThemeData.withFont(base:font,bold:font),build:(context)=>[
      pw.Center(child:pw.Text('বিনিয়োগ উদ্যোক্তা',style:pw.TextStyle(font:font,fontSize:20,fontWeight:pw.FontWeight.bold))),
      pw.SizedBox(height:6),pw.Center(child:pw.Text(title,style:pw.TextStyle(font:font,fontSize:16,fontWeight:pw.FontWeight.bold))),
      pw.SizedBox(height:18),
      pw.Table(border:pw.TableBorder.all(color:PdfColors.grey400,width:.5),columnWidths:{0:const pw.FlexColumnWidth(1),1:const pw.FlexColumnWidth(2)},children:rows.map((r)=>pw.TableRow(children:[pw.Padding(padding:const pw.EdgeInsets.all(8),child:pw.Text(r[0],style:pw.TextStyle(font:font,fontWeight:pw.FontWeight.bold))),pw.Padding(padding:const pw.EdgeInsets.all(8),child:pw.Text(r[1],style:pw.TextStyle(font:font)))] )).toList()),
      if(note!=null&&note.trim().isNotEmpty) ...[pw.SizedBox(height:16),pw.Text('বিবরণ / শর্তাবলি',style:pw.TextStyle(font:font,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:5),pw.Text(note,style:pw.TextStyle(font:font))],
      if(attachmentImageBytes!=null&&attachmentImageBytes.isNotEmpty) ...[pw.SizedBox(height:18),pw.Text(attachmentLabel??'সংযুক্ত ছবি',style:pw.TextStyle(font:font,fontWeight:pw.FontWeight.bold)),pw.SizedBox(height:8),pw.Center(child:pw.Image(pw.MemoryImage(Uint8List.fromList(attachmentImageBytes)),width:280,height:220,fit:pw.BoxFit.contain))],
      pw.SizedBox(height:34),pw.Text('তৈরির সময়: ${DateTime.now().toLocal()}',style:pw.TextStyle(font:font,fontSize:9,color:PdfColors.grey700)),pw.SizedBox(height:34),pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[pw.Text('প্রস্তুতকারীর স্বাক্ষর: __________________',style:pw.TextStyle(font:font,fontSize:10)),pw.Text('গ্রহণকারীর স্বাক্ষর: __________________',style:pw.TextStyle(font:font,fontSize:10))]),
      pw.SizedBox(height:18),pw.Text('নোট: এটি অ্যাপ থেকে তৈরি নথি। অনুমোদন, স্বাক্ষর যাচাই বা সার্ভার রেকর্ডের প্রমাণ নয়।',style:pw.TextStyle(font:font,fontSize:8,color:PdfColors.grey700)),
    ]));
    final bytes=await doc.save();
    final base=await getApplicationDocumentsDirectory();
    final dir=Directory('${base.path}/somiti_documents/${type}'); await dir.create(recursive:true);
    final now=DateTime.now(); final id='${now.microsecondsSinceEpoch}';
    final file=File('${dir.path}/${_safe(type)}_$id.pdf'); await file.writeAsBytes(bytes,flush:true);
    final item=SavedDocument(id:id,title:title,type:type,path:file.path,createdAt:now.toIso8601String());
    final prefs=await SharedPreferences.getInstance(); final all=prefs.getStringList(_archiveKey)??[]; all.insert(0,jsonEncode(item.toJson())); await prefs.setStringList(_archiveKey,all);
    return item;
  }
  static Future<List<SavedDocument>> list() async {final p=await SharedPreferences.getInstance();return (p.getStringList(_archiveKey)??[]).map((s){try{return SavedDocument.fromJson(jsonDecode(s));}catch(_){return null;}}).whereType<SavedDocument>().where((d)=>File(d.path).existsSync()).toList();}
  static Future<void> delete(SavedDocument d) async {final f=File(d.path);if(await f.exists())await f.delete();final p=await SharedPreferences.getInstance();final all=p.getStringList(_archiveKey)??[];all.removeWhere((s){try{return SavedDocument.fromJson(jsonDecode(s)).id==d.id;}catch(_){return false;}});await p.setStringList(_archiveKey,all);}
  static Future<void> share(SavedDocument d) async {final f=File(d.path);if(await f.exists())await Share.shareXFiles([XFile(f.path)],text:d.title);}
  static Future<void> printDocument(SavedDocument d) async {final f=File(d.path);if(await f.exists())await Printing.layoutPdf(onLayout:(_)=>f.readAsBytes());}
  static Future<void> preview(SavedDocument d) async {final f=File(d.path);if(await f.exists())await Printing.layoutPdf(onLayout:(_)=>f.readAsBytes());}
}
