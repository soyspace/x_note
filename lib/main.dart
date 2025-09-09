import 'dart:io';
import 'dart:ui' as ui;

import 'package:XNote/pages/splash_page.dart';
import 'package:XNote/routes/routes.dart';
import 'package:XNote/utils/messages.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility:false
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'XNote',
      translations: Messages(),
     locale: View.of(context).platformDispatcher.locale,
      // locale: Locale("en","US"),
      localizationsDelegates: [
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        AppFlowyEditorLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      supportedLocales: AppFlowyEditorLocalizations.delegate.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: "SIMYOU"
      ),
      getPages: routes,
      home: const SplashPage(),
    );
  }
}
