  // showcase 3: customize the command shortcuts
  import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:XNote/widgets/appflowy/custom/custom_paste_command.dart';

List<CommandShortcutEvent> buildCommandShortcuts(BuildContext context) {
    return [
      // customize the highlight color
      customToggleHighlightCommand(
        style: ToggleColorsStyle(
          highlightColor: Colors.orange.shade700,
        ),
      ),
      customPasteCommand,
      ...[
        ...standardCommandShortcutEvents
          ..removeWhere(
            (el) => el == toggleHighlightCommand,
          )..removeWhere(
            (el) => el == pasteCommand,
          ),
      ],
      ...findAndReplaceCommands(
        context: context,
        localizations: FindReplaceLocalizations(
          find: 'Find',
          previousMatch: 'Previous match',
          nextMatch: 'Next match',
          close: 'Close',
          replace: 'Replace',
          replaceAll: 'Replace all',
          noResult: 'No result',
        ),
      ),
    ];
  }

final CommandShortcutEvent myPasteCommand = CommandShortcutEvent(
  key: 'paste the content',
  getDescription: () => AppFlowyEditorL10n.current.cmdPasteContent,
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: _pasteCommandHandler,
);

CommandShortcutEventHandler _pasteCommandHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return KeyEventResult.ignored;
  }

  () async {
    final data = await AppFlowyClipboard.getData();
    final text = data.text;
    final html = data.html;
    if (html != null && html.isNotEmpty) {
      // if the html is pasted successfully, then return
      // otherwise, paste the plain text
      if (await editorState.pasteHtml(html)) {
        return;
      }
    }

    if (text != null && text.isNotEmpty) {
      editorState.pastePlainText(text);
    }
  }();

  return KeyEventResult.handled;
};


RegExp _hrefRegex = RegExp(
  r'https?://(?:www\.)?[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(?:/[^\s]*)?',
);

RegExp _phoneRegex = RegExp(r'^\+?' // Optional '+' at start
    r'(?:[0-9][\s-.]?)+' // Sequence of digits with optional separators
    r'[0-9]$' // Ensure it ends with a digit
    );


extension on EditorState {
  Future<bool> pasteHtml(String html) async {
    final nodes = htmlToDocument(html).root.children.toList();
    // remove the front and back empty line
    while (nodes.isNotEmpty &&
        nodes.first.delta?.isEmpty == true &&
        nodes.first.children.isEmpty) {
      nodes.removeAt(0);
    }
    while (nodes.isNotEmpty &&
        nodes.last.delta?.isEmpty == true &&
        nodes.last.children.isEmpty) {
      nodes.removeLast();
    }
    if (nodes.isEmpty) {
      return false;
    }
    if (nodes.length == 1) {
      await pasteSingleLineNode(nodes.first);
    } else {
      await pasteMultiLineNodes(nodes.toList());
    }
    return true;
  }

  Future<void> pastePlainText(String plainText) async {
    final selectionAttributes = getDeltaAttributesInSelectionStart();
    // TODO remove this deletion after refactoring pasteHtmlIfAvailable below
    final selection = await deleteSelectionIfNeeded();

    if (selection == null) {
      return;
    }

    if (await maybeConvertToUrlOrPhone(plainText)) {
      return;
    }

    final nodes = plainText
        .split('\n')
        .map(
          (paragraph) => paragraph
            ..replaceAll(r'\r', '')
            ..trimRight(),
        )
        .map((paragraph) {
          Delta delta = Delta();
          if (_hrefRegex.hasMatch(paragraph) ||
              _phoneRegex.hasMatch(paragraph)) {
            final match = _hrefRegex.firstMatch(paragraph) ??
                _phoneRegex.firstMatch(paragraph);
            if (match != null) {
              int startPos = match.start;
              int endPos = match.end;
              final String? entity = match.group(0);
              if (entity != null) {
                /// insert the text before the link or phone
                if (startPos > 0) {
                  delta.insert(paragraph.substring(0, startPos));
                }

                /// insert the link or phone
                delta.insert(
                  paragraph.substring(startPos, endPos),
                  attributes: {
                    AppFlowyRichTextKeys.href:
                        _phoneRegex.hasMatch(entity) ? 'tel:$entity' : entity,
                  },
                );

                /// insert the text after the link or phone
                if (endPos < paragraph.length) {
                  delta.insert(paragraph.substring(endPos));
                }
              }
            }
          } else {
            delta.insert(paragraph, attributes: selectionAttributes);
          }
          return delta;
        })
        .map((paragraph) => paragraphNode(delta: paragraph))
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

  Future<bool> maybeConvertToUrlOrPhone(String plainText) async {
    final selection = this.selection;
    if (selection == null ||
        !selection.isSingle ||
        selection.isCollapsed ||
        (!_hrefRegex.hasMatch(plainText) && !_phoneRegex.hasMatch(plainText))) {
      return false;
    }

    final node = getNodeAtPath(selection.start.path);
    if (node == null) {
      return false;
    }

    final transaction = this.transaction;
    final isPhone = _phoneRegex.hasMatch(plainText);
    transaction.formatText(node, selection.startIndex, selection.length, {
      AppFlowyRichTextKeys.href: isPhone ? 'tel:$plainText' : plainText,
    });
    await apply(transaction);
    return true;
  }
}
