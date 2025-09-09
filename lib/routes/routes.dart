import 'package:XNote/pages/home_index.dart';
import 'package:XNote/pages/splash_page.dart';
import 'package:get/get_navigation/src/routes/get_route.dart';

import '../pages/lock_screen_page.dart';

var routes = [
  GetPage(name: '/splash', page: () => const SplashPage()),
  GetPage(name: '/home', page: () => const HomeIndex()),
  GetPage(name: '/lock', page: () => const LockScreenPage()),
];
