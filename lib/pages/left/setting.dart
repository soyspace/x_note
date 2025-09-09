import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/style/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:XNote/widgets/dialog.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart'; // 使用之前创建的对话框组件

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final languages = {'zh_CN': '简体中文', 'en_US': 'English', 'ja_JP': '日本語'};

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
      child: GetBuilder<SystemController>(
        builder: (controller) {
          return Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionTitle('appearance'.tr),
                    _buildLanguageSelector(controller),
                    _buildThemeSelector(controller),
                    const Divider(height: 24),

                    _buildSectionTitle('security'.tr),
                    _buildLockSwitch(),
                    if (SystemController.to.system?.lock=='1') ...[
                      _buildLockPassword(),
                      _buildLockTimeout(),
                    ],
                    const Divider(height: 24),

                    _buildSectionTitle('storage'.tr),
                    _buildCachePath(controller),
                    _buildClearCache(controller),
                    const Divider(height: 24),

                    _buildSectionTitle('about'.tr),
                    _buildVersionInfo(),
                    _buildContactUs(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'setting'.tr,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(SystemController controller) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text('language'.tr),
      subtitle: Text(languages[controller.system?.language] ?? 'not set'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(controller),
    );
  }

  Widget _buildThemeSelector(SystemController controller) {
    final themeMode =
        Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';

    return ListTile(
      leading: Icon(themeMode == 'dark' ? Icons.dark_mode : Icons.light_mode),
      title:  Text('theme'.tr),
      subtitle: Text(themeData[controller.system?.theme]?.$1?? 'not_set'.tr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(controller),
    );
  }

  Widget _buildLockSwitch() {
    return ListTile(
      leading: const Icon(Icons.lock),
      title:  Text('enable_lock'.tr),
      trailing: Switch(
        value: SystemController.to.system?.lock=='1',
        onChanged: (value) => SystemController.to.changeLock(lock:value?'1':'0'),
      ),
    );
  }

  Widget _buildLockPassword() {
    String password=SystemController.to.system?.lockPassword??'';
    return ListTile(
      leading: const Icon(Icons.password),
      title:  Text('lock_password'.tr),
      subtitle: Text(password.isEmpty ? 'not_set'.tr : '••••••'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _setLockPassword(),
    );
  }

  Widget _buildLockTimeout() {
    int lockTimeout = SystemController.to.system?.lockInterval??0;
    return ListTile(
      leading: const Icon(Icons.timer),
      title:  Text('lock_timeout'.tr),
      subtitle: Text('$lockTimeout ${'second'.tr}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _selectLockTimeout(),
    );
  }

  Widget _buildCachePath(SystemController controller) {
    return ListTile(
      leading: const Icon(Icons.storage),
      title:  Text('cache_path'.tr),
      subtitle: Text(controller.system!.cacheDir!),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _changeCachePath(),
    );
  }

  Widget _buildVersionInfo() {
    return ListTile(
      leading: const Icon(Icons.info),
      title:  Text('app_version'.tr),
      subtitle: Text('${'current_version'.tr} v${SystemController.to.version}'),
    );
  }
  Widget _buildContactUs() {
    return ListTile(
      leading:Padding(padding: EdgeInsets.only(left: 3),child: SvgPicture.asset(
        'assets/icons/github.svg',
        width: 20,
        height: 20,
      ),),
      title:  Text('contact_us'.tr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => launchUrl(Uri.parse('https://github.com/soyspace/x_note')),
    );
  }
  Widget _buildClearCache(SystemController controller) {
    return ListTile(
      leading: const Icon(Icons.delete),
      title:  Text('clear_cache'.tr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _confirmClearCache(),
    );
  }

  // ----- 功能方法 -----
  Future<void> _showLanguageDialog(controller) async {
    final result = await AppDialog.showCustom<String>(
      context,
      child: SizedBox(
        height: 300,
        width: 500,
        child: Column(
          children: [
             Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'language'.tr,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Column(
                children:
                    languages.keys
                        .map(
                          (l) => ListTile(
                            title: Text(languages[l] ?? l),
                            onTap: () {
                              controller.changeLanguage(l);
                              return Navigator.pop(context, languages[l]);
                            },
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      // 实际应该调用语言切换逻辑
      // ScaffoldMessenger.of(
      //   context,
      // ).showSnackBar(SnackBar(content: Text('已选择: $result')));
    }
  }

  Future<void> _showThemeDialog(controller) async {
    final themes = [
      //{'name': 'system'.tr, 'mode': "system"},
      {'name': 'light'.tr, 'mode': "light"},
      {'name': 'dark'.tr, 'mode': "dark"},
    ];
    // final themes=themeData.keys.map((e) => {
    //   'name':themeData[e]?.$1,
    //   'mode':e,
    // }).toList();

    final result = await AppDialog.showCustom<String>(
      context,
      child: SizedBox(
        height: 200,
        width: 300,
        child: Column(
          children: [
             Padding(
              padding: EdgeInsets.all(16),
              child: Text('please_select_theme'.tr),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: themes.length,
                itemBuilder: (_, index) => ListTile(
                  title: Text(themes[index]['name'] as String),
                  onTap: () => Navigator.pop(context, themes[index]['mode'] as String),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      _toggleTheme(result);
    }
  }

  void _toggleTheme(String mode) {
    SystemController.to.changeTheme(mode);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('已切换至 ${themeData[mode]?.$1}')),
    // );
  }

  Future<void> _setLockPassword() async {
    final password = await AppDialog.showInput(
      context,
      title: 'set_lock_password'.tr,
      hintText: 'please_input_password'.tr,
    );
    if (password != null && password.length == 6) {
      SystemController.to.changeLock(password:  password);
    }
  }

  Future<void> _selectLockTimeout() async {
    final timeouts = [15, 30, 60, 120, 300];
    final result = await AppDialog.showCustom<int>(
      context,
      child: SizedBox(
        height: 300,
        width: 300,
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(16), child: Text('lock_timeout'.tr)),
            Expanded(
              child: ListView.builder(
                itemCount: timeouts.length,
                itemBuilder:
                    (_, index) => ListTile(
                      title: Text('${timeouts[index]} ${'second'.tr}'),
                      onTap: () => Navigator.pop(context, timeouts[index]),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      SystemController.to.changeLock(lockInterval:  result);
    }
  }

  Future<void> _changeCachePath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(initialDirectory: SystemController.to.system?.cacheDir);
    if (selectedDirectory != null) {
      SystemController.to.changeCache(selectedDirectory);
    }
  }

  Future<void> _confirmClearCache() async {
    final confirm = await AppDialog.showConfirm(
      context,
      title: 'clear_cache'.tr,
      content: 'clear_cache_confirm'.tr,
    );
    if (confirm == true) {
      // 实际应该调用缓存清除逻辑
      SystemController.to.clearCache();
      Get.snackbar('clear_cache'.tr,'clear_cache_success'.tr);
    }
  }
}
