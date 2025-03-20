import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloc/bloc.dart';
import 'package:mockzilla/mockzilla.dart'; // mock api

// local
import 'package:chat_demo/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setUpMockAPI();
  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

Future<Map> loadChatJson() async {
  final String res = await rootBundle.loadString("assets/chat_data.json");
  return jsonDecode(res);
}

// Setting up MockAPI Server (Mockzilla in this demo.)
// btw this is my first time using Mockzilla.
Future<void> setUpMockAPI() async {
  //
  // Reg for seek matching Single Conversation Message
  // since Mockzilla treated the endpoint uri as a whole 'String'
  //
  final RegExp getMessageRegExp = RegExp(r"^.+\/messages\?conversationId=(\d+)$");
  final RegExp postMessageRegExp = RegExp(r"^.+\/conversations\/(\d+)\/messages\/create$");
  final RegExp reactMessageRegExp = RegExp(r"^.+\/conversations\/(\d+)\/messages\/reaction$");

  final chatData = await loadChatJson();

  // Setting up server endpoints
  final mockzillaConfig = MockzillaConfig(
    port: 8080,
    localHostOnly: true,
    endpoints: [
      // Conversations List
      EndpointConfig(
        name: "Conversations",
        endpointMatcher: (request) => (request.method == HttpMethod.get && request.uri.endsWith("/conversations")),
        defaultHandler: (request) {
          final query = (chatData["conversations"] as List);
          if (query.isEmpty) {
            return MockzillaHttpResponse(statusCode: 500);
          }
          return MockzillaHttpResponse(statusCode: 200, body: jsonEncode(query));
        },
        errorHandler: (request) => const MockzillaHttpResponse(statusCode: 418),
        delay: const Duration(milliseconds: 500),
      ),

      // Messages History List
      EndpointConfig(
        name: "Specific Conversation",
        endpointMatcher: (request) => (request.method == HttpMethod.get && getMessageRegExp.hasMatch(request.uri)),
        defaultHandler: (request) {
          // Check again if reg could get specific id
          if (!getMessageRegExp.hasMatch(request.uri)) {
            return MockzillaHttpResponse(statusCode: 400);
          }

          // Extract conversation id
          final targetConvID = int.parse(
            getMessageRegExp.firstMatch(request.uri)!.group(1)!,
          ); // RegExp spits out String, need to parse to int

          final targetMessages =
              (chatData['messages'] as List).where((e) => e['conversationId'] == targetConvID).toList();
          if (targetMessages.isEmpty) {
            return MockzillaHttpResponse(statusCode: 500);
          }
          targetMessages.sort((a, b) => (a['timestamp'] as int).compareTo((b['timestamp'] as int)));
          return MockzillaHttpResponse(statusCode: 200, body: jsonEncode(targetMessages));
        },
        errorHandler: (request) => const MockzillaHttpResponse(statusCode: 418),
      ),

      // Post Messages to specific Conversation
      EndpointConfig(
        name: "Post Message",
        endpointMatcher: (request) => (request.method == HttpMethod.post && postMessageRegExp.hasMatch(request.uri)),
        delay: const Duration(seconds: 1),
        defaultHandler: (request) {
          // Check again if reg could get specific id
          if (!postMessageRegExp.hasMatch(request.uri)) {
            return MockzillaHttpResponse(statusCode: 400);
          }

          // Declare data
          final Map<String, dynamic> msg = jsonDecode(request.body);
          final convIdx = (chatData["conversations"] as List).indexWhere((e) => e['id'] == msg['conversationId']);
          final Map convLastMessage = {
            "id": msg['conversationId'],
            "participants": chatData["conversations"][convIdx]['participants'],
            "lastMessage": msg['message'],
            "timestamp": msg['timestamp'],
          };

          // Push to 'DB'
          (chatData["messages"] as List).add(msg); // Push to messages
          chatData["conversations"][convIdx] = convLastMessage;

          return MockzillaHttpResponse(statusCode: 200);
        },
        errorHandler: (request) => const MockzillaHttpResponse(statusCode: 418),
      ),

      // Post Messages to specific Conversation
      EndpointConfig(
        name: "Message React",
        endpointMatcher: (request) => (request.method == HttpMethod.patch && reactMessageRegExp.hasMatch(request.uri)),
        delay: const Duration(seconds: 1),
        defaultHandler: (request) {
          // Check again if reg could get specific id
          if (!reactMessageRegExp.hasMatch(request.uri)) {
            return MockzillaHttpResponse(statusCode: 400);
          }

          // Declare data.
          final Map<String, dynamic> msg = jsonDecode(request.body);
          print("received: $msg");
          final String reaction = msg["reaction"];
          final String operation = msg["operation"];
          final int hashIdentifier = msg['hashIdentifier'];
          final msgIdx = (chatData["messages"] as List).indexWhere(
            (e) =>
                e['message'].hashCode ==
                hashIdentifier, // Using dart's hash for now, all messages are supposed comes with key 'id'
          );

          // modify message data
          final modifiedMessage = chatData["messages"][msgIdx];
          if (operation == "add") {
            modifiedMessage['reactions'][reaction] += 1;
          } else {
            modifiedMessage['reactions'][reaction] -= 1;
            // This case should not happen but who knows.
            if (modifiedMessage['reactions'][reaction] < 0) {
              modifiedMessage['reactions'][reaction] = 0;
            }
          }

          // Push to 'DB'
          chatData["messages"][msgIdx] = modifiedMessage;

          return MockzillaHttpResponse(statusCode: 200);
        },
        errorHandler: (request) => const MockzillaHttpResponse(statusCode: 418),
      ),
    ],
  );

  await Mockzilla.startMockzilla(mockzillaConfig);
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
