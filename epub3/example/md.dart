import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

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
  final stack = <LeveledTitle>[];
  final body = <String>[]; // current Chapter's body in text(not html)

  final lines = file.readAsLinesSync();
  for (String line in lines) {
    if (line.startsWith('#')) {
      // End previous chapter: set content
      if (body.isNotEmpty) {
        stack.last.chapter =
            epub.Chapter.textContent(stack.last.chapter.title, body.join('\n'));

        body.clear();
      }

      // new Title
      final current = LeveledTitle.from(line);
      stack.add(current);
    } else {
      body.add(line.trim());
    }
  }

  if (body.isNotEmpty) {
    stack.last.chapter =
        epub.Chapter.textContent(stack.last.chapter.title, body.join('\n'));

    body.clear();
  }

  // Build tree liked chapters
  final res = <epub.Chapter>[];
  final toplevel = stack.first.level;
  for (final lt in stack) {
    if (lt.level == toplevel) {
      // new top Chapter
      res.add(lt.chapter);
    } else {
      // Find and push
      int i = stack.last.level;
      var c = res;
      while (i != lt.level) {
        c = c.last.children;
        i -= 1;
      }
      c.add(lt.chapter);
    }
  }

  return res;
}

// Convert markdown to epub
void main(List<String> args) {
  final fp = args[0];
  final chs = split(File(fp));
  final book = epub.Book.create(title: p.basenameWithoutExtension(fp), author: '');
  for (final ch in chs) {
    book.add(ch);
  }
  epub.writeFile(book, p.basenameWithoutExtension(fp) + '.epub');
}
