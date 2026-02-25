import 'package:flutter/material.dart';
import '../../services/app_state.dart';import '../../utils/cats.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget{const SettingsScreen({super.key});
  @override State<SettingsScreen> createState()=>_SS();}
class _SS extends State<SettingsScreen>{
  @override
  Widget build(BuildContext ctx){
    final s=AppState.of(ctx);final exp=s.exp;
    return Scaffold(backgroundColor:Theme.of(ctx).scaffoldBackgroundColor,
      appBar:AppBar(backgroundColor:Theme.of(ctx).cardColor,elevation:0,
        title:Text('Settings',style:TextStyle(fontWeight:FontWeight.w800,fontSize:22,color:Theme.of(ctx).colorScheme.onSurface))),
      body:SingleChildScrollView(padding:const EdgeInsets.all(20),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _sec('Preferences'),const SizedBox(height:10),
          _card(ctx,[
            _row(ctx,Icons.savings_rounded,'Monthly Budget','${exp.cur}${exp.budget.toInt()}',const Color(0xFF22C55E),()=>_budgetDlg(ctx)),
            _div(),
            _row(ctx,Icons.currency_exchange_rounded,'Currency',exp.cur,Colors.blue,()=>_curDlg(ctx)),
            _div(),
            ValueListenableBuilder(valueListenable:s.dark,builder:(_,dk,__)=>SwitchListTile(
              secondary:_ico(dk?Icons.light_mode_rounded:Icons.dark_mode_rounded,Colors.purple),
              title:Text('Dark Mode',style:TextStyle(fontWeight:FontWeight.w600,color:Theme.of(ctx).colorScheme.onSurface)),
              value:dk,activeColor:kP,onChanged:(v)=>s.dark.value=v)),
          ]),
          const SizedBox(height:24),
          _sec('Data'),const SizedBox(height:10),
          _card(ctx,[
            _row(ctx,Icons.download_rounded,'Export to CSV','Save all expenses',Colors.teal,()async{
              final path=await exp.exportCSV();
              if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:Text('Exported: $path'),backgroundColor:kP,behavior:SnackBarBehavior.floating));
            }),
            _div(),
            _row(ctx,Icons.delete_forever_rounded,'Delete All Expenses','Clear all records',Colors.red,()=>_delAllDlg(ctx)),
          ]),
          const SizedBox(height:24),
          _sec('About'),const SizedBox(height:10),
          _card(ctx,[
            _row(ctx,Icons.info_outline_rounded,'Version','1.0.0 · ExpenseFlow',Colors.grey,(){}),
            _div(),
            _row(ctx,Icons.code_rounded,'Built with','Flutter · Dart',Colors.blue,(){}),
          ]),
          const SizedBox(height:40),
        ])));
  }
  Widget _sec(String t)=>Padding(padding:const EdgeInsets.only(left:4),
    child:Text(t,style:TextStyle(fontWeight:FontWeight.w700,fontSize:13,color:Colors.grey.shade500,letterSpacing:.5)));
  Widget _card(BuildContext ctx,List<Widget> ch)=>Container(
    decoration:BoxDecoration(color:Theme.of(ctx).cardColor,borderRadius:BorderRadius.circular(22),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.05),blurRadius:12,offset:const Offset(0,3))]),
    child:Column(children:ch));
  Widget _row(BuildContext ctx,IconData icon,String t,String s,Color c,VoidCallback fn)=>ListTile(onTap:fn,
    leading:_ico(icon,c),
    title:Text(t,style:TextStyle(fontWeight:FontWeight.w600,color:Theme.of(ctx).colorScheme.onSurface)),
    subtitle:Text(s,style:TextStyle(color:Colors.grey.shade500,fontSize:12)),
    trailing:Icon(Icons.arrow_forward_ios_rounded,size:14,color:Colors.grey.shade400));
  Widget _ico(IconData i,Color c)=>Container(padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(color:c.withOpacity(.12),borderRadius:BorderRadius.circular(10)),child:Icon(i,color:c,size:20));
  Widget _div()=>const Divider(height:1,indent:56);
  void _budgetDlg(BuildContext ctx){
    final c=TextEditingController(text:AppState.of(ctx).exp.budget.toInt().toString());
    showDialog(context:ctx,builder:(dlg)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
      title:const Text('Monthly Budget',style:TextStyle(fontWeight:FontWeight.w800)),
      content:TextField(controller:c,keyboardType:TextInputType.number,
          decoration:InputDecoration(prefixText:AppState.of(ctx).exp.cur,labelText:'Amount',border:const OutlineInputBorder())),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dlg),child:Text('Cancel',style:TextStyle(color:Colors.grey.shade500))),
        ElevatedButton(onPressed:()async{final v=double.tryParse(c.text)??5000;
          final s=AppState.of(ctx);s.exp.budget=v;await s.users.update(budget:v);
          if(mounted){Navigator.pop(dlg);setState((){});}},
          style:ElevatedButton.styleFrom(backgroundColor:kP,foregroundColor:Colors.white,elevation:0,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
          child:const Text('Save')),
      ]));
  }
  void _curDlg(BuildContext ctx)=>showDialog(context:ctx,builder:(dlg)=>AlertDialog(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
    title:const Text('Select Currency',style:TextStyle(fontWeight:FontWeight.w800)),
    content:Column(mainAxisSize:MainAxisSize.min,children:kCurs.map((cur){
      final sel=AppState.of(ctx).exp.cur==cur;
      return ListTile(leading:Text(cur,style:const TextStyle(fontSize:22)),title:Text(curName(cur)),
        trailing:sel?const Icon(Icons.check_rounded,color:kP):null,
        onTap:()async{final s=AppState.of(ctx);s.exp.cur=cur;await s.users.update(currency:cur);
          if(mounted){Navigator.pop(dlg);setState((){});}});
    }).toList())));
  void _delAllDlg(BuildContext ctx)=>showDialog(context:ctx,builder:(dlg)=>AlertDialog(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
    title:const Text('Delete All Expenses',style:TextStyle(fontWeight:FontWeight.w800)),
    content:const Text('Permanently deletes all expense records.'),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(dlg),child:Text('Cancel',style:TextStyle(color:Colors.grey.shade500))),
      ElevatedButton(onPressed:()async{await AppState.of(ctx).exp.clear();if(mounted){Navigator.pop(dlg);setState((){});}},
        style:ElevatedButton.styleFrom(backgroundColor:Colors.red.shade400,foregroundColor:Colors.white,elevation:0,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
        child:const Text('Delete All')),
    ]));
}
