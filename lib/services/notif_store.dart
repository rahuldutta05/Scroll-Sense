import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_notif.dart';
import '../database/db.dart';

class NotifStore extends ChangeNotifier{
  final String uid;
  final _list=<AppNotif>[];
  NotifStore(this.uid);
  List<AppNotif> get all=>List.unmodifiable([..._list]..sort((a,b)=>b.time.compareTo(a.time)));
  int get unread=>_list.where((n)=>!n.read).length;
  Future<void> load()async{
    final raw=await DB.get('notif_$uid','list');if(raw==null)return;
    _list..clear()..addAll((jsonDecode(raw)as List).map((j)=>AppNotif.fromJson(j)));
    notifyListeners();
  }
  Future<void> _save()=>DB.put('notif_$uid','list',jsonEncode(_list.map((n)=>n.toJson()).toList()));
  String get _id=>DateTime.now().microsecondsSinceEpoch.toString();
  Future<void> _push(AppNotif n)async{_list.add(n);notifyListeners();await _save();}
  Future<void> markRead(String id)async{
    final i=_list.indexWhere((n)=>n.id==id);
    if(i!=-1){_list[i].read=true;notifyListeners();await _save();}
  }
  Future<void> markAllRead()async{for(final n in _list)n.read=true;notifyListeners();await _save();}
  Future<void> remove(String id)async{_list.removeWhere((n)=>n.id==id);notifyListeners();await _save();}
  Future<void> clear()async{_list.clear();notifyListeners();await _save();}
  Future<void> onAdded(String t,double a,String c)=>_push(AppNotif(id:_id,title:'Expense Recorded',
      body:'$t — ${c}${a.toInt()} saved.',type:NType.added,time:DateTime.now()));
  Future<void> onBig(String t,double a,String c)=>_push(AppNotif(id:_id,title:'⚡ Large Transaction',
      body:'$t (${c}${a.toInt()}) — big spend alert!',type:NType.bigSpend,time:DateTime.now()));
  Future<void> onWarn(double pct,String c,double b)=>_push(AppNotif(id:_id,title:'🟡 Budget Warning',
      body:'${(pct*100).toInt()}% of ${c}${b.toInt()} budget used.',type:NType.budgetWarn,time:DateTime.now()));
  Future<void> onOver(String c,double b)=>_push(AppNotif(id:_id,title:'🔴 Budget Exceeded',
      body:'Crossed your ${c}${b.toInt()} monthly limit.',type:NType.budgetOver,time:DateTime.now()));
  Future<void> onSummary(double t,int n,String c)=>_push(AppNotif(id:_id,title:'📊 Monthly Summary',
      body:'$n expenses · ${c}${t.toInt()} total this month.',type:NType.summary,time:DateTime.now()));
}
