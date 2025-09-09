import 'dart:convert';

import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/controller/left_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/controller/remote_controller.dart';
import 'package:XNote/pages/left/diary_tree.dart';
import 'package:XNote/pages/left/document_tree.dart';
import 'package:XNote/pages/left/setting.dart';
import 'package:XNote/pages/left/tree_node.dart';
import 'package:XNote/storage/entity/note.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:get_it/get_it.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../service/onedrive_service.dart';
import '../../storage/entity/notebook.dart';
import '../../utils/note_utils.dart';
import '../../widgets/dialog.dart';

GetIt getIt = GetIt.instance;

class LeftIndex extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const LeftIndex({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<LeftIndex> createState() => _LeftIndexState();
}

class _LeftIndexState extends State<LeftIndex> {
  bool _isNoteBooTitleEditing = false;
  bool _noteBookMenuOpen = false;
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool showRecycleBin = false;
  final TextEditingController _titleEditingController = TextEditingController();
  final TextEditingController _searchEditingController =
      TextEditingController();

  void _search(int index, String keyword) {
    keyword = '%${keyword.trim()}%';
    DiaryController.to.searchNodes(keyword);
    DocumentController.to.searchNodes(keyword);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    DiaryController.to.writeTodayNote(syncNotebookData: false);
  }
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => LeftController.to.onHoverChange(true),
      onExit: (_) => LeftController.to.onHoverChange(false),
      child: AnimatedContainer(
        padding: const EdgeInsets.only(left: 12, right: 12),
        duration: const Duration(milliseconds: 300),
        width: widget.isExpanded ? 240 : 0,
        //width: 240,
        // 最小保留按钮空间
        //color: Colors.grey[200],
        color: Theme.of(context).shadowColor,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 216,
            child:
                widget.isExpanded
                    ? // 只在展开时显示内容
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogo(),
                        _buildNoteBook(),
                        showRecycleBin?_buildDeletedNotes():SizedBox.shrink(),
                        ... !showRecycleBin?[
                          _buildSearch(),
                          SizedBox(height: 10),
                          _buildAddButton(),
                          SizedBox(height: 15),
                          _buildTabs(),
                          SizedBox(height: 10),
                          _buildTreePages(),]:[]
                        // const LeftHeader(),
                        // const LeftBody(),
                      ],
                    )
                    : SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return GetBuilder<LeftController>(
      id: 'logo',
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.only(top: 12, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              Image.asset('assets/icons/logo256.png', width: 24, height: 24),
              Image.asset(
                'assets/icons/xnote.png',
                height: 13,
                color: Theme.of(context).primaryColor,
              ),
              Expanded(child: SizedBox.shrink()),
              Visibility.maintain(
                visible: controller.onHover || !widget.isExpanded,
                child: IconButton(
                  constraints: BoxConstraints(maxHeight: 24, maxWidth: 24),
                  padding: EdgeInsets.all(4),
                  mouseCursor: SystemMouseCursors.basic,
                  hoverColor: Theme.of(context).hoverColor,
                  color: Theme.of(context).primaryColor,
                  icon: Icon(Icons.settings, size: 16),
                  onPressed: () {
                    AppDialog.showCustom(context, child: SettingsPage());
                  },
                ),
              ),
              Visibility.maintain(
                visible: controller.onHover || !widget.isExpanded,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 24, maxWidth: 24),
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    mouseCursor: SystemMouseCursors.basic,
                    hoverColor: Theme.of(context).hoverColor,
                    color: Theme.of(context).primaryColor,
                    icon: Icon(
                      widget.isExpanded
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                    ),
                    onPressed: widget.onToggle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteBook() {
    return GetBuilder<LeftController>(
      id: 'notebook',
      builder: (controller) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GetBuilder<LeftController>(
            id: 'notebook',
            builder: (controller) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  SvgPicture.asset(
                    controller.notebookController.currentNotebook.cloud == '1'
                        ? 'assets/icons/OneDrive.svg'
                        : 'assets/icons/notebook.svg',
                    width: 16,
                    height: 16,
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isNoteBooTitleEditing = !_isNoteBooTitleEditing;
                      });
                    },
                    child:
                        _isNoteBooTitleEditing
                            ? _buildEditNoteBookTitle(
                              controller.notebookController,
                            )
                            : Text(
                              controller
                                  .notebookController
                                  .currentNotebook
                                  .name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                  ).expanded(flex: 1),
                  Material(
                    color: Colors.transparent,
                    child: Visibility.maintain(
                      visible:
                          controller.onHover ||
                          !widget.isExpanded ||
                          _noteBookMenuOpen,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: PopupMenuButton<String>(
                          onOpened: () {
                            _noteBookMenuOpen = true;
                          },
                          onCanceled: () {
                            _noteBookMenuOpen = false;
                          },
                          padding: EdgeInsets.all(3),
                          offset: Offset(20, 20),
                          style: ButtonStyle(),
                          icon: SvgPicture.asset(
                            'assets/icons/more.svg',
                            width: 24,
                            height: 24,
                          ),
                          itemBuilder:
                              (BuildContext context) => [
                                if (NotebookController
                                        .to
                                        .currentNotebook
                                        .cloud !=
                                    '1')
                                  PopupMenuItem(
                                    padding: EdgeInsets.only(left: 10),
                                    height: 35,
                                    value: 'sync',
                                    onTap: () async {
                                      // TODO: 添加同步功能
                                      await RemoteController.to.connect(
                                        RemoteType.oneDrive,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/sync.svg',
                                          width: 16,
                                          height: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text('sync_to_onedrive'.tr),
                                      ],
                                    ),
                                  ),
                                if (NotebookController
                                        .to
                                        .currentNotebook
                                        .cloud ==
                                    '1')
                                  PopupMenuItem(
                                    onTap: () {
                                      NotebookController
                                          .to
                                          .currentNotebook
                                          .cloud = '0';
                                      NotebookController.to.saveNotebookData(
                                        onlySaveNotebook: true,
                                      );
                                    },
                                    padding: EdgeInsets.only(left: 10),
                                    height: 35,
                                    value: 'cancel_sync',
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/cancel_sync.svg',
                                          width: 16,
                                          height: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text('sync_cancel'.tr),
                                      ],
                                    ),
                                  ),
                                PopupMenuItem(
                                  onTap: () {
                                    setState(() {
                                      showRecycleBin = true;
                                    });
                                  },
                                  padding: EdgeInsets.only(left: 10),
                                  height: 35,
                                  value: 'recycle_bin'.tr,
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/recycleBin.svg',
                                        width: 16,
                                        height: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text('recycle_bin'.tr),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  onTap: () {
                                    _showNotebookProperties(
                                      controller
                                          .notebookController
                                          .currentNotebook,
                                    );
                                  },
                                  padding: EdgeInsets.only(left: 10),
                                  height: 35,
                                  value: 'properties',
                                  child: Row(
                                    children: [
                                      SvgPicture.asset(
                                        'assets/icons/properties.svg',
                                        width: 16,
                                        height: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text('profile'.tr),
                                    ],
                                  ),
                                ),
                              ],
                          onSelected: (String value) {
                            _noteBookMenuOpen = false;
                            switch (value) {
                              case 'sync':
                                debugPrint('同步操作');
                                break;
                              case 'cancel_sync':
                                debugPrint('取消同步操作');
                                break;
                              case 'switch_notebook':
                                debugPrint('切换日记本操作');
                                break;
                              case 'properties':
                                debugPrint('属性操作');
                                break;
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showNotebookProperties(Notebook notebook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('profile'.tr),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                _buildPropertyRow('ID', notebook.id),
                _buildPropertyRow('title'.tr, notebook.name),
                _buildPropertyRow(
                  'create_time'.tr,
                  fromDateTimeMillis(notebook.createTime ?? 0),
                ),
                _buildPropertyRow(
                  'update_time'.tr,
                  fromDateTimeMillis(notebook.updateTime ?? 0),
                ),
                // 如果 cloud 为 1，显示 icon 信息
                if (notebook.cloud == '1')
                  _buildIconSection(jsonDecode(notebook.icon!)),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('close'.tr),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }

  Widget _buildIconSection(Map<String, dynamic>? icon) {
    if (icon == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'group_info'.tr,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        _buildPropertyRow('userPrincipalName'.tr, icon['userPrincipalName']),
        _buildPropertyRow('displayName'.tr, icon['displayName']),
        _buildPropertyRow('surname'.tr, icon['surname']),
        _buildPropertyRow('givenName'.tr, icon['givenName']),
        _buildPropertyRow('preferredLanguage'.tr, icon['preferredLanguage']),
        _buildPropertyRow('mail'.tr, icon['mail']),
        _buildPropertyRow('mobilePhone'.tr, icon['mobilePhone']),
        _buildPropertyRow('jobTitle'.tr, icon['jobTitle']),
        // _buildPropertyRow('办公地点', icon['officeLocation']),
        // _buildPropertyRow('办公电话', icon['businessPhones']?.join(', ')),
      ],
    );
  }

  Widget _buildEditNoteBookTitle(NotebookController controller) {
    _titleEditingController.text = controller.currentNotebook.name;
    return TextField(
      controller: _titleEditingController,
      style: TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(bottom: 1), // 调整下边距
        isDense: true,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor.withAlpha(54), // 浅灰色
            width: 0.5, // 更细的边框
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor, // 保持一致的浅灰色
            width: 0.5, // 更细的边框
          ),
        ),
      ),
      onChanged: (value) {
        controller.currentNotebook.name = _titleEditingController.text; // 保存输入值
      },
      onEditingComplete: () {
        controller.saveNotebookData(onlySaveNotebook: true);
        _isNoteBooTitleEditing = false; // 退出编辑状态
      },
    );
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8,
        children: [
          SvgPicture.asset(
            'assets/icons/search.svg',
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColor,
              BlendMode.srcIn,
            ),
          ),
          TextField(
            controller: _searchEditingController,
            style: TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.only(bottom: 1),
              // 调整下边距
              isDense: true,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor.withAlpha(54), // 浅灰色
                  width: 0.5, // 更细的边框
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor, // 保持一致的浅灰色
                  width: 0.5, // 更细的边框
                ),
              ),
              suffix: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _searchEditingController.clear();
                      _search(_currentIndex, "");
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(0),
                    child: Icon(Icons.close, size: 16),
                  ),
                ),
              ),
            ),
            onSubmitted: (value) {
              debugPrint("value: $value");
              if (value.isNotEmpty) {
                _search(_currentIndex, value);
              }
            },
          ).expanded(flex: 1),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return _buildIconButton(
      icon: Padding(
        padding: EdgeInsets.symmetric(),
        child: Icon(
          _currentIndex == 0 ? Icons.edit_note : Icons.add,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: _currentIndex == 0 ? "write_today".tr : "new_document".tr,
      selected: true,
      onPressed: () async {
        debugPrint("add");

        if (_currentIndex == 0) {
          DiaryController.to.writeTodayNote();
        } else if (_currentIndex == 1) {
          String? title = await AppDialog.showInput(
            context,
            title: "please_input".tr,
          );
          if (title != null) {
            DocumentController.to.newDocument(null, title);
          }
        }
      },
    );
  }

  Widget _buildTabs() {
    final List tabs = [
      {"title": "diary".tr, "icon": "date.svg", "index": 0},
      {"title": "document".tr, "icon": "doc.svg", "index": 1},
    ];
    return Container(
      padding: EdgeInsets.only(left: 0, right: 0),
      child: Row(
        spacing: 4,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            tabs.map((item) {
              return Expanded(
                child: _buildIconButton(
                  title: item['title'],
                  icon: SvgPicture.asset(
                    "assets/icons/${item['icon']}",
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  selected: _currentIndex == item['index'],
                  onPressed: () {
                    setState(() {
                      if (_currentIndex == item['index']) return;
                      _pageController.jumpToPage(item['index']);
                      _currentIndex = item['index'];
                      // if(_searchEditingController.text.isNotEmpty){
                      //   _search(_currentIndex,_searchEditingController.text);
                      // }
                    });
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTreePages() {
    return Expanded(
      child: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {},
        children: [
          // 日志页面内容
          DiaryTree(),
          // 文档页面内容
          DocumentTree(),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    Widget? icon,
    String? title,
    required bool selected,
    VoidCallback? onPressed,
    double height = 30,
  }) {
    return SizedBox(
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(
            Theme.of(context).primaryColor,
          ),
          mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (selected) {
              return Theme.of(context).hoverColor; // 选中状态背景色
            }
            return Colors.transparent; // 默认透明
          }),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          // padding: WidgetStateProperty.all(
          //   EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          // ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon ?? SizedBox.shrink(),
            SizedBox(width: 4),
            Text(title ?? "", overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedNotes() {

    Widget deletedNotes = FutureBuilder<List<TreeType<TreeNodeType>>>(
      future: DocumentController.to.findDeletedNodes(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: snapshot.data!.map((node)=>ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                  title: Text(generateTreeNodeTitle(node)),
                  titleTextStyle: TextStyle(fontSize: 16,color: Colors.black),
                  //dense: true,
                  subtitle: Text(node.data.note?.pureContent?? "",overflow: TextOverflow.ellipsis,style: TextStyle(fontSize: 14,color: Colors.grey),),
                  onTap: () {
                    NotebookController.to.setCurrentTreeNote(node,[]);
                  },
                  trailing: InkWell(
                      child: Icon(Icons.undo,size: 16,),
                      onTap: () {
                        setState(() {
                          NotebookController.to.remove(node.data,recovery: true);
                        });
                      }
                  )
              )).toList()
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );

    return Column(
      children: [
       Container(
         margin: EdgeInsets.only(top: 8),
         padding: EdgeInsets.only(left: 18, right: 18, bottom: 4,top: 4),
         decoration: BoxDecoration(
           color: Get.theme.hoverColor,
           borderRadius: BorderRadius.circular(16),
         ),
         child: Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Icon(Icons.recycling,size: 16,),
               Text("recycle_bin".tr),
               InkWell(
                    child: Icon(Icons.close,size: 16,),
                   onTap: () {
                     setState(() {
                       showRecycleBin = false;
                       _currentIndex=0;
                     });
                   }
               )
             ]
         ),
       ),
        deletedNotes
      ]
    );
  }
}
