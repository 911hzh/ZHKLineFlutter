import 'package:flutter_bloc/flutter_bloc.dart';

class HomePageState {
  const HomePageState({
    this.title = 'Foundation Kit Demo',
    this.list = const [
      {"title": "Logout Demo", "route": "/logout"},
      {"title": "UserStore Demo", "route": "/userStore"},
      {"title": "CUtil Demo", "route": "/cutil"},
      {"title": "REST Client Demo", "route": "/apiImpl"},
      {"title": "KLine Delegate Demo", "route": "/kline"},
      {"title": "Logger Demo", "route": "/logger"},
      {"title": "Settings Demo", "route": "/settings"},
      {"title": "Store Demo", "route": "/store"},
    ],
  });

  final String title;
  final List<Map<String, String>> list;

  HomePageState copyWith({List<Map<String, String>>? list, String? title}) {
    return HomePageState(list: list ?? this.list, title: title ?? this.title);
  }
}

class HomePageCubit extends Cubit<HomePageState> {
  HomePageCubit() : super(const HomePageState());
}
