part of 'article_bloc.dart';

@immutable
abstract class NewsEvent {}

class FetchNews extends NewsEvent {
  final bool refresh;
  final String? query;

  FetchNews({this.refresh = false, this.query});
}

class SearchNews extends NewsEvent {
  final String query;
  SearchNews(this.query);
}
