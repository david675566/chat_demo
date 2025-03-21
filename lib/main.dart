import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloc/bloc.dart';

// local
import 'package:chat_demo/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

Future<Map> loadChatJson() async {
  final String res = await rootBundle.loadString("assets/chat_data.json");
  return jsonDecode(res);
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter Conversation Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      routerConfig: goRoutes(),
    );
  }
}

/// {@template app_bloc_observer}
/// Custom [BlocObserver] that observes all bloc and cubit state changes.
/// {@endtemplate}
class AppBlocObserver extends BlocObserver {
  /// {@macro app_bloc_observer}
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (bloc is Cubit) debugPrint(change.toString());
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    debugPrint(transition.toString());
  }
}
