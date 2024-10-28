import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Room',
      theme: ThemeData(
        primaryColor: Colors.teal,
        hintColor: Colors.tealAccent,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.teal),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide(color: Colors.tealAccent),
          ),
        ),
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController roomCodeController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  void joinChat() {
    String roomCode = roomCodeController.text.trim();
    String displayName = displayNameController.text.trim();

    if (roomCode.isNotEmpty && displayName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(roomCode: roomCode, displayName: displayName),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both Room Code and Display Name')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Join Chat Room")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: roomCodeController,
              decoration: InputDecoration(labelText: 'Room Code'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              decoration: InputDecoration(labelText: 'Display Name'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: joinChat,
              child: Text('Join Chat'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String roomCode;
  final String displayName;

  ChatScreen({required this.roomCode, required this.displayName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  List<String> messages = [];
  Socket? socket;

  @override
  void initState() {
    super.initState();
    connectToServer();
  }

  Future<void> connectToServer() async {
    try {
      socket = await Socket.connect('192.168.148.251', 12345);
      socket?.write('JOIN ${widget.roomCode} ${widget.displayName}');

      socket?.listen((data) {
        final serverMessage = utf8.decode(data);
        setState(() {
          messages.add(serverMessage);
        });
      }, onDone: () {
        disconnect();
      });
    } catch (e) {
      setState(() {
        messages.add("Unable to connect to server.");
      });
    }
  }

  void sendMessage() {
    if (socket != null && messageController.text.isNotEmpty) {
      // Send message in format "displayName:::message"
      socket!.write('${widget.displayName}: ${messageController.text}\n');
      setState(() {
        messages.add('You: ${messageController.text}');
      });
      messageController.clear();
    }
  }

  void disconnect() {
    socket?.close();
    setState(() {
      socket = null;
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Room: ${widget.roomCode}"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isMe = messages[index].startsWith('You:');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.tealAccent : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        messages[index],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: sendMessage,
                  color: Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
