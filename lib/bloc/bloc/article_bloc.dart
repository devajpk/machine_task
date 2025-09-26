import 'package:bloc/bloc.dart';
import 'package:machine_task/main.dart';
import 'package:machine_task/model/model.dart';
import 'package:machine_task/network/network.dart';
import 'package:meta/meta.dart';

part 'article_event.dart';
part 'article_state.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  final NewsRepository repository;
  String? currentQuery;
  int currentPage = 1;
  bool isFetching = false;

  NewsBloc({required this.repository}) : super(NewsInitial()) {
    on<FetchNews>(_onFetchNews, transformer: _throttleDroppable());
    on<SearchNews>(_onSearchNews);
  }

  EventTransformer<E> _throttleDroppable<E>() {
    return (events, mapper) => events.asyncExpand(mapper);
  }

  Future<void> _onFetchNews(FetchNews event, Emitter<NewsState> emit) async {
    if (isFetching) return;
    try {
      isFetching = true;
      final currentState = state;
      List<Article> oldArticles = [];
      if (event.refresh) {
        currentPage = 1;
      } else if (currentState is NewsLoadSuccess) {
        oldArticles = currentState.articles;
        currentPage = currentState.page + 1;
      } else {
        currentPage = 1;
      }

      if (event.query != null) {
        currentQuery = event.query;
        currentPage = 1;
        oldArticles = [];
      }

      emit(NewsLoadInProgress(oldArticles));

      final fetched = await repository.fetchTopHeadlines(page: currentPage, query: currentQuery);

      final List<Article> combined;
      bool hasReachedEnd = false;
      if (currentPage == 1) {
        combined = fetched;
      } else {
        combined = List.of(oldArticles)..addAll(fetched);
      }

      if (fetched.length < kPageSize) {
        hasReachedEnd = true;
      }

      emit(NewsLoadSuccess(articles: combined, hasReachedEnd: hasReachedEnd, page: currentPage));
    } catch (e) {
      emit(NewsLoadFailure(e.toString()));
    } finally {
      isFetching = false;
    }
  }

  Future<void> _onSearchNews(SearchNews event, Emitter<NewsState> emit) async {
    currentQuery = event.query;
    add(FetchNews(refresh: true, query: currentQuery));
  }
}