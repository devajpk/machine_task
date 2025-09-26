
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:machine_task/bloc/bloc/article_bloc.dart';
import 'package:machine_task/model/model.dart';
import 'package:machine_task/network/network.dart';
import 'package:machine_task/view/view.dart';
const String kApiKey = '3c908d66c17e479980705eaf3ffff95a';
const String kBaseUrl = 'https://newsapi.org/v2/top-headlines';
const int kPageSize = 20;
const String kCountry = 'us';

void main() {
  runApp(const NewsApp());
}
//
class NewsApp extends StatelessWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: RepositoryProvider(
        create: (_) => NewsRepository(),
        child: BlocProvider(
          create: (context) => NewsBloc(repository: context.read<NewsRepository>())..add(FetchNews()),
          child: const NewsFeedPage(),
        ),
      ),
    );
  }
}



// End of file
