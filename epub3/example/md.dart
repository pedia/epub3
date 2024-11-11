import 'dart:io';
import 'dart:convert';

import 'package:epub3/epub3_io.dart' as epub;

/// Parse "### title" => 3, "title"
class LeveledTitle {
  final int level;
  epub.Chapter chapter;
  LeveledTitle(this.level, this.chapter);

  factory LeveledTitle.from(String line) {
    int level = 0;

    int i = 0;
    while (true) {
      i = line.indexOf('#', i);
      if (-1 == i) {
        break;
      }
      i++;
      level++;
    }

    final title = line.trim().replaceAll('#', "").trim();
    return LeveledTitle(level, epub.Chapter(title: title, children: []));
  }

  String get html {
    final tag = {
      1: 'h5',
      2: 'h4',
      3: 'h3',
    }[level];
    return '<$tag>${HtmlEscape().convert(chapter.title)}</$tag>';
  }
}

List<epub.Chapter> split(File file) {
  final res = <epub.Chapter>[];

  final lines = file.readAsLinesSync();

  LeveledTitle? top;

  final body = <String>[]; // current Chapter's body

  for (String line in lines) {
    if (line.startsWith('#')) {
      if (body.isNotEmpty) {
        // find tail
        var tail = top?.chapter;
        while (true) {
          if (tail?.children.last != null) {
            tail = tail?.children.last;
          } else {
            break;
          }
        }

        // tail.chapter =
        //     epub.Chapter.textContent(current.chapter.title, body.join('\n'));

        body.clear();
      }

      final current = LeveledTitle.from(line);
      // first new chapter
      if (top == null) {
        top = current;
        continue;
      }

      if (current.level < top.level) {
        // sub chapter
        top.chapter.children.add(current.chapter);
      } else {
        // an other top level chapter
        res.add(current.chapter);
        top = current;
      }
    } else {
      body.add(line.trim());
    }
  }

  if (top != null) {
    res.add(top.chapter);
  }

  return res;
}

// Convert markdown to epub
void main(List<String> args) {
  final fp = '/Users/mord/t/Political-Science/国家为什么会失败——权力、富裕与贫困的根源.md';
  final chs = split(File(fp));
  final book = epub.Book.create(title: '国家为什么会失败', author: '');
  for (final ch in chs) {
    book.add(ch);
  }
  epub.writeFile(book, "国家为什么会失败.epub");
}
