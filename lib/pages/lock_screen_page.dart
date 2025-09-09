import 'package:XNote/controller/system_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LockScreenPage extends StatefulWidget {
  const LockScreenPage({super.key});

  @override
  State<LockScreenPage> createState() => _LockScreenPageState();
}

class _LockScreenPageState extends State<LockScreenPage> {
  final TextEditingController _passwordEditingController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/logo256.png',
                    width: 48,
                    height: 48,
                  ),
                  SizedBox(height: 48),
                  Image.asset('assets/icons/xnote.png', height: 48),
                ],
              ),
              SizedBox(height: 66),
              TextField(
                controller: _passwordEditingController,
                decoration: InputDecoration(
                  hintText: 'lock_password_hint'.tr,
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0),
                  prefixIcon: Icon(Icons.lock,),
                  suffix: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _passwordEditingController.clear();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ),
                ),
                obscureText: true, // 隐藏输入的密码
                onSubmitted: (value) {
                  debugPrint("value: $value");
                  if (value.isNotEmpty) {
                    if (value == SystemController.to.system?.lockPassword) {
                      SystemController.to.changeLock();
                      Get.back();
                    } else {
                      Get.snackbar("error".tr, "error_password".tr);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
