library epubview;

import 'package:flutter/material.dart';
import 'package:epub3/epub3_io.dart' as epub;
import 'package:html2md/html2md.dart' as html2md;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

/// none-tree-liked Chapter
class Chapter {
  Chapter({required this.title, this.href, this.parent});
  final String title;
  final String? href;
  final Chapter? parent;

  factory Chapter._raw(epub.Chapter ch, {Chapter? parent}) {
    return Chapter(title: ch.title, href: ch.href, parent: parent);
  }

  /// Expand the tree like chapters to plain list
  static List<Chapter> build(epub.Book book) {
    final all = <Chapter>[];
    for (var ch in book.chapters) {
      Chapter._expand(all, ch);
    }
    return all;
  }

  static _expand(List<Chapter> all, epub.Chapter ch, {Chapter? parent}) {
    final current = Chapter._raw(ch, parent: parent);
    all.add(current);
    for (var c in ch.children) {
      all.add(Chapter._raw(c, parent: current));
    }
  }
}

class ReaderState extends ChangeNotifier {
  final epub.Book book;
  final List<Chapter> chapters;
  Chapter? chapter;

  ReaderState(this.book) : chapters = Chapter.build(book);

  void setCurrent(Chapter ch) {
    chapter = ch;
    notifyListeners();
  }
}

class ChapterView extends StatelessWidget {
  final ReaderState rs;
  const ChapterView(this.rs, {super.key});

  factory ChapterView.from(epub.Book book) => ChapterView(ReaderState(book));

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        // print(
        //     'tile font: ${Theme.of(context).textTheme.bodyMedium?.fontFamily} '
        //     '${Theme.of(context).textTheme.bodyMedium?.fontFamilyFallback}');
        final ch = rs.chapters[index];
        return ListTile(
          leading: ch.parent == null ? null : const Text(''),
          title: Text(ch.title),
          selected: rs.chapter == ch,
          onTap: () {
            rs.setCurrent(ch);
            print('click ${ch.href}');
          },
        );
      },
      itemCount: rs.chapters.length,
    );
  }
}

class ReaderView extends StatefulWidget {
  final epub.Book book;
  final String? href;
  const ReaderView({required this.book, this.href, super.key});

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  // @override
  // void initState() {
  //   super.initState();
  // }

  bool updateShouldNotify(ReaderView oldWidget) {
    print('updateShouldNotify ${widget.href}');
    return widget.href != oldWidget.href;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.href != null) {
      final content = widget.book.readString(widget.href!);
      if (content != null) {
        final mdt = html2md.convert(content);
        print(mdt);
        final mdss = MarkdownStyleSheet.fromTheme(Theme.of(context)).merge(
          MarkdownStyleSheet(
            p: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
            h1: const TextStyle(fontSize: 32, fontFamily: 'NotoSansJP'),
            h2: const TextStyle(fontSize: 28, fontFamily: 'NotoSansJP'),
            h3: const TextStyle(fontSize: 24, fontFamily: 'NotoSansJP'),
            h4: const TextStyle(fontSize: 18, fontFamily: 'NotoSansJP'),
            h5: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
            h6: const TextStyle(fontSize: 14, fontFamily: 'NotoSansJP'),
            listBullet: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
            tableHead: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
            tableBody: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
            blockquote: const TextStyle(fontSize: 16, fontFamily: 'NotoSansJP'),
          ),
        );
        print(
            'fonts: p:${mdss.p?.fontFamily} h1:${mdss.h1?.fontFamily} h4:${mdss.h4?.fontFamily} a:${mdss.a?.fontFamily}');
        return Markdown(
          data: mdt,
          styleSheet: mdss,
          selectable: true,
          imageBuilder: buildImage,
        );
      }
    }

    /// test only
    final mdt = html2md.convert('<p>幸運 こううん にも中文</p>');
    final mdss = MarkdownStyleSheet.fromTheme(Theme.of(context));
    // .merge(
    //   MarkdownStyleSheet(p: const TextStyle(fontFamily: 'NotoSansJP')),
    // );
    return Markdown(
      data: mdt,
      styleSheet: mdss,
      selectable: true,
      imageBuilder: buildImage,
    );

    // return Text('${widget.href}');
  }

  /// TODO: title, alt
  Widget buildImage(Uri uri, String? title, String? alt) {
    final bs = widget.book.readBytes(uri.toString());
    if (bs != null) {
      return Image(image: MemoryImage(bs));
    }
    return const SizedBox(width: 100, height: 10, child: Text('not found'));
  }
}

// 幸運 こううん にも中文
// The default font-family for Android,Fuchsia and Linux is Roboto.
// The default font-family for iOS is SF Pro Display/SF Pro Text.
// The default font-family for MacOS is .AppleSystemUIFont.
// The default font-family for Windows is Segoe UI.
