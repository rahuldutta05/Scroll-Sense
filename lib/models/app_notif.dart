enum NType{added,budgetWarn,budgetOver,bigSpend,summary,general}
class AppNotif{
  final String id,title,body;
  final NType type;
  final DateTime time;
  bool read;
  AppNotif({required this.id,required this.title,required this.body,
      required this.type,required this.time,this.read=false});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'body':body,
      'type':type.name,'time':time.toIso8601String(),'read':read};
  factory AppNotif.fromJson(Map<String,dynamic> j)=>AppNotif(
      id:j['id'],title:j['title'],body:j['body'],
      type:NType.values.firstWhere((t)=>t.name==j['type'],orElse:()=>NType.general),
      time:DateTime.parse(j['time']),read:j['read']??false);
}
