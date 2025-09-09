import 'package:XNote/controller/system_controller.dart';
import 'package:XNote/pages/right/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:window_manager/window_manager.dart';

import '../../controller/notebook_controller.dart';
import '../../utils/note_utils.dart';

class RightIndex extends StatelessWidget {
  const RightIndex({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  final bool isExpanded;
  final VoidCallback onToggle;

  //窗口工具栏
  static final Map _toolbarButtons = {
    "minus": () async {
      //最小化
      await windowManager.minimize();
    },
    "max": () async {
      //最大化
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    },
    "close": () async {
      //关闭
      await windowManager.close();
    },
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).hoverColor,
      child: Column(
        children: [
          _buildToolBar(context),
          _buildBreadCrumbs(context),
          _buildEditor(context),
          _buildStatusBar(context),
        ],
      ),
    );
  }

  /// 工具栏,有缩小，放大，关闭按钮
  Widget _buildToolBar(BuildContext context) {
    Widget child = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) async {
        await windowManager.startDragging();
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4),
              child:
                  !isExpanded
                      ? ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 24,
                          maxWidth: 24,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.all(0),
                          hoverColor: Colors.grey[100],
                          mouseCursor: SystemMouseCursors.basic,
                          color: Colors.black26,
                          icon: Icon(Icons.chevron_right, size: 24),
                          onPressed: onToggle,
                        ),
                      )
                      : Text(""),
            ),
            Expanded(child: SizedBox()),
            ..._toolbarButtons.keys.map((key) {
              return Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: InkWell(
                  hoverColor: Theme.of(context).hoverColor.withAlpha(30),
                  onTap: () async {
                    await _toolbarButtons[key]!();
                  },
                  mouseCursor: SystemMouseCursors.basic,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: 10,
                      left: 10,
                      top: 8,
                      bottom: 8,
                    ),
                    child: SvgPicture.asset(
                      'assets/icons/$key.svg',
                      width: 16,
                      height: 16,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
    return child;
  }

  /// 面包屑
  Widget _buildBreadCrumbs(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(top:3,left: 10,right: 20,bottom: 7),
      height: 35,
      child: GetBuilder<NotebookController>(
        init: NotebookController.to,
        builder: (controller) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 18,color: Theme.of(context).primaryColor,),
              const SizedBox(width: 10),
              ...controller.breadCrumbs.map((item) {
                return Row(
                  children: [
                    GestureDetector(
                      onTap: (){
                        controller.setCurrentTreeNote(item, []);
                      },
                      child: Text(
                        "${item.data.note?.name}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.data.note?.id == controller.currentTreeNote?.data.note?.id
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withAlpha(95),
                        ),
                      ),
                    ),
                    if (item.data.note?.id != controller.currentTreeNote?.data.note?.id)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ),
                  ],
                );
              }),
              Spacer(),
              PopupMenuButton<String>(
                offset: const Offset(0, 20), // 菜单弹出位置偏移
                constraints: BoxConstraints(maxWidth: 100), // 菜单宽度限制
                padding: EdgeInsets.zero,
                icon: SvgPicture.asset(
                  'assets/icons/more.svg',
                  width: 24,
                  height: 24,
                ),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    padding: const EdgeInsets.only(left: 10),
                    height: 35,
                    value: 'copy',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/copy.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text('复制'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    padding: const EdgeInsets.only(left: 10),
                    height: 35,
                    value: 'export',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/export.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text('导出'),
                      ],
                    ),
                  ),
                ],
                onSelected: (String value) {
                  switch (value) {
                    case 'copy':
                      print('复制操作');
                      break;
                    case 'export':
                      print('导出操作');
                      break;
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Expanded(child: Container(color: Theme.of(context).hoverColor, child: Editor()));
  }

  Widget _buildStatusBar(BuildContext context){
    return GetBuilder<NotebookController>(
      id: "statusBar",
      init: NotebookController.to,
      builder: (controller) {
        return Container(
          padding: EdgeInsets.only(top:3,bottom:3,left: 10, right: 10),

          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 0.1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // if(controller.statusBarText.value!="") SizedBox(width: 10,height: 10,child: CircularProgressIndicator(strokeWidth: 2),),
              // Text(controller.statusBarText.value,style: TextStyle(fontSize: 12),),
              Text(controller.statusText),
              Spacer(),
              Text("${'update_time'.tr} ${fromDateTimeMillis(controller.currentTreeNote?.data.note!.updateTime??0)}",style: TextStyle(fontSize: 12),),
              SizedBox(width: 20,),
              Text("${'length'.tr} ${controller.currentTreeNote?.data.note?.size}",style: TextStyle(fontSize: 12),),
              SizedBox(width: 20,),
              InkWell(onTap: ()=>SystemController.to.lockScreen(),child: Icon(Icons.lock,size: 16,color: Colors.grey,)),
            ],
          ),
        );
      }
    );
  }

}
