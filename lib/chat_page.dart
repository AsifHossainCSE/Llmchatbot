import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const String openAiApiKey =
      "";
  static const String modelName = "gpt-4o-mini";

  final TextEditingController _textEditingController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  List<Map<String, String>> _buildApiMessage() {
    final List<Map<String, String>> msgs = [
      {
        "role": "system",
        "content": "You are a helpful assistant. Keep answer short and clear",
      },
    ];
    for (final m in _messages) {
      msgs.add({"role": m.role, "content": m.content});
    }
    return msgs;
  }

  Future<void> _send() async {
    final text = _textEditingController.text.trim();

    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(ChatMessage(role: "user", content: text));
      _textEditingController.clear();
      _loading = true;
    });
    setState(() {
      _messages.add(ChatMessage(role: "assistant", content: "Typing..."));
    });

    try {
      final uri = Uri.parse("https://api.openai.com/v1/chat/completions");

      final res = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAiApiKey",
        },
        body: json.encode({
          "model": modelName,
          "messages": _buildApiMessage(),
          "temperature": 0.7, // 0.2-0.9
        }),
      );

      if (res.statusCode != 200) {
        final err = res.body;
        setState(() {
          _messages.add(
            ChatMessage(role: "assistant", content: "API Error: $err"),
          );
          _loading = false;
        });
        return;
      }

      final data = jsonDecode(res.body);
      print("Api response ${data}");
      final reply =
          data["choices"]?[0]?["message"]?["content"]?.toString().trim() ??
          "NO Response";

      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(role: "assistant", content: reply));
        _loading = false;
      });
    } catch (e) {
      setState(() {
        if (_messages.isNotEmpty && _messages.last.content == "Typing...") {
          _messages.removeLast();
        }
      });
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("LLM Chat Bot")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isUser = m.role == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        hintText: "Type your message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  ElevatedButton(onPressed: _send, child: Text("send")),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String role;
  final String content;
  ChatMessage({required this.role, required this.content});
}