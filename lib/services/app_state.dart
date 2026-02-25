import 'package:flutter/material.dart';
import 'user_store.dart';import 'expense_store.dart';import 'notif_store.dart';
class AppState extends InheritedWidget{
  final UserStore users;final ExpenseStore exp;
  final NotifStore notifs;final ValueNotifier<bool> dark;
  const AppState({super.key,required this.users,required this.exp,
      required this.notifs,required this.dark,required super.child});
  static AppState of(BuildContext ctx)=>ctx.dependOnInheritedWidgetOfExactType<AppState>()!;
  @override bool updateShouldNotify(AppState o)=>true;
}
