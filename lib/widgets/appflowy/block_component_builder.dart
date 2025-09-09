  // showcase 2: customize the block style
  import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_code_block_component.dart';
import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_file_block_component.dart';
import 'package:XNote/widgets/appflowy/custom/custom_block_component/custom_image_block_component.dart';
import 'package:XNote/widgets/appflowy/drag_to_reorder_editor.dart';

Map<String, BlockComponentBuilder> buildBlockComponentBuilders() {
    final map = {
      ...standardBlockComponentBuilderMap,

      // columns block
      ColumnBlockKeys.type: ColumnBlockComponentBuilder(),
      ColumnsBlockKeys.type: ColumnsBlockComponentBuilder(),
    };
    // customize the image block component to show a menu
    // map[ImageBlockKeys.type] = ImageBlockComponentBuilder(
    //   showMenu: true,
    //   menuBuilder: (node, _) {
    //     return const Positioned(
    //       right: 10,
    //       child: Text('⭐️ Here is a menu!!'),
    //     );
    //   },
    // );
        // customize the image block component to show a menu
    map[ImageBlockKeys.type] = CustomImageBlockComponentBuilder(
      showMenu: true,
      // menuBuilder: (node, _) {
      //   return const Positioned(
      //     right: 10,
      //     child: Text('⭐️ Here is a menu!~!'),
      //   );
      // },
    );
    // customize the heading block component
    final levelToFontSize = [
      30.0,
      26.0,
      22.0,
      18.0,
      16.0,
      14.0,
    ];
    map[HeadingBlockKeys.type] = HeadingBlockComponentBuilder(
      textStyleBuilder: (level) => TextStyle(
        fontSize: levelToFontSize[level - 1],
        fontWeight: FontWeight.bold,
      ),
    );
    
    map[CustomFileBlockKeys.type] = CustomFileBlockComponentBuilder();

    map[CustomCodeBlockKeys.type]=CustomCodeBlockComponentBuilder();
    // customize the padding
    map.forEach((key, value) {
      value.configuration = value.configuration.copyWith(
        padding: (node) {
          if (node.type == ColumnsBlockKeys.type ||
              node.type == ColumnBlockKeys.type) {
            return EdgeInsets.zero;
          }
          return const EdgeInsets.only(bottom:2,top: 2);
        },
        blockSelectionAreaMargin: (_) => const EdgeInsets.symmetric(
          vertical: 2.0,
        ),
        textStyle: (node, {textSpan}){
          return const TextStyle();
        } ,
        textAlign: (node) {
          return TextAlign.start;
        },
        // indentPadding: (node, textDirection) {
        //   return const EdgeInsets.only(left: 0.0);
        // },
      );

        if (key != PageBlockKeys.type) {
        value.showActions = (_) => true;
        value.actionBuilder = (context, actionState) {
          return DragToReorderAction(
            blockComponentContext: context,
            builder: value,
          );
        };
      }
    });
    return map;
  }
