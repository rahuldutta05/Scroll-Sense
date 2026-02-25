import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';import '../database/db.dart';
class UserStore extends ChangeNotifier{
  AppUser? _cur;final _all=<AppUser>[];
  AppUser? get current=>_cur;List<AppUser> get all=>List.unmodifiable(_all);
  bool get loggedIn=>_cur!=null;
  Future<void> init()async{
    final raw=await DB.get('auth','users');
    if(raw!=null)_all..clear()..addAll((jsonDecode(raw)as List).map((j)=>AppUser.fromJson(j)));
    final id=await DB.get('auth','active');
    if(id!=null&&_all.isNotEmpty){try{_cur=_all.firstWhere((u)=>u.id==id);}catch(_){_cur=_all.first;}}
    notifyListeners();
  }
  Future<AppUser> login(String name,String email)async{
    AppUser? u;try{u=_all.firstWhere((x)=>x.email.toLowerCase()==email.toLowerCase());}
    catch(_){u=AppUser(id:'u_${DateTime.now().millisecondsSinceEpoch}',name:name,email:email);_all.add(u);}
    _cur=u;notifyListeners();await _persist();return u;
  }
  Future<void> logout()async{_cur=null;await DB.del('auth','active');notifyListeners();}
  Future<void> switchTo(AppUser u)async{_cur=u;notifyListeners();await _persist();}
  Future<void> update({String? name,double? budget,String? currency})async{
    if(_cur==null)return;
    if(name!=null){_cur!.name=name;_cur!.genAvatar();}
    if(budget!=null)_cur!.budget=budget;if(currency!=null)_cur!.currency=currency;
    final i=_all.indexWhere((u)=>u.id==_cur!.id);if(i!=-1)_all[i]=_cur!;
    notifyListeners();await _persist();
  }
  Future<void> deleteCurrent()async{
    if(_cur==null)return;final id=_cur!.id;_all.removeWhere((u)=>u.id==id);_cur=null;
    await DB.drop('exp_$id');await DB.drop('notif_$id');await _persist();notifyListeners();
  }
  Future<void> _persist()async{
    await DB.put('auth','users',jsonEncode(_all.map((u)=>u.toJson()).toList()));
    if(_cur!=null)await DB.put('auth','active',_cur!.id);
  }
}
