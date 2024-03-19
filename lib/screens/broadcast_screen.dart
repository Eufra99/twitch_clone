import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twitch_clone/config/appId.dart';

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
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool swithCamera = true;
  bool isMuted = false;
  bool isScreenSharing = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _initEngine() async {
    await _engine.initialize(RtcEngineContext(
      appId: appId,
    ));

    _addListeners();

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine
        .setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    if (widget.isBroadcaster) {
      _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    } else {
      _engine.setClientRole(role: ClientRoleType.clientRoleAudience);
    }

    //_joinChannel();
  }

  void _addListeners() {
    _engine.registerEventHandler(
        RtcEngineEventHandler(onJoinChannelSuccess: (connection, elapsed) {
      debugPrint(
          'joinChannelSuccess ${connection.channelId} ${connection.localUid} $elapsed');
    }));
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
