import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 代码块的类型标识符
class CustomCodeBlockKeys {
  const CustomCodeBlockKeys._();

  static const String type = 'custom_code_block';
  static const String code = 'code';
  static const String language = 'language';
}

// 创建代码块节点的工厂函数
// 创建代码块节点的工厂函数
Node customCodeBlockNode({
  String code = '',
  String language = 'c',
}) {
  // 预处理代码，处理可能的 HTML 格式
  final processedCode = _isHtmlCode(code) ? _extractCodeFromHtml(code) : code;
  
  return Node(
    type: CustomCodeBlockKeys.type,
    attributes: {
      CustomCodeBlockKeys.code: processedCode,
      CustomCodeBlockKeys.language: language,
    },
  );
}


// 代码块组件的构建器
class CustomCodeBlockComponentBuilder extends BlockComponentBuilder {
  CustomCodeBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomCodeBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
    );
  }

  @override
  BlockComponentValidate get validate => (node) => 
      node.attributes.containsKey(CustomCodeBlockKeys.code);
}

// 代码块组件的实现
class CustomCodeBlockComponentWidget extends BlockComponentStatelessWidget {
  const CustomCodeBlockComponentWidget({
    super.key,
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
  });

@override
Widget build(BuildContext context) {
  final rawCode = node.attributes[CustomCodeBlockKeys.code] as String? ?? '';
  final code = _preprocessCode(rawCode); // 预处理 HTML 格式代码
  final codeLines = code.split('\n');
  
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFFF8F8F8),
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF333333)
            : const Color(0xFFDDDDDD),
        width: 1.0,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildToolbar(context, code),
        _buildCodeContent(context, codeLines, code),
      ],
    ),
  );
}

Widget _buildToolbar(BuildContext context, String code) {
  final rawCode = node.attributes[CustomCodeBlockKeys.code] as String? ?? '';
  final isHtmlFormatted = _isHtmlCode(rawCode);
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252525)
          : const Color(0xFFEFEFEF),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(8.0),
        topRight: Radius.circular(8.0),
      ),
      border: Border(
        bottom: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF333333)
              : const Color(0xFFDDDDDD),
          width: 1.0,
        ),
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.code,
          size: 16,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: 8),
        Text(
          isHtmlFormatted ? 'Code (from HTML)' : 'Code',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        if (isHtmlFormatted) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.info_outline,
            size: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.orange[300]
                : Colors.orange[600],
          ),
        ],
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () => _copyCodeToClipboard(context, code),
          tooltip: 'Copy code',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCodeContent(BuildContext context, List<String> codeLines, String code) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLineNumbers(context, codeLines.length),
            const SizedBox(width: 12),
            _buildHighlightedCode(context, code),
          ],
        ),
      ),
    );
  }

  Widget _buildLineNumbers(BuildContext context, int lineCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        lineCount,
        (index) => Container(
          height: 20,
          alignment: Alignment.centerRight,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF6D6D6D)
                  : const Color(0xFF999999),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedCode(BuildContext context, String code) {
    final highlightedSpans = _highlightCode(context, code);
    
    return SelectableText.rich(
      TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.4,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: highlightedSpans,
      ),
    );
  }

  List<TextSpan> _highlightCode(BuildContext context, String code) {
    final lines = code.split('\n');
    final List<TextSpan> spans = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      spans.addAll(_highlightLine(context, line));
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return spans;
  }

  List<TextSpan> _highlightLine(BuildContext context, String line) {
    final List<TextSpan> spans = [];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // C语言关键字
    final keywords = {
      'auto', 'break', 'case', 'char', 'const', 'continue', 'default', 'do',
      'double', 'else', 'enum', 'extern', 'float', 'for', 'goto', 'if',
      'int', 'long', 'register', 'return', 'short', 'signed', 'sizeof', 'static',
      'struct', 'switch', 'typedef', 'union', 'unsigned', 'void', 'volatile', 'while',
      // 通用扩展关键字
      'class', 'public', 'private', 'protected', 'virtual', 'override',
      'function', 'var', 'let', 'const', 'import', 'export', 'from'
    };
    
    // 数据类型
    final types = {
      'bool', 'string', 'int8_t', 'int16_t', 'int32_t', 'int64_t',
      'uint8_t', 'uint16_t', 'uint32_t', 'uint64_t', 'size_t'
    };
    
    int i = 0;
    while (i < line.length) {
      // 跳过空白字符
      if (line[i].trim().isEmpty) {
        spans.add(TextSpan(text: line[i]));
        i++;
        continue;
      }
      
      // 检查注释
      if (i < line.length - 1 && line.substring(i, i + 2) == '//') {
        spans.add(TextSpan(
          text: line.substring(i),
          style: TextStyle(
            color: isDark ? const Color(0xFF6A9955) : const Color(0xFF008000),
            fontStyle: FontStyle.italic,
          ),
        ));
        break;
      }
      
      // 检查字符串
      if (line[i] == '"' || line[i] == "'") {
        final quote = line[i];
        int j = i + 1;
        while (j < line.length && line[j] != quote) {
          if (line[j] == '\\' && j + 1 < line.length) {
            j += 2; // 跳过转义字符
          } else {
            j++;
          }
        }
        if (j < line.length) j++; // 包含结束引号
        
        spans.add(TextSpan(
          text: line.substring(i, j),
          style: TextStyle(
            color: isDark ? const Color(0xFFCE9178) : const Color(0xFF008000),
          ),
        ));
        i = j;
        continue;
      }
      
      // 检查数字
      if (RegExp(r'[0-9]').hasMatch(line[i])) {
        int j = i;
        while (j < line.length && RegExp(r'[0-9a-fA-F.xX]').hasMatch(line[j])) {
          j++;
        }
        spans.add(TextSpan(
          text: line.substring(i, j),
          style: TextStyle(
            color: isDark ? const Color(0xFFB5CEA8) : const Color(0xFF098658),
          ),
        ));
        i = j;
        continue;
      }
      
      // 检查标识符（关键字、类型、函数等）
      if (RegExp(r'[a-zA-Z_]').hasMatch(line[i])) {
        int j = i;
        while (j < line.length && RegExp(r'[a-zA-Z0-9_]').hasMatch(line[j])) {
          j++;
        }
        
        final word = line.substring(i, j);
        TextStyle? style;
        
        if (keywords.contains(word)) {
          style = TextStyle(
            color: isDark ? const Color(0xFF569CD6) : const Color(0xFF0000FF),
            fontWeight: FontWeight.bold,
          );
        } else if (types.contains(word)) {
          style = TextStyle(
            color: isDark ? const Color(0xFF4EC9B0) : const Color(0xFF2B91AF),
          );
        }
        
        spans.add(TextSpan(text: word, style: style));
        i = j;
        continue;
      }
      
      // 检查操作符和标点符号
      if (RegExp(r'[+\-*/=<>!&|^~%]').hasMatch(line[i])) {
        spans.add(TextSpan(
          text: line[i],
          style: TextStyle(
            color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF000000),
            fontWeight: FontWeight.w500,
          ),
        ));
        i++;
        continue;
      }
      
      // 默认字符
      spans.add(TextSpan(text: line[i]));
      i++;
    }
    
    return spans;
  }

  void _copyCodeToClipboard(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }
}
// HTML 实体解码函数
// HTML 实体解码函数
String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('<', '<')
      .replaceAll('>', '>')
      .replaceAll('&', '&')
      .replaceAll('"', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#160;', ' ')    // 不间断空格
      .replaceAll('&nbsp;', ' ')    // 不间断空格
      .replaceAll('&#8203;', '')    // 零宽空格
      .replaceAll('&#8205;', '')    // 零宽连接符
      .replaceAll('&#13;', '\n')    // 回车符
      .replaceAll('&#10;', '\n')    // 换行符
      .replaceAll('&NewLine;', '\n'); // HTML5 换行实体
}


// 检测是否为 HTML 格式代码
// 检测是否为 HTML 格式代码
bool _isHtmlCode(String text) {
  return text.contains('<') || 
         text.contains('>') || 
         text.contains('&') ||
         text.contains('<div') || 
         text.contains('<span') || 
         text.contains('<code') ||
         text.contains('<pre') ||
         text.contains('style=') ||
         text.contains('color:') ||
         text.contains('background-color:');
}

// 从 HTML 提取纯文本代码
// 从 HTML 提取纯文本代码
String _extractCodeFromHtml(String html) {
  String result = '';
  bool insideTag = false;
  bool insideStyle = false;
  int i = 0;
  
  while (i < html.length) {
    // 检查是否为换行相关的标签
    if (i < html.length - 4) {
      String nextFour = html.substring(i, i + 4);
      if (nextFour == '<div' || nextFour == '</di') {
        // 遇到 div 标签，添加换行符（除了第一个 div）
        if (result.isNotEmpty && !result.endsWith('\n')) {
          result += '\n';
        }
        // 跳过整个标签
        while (i < html.length && html[i] != '>') {
          i++;
        }
        if (i < html.length) i++; // 跳过 '>'
        continue;
      }
    }
    
    if (i < html.length - 2) {
      String nextThree = html.substring(i, i + 3);
      if (nextThree == '<br' || nextThree == '<BR') {
        // 遇到 br 标签，添加换行符
        result += '\n';
        // 跳过整个标签
        while (i < html.length && html[i] != '>') {
          i++;
        }
        if (i < html.length) i++; // 跳过 '>'
        continue;
      }
    }
    
    if (i < html.length - 5 && html.substring(i, i + 6) == 'style=') {
      // 跳过样式属性
      insideStyle = true;
      i += 6;
      continue;
    }
    
    if (insideStyle && (html[i] == '"' || html[i] == "'")) {
      // 结束样式属性
      final quote = html[i];
      i++;
      while (i < html.length && html[i] != quote) {
        i++;
      }
      insideStyle = false;
      i++;
      continue;
    }
    
    if (html[i] == '<') {
      insideTag = true;
    } else if (html[i] == '>') {
      insideTag = false;
    } else if (!insideTag && !insideStyle) {
      result += html[i];
    }
    
    i++;
  }
  
  // 处理 HTML 实体字符并清理多余的换行符
  String cleaned = _decodeHtmlEntities(result);
  
  // 移除开头和结尾的空白行
  cleaned = cleaned.trim();
  
  // 将多个连续的换行符合并为单个换行符
  cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n'), '\n');
  
  return cleaned;
}


// 预处理代码，如果是 HTML 格式则进行转换
String _preprocessCode(String code) {
  if (_isHtmlCode(code)) {
    String extracted = _extractCodeFromHtml(code);
    
    // 进一步清理提取的代码
    extracted = extracted.replaceAll(RegExp(r'^\s+', multiLine: true), ''); // 移除行首空白
    extracted = extracted.replaceAll(RegExp(r'\s+$', multiLine: true), ''); // 移除行尾空白
    
    return extracted;
  }
  return code;
}

