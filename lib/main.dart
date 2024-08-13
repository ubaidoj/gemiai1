import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gai;
import 'package:image_picker/image_picker.dart';

void main() {
  Gemini.init(apiKey: 'AIzaSyB7fJT-GR1DyfXrP2kEkGGZmET25oREquw');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gemiaichat'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late gai.GenerativeModel model;
  File? _image;
  List<Map<String, dynamic>> messages = [];
  TextEditingController controller = TextEditingController();
  bool isWaitingForResponse = false; 

  @override
  void initState() {
    super.initState();
    model = gai.GenerativeModel(model: 'gemiai1', apiKey: 'AIzaSyB7fJT-GR1DyfXrP2kEkGGZmET25oREquw');
  }

  // Method to process text input
  Future<void> processTextInput() async {
    final textInput = controller.text.trim();

    if (textInput.isNotEmpty && !isWaitingForResponse) {
      setState(() {
        isWaitingForResponse = true;
        messages.add({'message': textInput, 'sender': 'user'}); 
      });

      controller.clear(); 

      final gemini = Gemini.instance;
      try {
        final response = await gemini.text(textInput);
        final botResponse = response?.output ?? 'No response from the model.';
        
        setState(() {
          messages.add({'message': botResponse, 'sender': 'bot'}); 
          isWaitingForResponse = false; 
        });
      } catch (e) {
        print('Error: $e');
        setState(() {
          isWaitingForResponse = false; 
        });
      }
    }
  }

  
  Future<void> processTextAndImageInput() async {
    if (_image != null && !isWaitingForResponse) {
      setState(() {
        isWaitingForResponse = true;
        messages.add({'image': _image, 'sender': 'user'}); 
      });

      controller.clear(); 

      final gemini = Gemini.instance;
      Uint8List imageBytes = await _image!.readAsBytes();
      final textInput = controller.text.isNotEmpty ? controller.text : "What is in this picture?";

      try {
        final response = await gemini.textAndImage(
          text: textInput,
          images: [imageBytes],
        );
        final botResponse = response?.content?.parts?.last.text ?? 'No response from the model.';

        setState(() {
          messages.add({'message': botResponse, 'sender': 'bot'}); 
          isWaitingForResponse = false; 
          _image = null; 
        });
      } catch (e) {
        print('Error: $e');
        setState(() {
          isWaitingForResponse = false; 
          _image = null; 
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
              itemCount: messages.length,
              reverse: true, 
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index]; 
                final alignment = message['sender'] == 'user' ? Alignment.centerRight : Alignment.centerLeft;
                final color = message['sender'] == 'user' ? Colors.blue : Colors.grey[300];

                if (message['image'] != null) {
                  // Display image
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Align(
                      alignment: alignment,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Image.file(
                          message['image'],
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                } else {
                  // Display text message
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Align(
                      alignment: alignment,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(message['message']!),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            height: MediaQuery.of(context).size.height * 0.20, 
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: isWaitingForResponse
                      ? null 
                      : () async {
                          final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
                          if (pickedImage != null) {
                            setState(() {
                              _image = File(pickedImage.path);
                            });
                            processTextAndImageInput();
                          }
                        },
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter your text...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueGrey),
                  onPressed: isWaitingForResponse
                      ? null 
                      : () {
                          if (_image == null) {
                            processTextInput();
                          } else {
                            processTextAndImageInput();
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
