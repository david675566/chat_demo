import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// local
import 'package:chat_demo/module/chat/conversations.view.dart';
import 'package:chat_demo/module/chat/chat_room.view.dart';

final GlobalKey<NavigatorState> _rootNavKey = GlobalKey<NavigatorState>();

GoRouter goRoutes() {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/c',
    routes: <RouteBase>[
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: '/c',
        name: 'chat',
        builder: (context, state) => const ConversationsView(),
        routes: [
          GoRoute(
            path: '/r',
            name: 'room',
            builder:
                (context, state) => ChatRoomView(
                  conversationId: (state.extra! as Map)['id'],
                  participants: (state.extra! as Map)['participants'],
                ),
          ),
        ],
      ),
    ],
  );
}
