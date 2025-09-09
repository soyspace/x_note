import 'package:flutter/material.dart';
import 'package:get/get.dart';

final Map<String, (String,ThemeData)> themeData = {
  "light": ('light'.tr,ThemeData(
    fontFamily: "SIMYOU",
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[200],
    shadowColor: Colors.grey[300],
    hoverColor: Colors.grey[200],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.black, fontSize: 20),
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
      bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    ),
  )),
  "dark": ('dark'.tr,ThemeData(
    fontFamily: "SIMYOU",
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    primaryColor: Colors.grey[300],
    shadowColor: Colors.grey[800],
    hoverColor: Colors.grey[700],
    scaffoldBackgroundColor: Colors.grey[600],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[850],
      foregroundColor: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white, fontSize: 20),
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
      bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[700],
        foregroundColor: Colors.white,
      ),
    ),
  )),
  'system': ('system'.tr,ThemeData(
    fontFamily: "SIMYOU",
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    shadowColor: Colors.grey[300],
    hoverColor: Colors.grey[200],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.black, fontSize: 20),
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
      bodySmall: TextStyle(color: Colors.black54, fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
    ),
  ))
};
