class Expense {
  final String id, title, category, note;
  final double amount;
  final DateTime date;
  Expense({required this.id,required this.title,required this.amount,
      required this.category,required this.date,this.note=''});
  Map<String,dynamic> toJson()=>{'id':id,'title':title,'amount':amount,
      'category':category,'date':date.toIso8601String(),'note':note};
  factory Expense.fromJson(Map<String,dynamic> j)=>Expense(
      id:j['id'],title:j['title'],amount:(j['amount'] as num).toDouble(),
      category:j['category'],date:DateTime.parse(j['date']),note:j['note']??'');
}
