import 'package:flutter/material.dart';
Map<String,dynamic> catInfo(String c){
  switch(c){
    case 'Food':return{'icon':Icons.restaurant_rounded,'color':const Color(0xFFF97316)};
    case 'Transport':return{'icon':Icons.directions_car_rounded,'color':const Color(0xFF3B82F6)};
    case 'Shopping':return{'icon':Icons.shopping_bag_rounded,'color':const Color(0xFFEC4899)};
    case 'Entertainment':return{'icon':Icons.movie_rounded,'color':const Color(0xFF8B5CF6)};
    case 'Health':return{'icon':Icons.favorite_rounded,'color':const Color(0xFFEF4444)};
    case 'Bills':return{'icon':Icons.receipt_rounded,'color':const Color(0xFF14B8A6)};
    default:return{'icon':Icons.category_rounded,'color':const Color(0xFF6B7280)};
  }
}
const kCats=['Food','Transport','Shopping','Entertainment','Health','Bills','Other'];
const kCurs=['₹',r'$','€','£','¥'];
String curName(String s){
  switch(s){case'₹':return'Indian Rupee';case r'$':return'US Dollar';
    case'€':return'Euro';case'£':return'British Pound';case'¥':return'Japanese Yen';default:return s;}
}
