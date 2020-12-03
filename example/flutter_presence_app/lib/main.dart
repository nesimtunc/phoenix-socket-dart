import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
      '[${record.loggerName}] ${record.level.name} ${record.time}: '
      '${record.message}',
    );
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phoenix Presence Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Phoenix Presence Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _socketOptions =
      PhoenixSocketOptions(params: {'user_id': 'example user 1'});
  PhoenixSocket _socket;
  PhoenixChannel _channel;
  PhoenixPresence _presence;
  var _responses = [];

  @override
  void initState() {
    _socket = PhoenixSocket('ws://localhost:4001/socket/websocket',
        socketOptions: _socketOptions);
    _channel = _socket.addChannel(topic: 'presence:lobby');
    _presence = PhoenixPresence(channel: _channel);

    _socket.closeStream.listen((event) {});
    _socket.openStream.listen((event) {
      _channel.join();
    });

    _presence.onSync = () => setState(() {});

    _socket.connect();
    super.initState();
  }

  @override
  void dispose() {
    _presence.dispose();
    _channel.close();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('state:');
    print(_presence?.state);

    _responses =
        _presence?.list(_presence?.state, (String id, Presence presence) {
      final metas = presence.metas;
      var count = metas.length;
      final response = '${id} (count: ${count})';
      return response;
    });
    if (_responses != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Presence Example')),
        body: Container(
          child: ListView.builder(
            itemCount: _responses.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(_responses[index]),
              );
            },
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
