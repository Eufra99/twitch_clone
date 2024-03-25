import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:twitch_clone/config/appId.dart';
import 'package:twitch_clone/providers/user_provider.dart';
import 'package:twitch_clone/resources/firestore_methods..dart';
import 'package:twitch_clone/responsive/responsive_layout.dart';
import 'package:twitch_clone/screens/home_screen.dart';
import 'package:twitch_clone/widgets/custom_button.dart';

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;
  const BroadcastScreen(
      {Key? key, required this.isBroadcaster, required this.channelId})
      : super(key: key);

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  RtcEngine? _engine;
  List<int> remoteUidList = [];
  bool swithCamera = true;
  bool isMuted = false;
  bool isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  
  void _initEngine() async {
    //await [Permission.microphone, Permission.camera].request();
   
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
    ));

    _addListeners();
    await _engine!.enableVideo();
    await _engine!.startPreview();

    await _engine!
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    if (widget.isBroadcaster) {
      _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    }

    _joinChannel();
  }

  void _addListeners() {
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onError: (err, msg) {
        debugPrint('[onError] err: $err, msg: $msg');
      },
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('joinChannelSuccess ${connection.toJson()} $elapsed');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint('userJoined ${connection.toJson()}  $elapsed)');
        setState(() {
          remoteUidList.add(remoteUid);
        });
      },
      onUserOffline: (connection, remoteUid, reason) {
        debugPrint('userOffline ${connection.toJson()}  $reason');
        setState(() {
          remoteUidList.removeWhere((element) => element == remoteUid);
        });
      },
      onLeaveChannel: (connection, stats) {
        debugPrint(
            'connection: ${connection.toJson()} leaveChannel ${stats.toJson()}');
        setState(() {
          remoteUidList.clear();
        });
      },
    ));
  }

  void _joinChannel() async {
    //await getToken();

    await _engine!.joinChannelWithUserAccount(
        token: tempToken,
        channelId: 'test123',
        userAccount:
            Provider.of<UserProvider>(context, listen: false).user.uid);
  }

  _leaveChannel() async {
    await _engine!.leaveChannel();
    if ('${Provider.of<UserProvider>(context, listen: false).user.uid}${Provider.of<UserProvider>(context, listen: false).user.username}' ==
        widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().uptadeViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return WillPopScope(
      onWillPop: () async {
        print("SSSSSSSS");
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: CustomButton(onTap: () {}, text: 'End Stream'),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: ResponsiveLatout(
            desktopBody: Row(
              children: [
                _renderVideo(user, isScreenSharing),
                Expanded(
                    child: Column(
                  children: [
                    if ("${user.uid}${user.username}" == widget.channelId)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {},
                            child: const Text('Switch Camera'),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text(isMuted ? 'Unmute' : 'Mute'),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text('Stop ScreenSharing'),
                          )
                        ],
                      )
                  ],
                )),
                //Chat(channelId: widget.channelId),
              ],
            ),
            mobileBody: Column(
              children: [
                _renderVideo(user, isScreenSharing),
                if ("${user.uid}${user.username}" == widget.channelId)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {},
                        child: const Text('Switch Camera'),
                      ),
                      InkWell(
                        onTap: () {},
                        child: Text(isMuted ? 'Unmute' : 'Mute'),
                      ),
                    ],
                  ),
                //chat
              ],
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(user, isScreenSharing) {
    return AspectRatio(
        aspectRatio: 16 / 9,
        child: "${user.uid}${user.username}" == widget.channelId
            ? isScreenSharing
                ? kIsWeb
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine!,
                          canvas: const VideoCanvas(uid: 0),
                          useFlutterTexture: false,
                          useAndroidSurfaceView: false,
                        ),
                        onAgoraVideoViewCreated: (viewId) {
                          _engine!.startPreview();
                        },
                      )
                    : AgoraVideoView(
                        controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                            useFlutterTexture: false,
                            useAndroidSurfaceView: false),
                        onAgoraVideoViewCreated: (viewId) {
                          _engine!.startPreview();
                        },
                      )
                : AgoraVideoView(
                    controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                        useFlutterTexture: false,
                        useAndroidSurfaceView: false),
                    onAgoraVideoViewCreated: (viewId) {
                      _engine!.startPreview();
                    },
                  )
            : isScreenSharing
                ? kIsWeb
                    ? AgoraVideoView(
                        controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                            useFlutterTexture: false,
                            useAndroidSurfaceView: false),
                        onAgoraVideoViewCreated: (viewId) {
                          _engine!.startPreview();
                        },
                      )
                    : AgoraVideoView(
                        controller: VideoViewController(
                            rtcEngine: _engine!,
                            canvas: const VideoCanvas(uid: 0),
                            useFlutterTexture: false,
                            useAndroidSurfaceView: false),
                        onAgoraVideoViewCreated: (viewId) {
                          _engine!.startPreview();
                        },
                      )
                : remoteUidList.isNotEmpty
                    ? kIsWeb
                        ? AgoraVideoView(
                            controller: VideoViewController.remote(
                                rtcEngine: _engine!,
                                canvas: VideoCanvas(uid: remoteUidList[0]),
                                connection:
                                    RtcConnection(channelId: widget.channelId),
                                useFlutterTexture: false,
                                useAndroidSurfaceView: false),
                          )
                        : AgoraVideoView(
                            controller: VideoViewController.remote(
                                rtcEngine: _engine!,
                                canvas: VideoCanvas(uid: remoteUidList[0]),
                                connection:
                                    RtcConnection(channelId: widget.channelId),
                                useFlutterTexture: false,
                                useAndroidSurfaceView: false),
                          )
                    : Container());
  }
}
