import 'package:flutter/material.dart';
import '../models/expense.dart';import '../services/app_state.dart';
import '../utils/cats.dart';import '../theme/app_theme.dart';

void showAddSheet(BuildContext ctx,{Expense? existing})=>showModalBottomSheet(
  context:ctx,isScrollControlled:true,backgroundColor:Colors.transparent,
  builder:(_)=>AddExpenseSheet(existing:existing));

class ExpenseTile extends StatelessWidget{
  final Expense e;
  const ExpenseTile({super.key,required this.e});
  void _del(BuildContext ctx)=>showDialog(context:ctx,builder:(dlg)=>AlertDialog(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
    title:const Text('Delete Expense',style:TextStyle(fontWeight:FontWeight.w800)),
    content:Text('Remove "${e.title}"?'),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(dlg),child:Text('Cancel',style:TextStyle(color:Colors.grey.shade500))),
      ElevatedButton(onPressed:(){AppState.of(ctx).exp.remove(e.id);Navigator.pop(dlg);},
        style:ElevatedButton.styleFrom(backgroundColor:Colors.red.shade400,foregroundColor:Colors.white,
            elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
        child:const Text('Delete')),
    ]));
  @override
  Widget build(BuildContext ctx){
    final info=catInfo(e.category);final cur=AppState.of(ctx).exp.cur;
    return Dismissible(
      key:Key(e.id),
      background:_bg(Alignment.centerLeft,kP,Icons.edit_rounded,'Edit'),
      secondaryBackground:_bg(Alignment.centerRight,Colors.red.shade400,Icons.delete_rounded,'Delete'),
      confirmDismiss:(dir)async{dir==DismissDirection.startToEnd?showAddSheet(ctx,existing:e):_del(ctx);return false;},
      child:GestureDetector(onLongPress:()=>_menu(ctx),
        child:Container(
          margin:const EdgeInsets.symmetric(horizontal:16,vertical:5),
          padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(color:Theme.of(ctx).cardColor,borderRadius:BorderRadius.circular(18),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04),blurRadius:12,offset:const Offset(0,3))]),
          child:Row(children:[
            Container(width:46,height:46,
              decoration:BoxDecoration(color:(info['color']as Color).withOpacity(.12),borderRadius:BorderRadius.circular(14)),
              child:Icon(info['icon']as IconData,color:info['color']as Color,size:22)),
            const SizedBox(width:14),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(e.title,style:TextStyle(fontWeight:FontWeight.w600,fontSize:15,color:Theme.of(ctx).colorScheme.onSurface)),
              const SizedBox(height:2),
              Row(children:[
                Text(e.category,style:TextStyle(color:Colors.grey.shade500,fontSize:12,fontWeight:FontWeight.w500)),
                if(e.note.isNotEmpty)...[
                  Text('  ·  ',style:TextStyle(color:Colors.grey.shade400)),
                  Flexible(child:Text(e.note,style:TextStyle(color:Colors.grey.shade400,fontSize:11),overflow:TextOverflow.ellipsis)),
                ],
              ]),
            ])),
            const SizedBox(width:10),
            Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
              Text('$cur${e.amount.toInt()}',style:TextStyle(fontWeight:FontWeight.w800,fontSize:16,color:Theme.of(ctx).colorScheme.onSurface)),
              const SizedBox(height:2),
              Text(_fmt(e.date),style:TextStyle(color:Colors.grey.shade400,fontSize:11)),
            ]),
            const SizedBox(width:4),Icon(Icons.more_vert_rounded,size:16,color:Colors.grey.shade300),
          ]))));
  }
  Widget _bg(Alignment a,Color c,IconData icon,String l)=>Container(
    margin:const EdgeInsets.symmetric(horizontal:16,vertical:5),
    decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(18)),
    alignment:a,padding:const EdgeInsets.symmetric(horizontal:20),
    child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,color:Colors.white,size:22),const SizedBox(height:4),
      Text(l,style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
    ]));
  void _menu(BuildContext ctx)=>showModalBottomSheet(context:ctx,backgroundColor:Colors.transparent,
    builder:(sh){
      final info=catInfo(e.category);final cur=AppState.of(ctx).exp.cur;
      return Container(margin:const EdgeInsets.fromLTRB(16,0,16,28),
        decoration:BoxDecoration(color:Theme.of(ctx).cardColor,borderRadius:BorderRadius.circular(28)),
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          const SizedBox(height:12),
          Container(width:44,height:4,decoration:BoxDecoration(color:Colors.grey.shade300,borderRadius:BorderRadius.circular(2))),
          Padding(padding:const EdgeInsets.fromLTRB(20,18,20,4),child:Row(children:[
            Container(padding:const EdgeInsets.all(10),
              decoration:BoxDecoration(color:(info['color']as Color).withOpacity(.12),borderRadius:BorderRadius.circular(12)),
              child:Icon(info['icon']as IconData,color:info['color']as Color,size:20)),
            const SizedBox(width:14),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(e.title,style:TextStyle(fontWeight:FontWeight.w700,fontSize:16,color:Theme.of(ctx).colorScheme.onSurface)),
              Text('$cur${e.amount.toInt()} · ${e.category}',style:TextStyle(color:Colors.grey.shade500,fontSize:13)),
            ])),
          ])),
          const Divider(height:20),
          _mi(sh,Icons.edit_rounded,'Edit',kP,(){Navigator.pop(sh);showAddSheet(ctx,existing:e);}),
          _mi(sh,Icons.delete_rounded,'Delete',Colors.red.shade400,(){Navigator.pop(sh);_del(ctx);}),
          const SizedBox(height:10),
        ]));
    });
  Widget _mi(BuildContext sh,IconData icon,String l,Color c,VoidCallback fn)=>ListTile(onTap:fn,
    leading:Container(padding:const EdgeInsets.all(8),
      decoration:BoxDecoration(color:c.withOpacity(.1),borderRadius:BorderRadius.circular(10)),
      child:Icon(icon,color:c,size:20)),
    title:Text(l,style:TextStyle(fontWeight:FontWeight.w600,color:c,fontSize:15)));
  String _fmt(DateTime d){
    final n=DateTime.now();
    if(d.year==n.year&&d.month==n.month&&d.day==n.day)return'Today';
    final y=n.subtract(const Duration(days:1));
    if(d.year==y.year&&d.month==y.month&&d.day==y.day)return'Yesterday';
    const m=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return'${m[d.month]} ${d.day}';
  }
}

// ─── ADD/EDIT SHEET ───────────────────────────────────────────────────────────
class AddExpenseSheet extends StatefulWidget{
  final Expense? existing;
  const AddExpenseSheet({super.key,this.existing});
  @override State<AddExpenseSheet> createState()=>_AES();
}
class _AES extends State<AddExpenseSheet>{
  late final TextEditingController _tc,_ac,_nc;
  late String _cat;late DateTime _date;
  bool get _edit=>widget.existing!=null;
  @override void initState(){
    super.initState();final ex=widget.existing;
    _tc=TextEditingController(text:ex?.title??'');
    _ac=TextEditingController(text:ex!=null?ex.amount.toInt().toString():'');
    _nc=TextEditingController(text:ex?.note??'');
    _cat=ex?.category??'Food';_date=ex?.date??DateTime.now();
  }
  @override void dispose(){_tc.dispose();_ac.dispose();_nc.dispose();super.dispose();}
  @override
  Widget build(BuildContext ctx){
    final cur=AppState.of(ctx).exp.cur;
    return Container(
      height:MediaQuery.of(ctx).size.height*.90,
      decoration:BoxDecoration(color:Theme.of(ctx).cardColor,
          borderRadius:const BorderRadius.vertical(top:Radius.circular(30))),
      child:Column(children:[
        const SizedBox(height:12),
        Container(width:44,height:4,decoration:BoxDecoration(color:Colors.grey.shade300,borderRadius:BorderRadius.circular(2))),
        const SizedBox(height:20),
        Text(_edit?'Edit Expense':'New Expense',style:TextStyle(fontSize:21,fontWeight:FontWeight.w800,color:Theme.of(ctx).colorScheme.onSurface)),
        const SizedBox(height:20),
        Expanded(child:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:24),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _amt(cur),const SizedBox(height:18),
            _fld(_tc,'Title',Icons.title_rounded),const SizedBox(height:14),
            _cats(),const SizedBox(height:14),
            _datePick(),const SizedBox(height:14),
            _fld(_nc,'Note (optional)',Icons.notes_rounded),const SizedBox(height:30),
            _saveBtn(),const SizedBox(height:28),
          ]))),
      ]));
  }
  Widget _amt(String cur)=>Container(
    padding:const EdgeInsets.all(22),
    decoration:BoxDecoration(gradient:const LinearGradient(colors:[kD,kL]),borderRadius:BorderRadius.circular(22)),
    child:Column(children:[
      const Text('Amount',style:TextStyle(color:Colors.white70,fontSize:13)),
      Row(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.only(top:10),child:Text(cur,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w700))),
        IntrinsicWidth(child:TextField(controller:_ac,keyboardType:TextInputType.number,textAlign:TextAlign.center,
          style:const TextStyle(color:Colors.white,fontSize:46,fontWeight:FontWeight.w900,letterSpacing:-1),
          decoration:const InputDecoration(hintText:'0',hintStyle:TextStyle(color:Colors.white38,fontSize:46,fontWeight:FontWeight.w900),
              border:InputBorder.none,isDense:true,contentPadding:EdgeInsets.zero))),
      ]),
    ]));
  Widget _fld(TextEditingController c,String h,IconData icon)=>Container(
    decoration:BoxDecoration(color:Theme.of(context).scaffoldBackgroundColor,borderRadius:BorderRadius.circular(16)),
    child:TextField(controller:c,decoration:InputDecoration(hintText:h,hintStyle:TextStyle(color:Colors.grey.shade400),
        prefixIcon:Icon(icon,color:kP,size:20),border:InputBorder.none,
        contentPadding:const EdgeInsets.symmetric(vertical:16))));
  Widget _cats()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text('Category',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14,color:Theme.of(context).colorScheme.onSurface)),
    const SizedBox(height:10),
    Wrap(spacing:8,runSpacing:8,children:kCats.map((cat){
      final info=catInfo(cat);final sel=cat==_cat;
      return GestureDetector(onTap:()=>setState(()=>_cat=cat),
        child:AnimatedContainer(duration:const Duration(milliseconds:160),
          padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),
          decoration:BoxDecoration(
            color:sel?(info['color']as Color).withOpacity(.13):Theme.of(context).scaffoldBackgroundColor,
            borderRadius:BorderRadius.circular(12),
            border:Border.all(color:sel?info['color']as Color:Colors.transparent,width:1.5)),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            Icon(info['icon']as IconData,color:sel?info['color']as Color:Colors.grey.shade400,size:16),
            const SizedBox(width:6),
            Text(cat,style:TextStyle(color:sel?info['color']as Color:Colors.grey.shade600,
                fontWeight:sel?FontWeight.w700:FontWeight.w500,fontSize:13)),
          ])));
    }).toList()),
  ]);
  Widget _datePick(){
    const mn=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final t=_date.day==DateTime.now().day&&_date.month==DateTime.now().month;
    return GestureDetector(onTap:()async{
        final p=await showDatePicker(context:context,initialDate:_date,firstDate:DateTime(2020),lastDate:DateTime.now(),
          builder:(ctx,c)=>Theme(data:Theme.of(ctx).copyWith(colorScheme:const ColorScheme.light(primary:kP)),child:c!));
        if(p!=null)setState(()=>_date=p);},
      child:Container(padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:Theme.of(context).scaffoldBackgroundColor,borderRadius:BorderRadius.circular(16)),
        child:Row(children:[
          const Icon(Icons.calendar_today_rounded,color:kP,size:20),const SizedBox(width:12),
          Text(t?'Today':'${mn[_date.month]} ${_date.day}, ${_date.year}',
              style:TextStyle(fontWeight:FontWeight.w500,color:Theme.of(context).colorScheme.onSurface)),
          const Spacer(),const Icon(Icons.arrow_forward_ios_rounded,size:14,color:Colors.grey),
        ])));
  }
  Widget _saveBtn()=>SizedBox(width:double.infinity,height:56,
    child:ElevatedButton(onPressed:_save,
      style:ElevatedButton.styleFrom(backgroundColor:kP,foregroundColor:Colors.white,elevation:0,
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),
      child:Text(_edit?'Save Changes':'Save Expense',style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16))));
  Future<void> _save()async{
    final t=_tc.text.trim();final a=double.tryParse(_ac.text.trim())??0;
    if(t.isEmpty||a<=0)return;
    final ex=Expense(id:_edit?widget.existing!.id:DateTime.now().millisecondsSinceEpoch.toString(),
        title:t,amount:a,category:_cat,date:_date,note:_nc.text.trim());
    final s=AppState.of(context).exp;
    if(_edit)await s.update(ex);else await s.add(ex);
    if(mounted)Navigator.pop(context);
  }
}
