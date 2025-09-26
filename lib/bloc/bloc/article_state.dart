part of 'article_bloc.dart';

@immutable
abstract class NewsState {}

class NewsInitial extends NewsState {}

class NewsLoadInProgress extends NewsState {
  final List<Article> existing;
  NewsLoadInProgress(this.existing);
}

class NewsLoadSuccess extends NewsState {
  final List<Article> articles;
  final bool hasReachedEnd;
  final int page;
  NewsLoadSuccess({required this.articles, required this.hasReachedEnd, required this.page});
}

class NewsLoadFailure extends NewsState {
  final String error;
  NewsLoadFailure(this.error);
}
