import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_image_block_component.dart';
import 'package:XNote/widgets/appflowy/log.dart';
import 'package:path/path.dart' as p;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:XNote/service/application_data_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

GetIt getIt = GetIt.instance;

extension PasteFromImage on EditorState {
  Future<bool> pasteImage(
    String format,
    Uint8List imageBytes,
    String documentId, {
    Selection? selection,
        String? fileName
  }) async {
    final context = document.root.context;

    if (context == null) {
      return false;
    }
    final imagePath = await getIt<ApplicationDataStorage>().getFilesPath();

    try {
      // create the directory if not exists
      String src='${Uuid().v1()}.$format';
      final filePath = p.join(imagePath, src);
      await File(filePath).writeAsBytes(imageBytes);
      await insertImageNode(src, selection: selection, fileName: fileName);
      debugPrint('inserted image node with path: $filePath');

      return true;
    } catch (e) {
      Log.error('cannot copy image file', e);
      if (context.mounted) {
        // showToastNotification(
        //   message: LocaleKeys.document_imageBlock_error_invalidImage.tr(),
        // );
      }
    }

    return false;
  }

  Future<void> insertImageNode(String src, {Selection? selection,String? fileName}) async {
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
          customImageNode(
            url: src,
            width: 200,
            fileName: fileName
            //type: type,
          ),
        )
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        node.path.next,
        customImageNode(
          url: src,
           width: 200,
            fileName: fileName
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
