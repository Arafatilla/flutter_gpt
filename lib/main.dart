
import 'package:flutter/material.dart';
import 'package:flutter_gpt/constants.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterGPT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF84D45E),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'FlutterGPT Chat'),
    );
  }
}

class Chat {
  final String? text;
  final bool isSender;

  Chat(this.text, this.isSender);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late OpenAI openAI;
  final List<Chat> _conversations = [];

  @override
  void initState() {
    super.initState();
    openAI = OpenAI.instance.build(token: OPENAI_API_KEY);
  }

Future<void> send() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  setState(() {
    _conversations.add(Chat(text, true)); // Add the user's message.
    _controller.clear(); // Clear the input field.
  });

  try {
    var response = await openAI.onCompletion(
      request: CompleteText(
        prompt: text,
        model: Gpt3TurboInstruct(), // Ensure this is the correct model
      ),
    );

    print('Response: $response'); // Debug print response

    if (response != null && response.choices.isNotEmpty) {
      setState(() {
        _conversations.add(Chat(response.choices.first.text.trim(), false)); // Add AI's response.
      });
    } else {
      setState(() {
        _conversations.add(Chat('No response from AI', false)); // Default message in case of empty response
      });
    }
  } catch (e) {
    print('Error: $e'); // Catch any errors and print
    if (e.toString().contains('429')) {
      setState(() {
        _conversations.add(Chat('Rate limit exceeded. Please try again later.', false)); // Handle 429 error
      });
    } else {
      setState(() {
        _conversations.add(Chat('Error occurred: $e', false)); // Show other errors
      });
    }
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final convo = _conversations[index];
                return Align(
                  alignment:
                      convo.isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Chip(
                    backgroundColor:
                        convo.isSender ? const Color.fromARGB(255, 112, 206, 178) : const Color.fromARGB(255, 185, 212, 253),
                    label: Text(
                      convo.text ?? "",
                      style: TextStyle(
                        color: convo.isSender ? const Color.fromARGB(255, 20, 17, 17) : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: send,
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
