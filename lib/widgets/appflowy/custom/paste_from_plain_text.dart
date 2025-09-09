

import 'package:appflowy_editor/appflowy_editor.dart';

const _hrefPattern =
    r'https?://(?:www\.)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[^\s]*)?';
final hrefRegex = RegExp(_hrefPattern);

extension PasteFromPlainText on EditorState {
  Future<void> pastePlainText(String plainText) async {
    await deleteSelectionIfNeeded();
    final nodes = plainText
        .split('\n')
        .map(
          (e) => e
            ..replaceAll(r'\r', '')
            ..trimRight(),
        )
        .map((e) => Delta()..insert(e))
        .map((e) => paragraphNode(delta: e))
        .toList();
    if (nodes.isEmpty) {
      return;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
  }


  Future<bool> pasteHtmlIfAvailable(String plainText) async {
    final selection = this.selection;
    if (selection == null ||
        !selection.isSingle ||
        selection.isCollapsed ||
        !hrefRegex.hasMatch(plainText)) {
      return false;
    }

    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return false;
    }

    final transaction = this.transaction;
    transaction.formatText(node, selection.startIndex, selection.length, {
      AppFlowyRichTextKeys.href: plainText,
    });
    await apply(transaction);
    //checkToShowPasteAsMenu(node);
    return true;
  }

  // void checkToShowPasteAsMenu(Node node) {
  //   if (selection == null || !selection!.isCollapsed) return;
  //   if (Platform.isAndroid || Platform.isIOS) return;
  //   final href = _getLinkFromNode(node);
  //   if (href != null) {
  //     final context = document.root.context;
  //     if (context != null && context.mounted) {
  //       PasteAsMenuService(context: context, editorState: this).show(href);
  //     }
  //   }
  // }

  // String? _getLinkFromNode(Node node) {
  //   final delta = node.delta;
  //   if (delta == null) return null;
  //   final inserts = delta.whereType<TextInsert>();
  //   if (inserts.isEmpty || inserts.length > 1) return null;
  //   final link = inserts.first.attributes?.href;
  //   if (link != null) return inserts.first.text;
  //   return null;
  // }
}
