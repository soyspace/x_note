import 'package:XNote/controller/document_controller.dart';
import 'package:XNote/pages/left/tree_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:recursive_tree_flutter/views/expandable_tree_mixin.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../controller/notebook_controller.dart';
import '../../utils/note_utils.dart';
import '../../widgets/dialog.dart';

class DocumentTree extends StatefulWidget {
  const DocumentTree({super.key});

  @override
  State<DocumentTree> createState() => _DocumentTreeState();
}

class _DocumentTreeState extends State<DocumentTree> with AutomaticKeepAliveClientMixin{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).shadowColor,
      body: SingleChildScrollView(
        child: GetBuilder<DocumentController>(
          builder: (controller) {
            return controller.onSearching?Container(
              alignment: Alignment.center,
              child: Text('Searching...'),
            ):Column(
              children:
              controller.filterDocumentTreeNodes
                  .map(
                    (e) => FocusScope(
                  child: _VTSNodeWidget(
                    GlobalObjectKey(e),
                    e,
                    onNodeDataChanged: () {
                      controller.update();
                    },
                  ),
                ),
              )
                  .toList(),
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _VTSNodeWidget extends StatefulWidget {
  const _VTSNodeWidget(this.key,this.tree, {required this.onNodeDataChanged});

  final TreeType<TreeNodeType> tree;
  final GlobalKey key;
  /// IMPORTANT: Because this library **DOESN'T** use any state management
  /// library, therefore I need to use call back function like this - although
  /// it is more readable if using `Provider`.
  final VoidCallback onNodeDataChanged;

  @override
  State<_VTSNodeWidget> createState() => _VTSNodeWidgetState();
}
class _VTSNodeWidgetState<T extends AbsNodeType> extends State<_VTSNodeWidget>
    with SingleTickerProviderStateMixin, ExpandableTreeMixin<TreeNodeType> {

  final Tween<double> _turnsTween = Tween<double>(begin: -0.25, end: 0.0);



  bool? _isHover;
  bool popMenuOpen=false;


  @override
  initState() {
    super.initState();
    initTree();
    initRotationController();
    if (tree.data.isExpanded) {
      rotationController.forward();
    }
    _isHover = false;
  }

  @override
  void initTree() {
    tree = widget.tree;
  }
  @override
  void didUpdateWidget(oldWidget) {
    ///tree=oldWidget.tree;
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree.data.isExpanded) {
      rotationController.forward();
    } else {
      rotationController.reverse();
    }
  }
  @override
  void initRotationController() {
    rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    tree.data.focusNode.addListener(() {
      if (tree.data.focusNode.hasFocus) {
        NotebookController.to.setCurrentTreeNote(tree, []);
      }
    });
  }

  @override
  void dispose() {
    disposeRotationController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildView();

  @override
  Widget buildNode() {
    if (widget.tree.data.note?.removed=='1') return const SizedBox.shrink();

    return MouseRegion(
      onHover: (event) {
        setState(() {
          _isHover = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHover = false;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color:
          NotebookController.to.currentTreeNote?.data.note?.id ==
              tree.data.note?.id
              ? Theme.of(context).hoverColor
              : Colors.transparent,
        ),
        child: Column(
          children: [
            SizedBox(
              height: 30,
              child: InkWell(
                focusNode: tree.data.focusNode,
                mouseCursor: SystemMouseCursors.basic,
                onTap: () {
                  tree.data.focusNode.requestFocus();
                  //NotebookController.to.setCurrentTreeNote(widget.tree, []);
                  //updateStateToggleExpansion();
                },
                child: Row(
                  children: [
                    buildRotationIcon(),
                    Expanded(child: buildTitle()),
                    buildTrailing(),
                  ],
                ),
              ),
            ),
            ...?tree.data.note?.searchedSummaryWidgets?.map((e)=>e)
          ],
        ),
      ),
    );
  }

  //* __________________________________________________________________________

  Widget buildRotationIcon() {
    return RotationTransition(
      turns: _turnsTween.animate(rotationController),
      child:
      tree.children.isEmpty
          ? SizedBox(width: 24, height: 24)
          : IconButton(
        padding: EdgeInsets.only(left: 0,top: 0),
        constraints: BoxConstraints.tight(Size(24, 24)),
        iconSize: 16,
        icon: const Icon(Icons.expand_more, size: 16.0),
        onPressed: updateStateToggleExpansion,
      ),
    );
  }

  Widget buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Text(
        tree.data.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget buildTrailing() {

    PopupMenuButton popupMenuButton = PopupMenuButton<String>(
      menuPadding: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(),
      color: Theme.of(context).cardColor.withAlpha(60),
      offset: Offset(0, 32),
      onOpened: (){
        popMenuOpen=true;
      },
      itemBuilder: (BuildContext context_) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          height: 32,
          onTap: () async {
            String? title = await AppDialog.showInput(context, title: "please_input_title".tr);
            if (title != null) {
              DocumentController.to.newDocument(tree, title);
            }
          },
          value: 'add',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/plus.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              const Text('添加'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: () async {
            String? title = await AppDialog.showInput(context, title: "please_input_title".tr,defaultValue: tree.data.title);
            if (title != null) {
              await NotebookController.to.rename(tree.data,title);
              tree.data.title = title;
              setState(() {

              });
            }
          },
          height: 32,
          value: 'rename',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/rename.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              const Text('重命名'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: () async {
            bool? confirm_ = await AppDialog.showConfirm(context, title: 'delete'.tr, content: 'confirm_delete'.tr);
            if (confirm_??false) {
              tree.data.note?.removed = '1';
              await NotebookController.to.remove(tree.data);
              //setState(() {});
            }
          },
          height: 32,
          value: 'delete',
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              const Text('删除'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          height: 32,
          value: 'properties',
          child: Tooltip(
            message: _getNoteTooltipMessage(),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/properties.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                const Text('属性'),
              ],
            ),
          ),
        ),
      ],
      child: Padding(padding: EdgeInsets.only(right: 8.0) ,child: SvgPicture.asset(
        'assets/icons/more.svg',
        width: 16,
        height: 16,
        colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
      ),),
    );

    if (!_isHover!&&!popMenuOpen) {
      return tree.data.note?.sync == '1'
          ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth:2)).paddingOnly(right: 8.0)
          : const SizedBox.shrink();
    }
    return popupMenuButton;
  }

  String _getNoteTooltipMessage() {
    if (tree.data.note == null) {
      return 'No data';
    }

    final buffer = StringBuffer();
    final note = tree.data.note;
    if (note == null) return 'No data';

    // 构建要显示的note属性信息
    buffer.writeln('Note Properties:');

    // 这里添加你想显示的note属性，以下是一些示例
    // 你可以根据TreeNodeType中note对象的实际属性进行调整
    buffer.writeln('ID: ${note.id ?? "N/A"}');
    buffer.writeln('Title: ${note.name ?? "N/A"}');
    buffer.writeln('Type: ${note.type ?? "N/A"}');
    buffer.writeln('Length: ${note.size ?? "N/A"}');
    buffer.writeln('Created: ${fromDateTimeMillis(note.createTime??0)}');
    buffer.writeln('Updated: ${fromDateTimeMillis(note.updateTime??0)}');
    return buffer.toString();
  }


  @override
  Widget buildChildrenNodes({
    final EdgeInsets? padding = const EdgeInsets.only(left: 8),
  }) {
    return super.buildChildrenNodes(padding: padding);
  }

  //* __________________________________________________________________________

  @override
  List<Widget> generateChildrenNodesWidget(List<TreeType<TreeNodeType>> list) =>
      List.generate(
        list.length,
            (int index) => _VTSNodeWidget(GlobalObjectKey(list[index]),
          list[index],
          onNodeDataChanged: widget.onNodeDataChanged,
        ),
      );

  @override
  void updateStateToggleExpansion() => setState(() => toggleExpansion());
}