import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reconciler/main.dart';

class SyncTxData{
  final LeftData? left;
  final RightData? right;
  bool saved;
  
  DateTime get date=>(left?.date??right?.date)!;
  String get id=>'${l_id}_${r_id}';
  int? get l_id=>LDataX(left)?.id;
  int? get r_id=>LDataX(right)?.id;
  bool get matched=>left!=null&&right!=null;
  List get entry=>[
    LDataX(left)?.id??'',
    ...(List.generate(26, (i){ if(left==null)return '';
      final l=left!.entries.map((e) => e.value).toList();
      return l.length<=i?'':l[i];
    })),
    RDataX(right)?.id??'',
    ...(right?.entries.map((e) => e.value)??[])
  ];

  SyncTxData({this.left,this.right,this.saved=false});
}

// class TsReconcilePage extends HookConsumerWidget {
//   final String? csid;
//   const TsReconcilePage({Key? key,this.csid,}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final testmyid=ref.watch(infoProvider.select((v) => v.value?.id))!;
//     final myid=testmyid!='0UrCXG6ZPUP9t3VPya5TTemHT8I3'?testmyid:'0vnZVb1yZ4h17YQeTlfz8V4Z4AP2';
//     //ref.watch(infoProvider.select((v) => v.value?.id))!;
//     final allCases=useMemoizedFuture(() => ref.read(firebaseFirestoreProvider).csRef().
//     where("members.$myid",isGreaterThanOrEqualTo: 0).get(),keys:[myid]);
//
//     final data=useStream(useMemoized((){
//       return ref.read(firebaseFirestoreProvider).userSyncTxRef(myid, 'cursor').snapshots();
//     },[]));
//     final loading=useState(false);
//     final syncDate=data.data?.data()?['syncDate'];
//     return DbFrame(title: 'Ledger Reconciliation',
//       actions: [
//         if(data.hasData&&(syncDate==null||DateTime.now().millisecondsSinceEpoch-syncDate>10*60*1000))Row(children: [
//           CaptionButton(text: 'Refresh From Bank',
//               loading: loading.value,
//               onPress: ()async{
//                 loading.value=true;
//                 final r=await ref.read(otherRepoProvider).postCloudFunc('/syncTransac', {'uid':myid});
//                 loading.value=false;
//                 if(r.error!=null)showDialog(context: context, builder: (context)=>tu_dialog(text: r.error,));
//               }),
//           width08,
//           if(syncDate!=null)Text('(last update ${formated(DateTime.fromMillisecondsSinceEpoch(data.data?.data()?['syncDate']))})'),
//           const QstTooltip(msg: "If there's any transaction not appearing on the 'Bank Transaction' column, try 'Refresh From Bank'. "
//               "Usually there could be at most a one day delay for Bank Transactions.")
//         ],)
//       ],
//       body: allCases.snapshot.hasData?
//       TsReconcile(allCases: allCases.snapshot.data!.docs.map((e) => Case.fromDoc(e)).toList(),
//           initialCsid: csid//allCases.snapshot.data!.docs[0].id,
//       ):
//       const Loading(),);
//   }
// }

// class TsReconcile extends HookConsumerWidget {
//   final String? initialCsid;
//   final List<Case> allCases;
//   const TsReconcile({Key? key,this.initialCsid, required this.allCases}) : super(key: key);
//
//   static const loadDaysDif=7;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final testmyid=ref.watch(infoProvider.select((v) => v.value?.id))!;
//     final myid=testmyid!='0UrCXG6ZPUP9t3VPya5TTemHT8I3'?testmyid:'0vnZVb1yZ4h17YQeTlfz8V4Z4AP2';
//     //ref.watch(infoProvider.select((v) => v.value?.id))!;
//     final filteredCase=useState(initialCsid==null?allCases:[allCases.singleWhere((cs) => cs.id==initialCsid)]);
//     final from=useState<int?>(DateTime.now().millisecondsSinceEpoch-30*24*3600*1000);
//     final till=useState<int?>(DateTime.now().millisecondsSinceEpoch);
//     final showFilter=useState(false);
//     final dragging=useState(false);
//
//     final plaidData=useStream(useMemoized((){
//       Query<Map<String,dynamic>> req=ref.read(firebaseFirestoreProvider).userSyncTxCol(myid);
//       if(from.value!=null)req=req.where('datetime',isGreaterThanOrEqualTo: from.value);
//       if(till.value!=null)req=req.where('datetime',isLessThanOrEqualTo: till.value);
//       return req.orderBy('datetime').snapshots();
//     },[from.value,till.value]));
//
//     final rawCsData=useStream(useMemoized((){
//       final streams=filteredCase.value.map((e){
//         Query<Map<String,dynamic>> req=ref.read(firebaseFirestoreProvider).tsRef(e.id!);
//
//         req=req.where('status',whereIn: [tsInt.manuelDB,tsInt.finished,tsInt.scheduled]);
//         if(from.value!=null)req=req.where('csBlDate',isGreaterThanOrEqualTo:
//         DateTime.fromMillisecondsSinceEpoch(from.value!-loadDaysDif*24*3600*1000).toIso8601String());
//         if(till.value!=null)req=req.where('csBlDate',isLessThanOrEqualTo:
//         DateTime.fromMillisecondsSinceEpoch(till.value!+loadDaysDif*24*3600*1000).toIso8601String());
//
//         return req.snapshots();
//       });
//
//       return StreamZip(streams);
//     },[from.value,till.value,...filteredCase.value]),preserveState: false);
//
//     final csData=rawCsData.data?.map((e) => e.docs).reduce((v, e) => v..addAll(e));
//
//     final loading=useState(false);
//
//     final showPending=useState(true);
//     final daysDiff=useState(5.0);
//     final csNameSimi=useState(true);
//     final ignoreSign=useState(false);
//
//     final bankTxRange=useState<DateTimeRange?>(null);
//     final tuTxRange=useState<DateTimeRange?>(null);
//     final bankTxQuery=useState('');
//     final tuTxQuery=useState('');
//
//
//     final data=plaidData.hasData&&rawCsData.hasData?
//     process(plaidData.requireData.docs.where((e) => e.id!='cursor').map((e) => e.data()).toList(),
//       csData!.map((e) => Transac.fromDoc(e)).toList(),
//       daysDiff.value,csNameSimi.value,ignoreSign.value,bankTxRange.value,tuTxRange.value,bankTxQuery.value,tuTxQuery.value,
//     ):null;
//
//     final edited=useState(data);
//
//     final dataKeys=data==null?[null]:data.isEmpty?[]:data.map((e) => [e.stsId,e.ts?.id,e.type]).reduce((v, e) => v..addAll(e));
//     useEffect((){
//       edited.value=data;
//     },dataKeys);
//
//     final dt=isdt;
//
//     return Column(children: [
//       Row(crossAxisAlignment:CrossAxisAlignment.center, children: [
//         Row(children: [
//           _buildDateFilter( 'from',from.value,(newVal){
//             from.value=newVal?.millisecondsSinceEpoch;
//           },(){from.value=null;}
//           ),width05,
//           Text("To".tr()),width05,
//           _buildDateFilter( 'to',till.value,(newVal){
//             till.value=newVal?.millisecondsSinceEpoch;
//           },(){till.value=null;}
//           )]),
//         const Spacer(),
//         Text('Matching Settings', style: AppTextStyle.body2,),
//         FilterIcon(showFilter: showFilter,
//           filterNum: showFilter.value||filteredCase.value.length==allCases.length?0:filteredCase.value.length,),
//       ],),
//
//       if(showFilter.value)...[
//         height16,
//         Flexible(child: Container(padding:vertical8,color:bgLight,child:ListView( shrinkWrap: true,padding: horizontal8,
//             children:[
//               Row(children: [
//                 Expanded(child: Row(children: [
//                   Text('Days Difference Tolerant:', style: AppTextStyle.body1),
//                   SizedBox(width: 60,height:40,child:cFormBuilderTextField(name: 'days',initial: daysDiff.value.toString(),numeric: true, required: false,
//                     onChanged: (v){
//                       if(v!=null&&double.tryParse(v)!=null)daysDiff.value=double.parse(v);
//                     },))
//                 ])),
//                 Expanded(child: Row(children: [
//                   Text('Similar Case Name Tolerant', style: AppTextStyle.body1,),
//                   Switch(value: csNameSimi.value,onChanged: (v)=>csNameSimi.value=v,activeColor: prm,)
//                 ],)),
//                 Expanded(child: Row(children: [
//                   Text('Ignore Sign(+-)', style: AppTextStyle.body1,),
//                   Switch(value: ignoreSign.value,onChanged: (v)=>ignoreSign.value=v,activeColor: prm)
//                 ],)),
//               ],),
//               height10,
//               Text('TrustUS transactions load from cases:', style: AppTextStyle.body1),
//               height8,
//               Wrap(children: allCases.map((cs){
//                 return SizedBox( width: 300,
//                   child: CheckboxListTile(value: filteredCase.value.any((ckcs) => cs.id==ckcs.id),
//                       title: Text(cs.name??''),onChanged: (v){
//                         filteredCase.value=List.of(v==true?[...filteredCase.value,cs]:filteredCase.value..removeWhere((ckcs) => cs.id==ckcs.id));
//                       }),
//                 );
//               }).toList(),)
//             ])))
//       ],
//
//       Row(crossAxisAlignment:CrossAxisAlignment.start, children: [
//         Expanded(child: ExpansionTile(collapsedBackgroundColor: bgDark, backgroundColor: bgDark,
//           title: Row(mainAxisSize:MainAxisSize.min, children: [
//             Text('Bank Transactions', style: AppTextStyle.h6),
//             const Spacer(),
//             Checkbox(value: showPending.value, onChanged: (v)=>showPending.value=v??false),
//             width05,
//             Text('hide confirmed transactions', style: AppTextStyle.body2),
//             width16
//           ],),
//           children: [if(edited.value!=null)Container(width: double.infinity,padding: horizontal32,
//               child: Text.rich(TextSpan(style: AppTextStyle.body2.copyWith(color: textGrey40), children: [
//                 ...(){
//                   final confirmed=edited.value!.where((e) => e.type<=1);
//                   final n=confirmed.length;
//                   if(n==0) return [];
//                   return[
//                     TextSpan(text: '$n transactions(${_getTotalAmount(confirmed)} total) confirmed linking,\n')];
//               }(),
//                 ...(){
//                   final bySys=edited.value!.where((e) => e.type==2);
//                   final n=bySys.length;
//                   if(n==0) return [];
//                   return[
//                     TextSpan(text: '$n transactions(${_getTotalAmount(bySys)} total) matched by system,\n')];
//               }(),
//                 // TextSpan(text: '${edited.value!.where((e) => e.type<=1).length} transactions confirmed linking, ${edited.value!.where((e) => e.type==2).length} transactions matched by system,\n'),
//
//                 ...(){
//                   final predictTu=edited.value!.where((e) => e.type==3);
//                   final n=predictTu.length;
//                   if(n==0) return [];
//                   return[
//                     TextSpan(text: '$n transactions(${_getTotalAmount(predictTu)} total)',style: const TextStyle(color: textGrey20)),
//                     const TextSpan(text: ' predicted as \'from TrustUS\' by system,\n')];
//               }(),
//
//                 ...(){
//                   final nMatch=edited.value!.where((e) => e.type==4||e.type==6);
//                   final n=nMatch.length;
//                   if(n==0) return [];
//                   return[
//                     TextSpan(text: '$n transactions(${_getTotalAmount(nMatch)} total)',style: const TextStyle(color: textGrey20)),
//                     const TextSpan(text: ' not matched'),
//                     const WidgetSpan(child: Icon(Icons.error,color: accentWarning,),)];
//               }(),
//               ]))),
//             height16,
//             Container(width: double.infinity,padding: horizontal32,
//                 child:Wrap(spacing:32,runSpacing:16,crossAxisAlignment: WrapCrossAlignment.center,children: [
//                   SizedBox(width: 260,child:FormBuilderDateRangePicker(name: 'left_range',
//                     allowClear: true, decoration: form_dec(bgColor: bgLight, hint: 'Bank Transfer Date Range',
//                         prefix: const Icon(Icons.date_range, color: uiGrey600)),
//                     firstDate: DateTime.now().subtract(const Duration(days: 730)),
//                     lastDate: DateTime.now().add(const Duration(days: 7)),initialValue: bankTxRange.value,
//                     onChanged: (v)=>bankTxRange.value=v,
//                     pickerBuilder: (ctx,c)=>dateRangePickerBuilder(context, dt, c),
//                   )),
//                   SizedBox(width: 360,child:TextFormField(
//                     decoration: form_dec(bgColor: bgLight, hint: 'e.g. -15.9 interest online..',prefix: const SearchIcon()),
//                     initialValue: bankTxQuery.value,onChanged: (v)=>bankTxQuery.value=v,)),
//                 ],)),
//             height05,
//           ],
//         )),
//         Expanded(child: ExpansionTile(collapsedBackgroundColor: bgDark, backgroundColor: bgDark,
//           title: Row(crossAxisAlignment:CrossAxisAlignment.end, children: [
//             Text('TrustUS Transactions', style: AppTextStyle.h6,),
//             width16,
//             Text.rich(TextSpan(style: AppTextStyle.caption.copyWith(color: textGrey40), children: const [
//               TextSpan(text: "Drag and drop transactions ",),
//               WidgetSpan(child: Icon(Icons.drag_indicator, size: 14),),
//               TextSpan(text: " tiles to manually match",),
//             ]),
//             ),
//           ]),
//           children: [
//             if(edited.value!=null)Container(width: double.infinity,padding: horizontal32,
//                 child: Text.rich(TextSpan(style: AppTextStyle.body2.copyWith(color: textGrey40), children: [
//                   TextSpan(text: '${csData!.length} Transactions within '
//                       '${formated(from.value==null?DateTime.now().subtract(const Duration(days: 730)):
//                   DateTime.fromMillisecondsSinceEpoch(from.value!-loadDaysDif*24*3600*1000))} ~ '
//                       '${formated(till.value==null?DateTime.now():
//                   DateTime.fromMillisecondsSinceEpoch(till.value!+loadDaysDif*24*3600*1000))}:\n'),
//
//                   ...(){
//                     final matched=edited.value!.where((e) => e.type==0||e.type==2);
//                     final n=matched.length;
//                     if(n==0) return [];
//                     return[
//                       TextSpan(text: '$n transactions(${_getTotalAmount(matched)} total) matched to bank ledger,\n')];
//                   }(),
//                   // TextSpan(text: '${edited.value!.where((e) => e.type==0||e.type==2).length} matched to bank ledger,\n'),
//
//                   TextSpan(text: (){
//                     final n=edited.value!.where((e) => e.type==5);
//                     if(n.isEmpty)return '0 transaction';
//                     num manu=0,real=0,manuTt=0,realTt=0;
//                     n.forEach((e) {
//                       if(e.ts!.status==tsInt.manuelDB){
//                         manu++;manuTt+=e.ts!.amount!*(e.ts!.credit?1:-1);
//                       }else{
//                         real++;realTt+=e.ts!.amount!*(e.ts!.credit?1:-1);
//                       }
//                     });
//
//                     return '${n.length} transactions(${manu} Manual ${formate_amount(manuTt)} total + ${real} Realtime ${formate_amount(realTt)} total)';
//                   }(),style: const TextStyle(color: textGrey20)),
//                   const TextSpan(text: ' not found on bank ledger')
//                 ]))),
//
//             height16,
//             Container(width: double.infinity,padding: horizontal32,
//                 child:Wrap(spacing:32,runSpacing:16,crossAxisAlignment: WrapCrossAlignment.center,children: [
//                   SizedBox(width: 260,child:FormBuilderDateRangePicker(name: 'left_range',
//                     allowClear: true, decoration: form_dec(bgColor: bgLight, hint: 'TrustUS Transfer Date Range',
//                         prefix: const Icon(Icons.date_range, color: uiGrey600)),
//                     firstDate: DateTime.now().subtract(const Duration(days: 730)),
//                     lastDate: DateTime.now().add(const Duration(days: 7)),initialValue: tuTxRange.value,
//                     onChanged: (v)=>tuTxRange.value=v,
//                     pickerBuilder: (ctx,c)=>dateRangePickerBuilder(context, dt, c),
//                   )),
//                   SizedBox(width: 360,child:TextFormField(
//                     decoration: form_dec(bgColor: bgLight, hint: 'e.g. -15.9 compensation gs-john-jane..',prefix: const SearchIcon()),
//                     initialValue: tuTxQuery.value,onChanged: (v)=>tuTxQuery.value=v,)),
//                 ],)),
//             height05,
//           ],
//         )),
//       ],),
//
//
//       Expanded(child: edited.value==null?const Loading():edited.value!.isEmpty?const EmptyList():
//       DragScrollable(dragging:dragging.value,
//           builder: (sc){
//             final data=showPending.value?(List.of(edited.value!)..retainWhere((e) => e.type>1)):edited.value!;
//             return ListView.builder(controller: sc,physics: const ClampingScrollPhysics(),
//               padding: vertical8,
//               itemCount: data.length,
//               // prototypeItem: PldTxTile(data: data.first, allCases: allCases, setter: edited, dragging: dragging),
//               itemBuilder: (BuildContext context, int index) {
//                 return PldTxTile(data: data[index], allCases: allCases,
//                   setter:edited, dragging: dragging,);
//               },
//             );})
//       ),
//       height8,
//       if(edited.value?.any((e) => e.isUpdate)==true)approveButton(onpress: ()async{
//         loading.value=true;
//         final batch=ref.read(firebaseFirestoreProvider).batch();
//         edited.value?.where((e) => e.isUpdate).forEach((e) =>
//             batch.set(ref.read(firebaseFirestoreProvider).userSyncTxRef(myid, e.stsId!),
//                 {'tslinked':e.ts?.id??(e.type==3?'':null)}, SetOptions(merge: true)));
//         await batch.commit();
//         loading.value=false;
//       },text: 'SAVE MATCHES',loading: loading.value,)
//     ],);
//   }
//
//   _getTotalAmount(Iterable<SyncTxData> tss)=>formate_amount(tss.map((e) => e.syncTx!['amount']).reduce((v, e) => v-e));
//
//   _buildDateFilter(
//       String titleText,
//       int? date,
//       Function(DateTime?) onChange,
//       VoidCallback onClear,
//       ) =>
//       SizedBox(height: filter_field_height, width: 260,
//           child: DateTimeField(
//             firstDate: DateTime.now().subtract(const Duration(days: 730)),
//             initialDate: DateTime.now(),
//             mode: DateTimeFieldPickerMode.date,
//             decoration: form_dec(
//                 bgColor: bgLight,
//                 hint: titleText,
//                 suffix: InkWell(
//                   onTap: onClear,
//                   child: const Icon(Icons.clear),
//                 )),
//             selectedDate: date==null?null:DateTime.fromMillisecondsSinceEpoch(date),
//             onDateSelected: onChange,
//           ));
//
//   ///type:
//   ///0 => matched, set
//   ///1 => set, confirmed
//   ///2 => matched, unset
//   ///3 => confirmed, unset
//   ///4 => no matched, unset
//   ///5 => extra tss
//   List<SyncTxData> process(List<Map<String,dynamic>> syncTx, List<Transac> ts,num daysDiff,bool csNameSimi,bool ignoreSign,
//       DateTimeRange? bankTxRange,DateTimeRange? tuTxRange,String bankTxQuery,String tuTxQuery,){
//     var r=<SyncTxData>[];
//     for(int i=syncTx.length-1;i>0;i--){
//       final String? txId=syncTx[i]['tslinked'];
//       if((txId??'').isNotEmpty){
//         final linked=ts.indexWhere((v)=>v.id==txId);
//         r.add(SyncTxData(syncTx: syncTx[i],ts: linked==-1?null:ts[linked],type: linked==-1?1:0));
//         syncTx.removeAt(i);
//         if(linked!=-1)ts.removeAt(linked);
//       }else if(txId==''){
//         r.add(SyncTxData(syncTx: syncTx[i], type: 1));
//         syncTx.removeAt(i);
//       }
//     }
//     for(int i=syncTx.length-1;i>0;i--){
//       final num amount=-syncTx[i]['amount'];
//       final DateTime date= DateTime.fromMillisecondsSinceEpoch(syncTx[i]['datetime']);
//
//       final parsedData=parseData(syncTx[i]);
//
//       final matched=ts.where((ts){
//         final catMatch=(parsedData?['cate']==null?true:ts.category==parsedData!['cate'])&&
//             (parsedData?['cateDetail']==null?true:ts.categoryDetail==parsedData!['cateDetail']);
//         final caseMatch=parsedData?['case']==null?true:!csNameSimi?
//         allCases.singleWhere((e) => e.id==ts.csid).name==parsedData!['case']:
//         caseNameSimilar(allCases.singleWhere((e) => e.id==ts.csid).name??'',parsedData!['case']);
//         final amountMatch=ignoreSign?ts.amount!.abs()==amount.abs():ts.amount!*(ts.credit?1:-1)==amount;
//         // if(syncTx[i]['name'].contains('I6BXE9G2E GS-SU-WANG-MARTIN ÝTravel¨--ÝLodging¨ (TrustUS')&&ts.category==1&&ts.categoryDetail==7&&ts.amount!-711.01<1){
//         //   print(ts);
//         //   print(catMatch);print(allCases.singleWhere((e) => e.id==ts.csid).name);print(ts.amount!-711.01);
//         //   print(ts.amount!*(ts.credit?1:-1)==amount && ts.csBlDate!=null);
//         //   print(ts.csBlDate!.difference(date).inMinutes.abs()<4*24*60);
//         // }
//         return catMatch && caseMatch && amountMatch
//             && ts.csBlDate!=null
//             && ts.csBlDate!.difference(date).inMinutes.abs()<daysDiff*24*60;
//       }).sorted((t1,t2) => t1.csBlDate!.difference(date).inMinutes.abs()-t2.csBlDate!.difference(date).inMinutes.abs());
//
//       if(matched.isNotEmpty){
//         final linked=ts.indexWhere((v)=>v.id==matched[0].id);
//         r.add(SyncTxData(syncTx: syncTx[i],ts: ts[linked],type: 2));
//         syncTx.removeAt(i);
//         ts.removeAt(linked);
//       }else if(parsedData!=null){
//         r.add(SyncTxData(syncTx: syncTx[i], type: 4));
//         syncTx.removeAt(i);
//       } else{
//         r.add(SyncTxData(syncTx: syncTx[i], type: 4));
//         syncTx.removeAt(i);
//       }
//     }
//     r.addAll(ts.map((e) => SyncTxData(ts:e, type: 5)));
//
//     final bankFilter=bankTxRange!=null||bankTxQuery.isNotEmpty;
//     final tuFilter=tuTxRange!=null||tuTxQuery.isNotEmpty;
//     if(bankFilter||tuFilter){
//       final bankWords=bankTxQuery.toLowerCase().split(' ').map((e) => formatWord(e));
//       final tuWords=tuTxQuery.toLowerCase().split(' ').map((e) => formatWord(e));
//
//       r=r.where((e){
//         final bankDate=e.syncTx==null?null:DateTime.fromMillisecondsSinceEpoch(e.syncTx!['datetime']);
//
//         return (bankFilter&&bankDate!=null&&((bankTxRange==null||(!bankTxRange.start.isAfter(bankDate)&&!bankTxRange.end.isBefore(bankDate)))&&
//             (bankTxQuery.isEmpty||bankWords.every((word) =>
//                 makeBankTxDescription(e.syncTx!).contains(word)))))||
//             (tuFilter&&e.ts!=null&&((tuTxRange==null||(!tuTxRange.start.isAfter(e.ts!.csBlDate!)&&!tuTxRange.end.isBefore(e.ts!.csBlDate!)))&&
//                 (tuTxQuery.isEmpty||tuWords.every((word) =>
//                     makeTuTxDescription(e.ts!).contains(word)))));
//       }).toList();
//     }
//
//     return sortDate(r);
//   }
//
//   String makeBankTxDescription(Map<String,dynamic> tx)=>'${formate_amount(-tx['amount'])}  '
//       '${formated(DateTime.fromMillisecondsSinceEpoch(tx['datetime']))}  '
//       '${tx['merchant_name']??''}  '
//       '${tx['name']}'.toLowerCase();
//
//   String makeTuTxDescription(Transac ts)=>'${formate_amount(ts.amount!*(ts.credit?1:-1))}  '
//       '${allCases.singleWhereOrNull((e) => e.id==ts.csid)?.name??''}  '
//       '${tsInt.getCategoryName(ts.category)}  '
//       '${tsInt.getCategoryDetailName(ts.categoryDetail)}  '
//       '${ts.statement??''}'.toLowerCase();
//
//   String formatWord(String word){
//     final num=double.tryParse(word.replaceAll('\$', ''));
//     return num==null?word:formate_amount(num);
//   }
//
//   ///reverse sort by date -> amount
//
//   static Map<String,dynamic>? parseData(Map<String,dynamic> syncTx){
//     String statement=syncTx['name']??'';
//     if(pattern.hasMatch(statement)){
//
//       final segs=statement.split(' ');
//       final cates=segs[1].split('--');
//       final cate=tsInt.categories.indexOf(cates[0].replaceAll('[', '').replaceAll(']', ''));
//       final catDetail=tsInt.detailCate.indexOf(cates[1].replaceAll('[', '').replaceAll(']', ''));
//       final ymd=[int.tryParse(segs[6].substring(0,4)),
//         months.indexOf(segs[4])+1,
//         int.tryParse(segs[5].substring(0,2))];
//       if(cate==-1||catDetail==-1||ymd.any((e) => (e??0)==0))return {};
//       final tsDate=DateTime(ymd[0]!,ymd[1]!,ymd[2]!);
//       return {'cate':cate,'cateDetail':catDetail,'date':tsDate,'case':segs[0]};
//     }else if(pattern1.hasMatch(statement)||pattern2.hasMatch(statement)){
//       statement=statement.substring(48);
//       final segs=statement.split(' ');
//       if(segs.length<=2)return {};
//       final cates=segs.sublist(2).join(' ').split('¨');
//       if(cates.length==1)return{'case':segs[1]};
//       final cate=tsInt.categories.indexOf(cates[0].substring(1));
//       if(cates.length==2||cate==-1)return{'case':segs[1],if(cate!=-1)'cate':cate};
//       final catDetail=tsInt.detailCate.sublist(cate==0?0:tsInt.cateDetailRage[cate-1],
//           tsInt.cateDetailRage[cate]).indexOf(cates[1].substring(3));
//       return {'case':segs[1],if(cate!=-1)'cate':cate,
//         if(catDetail!=-1)'cateDetail':catDetail+(cate==0?0:tsInt.cateDetailRage[cate-1])};
//     }
//   }
//
//   static bool caseNameSimilar(String a,String b){
//     final al=a.split('-')..remove('');
//     final bl=b.split('-')..remove('');
//     return al.length>=3&&bl.length>=3&&
//         (al.toSet().difference(bl.toSet()).length
//             + bl.toSet().difference(al.toSet()).length <=1);
//   }
//
//   static RegExp pattern = RegExp(r'^([A-Z]+-)*[A-Z]+ \[.*\]--\[.*\] \(TrustUS Date (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{2}, \d{4}\).*$');
//   static RegExp pattern1 = RegExp(r'^BUSINESS TO BUSINESS ACH TrustUS INC TrustUS IN [A-Za-z0-9]+ ([A-Z]+-)*[A-Z]+ Ý.*¨--Ý.*¨.*$');
//   static RegExp pattern2 = RegExp(r'^BUSINESS TO BUSINESS ACH TrustUS INC TrustUS IN [A-Za-z0-9]+ ([A-Z]+-)*[A-Z]+ .*$');
// }


class DragScrollable extends HookConsumerWidget {
  final Widget Function(ScrollController) builder;
  final bool dragging;
  const DragScrollable({
    Key? key,required this.builder,required this.dragging,
  }) : super(key: key);

  static const _gridViewHeight=360;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scroller=useScrollController();

    return Stack(children: [
      builder(scroller),
      if(dragging)Align(
        alignment: Alignment.topCenter,
        child: DragTarget(
          builder: (context, accepted, rejected) => Container(
            height: 40,
            width: double.infinity,
            color: Colors.white.withOpacity(0.04),
            child: const Icon(Icons.keyboard_double_arrow_up),
          ),
          onWillAccept: (accept) {
            scroller.animateTo(scroller.offset - _gridViewHeight,
                curve: Curves.linear, duration: const Duration(milliseconds: 700));
            return false;
          },
        ),
      ),
      if(dragging)Align(
        alignment: Alignment.bottomCenter,
        child: DragTarget(
          builder: (context, accepted, rejected) => Container(
            height: 40,
            width: double.infinity,
            color: Colors.white.withOpacity(0.04),
            child: const Icon(Icons.keyboard_double_arrow_down),
          ),
          onWillAcceptWithDetails: (accept) {
            scroller.animateTo(scroller.offset + _gridViewHeight,
                curve: Curves.linear, duration: const Duration(milliseconds: 500));
            return false;
          },
        ),
      )
    ],);
  }
}

class PldTxTile extends HookConsumerWidget {
  final SyncTxData data;
  final ValueNotifier<bool> dragging;
  final ValueNotifier<List<SyncTxData>> setter;
  const PldTxTile({
    super.key, required this.data, required this.setter,required this.dragging
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return IntrinsicHeight( child: Row(crossAxisAlignment:CrossAxisAlignment.stretch,children: [
      Expanded(child:buildHalf(data.left,true)),

      Expanded(child: data.saved?Text('SAVED',style: TextStyle(color: Colors.green),):
      data.matched?TextButton(onPressed: (){
        final rest=setter.value.where((e) => e.id!=data.id).toList();
        rest.addAll([
          SyncTxData(left: data.left),
          SyncTxData(right: data.right)
        ]);
        setter.value=sortDate(rest);
      }, child: Text('unmatch')):Container()),
      Expanded(child: buildHalf(data.right,false)),
      // TextButton(onPressed: onPressed, child: Text())
    ],));
  }

  Widget buildHalf(Map<String,dynamic>? dt,bool left){
    if(dt!=null)return Draggable<SyncTxData>(feedback: Card(child: tsContent(left),), data: data,
      child: tsContent(left),
      onDragCompleted: ()=>dragging.value=false, onDraggableCanceled: (v,offset)=>dragging.value=false,
      onDragStarted: ()=>dragging.value=true, onDragEnd: (dt)=>dragging.value=false,);

    return DragTarget<SyncTxData>(builder: (context,candidate,rejected){
      return Container(height: double.infinity, width:double.infinity ,
        color: dragging.value?candidate.any((e) => e!=null&&canMatch(e, data))?Colors.black26:Colors.black45:null,
        alignment: Alignment.topLeft,);
    },
      onAcceptWithDetails: (coming){
      // if((coming.data.left!=null&&data.left!=null)||(coming.data.right!=null&&data.right!=null))return;
        final rest=setter.value.where((e) => e.id!=data.id&&coming.data.id!=e.id).toList();
        rest.add(SyncTxData(left: data.left??coming.data.left,right: data.right??coming.data.right));
        setter.value=sortDate(rest);
      },
      onWillAcceptWithDetails: (coming)=>canMatch(coming.data, data),);
  }

  bool canMatch(SyncTxData a,SyncTxData b)=>!(a.left!=null&&b.left!=null)||(a.right!=null&&b.right!=null);

  Widget tsContent(bool left){
    final ts=(left?data.left:data.right)!;
    // print(ts);
    // print(ts);
    return Container(constraints: const BoxConstraints(maxWidth: 500), child:ListTile(
      title:Row(children:[
        Text('${(left?LDataX(ts).id!+2:RDataX(ts).id)}'),
        SizedBox(width: 16,),
        Text('${(left?LDataX(ts).amount:RDataX(ts).amount)}')
      ],),
      subtitle: Text('${(left?LDataX(ts).desc:RDataX(ts).desc)}'),
      trailing: Text('${ts.date}'),
    ));
  }



  String mapText(Map<String,dynamic> data)=>data.entries.where((e) => e.value!=null).map((e) => '${e.key}: ${e.value}').join(';\n');
}

List<SyncTxData> sortDate(List<SyncTxData> r)=>r.sorted((b, a)=>a.date.compareTo(b.date));
