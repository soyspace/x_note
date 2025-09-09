import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_file_block_component.dart';
import 'package:XNote/widgets/appflowy/log.dart';
import 'package:path/path.dart' as p;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:XNote/service/application_data_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

GetIt getIt = GetIt.instance;

extension PasteFromFile on EditorState {
  Future<bool> pasteFile(
    String fileName,
    Uint8List fileBytes,
    String documentId, {
    Selection? selection,
  }) async {
    final context = document.root.context;

    if (context == null) {
      return false;
    }
    final filesPath = await getIt<ApplicationDataStorage>().getFilesPath();

    try {
      // create the directory if not exists
      String ext = p.extension(fileName);
      String srcFileName = '${Uuid().v1()}$ext';
      final filePath = p.join(filesPath, srcFileName);
      await File(filePath).writeAsBytes(fileBytes);
      await insertFileNode(srcFileName,fileName, selection: selection);
      debugPrint('inserted file node with path: $filePath');

      return true;
    } catch (e) {
      Log.error('cannot copy file file', e);
      if (context.mounted) {
        // showToastNotification(
        //   message: LocaleKeys.document_fileBlock_error_invalidFile.tr(),
        // );
      }
    }

    return false;
  }

  Future<void> insertFileNode(String src,String fileName, {Selection? selection}) async {

    selection ??= this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final transaction = this.transaction;
    // if the current node is empty paragraph, replace it with file node
    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(
          node.path,
          customFileNode(
            url: src,
            fileName: fileName
          ),
        )
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        node.path.next,
       customFileNode(
            url: src,
            fileName: fileName
          ),
      );
    }

    transaction.afterSelection = Selection.collapsed(
      Position(path: node.path.next),
    );

    return apply(transaction);
  }
}
