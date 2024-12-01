import 'dart:io';

import 'package:leopard_flutter/leopard_transcript.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
// class TextUtils {
//   /*

//   */
// }

Future<String> constructChat(LeopardTranscript result, String path, String filename) async {
  int length = result.words.length;

  int head = 0, curSpeaker = -1, strHead = 0;

  String paragraph = '';
  try {
    File file = File('$path/$filename');
    final sink = file.openWrite();
    while (head < length) {
    if (curSpeaker != result.words[head].speakerTag) {
      if (curSpeaker != -1) {
        sink.write('\n');
        paragraph += '\n';
      }
      curSpeaker = result.words[head].speakerTag;
      sink.write('Speaker $curSpeaker:\n');
      paragraph += 'Speaker $curSpeaker:\n';
    }
    sink.write(result.words[head].word);
    paragraph += result.words[head].word;

    // Check for punctuation
    strHead += result.words[head].word.length;
    if (result.transcript[strHead] == '.') {
      sink.write('.');
      paragraph += '.';
    } else{
      sink.write(' ');
      paragraph += ' ';
      strHead++;
    }
    head++;
  }

    await sink.flush();
    // Close the IOSink to free system resources.
    await sink.close();
  } catch (e) {
    return '';
  }
  
  return paragraph;
}

Future<String> getPrompt(String type) async {
  String? promptPath;
  switch (type) {
    case 'TEST':
      promptPath = 'assets/prompts/test_prompt.txt';
    default:
      promptPath = 'assets/prompts/default_prompt.txt';
  }

  return await rootBundle.loadString(promptPath);
}

Future<String> generateLLMText(String prompt, String model, String filename) async {
  const String url = 'https://api.openai.com/v1/chat/completions';
  const String apiKey = 'YOUR API KEY';
  
  final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
  };

  // Read the file
  final contents = await File(filename).readAsString();
  
  // https://platform.openai.com/docs/api-reference/chat/create#chat-create-messages
  final data = {
    // 'prompt': prompt,
    'model': model,
    'temperature': 0.5,
    'messages':[
      {
        'role': 'system',
        'content': prompt
      },
      {
        'role': 'user',
        'content': contents
      }
    ],
  };
  
  var response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(data),
  );
  return jsonDecode(response.body)['choices'][0]['message']['content'];
}