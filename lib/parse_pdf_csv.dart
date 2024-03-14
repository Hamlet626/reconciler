import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'main.dart';

class PdfCsvParser extends HookConsumerWidget {
  const PdfCsvParser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content=useState(<dynamic>[]);
    return Scaffold(body: Column(children: [
      Row(children: [
        TextButton(onPressed: ()=>onUploadPdfCsv(), child: Text('Upload')),
        // TextButton(onPressed: ()=>onUpload(lefts), child: Text('download')),
      ],)
    ],),);
  }

  static const secKeys=[
    'DEPOSITS AND ADDITIONS',
    'ATM & DEBIT CARD WITHDRAWALS',
    'ELECTRONIC WITHDRAWALS',
    'FEES'
  ];
  onUploadPdfCsv()async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,type:FileType.custom,
        allowedExtensions: ['csv']);
    if(result==null||result.files.isEmpty)
      return;

    final bytes=utf8.decode(result.files[0].bytes!);
    List<String> r = const CsvToListConverter().convert(bytes)[0][0].split('"');


    // print(r);
    r=r.map((e)=>e.trim()).toList()..removeWhere((e) => e.isEmpty);
    print(r);
    final tss=r.map((e){
      // if(e.length!=1)return null;
      // if(e[0] is! String)return null;
      if(secKeys.contains(e))return e;
      if(RegExp(r'^DATE\s+DESCRIPTION\s+AMOUNT$').hasMatch(e))return 'title';
      var segments=(e as String).split('                  ');
      segments=segments.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if(segments.length<2)return null;
      print(segments);
      if(!RegExp(r'^\b\d{2}/\d{2}\b$').hasMatch(segments[0]))return null;
      if(!RegExp(r'^\$?\d{1,3}(,\d{3})*(\.\d{1,2})?$').hasMatch(segments.last))return null;
      return [
        '${segments[0]}/$year',
        e.substring(0,e.length-segments.last.length).replaceFirst(segments[0], '').trim(),
        segments.last.replaceAll('\$', '').replaceAll(',', '')
      ];
    });//.where((e) => e!=null).toList().cast<List>();

    print(tss);

    final prit=[
      ['Transaction Date','Description',
        'Amount','Category'],
    ];

    String? cate;
    bool canadd=false;
    tss.forEach((e) {
      if(e=='title'){canadd=true;return;}
      if(e==null){
      }
      else if(e is String){
        cate=e;
      }
      else {
        e=e as List;
        if(cate!=null&&canadd) {
          prit.add(cate==secKeys[0]?
          [e[0],e[1],'-${e[2]}',cate!]:[...e,cate!]);
          canadd=true;
          return;
        }
      }
        canadd=false;
    });

    String csvData = const ListToCsvConverter().convert(
        prit
    );

    final byte = utf8.encode(csvData);
    downloadFile(byte, "csv", 'Chase ${year}');
  }
}


const year=2020;