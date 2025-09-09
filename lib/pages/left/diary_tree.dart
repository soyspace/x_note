import 'package:XNote/controller/diary_controller.dart';
import 'package:XNote/controller/notebook_controller.dart';
import 'package:XNote/pages/left/tree_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:recursive_tree_flutter/models/abstract_node_type.dart';
import 'package:recursive_tree_flutter/models/tree_type.dart';
import 'package:recursive_tree_flutter/views/expandable_tree_mixin.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../utils/note_utils.dart';

class DiaryTree extends StatefulWidget {
  const DiaryTree({super.key});

  @override
  State<DiaryTree> createState() => _DiaryTreeState();
}

class _DiaryTreeState extends State<DiaryTree>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).shadowColor,
      body: SingleChildScrollView(
        child: GetBuilder<DiaryController>(
          builder: (controller) {
            return controller.onSearching?Container(
              alignment: Alignment.center,
              child: Text('Searching...'),
            ):Column(
              children:
                  controller.filterDiaryTreeNodes
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
  const _VTSNodeWidget(this.key, this.tree, {required this.onNodeDataChanged});

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
  void initTree() {
    tree = widget.tree;
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
    //if (!widget.tree.data.isShowedInSearching) return const SizedBox.shrink();

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
                padding: EdgeInsets.only(left: 0, top: 0),
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
    if (!_isHover!) {
      return tree.data.note?.sync == '1'
          ? SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ).paddingOnly(right: 8.0)
          : const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: _buildNoteTooltipMessage(),
          child: InkWell(
            focusNode: FocusNode(skipTraversal: true),
            mouseCursor: SystemMouseCursors.basic,
            hoverColor: Theme.of(context).hoverColor,
            onTap: () {},
            child: SvgPicture.asset(
              'assets/icons/more.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
          ).constrained(width: 16, height: 16),
        ),
        // const SizedBox(width: 8.0),
        // InkWell(
        //   focusNode: FocusNode(skipTraversal: true),
        //   mouseCursor: SystemMouseCursors.basic,
        //   hoverColor: Colors.grey[200],
        //   onTap: () {},
        //   child: SvgPicture.asset(
        //     'assets/icons/plus.svg',
        //     width: 16,
        //     height: 16,
        //     colorFilter: ColorFilter.mode(Colors.black26!, BlendMode.srcIn),
        //   ),
        // ).constrained(width: 16, height: 16),
      ],
    ).marginOnly(right: 8.0);
  }

  String _buildNoteTooltipMessage() {
    final note = tree.data.note;
    if (note == null) return 'No data';

    // 构建要显示的note属性信息
    final buffer = StringBuffer();
    buffer.writeln('Properties:');

    // 这里添加你想显示的note属性，以下是一些示例
    // 你可以根据TreeNodeType中note对象的实际属性进行调整
    buffer.writeln('ID: ${note.id ?? "N/A"}');
    buffer.writeln('Title: ${note.name ?? "N/A"}');
    buffer.writeln('Type: ${note.type ?? "N/A"}');
    buffer.writeln('Length: ${note.size ?? "N/A"}');
    buffer.writeln('Created: ${fromDateTimeMillis(note.createTime ?? 0)}');
    buffer.writeln('Updated: ${fromDateTimeMillis(note.updateTime ?? 0)}');

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
        (int index) => _VTSNodeWidget(
          GlobalObjectKey(list[index]),
          list[index],
          onNodeDataChanged: widget.onNodeDataChanged,
        ),
      );

  @override
  void updateStateToggleExpansion() => setState(() => toggleExpansion());
}
