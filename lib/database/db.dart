import 'dart:convert';import 'dart:io';
import 'package:path_provider/path_provider.dart';
class DB{
  static Future<File> _f(String n)async{
    final d=await getApplicationDocumentsDirectory();
    return File('${d.path}/$n.json');
  }
  static Future<void> put(String box,String key,dynamic val)async{
    final f=await _f(box);Map<String,dynamic> d={};
    if(await f.exists())try{d=jsonDecode(await f.readAsString());}catch(_){}
    d[key]=val;await f.writeAsString(jsonEncode(d));
  }
  static Future<dynamic> get(String box,String key)async{
    final f=await _f(box);if(!await f.exists())return null;
    try{return(jsonDecode(await f.readAsString())as Map<String,dynamic>)[key];}catch(_){return null;}
  }
  static Future<void> del(String box,String key)async{
    final f=await _f(box);if(!await f.exists())return;
    try{final d=jsonDecode(await f.readAsString())as Map<String,dynamic>;
      d.remove(key);await f.writeAsString(jsonEncode(d));}catch(_){}
  }
  static Future<void> drop(String box)async{
    final f=await _f(box);if(await f.exists())await f.delete();
  }
}
