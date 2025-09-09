import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' as my_get;
import 'package:url_launcher/url_launcher.dart';

EditorStyle buildDesktopEditorStyle(BuildContext context) {
  return EditorStyle.desktop(
    cursorWidth: 2.0,
    cursorColor: Colors.blue,
    selectionColor: my_get.Get.theme.shadowColor,
    textStyleConfiguration: TextStyleConfiguration(
      text: TextStyle(
        fontFamily: "SIMYOU",
        fontSize: 16,
        color:  my_get.Get.theme.textTheme.displayLarge?.color??Colors.black, // 使用传递的primaryColor参数
        height: 1.5,
        leadingDistribution: TextLeadingDistribution.even,
      ),
      code: const TextStyle(
        color: Color.fromARGB(255, 129, 232, 250),
        backgroundColor: Color.fromARGB(98, 0, 195, 255),
      ),
      bold: const TextStyle(fontWeight: FontWeight.bold),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10,vertical:2),
    //maxWidth: 640,
    textSpanOverlayBuilder: _buildTextSpanOverlay,
    textScaleFactor: 1,
  );
}

List<Widget> _buildTextSpanOverlay(
  BuildContext context,
  Node node,
  SelectableMixin delegate,
) {
  final delta = node.delta;
  if (delta == null) return [];
  
  final widgets = <Widget>[];
  final textInserts = delta.whereType<TextInsert>();
  int index = 0;
  
 // final editorState = context.read<EditorState>();
  
  for (final textInsert in textInserts) {
    // 检查是否含有链接属性
    if (textInsert.attributes?.containsKey('href') == true) {
      final href = textInsert.attributes?['href'];
      if (href != null) {
        final nodeSelection = Selection(
          start: Position(path: node.path, offset: index),
          end: Position(
            path: node.path,
            offset: index + textInsert.length,
          ),
        );
        
        // 获取链接文本在视图中的位置矩形
        final rectList = delegate.getRectsInSelection(nodeSelection);
        if (rectList.isNotEmpty) {
          for (final rect in rectList) {
            widgets.add(
              Positioned(
                left: rect.left,
                top: rect.top,
                child: SizedBox(
                  width: rect.width,
                  height: rect.height,
                  child: LinkHoverTrigger(
                    //editorState: editorState,
                    selection: nodeSelection,
                    attribute: textInsert.attributes!,
                    node: node,
                    size: rect.size,
                  ),
                ),
              ),
            );
          }
        }
      }
    }
    index += textInsert.length;
  }
  return widgets;
}
class LinkHoverTrigger extends StatelessWidget {
  const LinkHoverTrigger({
    Key? key,
    //required this.editorState,
    required this.selection,
    required this.attribute,
    required this.node,
    required this.size,
  }) : super(key: key);

  //final EditorState editorState;
  final Selection selection;
  final Map<String, dynamic> attribute;
  final Node node;
  final Size size;

  @override
    @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final href = attribute['href'] as String?;
          if (href != null) {
            _openLink(href);
          }
        },
        child: HoverMenu(
          child: const SizedBox.expand(),
          itemBuilder: (context) {
            final href = attribute['href'] as String?;
            if (href == null) {
              return const SizedBox.shrink();
            }
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 显示链接地址
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      href,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  // 链接操作按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.open_in_new,
                        label: AppFlowyEditorL10n.current.openLink,
                        onPressed: () => _openLink(href),
                      ),
                      _buildActionButton(
                        icon: Icons.content_copy,
                        label: AppFlowyEditorL10n.current.copyLink,
                        onPressed: () => _copyLink(context, href),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.blue),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.blue,
        ),
      ),
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
    );
  }

  void _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error opening link: $e');
    }
  }

  void _copyLink(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    // 显示复制成功提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class HoverMenu extends StatefulWidget {
  final Widget child;
  final WidgetBuilder itemBuilder;

  const HoverMenu({
    super.key,
    required this.child,
    required this.itemBuilder,
  });

  @override
  HoverMenuState createState() => HoverMenuState();
}

class HoverMenuState extends State<HoverMenu> {
  OverlayEntry? overlayEntry;
  bool isHoveringLink = false;
  bool isHoveringMenu = false;
  Timer? _closeTimer;

  @override
  void dispose() {
    _removeOverlay();
    _closeTimer?.cancel();
    super.dispose();
  }

  void _removeOverlay() {
    overlayEntry?.remove();
    overlayEntry = null;
  }
  
  void _startCloseTimer() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 100), () {
      if (!isHoveringLink && !isHoveringMenu) {
        _removeOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (details) {
        isHoveringLink = true;
        _closeTimer?.cancel();
        
        // 鼠标进入链接区域显示菜单
        if (overlayEntry == null) {
          _showMenu();
        }
      },
      onExit: (details) {
        isHoveringLink = false;
        // 延迟关闭菜单，给用户时间移动到菜单上
        _startCloseTimer();
      },
      child: widget.child,
    );
  }

  void _showMenu() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    overlayEntry = OverlayEntry(
      maintainState: true,
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height,
        child: Material(
          elevation: 4.0,
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: MouseRegion(
            onEnter: (_) {
              isHoveringMenu = true;
              _closeTimer?.cancel();
            },
            onExit: (_) {
              isHoveringMenu = false;
              _startCloseTimer();
            },
            child: widget.itemBuilder(context),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlayEntry!);
  }
}
