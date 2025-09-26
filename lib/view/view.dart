import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:machine_task/bloc/bloc/article_bloc.dart';
import 'package:machine_task/model/model.dart';

class NewsFeedPage extends StatefulWidget {
  const NewsFeedPage({Key? key}) : super(key: key);

  @override
  State<NewsFeedPage> createState() => _NewsFeedPageState();
}

class _NewsFeedPageState extends State<NewsFeedPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !_isFetching(context)) {
      context.read<NewsBloc>().add(FetchNews());
    }
  }

  bool _isFetching(BuildContext context) {
    final bloc = context.read<NewsBloc>();
    return bloc.isFetching;
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    return current >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<NewsBloc>().add(FetchNews(refresh: true));
    // wait for refresh to complete or time out
    await Future.any([
      context.read<NewsBloc>().stream.firstWhere((s) => s is NewsLoadSuccess || s is NewsLoadFailure),
      Future.delayed(const Duration(seconds: 5)),
    ]);
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<NewsBloc>().add(SearchNews(text));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Headlines'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search headlines...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      context.read<NewsBloc>().add(SearchNews(''));
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<NewsBloc, NewsState>(
        builder: (context, state) {
          if (state is NewsInitial || (state is NewsLoadInProgress && state.existing.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NewsLoadFailure) {
            return Center(child: Text('Failed to load: ${state.error}'));
          }

          List<Article> articles = [];
          bool isLoadingMore = false;
          bool hasReachedEnd = false;

          if (state is NewsLoadInProgress) {
            articles = state.existing;
            isLoadingMore = true;
          } else if (state is NewsLoadSuccess) {
            articles = state.articles;
            hasReachedEnd = state.hasReachedEnd;
          }

          if (articles.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 200), Center(child: Text('No articles found'))],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: articles.length + (isLoadingMore || !hasReachedEnd ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= articles.length) {
                  if (hasReachedEnd) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final article = articles[index];
                final heroTag = article.url ?? '${article.title}-$index';

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => ArticleDetailPage(article: article, heroTag: heroTag),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article.urlToImage != null)
                          Hero(
                            tag: heroTag,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  article.urlToImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image))),
                                  loadingBuilder: (c, w, e) {
                                    if (e == null) return w;
                                    return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                                  },
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(article.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              if (article.description != null) Text(article.description!, maxLines: 3, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (article.publishedAt != null) Text(_formatDate(article.publishedAt!), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).push(PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => ArticleDetailPage(article: article, heroTag: heroTag),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return FadeTransition(opacity: animation, child: child);
                                        },
                                      ));
                                    },
                                    child: const Text('Read'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () => context.read<NewsBloc>().add(FetchNews(refresh: true)),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

class ArticleDetailPage extends StatelessWidget {
  final Article article;
  final String heroTag;
  const ArticleDetailPage({Key? key, required this.article, required this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (article.urlToImage != null)
              Hero(
                tag: heroTag,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    article.urlToImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image))),
                    loadingBuilder: (c, w, e) {
                      if (e == null) return w;
                      return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (article.author != null) Text('By ${article.author!}', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                      if (article.publishedAt != null) Text(_formatDate(article.publishedAt!), style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (article.content != null) Text(article.content!),
                  if (article.description != null && (article.content == null || article.content!.isEmpty)) Text(article.description!),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to feed'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}