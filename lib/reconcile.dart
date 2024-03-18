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
