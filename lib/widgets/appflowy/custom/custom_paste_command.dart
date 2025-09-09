import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:XNote/widgets/appflowy/custom/paste_from_file.dart';
import 'package:XNote/widgets/appflowy/custom/paste_from_html.dart';
import 'package:XNote/widgets/appflowy/custom/paste_from_plain_text.dart';
import 'package:XNote/service/clipboard_service.dart';
import 'package:XNote/widgets/appflowy/custom/paste_from_image.dart';
import 'package:XNote/widgets/appflowy/custom/paste_from_in_app_json.dart';
import 'package:XNote/widgets/appflowy/log.dart';
import 'package:get_it/get_it.dart';


GetIt getIt = GetIt.instance;

/// - support
///   - desktop
///   - web
///   - mobile
///
final CommandShortcutEvent customPasteCommand = CommandShortcutEvent(
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

  doPaste(editorState).then((_) {
    final context = editorState.document.root.context;
    if (context != null && context.mounted) {
      //context.read<ClipboardState>().didPaste();
    }
  });

  return KeyEventResult.handled;
};


Future<void> doPaste(EditorState editorState) async {
  final selection = editorState.selection;
  if (selection == null) {
    return;
  }

  //EditorNotification.paste().post();

  // dispatch the paste event
  final data = await getIt<ClipboardService>().getData();
  final inAppJson = data.inAppJson;
  final html = data.html;
  final plainText = data.plainText;
  final images = data.images;
  final files = data.files;

  // dump the length of the data here, don't log the data itself for privacy concerns
  Log.info('paste command: inAppJson: ${inAppJson?.length}');
  Log.info('paste command: html: ${html?.length}');
  Log.info('paste command: plainText: ${plainText?.length}');

//处理文件
  if (inAppJson != null && inAppJson.isNotEmpty) {
    if (await editorState.pasteInAppJson(inAppJson)) {
      return Log.info('Pasted in app json');
    }
  }

//处理文件
  if (html != null && html.isNotEmpty) {
    await editorState.deleteSelectionIfNeeded();
    if (await editorState.pasteHtml(html)) {
      return Log.info('Pasted html');
    }
  }
 //处理纯文本
  if (plainText != null && plainText.isNotEmpty) {
    final currentSelection = editorState.selection;
    if (currentSelection == null) {
      await editorState.updateSelectionWithReason(
        selection,
        reason: SelectionUpdateReason.uiEvent,
      );
    }
    await editorState.pastePlainText(plainText);
    return Log.info('Pasted plain text');
  }
//
  //处理图片
 await Future.forEach(images ?? [], (image) async {
    Log.info('paste command: ${image.$1}, ${image.$2?.length}');

    if (image.$1.isNotEmpty && image.$2 != null && image.$2!.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteImage(
        image.$1,
        image.$2!,
        "ddd",
        selection: selection,
      );
      if (result) {
        return Log.info('Pasted image ${image.$1}');
      }
    }
    });
  if(images!=null&&images.isNotEmpty){

    return Log.info('Pasted image');
  }
 //处理文件 

 await Future.forEach(files??[], (file) async {
    Log.info('paste command: ${file.$1}, ${file.$2?.length}');

    if (file.$1.isNotEmpty && file.$2 != null && file.$2!.isNotEmpty) {
      await editorState.deleteSelectionIfNeeded();
      final result = await editorState.pasteFile(
        file.$1,
        file.$2!,
        "ddd",
        selection: selection,
      );
      if (result) {
        return Log.info('Pasted file ${file.$1}');
      }
    }
    });

  return Log.info('unable to parse the clipboard content');
}



// Future<void> doPlainPaste(EditorState editorState) async {
//   final selection = editorState.selection;
//   if (selection == null) {
//     return;
//   }

//   //EditorNotification.paste().post();

//   // dispatch the paste event
//   final data = await getIt<ClipboardService>().getData();
//   final plainText = data.plainText;
//   if (plainText != null && plainText.isNotEmpty) {
//     await editorState.pastePlainText(plainText);
//     Log.info('Pasted plain text');
//     return;
//   }
//   Log.info('unable to parse the clipboard content');
//   return;
// }


