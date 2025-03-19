import 'package:avatar_stack/animated_avatar_stack.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:jiffy/jiffy.dart';

// local
import 'package:chat_demo/domain/conversation/conversation.bloc.dart';
import 'package:chat_demo/domain/conversation/conversation.model.dart';

class ConversationsView extends StatefulWidget {
  const ConversationsView({super.key});

  @override
  createState() => _ConversationsState();
}

class _ConversationsState extends State<ConversationsView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat Demo App")),
      body: SafeArea(
        child: BlocProvider<ConversationBloc>(
          create: (context) {
            return ConversationBloc(convRepository: ConversationRepository())..add(RequestGetConversations());
          },
          child: BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (previous, current) => previous.runtimeType != current.runtimeType,
            builder:
                (context, state) => RefreshIndicator.adaptive(
                  onRefresh: () async {
                    Future block = context.read<ConversationBloc>().stream.first;
                    context.read<ConversationBloc>().add(RequestGetConversations());
                    await block;
                  },
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 36)), // padding
                      // When everything ready
                      if (state is ConversationReady)
                        SliverList.separated(
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemCount: state.data.length,
                          itemBuilder: (context, index) => _buildChatTile(state.data[index]),
                        ),

                      // When still loading
                      if (state is ConversationInitial || state is FetchingConversation)
                        SliverToBoxAdapter(child: Center(child: CircularProgressIndicator.adaptive())),

                      // When failed, shows a red line of error string
                      if (state is ConversationLoadFailure)
                        SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              "Error!, Exception:${state.errorStr}",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(ConversationModel data) {
    return ListTile(
      onTap: () => context.goNamed("room", extra: {'id': data.id, 'participants': data.participants}),
      leading: Container(
        width: 72,
        alignment: Alignment.centerLeft,
        child: AnimatedAvatarStack(
          // settings: RestrictedPositions(maxCoverage: -0.1, minCoverage: -0.5, align: StackAlign.right),
          height: 42,
          avatars: data.participants.map((e) => CachedNetworkImageProvider(e.photoUrl!)).toList(),
        ),
      ),
      title: Text(data.participants.map((e) => e.name!).join('&')),
      subtitle: Text(data.lastMessage),
      trailing: Text(Jiffy.parseFromDateTime(data.timestamp).fromNow(), style: TextStyle(color: Colors.grey)),
    );

    //
    // Old implementation from one of my past project.
    // That project required more versatile layout (especially @ 'leading') so ListTile is out for that.
    //
    // return Container(
    //   height: 81,
    //   alignment: Alignment.center,
    //   padding: const EdgeInsets.only(left: 12, right: 24, top: 9, bottom: 9),
    //   decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey))),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     children: [
    //       Stack(
    //         children: [
    //           Center(child: Avatar(from: data.participants.first)),
    //           Positioned(
    //             right: 1.5,
    //             bottom: 8.1,
    //             child: Container(
    //               height: 9.6,
    //               width: 9.6,
    //               decoration: BoxDecoration(
    //                 color: Colors.greenAccent,
    //                 shape: BoxShape.circle,
    //                 border: Border.all(color: Colors.white),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //       const SizedBox(width: 12),
    //       Column(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [Text(data.lastMessage, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))],
    //       ),
    //       const Spacer(),
    //       Column(
    //         mainAxisAlignment: MainAxisAlignment.end,
    //         crossAxisAlignment: CrossAxisAlignment.end,
    //         children: [Text(Jiffy.parseFromDateTime(data.timestamp).fromNow(), style: TextStyle(color: Colors.grey))],
    //       ),
    //     ],
    //   ),
    // );
  }
}
