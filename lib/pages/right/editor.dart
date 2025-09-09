import 'package:XNote/controller/editor_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/notebook_controller.dart';
import '../../widgets/appflowy/index_page.dart';

class Editor extends StatelessWidget {
  const Editor({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditorController>(
      builder:
          (controller) => Stack(
        children: [
          AppFlowyPage(key:GlobalObjectKey(controller.editorState),editorState: controller.editorState),
          Positioned(
            right: 20,
            bottom: 20,
            child: IconButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
              ),
              color: Colors.blue,
              icon: const Icon(Icons.save),
              onPressed: () async {
                NotebookController.to.saveNote(NotebookController.to.currentTreeNote!.data);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// class _EditorState extends State<Editor> {
//
//   @override
//   void didUpdateWidget(covariant Editor oldWidget) {
//     super.didUpdateWidget(oldWidget);
//   }
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<EditorController>(
//       builder:
//           (controller) => Stack(
//             children: [
//               AppFlowyPage(editorState: controller.editorState),
//               Positioned(
//                 right: 20,
//                 bottom: 20,
//                 child: IconButton(
//                   style: ButtonStyle(
//                     backgroundColor: WidgetStateProperty.all(Colors.grey[300]),
//                   ),
//                   color: Colors.blue,
//                   icon: const Icon(Icons.save),
//                   onPressed: () async {
//                     NotebookController.to.saveNote(NotebookController.to.currentTreeNote!.data);
//                   },
//                 ),
//               ),
//             ],
//           ),
//     );
//   }
// }
