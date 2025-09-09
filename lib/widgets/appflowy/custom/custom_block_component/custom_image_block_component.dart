import 'dart:io';

import 'package:XNote/controller/notebook_controller.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;

import '../../../../controller/editor_controller.dart';
import '../../../../service/application_data_storage.dart';
import '../../../dialog.dart';
const kImagePlaceholderKey = 'imagePlaceholderKey';
GetIt getIt = GetIt.instance;

class CustomImageBlockKeys {
  const CustomImageBlockKeys._();

  static const String type = 'image';

  /// The align data of a image block.
  ///
  /// The value is a String.
  /// left, center, right
  static const String align = 'align';

  /// The image src of a image block.
  ///
  /// The value is a String.
  /// It can be a url or a base64 string(web).
  static const String url = 'url';

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
  /// The value is a CustomImageType enum.
  static const String imageType = 'image_type';
}

Node customImageNode({
  required String url,
  String align = 'center',
  double? height,
  double? width,
  String? fileName
}) {
  return Node(
    type: CustomImageBlockKeys.type,
    attributes: {
      CustomImageBlockKeys.url: url,
      "fileName":fileName,
      CustomImageBlockKeys.align: align,
      CustomImageBlockKeys.height: height,
      CustomImageBlockKeys.width: width,
    },
  );
}

typedef CustomImageBlockComponentMenuBuilder =
    Widget Function(
      Node node,
      CustomImageBlockComponentState state,
      //ValueNotifier<ResizableImageState> imageStateNotifier,
    );

class CustomImageBlockComponentBuilder extends BlockComponentBuilder {
  CustomImageBlockComponentBuilder({
    super.configuration,
    this.showMenu = false,
    this.menuBuilder=defaultImageMenuBuilder,
  });

  /// Whether to show the menu of this block component.
  final bool showMenu;

  ///
  final CustomImageBlockComponentMenuBuilder? menuBuilder;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomImageBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
      showMenu: showMenu,
      menuBuilder: menuBuilder,
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.children.isEmpty;
}

class CustomImageBlockComponent extends BlockComponentStatefulWidget {
  const CustomImageBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
    this.showMenu = false,
    this.menuBuilder,
  });

  /// Whether to show the menu of this block component.
  final bool showMenu;

  final CustomImageBlockComponentMenuBuilder? menuBuilder;

  @override
  State<CustomImageBlockComponent> createState() =>
      CustomImageBlockComponentState();
}

class CustomImageBlockComponentState extends State<CustomImageBlockComponent>


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
    String src = attributes[CustomImageBlockKeys.url];

    final alignment = AlignmentExtension.fromString(
      attributes[CustomImageBlockKeys.align] ?? 'center',
    );
    final width =
        attributes[CustomImageBlockKeys.width]?.toDouble() ??
        MediaQuery.of(context).size.width;
    final height = attributes[CustomImageBlockKeys.height]?.toDouble();


    return FutureBuilder(
      future: getImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final imagePath = snapshot.data as String;
           Widget child = ResizableImage(
            src:  src.startsWith("http")?src:p.join(imagePath, src),
            width: width,
            height: height,
            editable: true,
            alignment: alignment,
            onResize: (width) {
              // final transaction = editorState.transaction
              //   ..updateNode(node, {CustomImageBlockKeys.width: width});
              // editorState.apply(transaction);
            },
          );

          // 新增：双击全屏预览
          child = GestureDetector(
            onDoubleTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) {
                  return GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      color: Colors.black.withOpacity(0.95),
                      alignment: Alignment.center,
                      child: InteractiveViewer(
                        child: Image.file(
                          File(p.join(imagePath, src)),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            child: child,
          );

          child = Padding(
            padding: padding,
            child: RepaintBoundary(key: imageKey, child: child),
          );

          child = BlockSelectionContainer(
            node: node,
            delegate: this,
            listenable: ValueNotifier<Selection?>(null),
            //blockColor: editorState.editorStyle.selectionColor,
            selectionAboveBlock: true,
            supportTypes: const [BlockSelectionType.block],
            child: child,
          );

          if (widget.showActions && widget.actionBuilder != null) {
            child = BlockComponentActionWrapper(
              node: node,
              actionBuilder: widget.actionBuilder!,
              actionTrailingBuilder: widget.actionTrailingBuilder,
              child: child,
            );
          }

          // show a hover menu on desktop or web
          //if (UniversalPlatform.isDesktopOrWeb) {
          if (widget.showMenu && widget.menuBuilder != null) {
            child = MouseRegion(
              onEnter: (_) => showActionsNotifier.value = true,
              onExit: (_) {
                if (!alwaysShowMenu) {
                  showActionsNotifier.value = false;
                }
              },
              hitTestBehavior: HitTestBehavior.opaque,
              opaque: false,
              child: ValueListenableBuilder<bool>(
                valueListenable: showActionsNotifier,
                builder: (_, value, child) {
                  return Stack(
                    children: [
                      BlockSelectionContainer(
                        node: node,
                        delegate: this,
                        listenable: ValueNotifier<Selection?>(null),
                        cursorColor: Colors.black12,
                        selectionColor: Colors.redAccent,
                        child: child!,
                      ),
                      if (value) widget.menuBuilder!(widget.node, this),
                    ],
                  );
                },
                child: child,
              ),
            );
          }
          return child;
        }
      },
    );
  }

  Future<String> getImagePath() async {
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

Widget defaultImageMenuBuilder(Node node, CustomImageBlockComponentState state) {
  final attributes = node.attributes;
  final src = attributes[CustomImageBlockKeys.url];
  return Positioned(
    top: 8,
    right: 8,
    child: Material(
      color: const Color.fromARGB(0, 216, 216, 216),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.download, color: Color.fromARGB(255, 49, 48, 48)),
            tooltip: '下载图片',
            onPressed: () async {
              final imagePath = await state.getImagePath();
              final file = File(p.join(imagePath, src));
              // 这里以桌面为例保存到桌面
              List<String> extensions= [
                p.extension(file.path).substring(1),
              ];
              String? outputFile =await FilePicker.platform.saveFile(
                  fileName: src,
                  allowedExtensions: extensions
              );
              if(outputFile!=null){
                await File(outputFile).writeAsBytes(await file.readAsBytes());
                Get.snackbar('成功', '图片保存至 $outputFile');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 49, 48, 48)),
            tooltip: '删除图片',
            onPressed: () async {
              EditorController.to.deleteNode(node);
            },
          ),
        ],
      ),
    ),
  );
}