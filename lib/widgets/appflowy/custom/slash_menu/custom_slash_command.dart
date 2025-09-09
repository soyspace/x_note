import 'dart:io';

import 'package:XNote/widgets/appflowy/custom/paste_from_image.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const Set<String> _defaultSupportSlashMenuNodeTypes = {
  ParagraphBlockKeys.type,
  HeadingBlockKeys.type,
  TodoListBlockKeys.type,
  BulletedListBlockKeys.type,
  NumberedListBlockKeys.type,
  QuoteBlockKeys.type,
};
final CharacterShortcutEvent myCustomSlashCommand = CharacterShortcutEvent(
  key: 'show the slash menu',
  character: '/',
  handler:
      (editorState) async => await _showSlashMenu(editorState, [
        ...standardSelectionMenuItems..removeWhere((e)=>e.name==AppFlowyEditorL10n.current.image),
        SelectionMenuItem(
          getName: () => AppFlowyEditorL10n.current.image,
          icon: (editorState, isSelected, style) => SelectionMenuIconWidget(
            name: 'image',
            isSelected: isSelected,
            style: style,
          ),
          keywords: ['image'],
          handler: (editorState, menuService, context) {
            final container = Overlay.of(context, rootOverlay: true);
            showImageMenu(container, editorState, menuService,onInsertImage: (url){
              var imageBytes= File(url).readAsBytesSync();
                  editorState.pasteImage(url.substring(url.indexOf(".")+1),
                      imageBytes,"",fileName: url?.split(Platform.pathSeparator)?.last);
            });
          },
        ),
      ]),
);

SelectionMenuService? _selectionMenuService;
Future<bool> _showSlashMenu(
  EditorState editorState,
  List<SelectionMenuItem> items, {
  bool shouldInsertSlash = true,
  bool singleColumn = true,
  bool deleteKeywordsByDefault = false,
  SelectionMenuStyle style = SelectionMenuStyle.light,
  Set<String> supportSlashMenuNodeTypes = _defaultSupportSlashMenuNodeTypes,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    return false;
  }

  final selection = editorState.selection;
  if (selection == null) {
    return false;
  }

  // delete the selection
  if (!selection.isCollapsed) {
    await editorState.deleteSelection(selection);
  }

  final afterSelection = editorState.selection;
  if (afterSelection == null || !afterSelection.isCollapsed) {
    assert(false, 'the selection should be collapsed');
    return true;
  }

  final node = editorState.getNodeAtPath(selection.start.path);

  // only enable in white-list nodes
  if (node == null ||
      !_isSupportSlashMenuNode(node, supportSlashMenuNodeTypes)) {
    return false;
  }

  // insert the slash character
  if (shouldInsertSlash) {
    keepEditorFocusNotifier.increase();
    await editorState.insertTextAtPosition('/', position: selection.start);
  }

  // show the slash menu

  final context = editorState.getNodeAtPath(selection.start.path)?.context;
  if (context != null && context.mounted) {
    _selectionMenuService = SelectionMenu(
      context: context,
      editorState: editorState,
      selectionMenuItems: items,
      deleteSlashByDefault: shouldInsertSlash,
      deleteKeywordsByDefault: deleteKeywordsByDefault,
      singleColumn: singleColumn,
      style: style,
    );
    // if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
    //   _selectionMenuService?.show();
    // } else {
    await _selectionMenuService?.show();
    // }
  }

  if (shouldInsertSlash) {
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => keepEditorFocusNotifier.decrease(),
    );
  }

  return true;
}

bool _isSupportSlashMenuNode(
  Node node,
  Set<String> supportSlashMenuNodeWhiteList,
) {
  // Check if current node type is supported
  if (!supportSlashMenuNodeWhiteList.contains(node.type)) {
    return false;
  }

  // If node has a parent and level > 1, recursively check parent nodes
  if (node.level > 1 && node.parent != null) {
    return _isSupportSlashMenuNode(node.parent!, supportSlashMenuNodeWhiteList);
  }

  return true;
}
