import 'package:flutter/material.dart';
import '../../services/app_state.dart';import '../../utils/cats.dart';
import '../../theme/app_theme.dart';import '../login/login_screen.dart';

class ProfileScreen extends StatefulWidget{const ProfileScreen({super.key});
  @override State<ProfileScreen> createState()=>_PS();}
class _PS extends State<ProfileScreen>{
  @override
  Widget build(BuildContext ctx){
    final s=AppState.of(ctx);final u=s.users.current!;final exp=s.exp;
    return Scaffold(backgroundColor:Theme.of(ctx).scaffoldBackgroundColor,
      appBar:AppBar(backgroundColor:Theme.of(ctx).cardColor,elevation:0,
        title:Text('Profile',style:TextStyle(fontWeight:FontWeight.w800,fontSize:22,color:Theme.of(ctx).colorScheme.onSurface))),
      body:SingleChildScrollView(padding:const EdgeInsets.all(20),
        child:Column(children:[
          _hero(ctx,u,exp),const SizedBox(height:20),
          _stats(ctx,exp),const SizedBox(height:20),
          _prefs(ctx,exp),const SizedBox(height:20),
          _switcher(ctx),const SizedBox(height:20),
          _danger(ctx),const SizedBox(height:50),
        ])));
  }
  Widget _hero(BuildContext ctx,u,exp)=>Container(
    padding:const EdgeInsets.all(24),
    decoration:BoxDecoration(
      gradient:const LinearGradient(colors:[kD,kL],begin:Alignment.topLeft,end:Alignment.bottomRight),
      borderRadius:BorderRadius.circular(26),
      boxShadow:[BoxShadow(color:kP.withOpacity(.35),blurRadius:24,offset:const Offset(0,10))]),
    child:Row(children:[
      Stack(children:[
        CircleAvatar(radius:40,backgroundColor:Colors.white.withOpacity(.2),
          child:Text(u.avatar,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:26))),
        Positioned(right:0,bottom:0,child:GestureDetector(onTap:()=>_editName(ctx),
          child:Container(width:28,height:28,decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle),
              child:const Icon(Icons.edit_rounded,size:14,color:kP)))),
      ]),
      const SizedBox(width:18),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(u.name,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:20)),
        const SizedBox(height:3),
        Text(u.email,style:TextStyle(color:Colors.white.withOpacity(.72),fontSize:13)),
        const SizedBox(height:14),
        Wrap(spacing:8,runSpacing:6,children:[
          _badge('${exp.cur}${exp.budget.toInt()}','Budget'),
          _badge(exp.cur,'Currency'),
        ]),
      ])),
    ]));
  Widget _badge(String v,String l)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:11,vertical:5),
    decoration:BoxDecoration(color:Colors.white.withOpacity(.18),borderRadius:BorderRadius.circular(20)),
    child:Text('$v  $l',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)));
  Widget _stats(BuildContext ctx,exp){
    final total=exp.totalMonth;final cnt=exp.expenses.where((e)=>e.date.month==DateTime.now().month).length;
    return Row(children:[
      _stat(ctx,'${exp.cur}${total.toInt()}','Spent',Icons.trending_up_rounded,Colors.purple),
      const SizedBox(width:12),
      _stat(ctx,'$cnt','Transactions',Icons.receipt_long_rounded,Colors.blue),
      const SizedBox(width:12),
      _stat(ctx,'${((total/exp.budget)*100).clamp(0,999).toInt()}%','Budget Used',Icons.donut_small_rounded,const Color(0xFF22C55E)),
    ]);
  }
  Widget _stat(BuildContext ctx,String v,String l,IconData icon,Color c)=>Expanded(
    child:Container(padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:Theme.of(ctx).cardColor,borderRadius:BorderRadius.circular(18),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04),blurRadius:8,offset:const Offset(0,2))]),
      child:Column(children:[
        Container(padding:const EdgeInsets.all(8),
          decoration:BoxDecoration(color:c.withOpacity(.12),borderRadius:BorderRadius.circular(10)),
          child:Icon(icon,color:c,size:18)),
        const SizedBox(height:8),
        Text(v,style:TextStyle(fontWeight:FontWeight.w800,fontSize:13,color:Theme.of(ctx).colorScheme.onSurface),overflow:TextOverflow.ellipsis),
        const SizedBox(height:2),
        Text(l,style:TextStyle(color:Colors.grey.shade500,fontSize:10),textAlign:TextAlign.center),
      ])));
  Widget _prefs(BuildContext ctx,exp)=>_card(ctx,[
    _row(ctx,Icons.savings_rounded,'Budget','${exp.cur}${exp.budget.toInt()}',const Color(0xFF22C55E),()=>_budgetDlg(ctx)),
    _div(),
    _row(ctx,Icons.currency_exchange_rounded,'Currency',exp.cur,Colors.blue,()=>_curDlg(ctx)),
    _div(),
    ValueListenableBuilder(valueListenable:AppState.of(ctx).dark,builder:(_,dk,__)=>SwitchListTile(
      secondary:_ico(dk?Icons.light_mode_rounded:Icons.dark_mode_rounded,Colors.purple),
      title:Text('Dark Mode',style:TextStyle(fontWeight:FontWeight.w600,color:Theme.of(ctx).colorScheme.onSurface)),
      value:dk,activeColor:kP,onChanged:(v)=>AppState.of(ctx).dark.value=v)),
  ]);
  Widget _row(BuildContext ctx,IconData icon,String t,String s,Color c,VoidCallback fn)=>ListTile(onTap:fn,
    leading:_ico(icon,c),
    title:Text(t,style:TextStyle(fontWeight:FontWeight.w600,color:Theme.of(ctx).colorScheme.onSurface)),
    subtitle:Text(s,style:TextStyle(color:Colors.grey.shade500,fontSize:12)),
    trailing:Icon(Icons.arrow_forward_ios_rounded,size:14,color:Colors.grey.shade400));
  Widget _ico(IconData i,Color c)=>Container(padding:const EdgeInsets.all(8),
    decoration:BoxDecoration(color:c.withOpacity(.12),borderRadius:BorderRadius.circular(10)),
    child:Icon(i,color:c,size:20));
  Widget _div()=>const Divider(height:1,indent:56);
  Widget _card(BuildContext ctx,List<Widget> ch)=>Container(
    decoration:BoxDecoration(color:Theme.of(ctx).cardColor,borderRadius:BorderRadius.circular(22),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.05),blurRadius:12,offset:const Offset(0,3))]),
    child:Column(children:ch));
  Widget _switcher(BuildContext ctx){
    final users=AppState.of(ctx).users.all;
    if(users.length<=1)return const SizedBox.shrink();
    return _card(ctx,[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),
        child:Text('Switch Account',style:TextStyle(fontWeight:FontWeight.w700,fontSize:15,color:Theme.of(ctx).colorScheme.onSurface))),
      ...users.map((u){
        final active=u.id==AppState.of(ctx).users.current?.id;
        return ListTile(
          leading:CircleAvatar(backgroundColor:active?kP:Colors.grey.shade200,
            child:Text(u.avatar,style:TextStyle(color:active?Colors.white:Colors.grey.shade600,fontWeight:FontWeight.w700))),
          title:Text(u.name,style:TextStyle(fontWeight:FontWeight.w600,color:Theme.of(ctx).colorScheme.onSurface)),
          subtitle:Text(u.email,style:TextStyle(color:Colors.grey.shade500,fontSize:12)),
          trailing:active
              ?Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                  decoration:BoxDecoration(color:kP.withOpacity(.1),borderRadius:BorderRadius.circular(12)),
                  child:const Text('Active',style:TextStyle(color:kP,fontSize:11,fontWeight:FontWeight.w700)))
              :TextButton(onPressed:()async{
                  final s=AppState.of(context);await s.users.switchTo(u);await s.exp.load();await s.notifs.load();
                  setState((){});},child:const Text('Switch')));
      }),
      const SizedBox(height:8),
    ]);
  }
  Widget _danger(BuildContext ctx)=>_card(ctx,[
    ListTile(leading:_ico(Icons.logout_rounded,Colors.orange),
      title:Text('Logout',style:TextStyle(fontWeight:FontWeight.w600,color:Colors.orange.shade700)),
      onTap:()=>_logout(ctx)),
    _div(),
    ListTile(leading:_ico(Icons.person_remove_rounded,Colors.red),
      title:Text('Delete Account',style:TextStyle(fontWeight:FontWeight.w600,color:Colors.red.shade500)),
      onTap:()=>_delAccDlg(ctx)),
  ]);
  void _editName(BuildContext ctx){
    final c=TextEditingController(text:AppState.of(ctx).users.current!.name);
    _dlg(ctx,'Edit Name',[TextField(controller:c,decoration:const InputDecoration(labelText:'Full Name',border:OutlineInputBorder()))],
      ()async{await AppState.of(ctx).users.update(name:c.text.trim());setState((){});});
  }
  void _budgetDlg(BuildContext ctx){
    final c=TextEditingController(text:AppState.of(ctx).exp.budget.toInt().toString());
    _dlg(ctx,'Monthly Budget',[TextField(controller:c,keyboardType:TextInputType.number,
      decoration:InputDecoration(prefixText:AppState.of(ctx).exp.cur,labelText:'Amount',border:const OutlineInputBorder()))],
      ()async{final v=double.tryParse(c.text)??5000;final s=AppState.of(ctx);s.exp.budget=v;await s.users.update(budget:v);setState((){});});
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
  void _dlg(BuildContext ctx,String title,List<Widget> fields,VoidCallback fn)=>showDialog(
    context:ctx,builder:(dlg)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
      title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),
      content:Column(mainAxisSize:MainAxisSize.min,children:fields),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(dlg),child:Text('Cancel',style:TextStyle(color:Colors.grey.shade500))),
        ElevatedButton(onPressed:(){fn();Navigator.pop(dlg);},
          style:ElevatedButton.styleFrom(backgroundColor:kP,foregroundColor:Colors.white,elevation:0,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
          child:const Text('Save')),
      ]));
  void _logout(BuildContext ctx)async{await AppState.of(ctx).users.logout();
    if(mounted)Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}
  void _delAccDlg(BuildContext ctx)=>showDialog(context:ctx,builder:(dlg)=>AlertDialog(
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
    title:const Text('Delete Account',style:TextStyle(fontWeight:FontWeight.w800)),
    content:const Text('Permanently deletes your account and all data.'),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(dlg),child:Text('Cancel',style:TextStyle(color:Colors.grey.shade500))),
      ElevatedButton(onPressed:()async{await AppState.of(ctx).users.deleteCurrent();
        if(mounted)Navigator.of(ctx).pushAndRemoveUntil(MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);},
        style:ElevatedButton.styleFrom(backgroundColor:Colors.red.shade400,foregroundColor:Colors.white,elevation:0,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
        child:const Text('Delete Forever')),
    ]));
}
