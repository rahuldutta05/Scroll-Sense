import 'package:flutter/material.dart';
const kP=Color(0xFF6C63FF);const kD=Color(0xFF4A43D4);
const kL=Color(0xFF9C94FF);const kBgL=Color(0xFFF8F7FF);
const kBgDk=Color(0xFF0D0D1A);const kCdDk=Color(0xFF1A1A2E);
class AppTheme{
  static ThemeData light()=>ThemeData(useMaterial3:true,fontFamily:'Poppins',
    colorScheme:ColorScheme.fromSeed(seedColor:kP),
    scaffoldBackgroundColor:kBgL,cardColor:Colors.white);
  static ThemeData dark()=>ThemeData(useMaterial3:true,fontFamily:'Poppins',
    colorScheme:ColorScheme.fromSeed(seedColor:kP,brightness:Brightness.dark),
    scaffoldBackgroundColor:kBgDk,cardColor:kCdDk);
}
