import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reconciler/parse_pdf_csv.dart';
import 'package:reconciler/reconcile.dart';
import 'package:universal_html/html.dart' as html;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Reconciler(),
    );
  }
}


typedef LeftData=Map<String,dynamic>;

extension LDataX on LeftData{
  ///if we still use Consts() for dcConstsProvider in genera_providers.dart,
  ///then keys,(like Consts().dataIdKey), below works
  int? get id=>this['id']; ///"id"
  DateTime get date{
    final dt=this['Transaction Date'];
    if((dt as String).contains('/')){
      final dl=(dt as String).split('/');
      if(int.parse(dl[0])>2000)
        return DateTime(int.parse(dl[0])%2000+2000,int.parse(dl[1]),int.parse(dl[2]));
      else
        return DateTime(int.parse(dl[2])%2000+2000,int.parse(dl[0]),int.parse(dl[1]));
    }else{
      final dl=(dt as String).split('-');
      if(int.parse(dl[0])>2000)
        return DateTime(int.parse(dl[0])%2000+2000,int.parse(dl[1]),int.parse(dl[2]));
      else
        return DateTime(int.parse(dl[2])%2000+2000,int.parse(dl[0]),int.parse(dl[1]));
    }
    // return null;
  }
  double get amount=>this['Amount (One column)'];
  String get desc=>this['Transaction Description'];
  String get searchText=>'$amount $desc'.toLowerCase();
}

typedef RightData=Map<String,dynamic>;

extension RDataX on RightData{
  ///if we still use Consts() for dcConstsProvider in genera_providers.dart,
  ///then keys,(like Consts().dataIdKey), below works
  int? get id=>this['id']; ///"id"

  double get amount=>this['amount'];
  String get desc=>this['description'];
  String get searchText=>'$amount $desc'.toLowerCase();
}


class Reconciler extends HookConsumerWidget {
  const Reconciler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lefts=useState<List<LeftData>>([]);
    final rights=useState<List<RightData>>([]);

    final edited=useState<List<SyncTxData>>([]);

    final dragging=useState(false);
    final showUnMatch=useState(true);
    final showMatch=useState(true);
    final showSave=useState(true);

    final descMatch=useState(true);
    final days=useState(3);

    final sDate=useState<DateTime?>(null);
    final eDate=useState<DateTime?>(null);
    final searchText=useState('');

    final fk=useMemoized(() => GlobalKey<FormBuilderState>());

    match(List<LeftData>left,List<RightData>right){
      final matched=edited.value.where((e) => e.matched);
      final paired=<SyncTxData>[];
      final leftSg=<LeftData>[];
      final rightCp=List.of(right);

      left.forEach((l) {
        final pr=rightCp.where((r){

          if(!(RDataX(r).amount==LDataX(l).amount&&
            (r.date.difference(l.date).abs().inDays<days.value)))return false;
          if(descMatch.value){
            RegExp regExp = RegExp(r"[^a-zA-Z0-9]");
            final dr=RDataX(r).desc.replaceAll(regExp, '').toLowerCase();
            final dl=LDataX(l).desc.replaceAll(regExp, '').toLowerCase();
            return dr.contains(dl)||dl.contains(dr);
          }
          return true;
        }
        );
        if(pr.isNotEmpty){
          paired.add(SyncTxData(left: l,right: pr.first));
          rightCp.removeWhere((e) => RDataX(e).id==RDataX(pr.first).id);
        }else leftSg.add(l);
      });

      leftSg.forEach((e)=>paired.add(SyncTxData(left: e)));
      rightCp.forEach((e)=>paired.add(SyncTxData(right: e)));

      edited.value=sortDate([...matched,...paired]);
    }

    useEffect((){
      match(lefts.value,rights.value);
    },[lefts.value,rights.value]);

    final leftUnMatched=List.of(edited.value).where((e) => (e.left!=null)&& (e.right==null)).length;
    final rightUnMatched=List.of(edited.value).where((e) => (e.left==null)&& (e.right!=null)).length;
    final matched=List.of(edited.value).where((e) => (e.left!=null)&& (e.right!=null)).length;

    return Scaffold(body: Column(children: [
      // ElevatedButton(onPressed: ()=>Navigator.push, child: Text('Upload Wave')),
      Row(children: [
        TextButton(onPressed: ()=>onUpload(lefts), child: Text('Upload Wave')),
        Text('$leftUnMatched/${leftUnMatched+matched}'),
        TextButton(onPressed: ()=>onUpload(rights), child: Text('Upload Chase')),
        Text('$rightUnMatched/${rightUnMatched+matched}'),
        IconButton(onPressed: (){lefts.value=[];rights.value=[];}, icon: Icon(Icons.refresh)),
        Spacer(),
        FilledButton(onPressed: (){
          String csvData = const ListToCsvConverter().convert(
              [
                ['Left Row#',...lefts.value.first.keys,
                  ...List.generate(26-lefts.value.first.length, (i) => ''),
                  'Right Row#',...rights.value.first.keys],
                ...edited.value.map((e) => e.entry)
              ]
          );

          final bytes = utf8.encode(csvData);
          downloadFile(bytes, "csv", 'All Matching Ts');
        }, child: Text('Export All')),
        FilledButton(onPressed: (){
          String csvData = const ListToCsvConverter().convert(
              [
                ['Left Row#',...lefts.value.first.keys,
                  ...List.generate(26-lefts.value.first.length, (i) => ''),
                  'Right Row#',...rights.value.first.keys],
                ...edited.value.where((e) => e.left==null||e.right==null).map((e) => e.entry)
              ]
          );

          final bytes = utf8.encode(csvData);
          downloadFile(bytes, "csv", 'UnMatched Ts');
        }, child: Text('Export Difference'))
      ],),
      Row(children: [
        Checkbox(value: showUnMatch.value, onChanged: (v)=>showUnMatch.value=v??false),
        Text('show un-matched (${edited.value.where((e) => !e.matched).length})        '),
        Checkbox(value: showMatch.value, onChanged: (v)=>showMatch.value=v??false),
        Text('show matched (${edited.value.where((e) => e.matched&&!e.saved).length})       '),
        Checkbox(value: showSave.value, onChanged: (v)=>showSave.value=v??false),
        Text('show saved (${edited.value.where((e) => e.saved).length})       '),
      ],),
      Row(children: [
        Checkbox(value: descMatch.value, onChanged: (v)=>descMatch.value=v??false),
        const Text('Description match        '),
        SizedBox(width:100,child:TextFormField(
          initialValue: days.value.toString(),
          onChanged: (v)=>days.value=int.parse(v),)),

        FilledButton(onPressed: (){
          match(edited.value.where((e) => !e.matched&&e.left!=null).map((e) => e.left!).toList(),
              edited.value.where((e) => !e.matched&&e.right!=null).map((e) => e.right!).toList());
        }, child: Text('MATCH')),
        FilledButton(onPressed: (){
          edited.value=List.of(edited.value.map((e) => e.matched?(e..saved=true):e));
        }, child: Text('SAVE'))
      ],),
      FormBuilder(key: fk,
          child: Row(children: [
            SizedBox(width:240,child:FormBuilderDateTimePicker(name: 'start',
              decoration: InputDecoration(labelText: 'Start Date',
                  suffixIcon: IconButton(icon: Icon(Icons.close),
                      onPressed: () => fk.currentState?.fields['start']?.didChange(null))),
              onChanged: (v)=>sDate.value=v,
            )),
            const SizedBox(width: 100,),
            SizedBox(width:240,child:FormBuilderDateTimePicker(name: 'end',
              decoration: InputDecoration(labelText: 'End Date',
                  suffixIcon: IconButton(icon: Icon(Icons.close),
                      onPressed: () => fk.currentState?.fields['end']?.didChange(null))),
              onChanged: (v)=>eDate.value=v,
            )),
            const SizedBox(width: 100,),
            Flexible(child: TextField(onChanged: (v)=>searchText.value=v,
              decoration: InputDecoration(prefixIcon:Icon(Icons.search_rounded),hintText: 'e.g. 1200.6 payment description..'),))
          ],)),
      Expanded(child: DragScrollable(dragging:dragging.value,
          builder: (sc){
            var data=(List.of(edited.value)..retainWhere((e) =>
            ((sDate.value==null||!sDate.value!.isAfter(e.date))&&
                (eDate.value==null||!eDate.value!.isBefore(e.date)))
                &&
            ((showSave.value&&e.saved)||
                (showMatch.value&&e.matched&&!e.saved)||
                (showUnMatch.value&&!e.matched))
            ));
            final st=searchText.value.trim();
            if(st.isNotEmpty) {
              data=data.where((e) => LDataX(e.left)?.searchText.contains(st)==true
                ||RDataX(e.right)?.searchText.contains(st)==true).toList();
            }
            return ListView.separated(controller: sc,physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: data.length,
              // prototypeItem: PldTxTile(data: data.first, allCases: allCases, setter: edited, dragging: dragging),
              itemBuilder: (BuildContext context, int index) {
                return PldTxTile(data: data[index], setter:edited, dragging: dragging,);
              },
              separatorBuilder: (BuildContext context, int index)=>Divider(),
            );}))
    ],),);
  }

  onUpload(ValueNotifier state)async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        withData: true,type:FileType.custom,
        allowedExtensions: ['csv']);
    if(result==null||result.files.isEmpty)
      return;

    final bytes=utf8.decode(result.files[0].bytes!);
    final r = const CsvToListConverter().convert(bytes);
    print(r);
    final data=(r.sublist(1))..removeWhere((cs) => cs.every((e){
      try{return e==null||(e is String&&e.isEmpty);
      }catch(er){print(e);rethrow;}
    }));

    state.value=List.generate(data.length, (i){
      final d=Map.fromIterables(r[0].cast<String>(),
          [...data[i],if(data[i].length<r[0].length)...List.generate(r[0].length-data[i].length,
                  (i) => '')]);
      return d..['id']=i;
    });
  }

}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


downloadFile(List<int> bytes,String type,String name,{String? blobType,String? uti})async{
  //Create blob and link from bytes
  final blob = html.Blob([bytes], blobType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = '$name.$type';
  html.document.body?.children.add(anchor);
  // download
  anchor.click();
  // cleanup
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}