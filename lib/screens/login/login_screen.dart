import 'package:flutter/material.dart';
import '../../services/app_state.dart';import '../../theme/app_theme.dart';
import '../dashboard/main_screen.dart';

class LoginScreen extends StatefulWidget{const LoginScreen({super.key});
  @override State<LoginScreen> createState()=>_LS();}
class _LS extends State<LoginScreen> with TickerProviderStateMixin{
  final _nc=TextEditingController();final _ec=TextEditingController();
  bool _loading=false;
  late final AnimationController _ac;
  late final Animation<double> _fade;late final Animation<Offset> _slide;
  @override void initState(){
    super.initState();
    _ac=AnimationController(vsync:this,duration:const Duration(milliseconds:900));
    _fade=CurvedAnimation(parent:_ac,curve:Curves.easeOut);
    _slide=Tween<Offset>(begin:const Offset(0,.06),end:Offset.zero)
        .animate(CurvedAnimation(parent:_ac,curve:Curves.easeOut));
    _ac.forward();
  }
  @override void dispose(){_ac.dispose();_nc.dispose();_ec.dispose();super.dispose();}
  Future<void> _go()async{
    if(_nc.text.trim().isEmpty||_ec.text.trim().isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:Text('Please fill in all fields'),backgroundColor:kP,behavior:SnackBarBehavior.floating));return;
    }
    setState(()=>_loading=true);
    final s=AppState.of(context);
    await s.users.login(_nc.text.trim(),_ec.text.trim());
    await s.exp.load();await s.notifs.load();
    if(mounted)Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const MainScreen()));
  }
  @override
  Widget build(BuildContext ctx)=>Scaffold(
    body:Container(
      decoration:const BoxDecoration(gradient:LinearGradient(
        colors:[kD,kP,Color(0xFFB3AEFF),kBgL],
        begin:Alignment.topLeft,end:Alignment.bottomCenter,stops:[0.0,0.35,0.62,0.85])),
      child:SafeArea(child:FadeTransition(opacity:_fade,child:SlideTransition(position:_slide,
        child:SingleChildScrollView(padding:const EdgeInsets.symmetric(horizontal:28,vertical:24),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const SizedBox(height:28),_hero(),const SizedBox(height:48),
            _card(),const SizedBox(height:22),_quickSwitch(),
          ])))))));

  Widget _hero()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:64,height:64,
      decoration:BoxDecoration(color:Colors.white.withOpacity(.18),borderRadius:BorderRadius.circular(20),
          border:Border.all(color:Colors.white.withOpacity(.3))),
      child:const Icon(Icons.account_balance_wallet_rounded,color:Colors.white,size:34)),
    const SizedBox(height:22),
    const Text('ExpenseFlow',style:TextStyle(color:Colors.white,fontSize:38,fontWeight:FontWeight.w900,letterSpacing:-1.5)),
    const SizedBox(height:7),
    Text('Smart money, smarter life.',style:TextStyle(color:Colors.white.withOpacity(.78),fontSize:15)),
    const SizedBox(height:20),
    Wrap(spacing:8,runSpacing:8,children:[
      _tag(Icons.people_rounded,'Multi-user'),_tag(Icons.notifications_rounded,'Smart alerts'),
      _tag(Icons.analytics_rounded,'Analytics'),_tag(Icons.savings_rounded,'Budget'),
    ]),
  ]);
  Widget _tag(IconData icon,String l)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:11,vertical:5),
    decoration:BoxDecoration(color:Colors.white.withOpacity(.15),borderRadius:BorderRadius.circular(20),
        border:Border.all(color:Colors.white.withOpacity(.25))),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:Colors.white,size:12),const SizedBox(width:5),
      Text(l,style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w600)),
    ]));
  Widget _card()=>Container(
    padding:const EdgeInsets.all(26),
    decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(28),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.14),blurRadius:32,offset:const Offset(0,12))]),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('Get Started',style:TextStyle(fontSize:24,fontWeight:FontWeight.w800,color:Theme.of(context).colorScheme.onSurface)),
      const SizedBox(height:4),
      Text('Login or create account instantly',style:TextStyle(color:Colors.grey.shade500,fontSize:13)),
      const SizedBox(height:26),
      _inp(_nc,'Full Name',Icons.person_rounded),const SizedBox(height:14),
      _inp(_ec,'Email Address',Icons.email_rounded,type:TextInputType.emailAddress),
      const SizedBox(height:26),
      SizedBox(width:double.infinity,height:54,
        child:ElevatedButton(onPressed:_loading?null:_go,
          style:ElevatedButton.styleFrom(backgroundColor:kP,foregroundColor:Colors.white,elevation:0,
              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
          child:_loading
              ?const SizedBox(width:22,height:22,child:CircularProgressIndicator(strokeWidth:2.5,color:Colors.white))
              :const Text('Continue →',style:TextStyle(fontWeight:FontWeight.w700,fontSize:16)))),
    ]));
  Widget _inp(TextEditingController c,String h,IconData icon,{TextInputType type=TextInputType.text})=>Container(
    decoration:BoxDecoration(color:Theme.of(context).scaffoldBackgroundColor,borderRadius:BorderRadius.circular(14)),
    child:TextField(controller:c,keyboardType:type,
      decoration:InputDecoration(hintText:h,hintStyle:TextStyle(color:Colors.grey.shade400),
          prefixIcon:Icon(icon,color:kP,size:20),border:InputBorder.none,
          contentPadding:const EdgeInsets.symmetric(vertical:16))));
  Widget _quickSwitch(){
    final users=AppState.of(context).users.all;
    if(users.isEmpty)return const SizedBox.shrink();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.only(left:4,bottom:10),
        child:Text('Quick Switch',style:TextStyle(color:Colors.grey.shade600,fontSize:12,fontWeight:FontWeight.w700,letterSpacing:.5))),
      SizedBox(height:82,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:users.length,
        separatorBuilder:(_,__)=>const SizedBox(width:10),
        itemBuilder:(_,i){
          final u=users[i];
          return GestureDetector(onTap:()async{
            final s=AppState.of(context);await s.users.switchTo(u);await s.exp.load();await s.notifs.load();
            if(mounted)Navigator.of(context).pushReplacement(MaterialPageRoute(builder:(_)=>const MainScreen()));
          },
          child:Container(width:70,
            decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(18),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(.08),blurRadius:10,offset:const Offset(0,3))]),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              CircleAvatar(radius:22,backgroundColor:kP,
                  child:Text(u.avatar,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:13))),
              const SizedBox(height:6),
              Padding(padding:const EdgeInsets.symmetric(horizontal:4),
                child:Text(u.name.split(' ').first,style:TextStyle(fontSize:10,fontWeight:FontWeight.w600,
                    color:Theme.of(context).colorScheme.onSurface),overflow:TextOverflow.ellipsis)),
            ])));
        })),
    ]);
  }
}
