import 'package:flutter/material.dart';
import 'package:get/get.dart' as my_get;
class AppDialog {
  /// 基础AlertDialog样式配置
  static AlertDialog _baseDialog({
    required BuildContext context,
    Widget? title,
    Widget? content,
    List<Widget>? actions,
  }) {
    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// 确认对话框
  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Ok',
    String cancelText = 'Cancel',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => _baseDialog(
        context: context,
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 输入对话框
  static Future<String?> showInput(
    BuildContext context, {
    required String title,
    String hintText = 'Please Input',
    String confirmText = 'Ok',
    String cancelText = 'Cancel',
    String? defaultValue,
  }) async {
    final controller = TextEditingController(text: defaultValue);
    return showDialog<String>(
      context: context,
      builder: (context) => _baseDialog(
        context: context,
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hintText),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// 自定义组件弹窗
  static Future<T?> showCustom<T>(
    BuildContext context, {
    required Widget child,
    bool dismissible = true,
  }) async {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => Dialog(
        backgroundColor: my_get.Get.theme.hoverColor ,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      ),
    );
  }

  /// 底部弹窗
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => child,
    );
  }
}
