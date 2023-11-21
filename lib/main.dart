// ignore_for_file: library_private_types_in_public_api

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Audio Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CallScreen(),
    );
  }
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine rtcEngin;
  int? _remoteUid;
  bool _localUserJoined = false;
  @override
  void initState() {
    super.initState();
    initializeAgora();
  }

  Future<void> initializeAgora() async {
    await [
      Permission.microphone,
      Permission.audio,
    ].request();

    rtcEngin = createAgoraRtcEngine();
    rtcEngin.initialize(const RtcEngineContext(
        appId: '06b417f44ed0470e9249534d3a603920',
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting));

    rtcEngin.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await rtcEngin.setClientRole(role: ClientRoleType.clientRoleAudience);
  }

  @override
  void dispose() async {
    await rtcEngin.leaveChannel();
    await rtcEngin.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Audio Call'),
      ),
      body: Center(
          child: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                try {
                  await rtcEngin.leaveChannel();
                  await rtcEngin.joinChannel(
                    token: 'token',
                    channelId: 'ak',
                    uid: 0,
                    options: const ChannelMediaOptions(
                      autoSubscribeAudio: true,
                    ),
                  );
                } catch (e) {
                  print('${e.toString()} ====================');
                }
              },
              child: const Text('Join')),
          Builder(
            builder: (context) {
              if (_localUserJoined) {
                return const Text('Joined');
              } else {
                return const Text('Waiting');
              }
            },
          ),
          // Builder(
          //   builder: (context) {
          //     if (_remoteUid == null) {
          //       return const Text('Offline');
          //     } else {
          //       return const Text('joined');
          //     }
          //   },
          // ),
        ],
      )),
    );
  }
}

// 06b417f44ed0470e9249534d3a603920