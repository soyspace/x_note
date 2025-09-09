import 'package:XNote/controller/system_controller.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:XNote/widgets/appflowy/block_component_builder.dart';
import 'package:XNote/widgets/appflowy/command_shortcuts.dart';
import 'package:XNote/widgets/appflowy/custom/custom_conext_menu.dart';
import 'package:XNote/widgets/appflowy/custom/slash_menu/custom_slash_command.dart';
import 'package:XNote/widgets/appflowy/desktop_editor_style.dart';
import 'package:get_it/get_it.dart';

import '../../controller/editor_controller.dart';
import '../../controller/remote_controller.dart';
import '../../storage/entity/note.dart';

GetIt getIt = GetIt.instance;

class AppFlowyPage extends StatefulWidget {
  const AppFlowyPage({super.key, required this.editorState});
  final EditorState editorState;
  @override
  State<AppFlowyPage> createState() => _AppFlowyPageState();
}

class _AppFlowyPageState extends State<AppFlowyPage> {

  late final EditorScrollController editorScrollController;

  late EditorStyle editorStyle;
  late Map<String, BlockComponentBuilder> blockComponentBuilders;
  late List<CommandShortcutEvent> commandShortcuts;
  bool synced=false;
  @override
  void initState() {
    super.initState();
  
    if(getIt.isRegistered<EditorState>()){
      getIt.unregister<EditorState>();
    }
    getIt.registerSingleton<EditorState>(widget.editorState);

    editorScrollController = EditorScrollController(
      editorState: widget.editorState,
      shrinkWrap: false,
    );
    //  editorState.updateSelectionWithReason(
    //     Selection.collapsed(Position(path: [0])),
    //   );
    editorStyle = buildDesktopEditorStyle(context);
    blockComponentBuilders = buildBlockComponentBuilders();
    widget.editorState.selectionNotifier.addListener(() {
      // This is a workaround to ensure the editor scrolls to the focused selection
      // when the selection changes.
      //debugPrint("Selection changed: ${widget.editorState.selection}");
      SystemController.to.refreshTime=0;
      //       int lastRowLength = editorState.document.last?.delta?.length ?? 0;
      // debugPrint('Document last: $lastRowLength');
      // if(lastRowLength>0){
      //       editorState.insertNewLine(position: Position(path: [editorState.document.root.children.length+1], offset: 0));
      //       final transaction = editorState.transaction;
      //       transaction.insertNode([editorState.document.root.children.length], paragraphNode());
      //       editorState.apply(transaction);
      // }
    });
  }

  @override
  void dispose() {
    editorScrollController.dispose();
    widget.editorState.dispose();

    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();

    editorStyle = buildDesktopEditorStyle(context);
    blockComponentBuilders = buildBlockComponentBuilders();
  }

  @override
  Widget build(BuildContext context) {
    commandShortcuts = buildCommandShortcuts(context);
    final (bool autoFocus, Selection? selection) =
        _computeAutoFocusParameters();

    return Scaffold(
      backgroundColor: Theme.of(context).hoverColor,
      body: Listener(
        onPointerDown: (event) async {
          if(EditorController.to.treeNodeType!=null&&synced==false) {
            Note? note =await SystemController.to.database.noteDao.findNoteById(EditorController.to.treeNodeType!.note!.id!).first;
            if(note!=null){
              EditorController.to.treeNodeType?.note=note;
            }
            RemoteController.to.syncNoteSingle(EditorController.to.treeNodeType!);
            synced=true;
          }
        },
        child: FloatingToolbar(
          items: [
            //paragraphItem,
            ...headingItems,
            ...markdownFormatItems,
            quoteItem,
            bulletedListItem,
            numberedListItem,
            linkItem,
            buildTextColorItem(),
            buildHighlightColorItem(),
            ...textDirectionItems,
            ...alignmentItems,
          ],
          tooltipBuilder: (context, _, message, child) {
            return Tooltip(message: message, preferBelow: false, child: child);
          },
          //padding: EdgeInsets.only(top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          style: FloatingToolbarStyle(
            backgroundColor: Colors.white,
            toolbarIconColor: Colors.black87,
            toolbarActiveColor: Colors.black,
            toolbarShadowColor: Colors.black12,
            toolbarElevation: 2,
          ),
          editorState: widget.editorState,
          textDirection: TextDirection.ltr,
          editorScrollController: editorScrollController,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AppFlowyEditor(
              editorState: widget.editorState,
              editorScrollController: editorScrollController,
              blockComponentBuilders: blockComponentBuilders,
              commandShortcutEvents: commandShortcuts,
              characterShortcutEvents: [
                ...standardCharacterShortcutEvents
                  ..removeWhere((el) => el == slashCommand),
                myCustomSlashCommand,
                // ...codeBlockCharacterEvents,
              ],
              // customize the context menu items
              contextMenuItems: custotmContextMenuItems,
              autoFocus: autoFocus,
              shrinkWrap: true,
              focusNode: FocusNode(),
              focusedSelection: selection,
              editorStyle: editorStyle,
              enableAutoComplete: true,
              //autoScrollEdgeOffset: 250,
              dropTargetStyle: const AppFlowyDropTargetStyle(
                color: Colors.blueAccent,
              ),
              footer: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () async {
                  // if the last one isn't a empty node, insert a new empty node.
                  await _focusOnLastEmptyParagraph();
                },
                child: SizedBox(width: double.infinity, height: 600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (bool, Selection?) _computeAutoFocusParameters() {
    if (widget.editorState.document.isEmpty) {
      return (true, Selection.collapsed(Position(path: [0])));
    }
    return const (false, null);
  }

  Future<void> _focusOnLastEmptyParagraph() async {
    final root = widget.editorState.document.root;
    final lastNode = root.children.lastOrNull;
    final transaction = widget.editorState.transaction;
    if (lastNode == null ||
        lastNode.delta?.isEmpty == false ||
        lastNode.type != ParagraphBlockKeys.type) {
      transaction.insertNode([root.children.length], paragraphNode());
      transaction.afterSelection = Selection.collapsed(
        Position(path: [root.children.length]),
      );
    } else {
      transaction.afterSelection = Selection.collapsed(
        Position(path: lastNode.path),
      );
    }

    transaction.customSelectionType = SelectionType.inline;
    transaction.reason = SelectionUpdateReason.uiEvent;

    await widget.editorState.apply(transaction);
  }
}
