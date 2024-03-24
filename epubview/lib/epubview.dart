library epubview;

import 'package:flutter/material.dart';
import 'package:epub3/epub3_io.dart' as epub;

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}

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

class ChapterView extends StatelessWidget {
  final List<Chapter> chapters;
  final String? href;
  final void Function(Chapter)? onChapterSelect;
  const ChapterView({
    required this.chapters,
    this.href,
    this.onChapterSelect,
    super.key,
  });

  factory ChapterView.from(
    epub.Book book, {
    void Function(Chapter)? onChapterSelect,
  }) =>
      ChapterView(
        chapters: Chapter.build(book),
        onChapterSelect: onChapterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final ch = chapters[index];
        return ListTile(
          leading: ch.parent == null ? null : const Text(''),
          title: Text(ch.title),
          onTap: () {
            onChapterSelect?.call(ch);
            print('click ${ch.href}');
          },
        );
      },
      itemCount: chapters.length,
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
        return Text(content);
      }
    }
    return Text('${widget.href}');
  }
}
