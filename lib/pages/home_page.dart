import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:leopard_flutter/leopard.dart';
import 'package:leopard_flutter/leopard_error.dart';
import 'package:leopard_flutter/leopard_transcript.dart';

import 'package:logger/logger.dart';

import '../utils/text_utils.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder audioRecorder = AudioRecorder();
  final AudioPlayer audioPlayer = AudioPlayer();

  String? recordingPath;
  bool isRecording = false, isPlaying = false, isSTTing = false;

  // String paragraph = "Nothing has been generated yet.";
  String paragraph = "The RichText widget displays text that uses multiple different styles. The text to display is described using a tree of TextSpan objects, each of which has an associated style that is used for that subtree. The text might break across multiple lines or might all be displayed on the same line depending on the layout constraints.Text displayed in a RichText widget must be explicitly styled. When picking which style to use, consider using DefaultTextStyle.of the current BuildContext to provide defaults. For more details on how to style text in a RichText widget, see the documentation for TextStyle.Consider using the Text widget to integrate with the DefaultTextStyle automatically. When all the text uses the same style, the default constructor is less verbose. The Text.rich constructor allows you to style multiple spans with the default text style while still allowing specified styles per span.";

  final ScrollController _scrollController = ScrollController();
  // double _scrollTopOffset = 0.0;

  // Leopard audio recognition
  String accessKey = "Your API KEY"; // AccessKey obtained from Picovoice Console (https://console.picovoice.ai/)
  String modelPath = "assets/leopard_params.pv"; // path relative to the assets folder or absolute path to file on device
  Leopard? _leopard;
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversation coach')),
      floatingActionButton: _recordingButton(),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return Column(
      children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Scrollbar(
              thickness: 10.0,
                thumbVisibility: true,
                controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
              child: RichText(
                text: TextSpan(
                  text: paragraph,
                  style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.normal,
                    color: Colors.black
                  ),
                ),
              ),
            ),
          ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (recordingPath != null)...[
                Expanded(
                child:Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(255, 143, 158, 1),
                        Color.fromRGBO(255, 188, 143, 1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ]
                  ),
                  // Record Button
                  child:GestureDetector(
                    onTap: () async {
                      if (audioPlayer.playing) {
                        audioPlayer.stop();
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        await audioPlayer.setFilePath(recordingPath!);
                        audioPlayer.play();
                        setState(() {
                          isPlaying = true;
                        });
                      }
                    },
                    // color: Theme.of(context).colorScheme.primary,
                    child: Text(
                      isPlaying
                          ? "Stop playing"
                          : "Play recording",
                      style: const TextStyle(
                        color: Colors.white,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                ),
                Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(255, 143, 158, 1),
                        Color.fromRGBO(255, 188, 143, 1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ]
                  ),
                // STT Button
                child:GestureDetector(
                  onTap: () async {
                    // Stop playing recording
                    if (audioPlayer.playing) {
                      audioPlayer.stop();
                      setState(() {
                        isPlaying = false;
                      });
                    }
                    
                    // Start STT
                    setState(() {
                      isSTTing = true;
                    });

                    // Simulate STT processing
                    // Delay for 3 seconds
                    //await Future.delayed(const Duration(seconds: 3));
                    
                    if (recordingPath != null) {
                      try {
                        _leopard = await Leopard.create(accessKey, modelPath, enableAutomaticPunctuation: true, enableDiarization: true);
                      } on LeopardException catch (err) {
                          // handle Leopard init error
                          // print("Leopard init error: $err");
                          logger.e("Leopard process file error: $err"); 
                      }// Use logger instead of print                  }
                      
                      try {
                          LeopardTranscript result = await _leopard!.processFile(recordingPath!);
                          logger.i(result.transcript); 
                          final Directory appDocumentsDir =
                              await getApplicationDocumentsDirectory();
                          String conSuccess = await constructChat(result, appDocumentsDir.path,  "chat.txt");
                          if (conSuccess != '') {
                            setState(() {
                              paragraph = result.transcript;
                            });
                            logger.e("Successfully construct chat."); 
                          } else {
                            logger.e("Failed to construct chat."); 

                            setState(() {
                              paragraph = 'Empty chat.';
                              isSTTing = false;
                            });
                          }
                      } on LeopardException catch (err) { 
                          logger.e("Leopard process file error: $err");
                      } // Use logger instead of print       
                      
                    } else {
                      logger.e("No recording path found.");
                    }
                    await _leopard!.delete();

                    // Stop STT
                    setState(() {
                      isSTTing = false;
                    });
                  },
                  //color: Theme.of(context).colorScheme.primary,
                  child: Text(
                    isSTTing
                        ? "Processing STT"
                        : "Tab to start STT",
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                ),
                ),
                Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.fromRGBO(255, 143, 158, 1),
                        Color.fromRGBO(255, 188, 143, 1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(25.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        spreadRadius: 4,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      )
                    ]
                  ),
                // LLM Button
                child:GestureDetector(
                  onTap: () async {
                    final String prompt = await getPrompt('TEST');
                    const String model = 'gpt-4o-mini';
                    final Directory appDocumentsDir =
                              await getApplicationDocumentsDirectory();
                    const String filename = 'chat.txt';
                    await generateLLMText(prompt, model, p.join(appDocumentsDir.path, filename));
                  },
                  //color: Theme.of(context).colorScheme.primary,
                  child: const Text(
                    "Generate LLM Text",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  ),
                ),
                ),
              ],
            ],
          ),
          if (recordingPath == null) ...[
            const Text(
              "No Recording Found. :(",
            ),
          ],
      ],
    );
    // );SizedBox(
    //   width: MediaQuery.sizeOf(context).width,
    //   child: Column(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     crossAxisAlignment: CrossAxisAlignment.center,
    //     children: [
          
          
          
    //       if (recordingPath != null)...[
    //       // Record Button
    //         MaterialButton(
    //           onPressed: () async {
    //             if (audioPlayer.playing) {
    //               audioPlayer.stop();
    //               setState(() {
    //                 isPlaying = false;
    //               });
    //             } else {
    //               await audioPlayer.setFilePath(recordingPath!);
    //               audioPlayer.play();
    //               setState(() {
    //                 isPlaying = true;
    //               });
    //             }
    //           },
    //           color: Theme.of(context).colorScheme.primary,
    //           child: Text(
    //             isPlaying
    //                 ? "Stop Playing \n Recording"
    //                 : "Start Playing \n Recording",
    //             style: const TextStyle(
    //               color: Colors.white,
    //             ),
    //           ),
    //         ),
    //         // STT Button
    //         MaterialButton(
    //           onPressed: () async {
    //             // Stop playing recording
    //             if (audioPlayer.playing) {
    //               audioPlayer.stop();
    //               setState(() {
    //                 isPlaying = false;
    //               });
    //             }
                
    //             // Start STT
    //             setState(() {
    //               isSTTing = true;
    //             });

    //             // Simulate STT processing
    //             // Delay for 3 seconds
    //             //await Future.delayed(const Duration(seconds: 3));
                
    //             if (recordingPath != null) {
    //               try {
    //                 _leopard = await Leopard.create(accessKey, modelPath, enableAutomaticPunctuation: true, enableDiarization: true);
    //               } on LeopardException catch (err) {
    //                   // handle Leopard init error
    //                   // print("Leopard init error: $err");
    //                   logger.e("Leopard process file error: $err"); 
    //               }// Use logger instead of print                  }
                  
    //               try {
    //                   LeopardTranscript result = await _leopard!.processFile(recordingPath!);
    //                   logger.i(result.transcript); 
    //                   final Directory appDocumentsDir =
    //                       await getApplicationDocumentsDirectory();
    //                   bool conSuccess = await constructChat(result, appDocumentsDir.path,  "chat.txt");
    //                   if (conSuccess) {
    //                     logger.e("Successfully construct chat."); 
    //                   } else {
    //                     logger.e("Failed to construct chat."); 
    //                   }
    //               } on LeopardException catch (err) { 
    //                   logger.e("Leopard process file error: $err");
    //               } // Use logger instead of print       
                  
    //             } else {
    //               logger.e("No recording path found.");
    //             }
    //             await _leopard!.delete();

    //             // Stop STT
    //             setState(() {
    //               isSTTing = false;
    //             });
    //           },
    //           color: Theme.of(context).colorScheme.primary,
    //           child: Text(
    //             isSTTing
    //                 ? "Processing STT"
    //                 : "Tab to start STT",
    //             style: const TextStyle(
    //               color: Colors.white,
    //             ),
    //           ),
    //         ),
    //         // LLM Button
    //         MaterialButton(
    //           onPressed: () async {
    //             final String prompt = await getPrompt('TEST');
    //             const String model = 'gpt-4o-mini';
    //             final Directory appDocumentsDir =
    //                       await getApplicationDocumentsDirectory();
    //             const String filename = 'chat.txt';
    //             await generateLLMText(prompt, model, p.join(appDocumentsDir.path, filename));
    //           },
    //           color: Theme.of(context).colorScheme.primary,
    //           child: const Text(
    //             "Generate LLM Text",
    //             style: TextStyle(
    //               color: Colors.white,
    //             ),
    //           ),
    //         ),
    //       ],
    //       if (recordingPath == null) ...[
    //         const Text(
    //           "No Recording Found. :(",
    //         ),
    //       ]
    //     ],
    //   ),
    // );
  }

  Widget _recordingButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (isRecording) {
          String? filePath = await audioRecorder.stop();
          if (filePath != null) {
            setState(() {
              isRecording = false;
              recordingPath = filePath;
            });
          }
        } else {
          if (await audioRecorder.hasPermission()) {
            final Directory appDocumentsDir =
                await getApplicationDocumentsDirectory();
            final String filePath =
                p.join(appDocumentsDir.path, "recording.m4a");
            await audioRecorder.start(
              const RecordConfig(),
              path: filePath,
            );
            setState(() {
              isRecording = true;
              recordingPath = null;
            });
          }
        }
      },
      child: Icon(
        isRecording ? Icons.stop : Icons.mic,
      ),
    );
  }
}
