import 'package:XNote/widgets/appflowy/custom/paste_from_code.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

import 'custom_paste_command.dart';

final custotmContextMenuItems = [
  [
    // cut
    ContextMenuItem(
      getName: () => AppFlowyEditorL10n.current.cut,
      onPressed: (editorState) {
        handleCut(editorState);
      },
    ),
    // copy
    ContextMenuItem(
      getName: () => AppFlowyEditorL10n.current.copy,
      onPressed: (editorState) {
        handleCopy(editorState);
      },
    ),
    // Paste
    ContextMenuItem(
      getName: () => AppFlowyEditorL10n.current.paste,
      onPressed: (editorState) {
        customPasteCommand.execute(editorState);
      },
    ),
     // Paste Code
    ContextMenuItem(
      getName: () => "粘贴代码",
      onPressed: (editorState) {
        editorState.pasteCode();
      },
    ),
  ],
];