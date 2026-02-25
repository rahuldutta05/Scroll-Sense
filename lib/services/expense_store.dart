import 'dart:convert';import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';
import '../database/db.dart';
import 'notif_store.dart';

class ExpenseStore extends ChangeNotifier{
  final String uid;final NotifStore ns;
  final _list=<Expense>[];
  double _budget=5000;String _cur='₹';
  bool _w80=false,_wOver=false;
  ExpenseStore(this.uid,this.ns);
  List<Expense> get expenses=>List.unmodifiable(_list);
  double get budget=>_budget;String get cur=>_cur;
  set budget(double v){_budget=v;_w80=false;_wOver=false;notifyListeners();_save();}
  set cur(String v){_cur=v;notifyListeners();_save();}
  Future<void> load()async{
    final raw=await DB.get('exp_$uid','list');
    if(raw!=null){_list..clear()..addAll((jsonDecode(raw)as List).map((j)=>Expense.fromJson(j)));}
    else{_defaults();}
    final b=await DB.get('exp_$uid','budget');if(b!=null)_budget=(b as num).toDouble();
    final c=await DB.get('exp_$uid','cur');if(c!=null)_cur=c as String;
    notifyListeners();
  }
  void _defaults()=>_list.addAll([
    Expense(id:'d1',title:'Grocery Shopping',amount:850,category:'Food',date:DateTime.now().subtract(const Duration(days:1)),note:'Weekly groceries'),
    Expense(id:'d2',title:'Uber Ride',amount:220,category:'Transport',date:DateTime.now().subtract(const Duration(days:1))),
    Expense(id:'d3',title:'Netflix',amount:499,category:'Entertainment',date:DateTime.now().subtract(const Duration(days:3))),
    Expense(id:'d4',title:'New Shoes',amount:2499,category:'Shopping',date:DateTime.now().subtract(const Duration(days:5))),
    Expense(id:'d5',title:'Restaurant Dinner',amount:1200,category:'Food',date:DateTime.now()),
  ]);
  Future<void> _save()async{
    await DB.put('exp_$uid','list',jsonEncode(_list.map((e)=>e.toJson()).toList()));
    await DB.put('exp_$uid','budget',_budget);await DB.put('exp_$uid','cur',_cur);
  }
  Future<void> add(Expense e)async{
    _list.add(e);notifyListeners();await _save();
    await ns.onAdded(e.title,e.amount,_cur);
    if(e.amount>=2000)await ns.onBig(e.title,e.amount,_cur);
    final pct=totalMonth/_budget;
    if(pct>=1.0&&!_wOver){_wOver=true;await ns.onOver(_cur,_budget);}
    else if(pct>=0.8&&!_w80){_w80=true;await ns.onWarn(pct,_cur,_budget);}
  }
  Future<void> remove(String id)async{_list.removeWhere((e)=>e.id==id);notifyListeners();await _save();}
  Future<void> update(Expense u)async{
    final i=_list.indexWhere((e)=>e.id==u.id);
    if(i!=-1){_list[i]=u;notifyListeners();await _save();}
  }
  Future<void> clear()async{_list.clear();notifyListeners();await DB.drop('exp_$uid');}
  List<Expense> forDate(DateTime d)=>_list.where((e)=>
      e.date.year==d.year&&e.date.month==d.month&&e.date.day==d.day).toList();
  double dateTotal(DateTime d)=>forDate(d).fold(0,(s,e)=>s+e.amount);
  double get totalMonth{
    final n=DateTime.now();
    return _list.where((e)=>e.date.year==n.year&&e.date.month==n.month).fold(0,(s,e)=>s+e.amount);
  }
  Map<String,double> get catTotals{
    final m=<String,double>{};
    for(final e in _list)m[e.category]=(m[e.category]??0)+e.amount;
    return m;
  }
  Future<String> exportCSV()async{
    final rows=[['Title','Amount','Category','Date','Note'],
      ..._list.map((e)=>[e.title,e.amount,e.category,e.date.toString(),e.note])];
    final csv=const ListToCsvConverter().convert(rows);
    final dir=await getApplicationDocumentsDirectory();
    final file=File('${dir.path}/expenses_$uid.csv');
    await file.writeAsString(csv);return file.path;
  }
}
