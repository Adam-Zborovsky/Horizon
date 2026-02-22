import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_articles_provider.g.dart';

@riverpod
class SavedArticles extends _$SavedArticles {
  @override
  Set<String> build() {
    return {};
  }

  void toggle(String articleTitle) {
    if (state.contains(articleTitle)) {
      state = {...state}..remove(articleTitle);
    } else {
      state = {...state, articleTitle};
    }
  }

  bool contains(String articleTitle) => state.contains(articleTitle);
}
