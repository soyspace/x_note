
import 'dart:io';

import 'package:XNote/controller/editor_controller.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:get/route_manager.dart';

import '../../../../service/application_data_storage.dart';

const kImagePlaceholderKey = 'imagePlaceholderKey';
GetIt getIt = GetIt.instance;

class CustomFileBlockKeys {
  const CustomFileBlockKeys._();

  static const String type = 'file';

  /// The align data of a image block.
  ///
  /// The value is a String.
  /// left, center, right
  static const String align = 'align';

  /// The file name in path
  ///
  /// The value is a String.
  static const String url = 'url';

  /// display name
  static const String fileName = 'file_name';

  /// The height of a image block.
  ///
  /// The value is a double.
  static const String width = 'width';

  /// The width of a image block.
  ///
  /// The value is a double.
  static const String height = 'height';

  /// The image type of a image block.
  ///
  /// The value is a customFileType enum.
  static const String imageType = 'image_type';
}

Node customFileNode({
  required String url,
  required String fileName,
  String align = 'center',
  double? height,
  double? width,
}) {
  return Node(
    type: CustomFileBlockKeys.type,
    attributes: {
      CustomFileBlockKeys.url: url,
      CustomFileBlockKeys.fileName: fileName,
      CustomFileBlockKeys.align: align,
      CustomFileBlockKeys.height: height,
      CustomFileBlockKeys.width: width,
    },
  );
}

class CustomFileBlockComponentBuilder extends BlockComponentBuilder {
  CustomFileBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomFileBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.children.isEmpty;
}

class CustomFileBlockComponent extends BlockComponentStatefulWidget {
  const CustomFileBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  /// Whether to show the menu of this block component.

  @override
  State<CustomFileBlockComponent> createState() =>
      CustomFileBlockComponentState();
}

class CustomFileBlockComponentState extends State<CustomFileBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final imageKey = GlobalKey();
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  //late final editorState = Provider.of<EditorState>(context, listen: false);

  final showActionsNotifier = ValueNotifier<bool>(false);
  // final imageStateNotifier =
  //     ValueNotifier<ResizableImageState>(ResizableImageState.loading);

  bool alwaysShowMenu = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final attributes = node.attributes;
    final srcFileName = attributes[CustomFileBlockKeys.url];
    final fileName = attributes[CustomFileBlockKeys.fileName];

    // final alignment = AlignmentExtension.fromString(
    //   attributes[CustomFileBlockKeys.align] ?? 'center',
    // );
    // final width =
    //     attributes[CustomFileBlockKeys.width]?.toDouble() ??
    //     MediaQuery.of(context).size.width;
    // final height = attributes[CustomFileBlockKeys.height]?.toDouble();

    return FutureBuilder(
      future: getFilesPath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final filesPath = snapshot.data as String;
          final filePath = p.join(filesPath, srcFileName);
          // 新增：双击全屏预览
          // ...existing code...
          Widget child = MouseRegion(
            onEnter: (_) => showActionsNotifier.value = true,
            onExit: (_) => showActionsNotifier.value = false,
            child: ValueListenableBuilder<bool>(
              valueListenable: showActionsNotifier,
              builder: (context, show, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 文件图标
                      Container(
                        padding: const EdgeInsets.only(left: 8, right: 4),
                        child: const Icon(
                          Icons.insert_drive_file,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),

                          child: Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (show) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                          ),
                          tooltip: '查看',
                          onPressed:
                              () async => await launchUrl(Uri.file(filePath)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          tooltip: '下载',
                          onPressed: () async {
                            // await Clipboard.setData(
                            //   ClipboardData(text: filePath),
                            // );
                            List<String> extensions= [
                              p.extension(filePath).substring(1),
                            ];
                            String? outputFile =await FilePicker.platform.saveFile(
                              fileName: fileName,
                              allowedExtensions: extensions
                            );
                            if(outputFile!=null){
                              await File(outputFile).writeAsBytes(await File(filePath).readAsBytes());
                              Get.snackbar('成功', '文件保存至 $outputFile');
                            }

                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: '删除',
                          onPressed: () async {
                            if(await File(filePath).exists()) {
                              await File(filePath).delete();
                            }
                            EditorController.to.deleteNode(widget.node);
                            Get.snackbar('成功', '文件已删除');
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
          //child.marginOnly(top: 10);
          child = Container(margin: EdgeInsets.only(top: 10), child: child);
          // ...existing code...
          return child;
        }
      },
    );
  }

  Future<String> getFilesPath() async {
    return await getIt<ApplicationDataStorage>().getFilesPath();
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final imageBox = imageKey.currentContext?.findRenderObject();
    if (imageBox is RenderBox) {
      return padding.topLeft & imageBox.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final rects = getRectsInSelection(Selection.collapsed(position));
    return rects.firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final imageBox = imageKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && imageBox is RenderBox) {
      return [
        imageBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            imageBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);
}
