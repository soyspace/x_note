import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_code_block_component.dart';
import 'package:XNote/service/clipboard_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

extension PasteFromImage on EditorState {
  Future<bool> pasteCode() async {
    final context = document.root.context;

    if (context == null) {
      return false;
    }
     final data = await getIt<ClipboardService>().getData();
    final inAppJson = data.inAppJson;
    final html = data.html;
    final plainText = data.plainText;
    final codeText=inAppJson??html??plainText;
    if (codeText == null) {
      return false;
    }
    insertCodeNode(codeText);
    return true;
  }

  Future<void> insertCodeNode(String text, {Selection? selection}) async {
    selection ??= this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final transaction = this.transaction;
    // if the current node is empty paragraph, replace it with image node
    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(
          node.path,
          customCodeNode(
            text: text,
            //type: type,
          ),
        )
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        node.path.next,
        customCodeNode(
          text: text,
          //type: type,
        ),
      );
    }

    transaction.afterSelection = Selection.collapsed(
      Position(path: node.path.next),
    );

    return apply(transaction);
  }
}
Node customCodeNode({
  required String text,
}) {
  return Node(
    type: CustomCodeBlockKeys.type,
    attributes: {
      CustomCodeBlockKeys.code: text,
    },
  );
}