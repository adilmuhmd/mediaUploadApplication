import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mediauploadapplication/main.dart';
import 'package:mediauploadapplication/videoplayer.dart';


class homePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  final String baseUrl = 'http://192.168.1.5:3000';
  List<String> uploadedFiles = [];
  double uploadProgress = 0.0;
  bool uploading = false;
  bool show =true;
  final int minFileSize = 100 * 1024 * 1024; // 100 MB in bytes
  String selectedFile = "No file selected";
  String validationMessage = "";

  @override
  void initState() {
    super.initState();
    fetchUploadedFiles();
    uploading = true;
  }
  void showNotification(double progress) {
    const int notificationId = 1;

    flutterLocalNotificationsPlugin.show(
      notificationId,
      'Uploading File',
      'Progress: ${(progress ).toStringAsFixed(1)}%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_channel',
          'File Upload',
          channelDescription: 'Notification for file upload progress',
          importance: Importance.low,
          priority: Priority.low,
          showProgress: true,
          maxProgress: 100,
          progress: (progress).toInt(),
        ),
      ),
    );

    if (progress == 100) {
      flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> fetchUploadedFiles() async {
    try {
      final response = await Dio().get('$baseUrl/files');
      if (response.statusCode == 200) {
        setState(() {
          uploadedFiles = List<String>.from(response.data);
        });
      }
    } catch (e) {
      print('Error fetching files: $e');
    }
  }

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });

      try {
        final dio = Dio();
        dio.interceptors.add(LogInterceptor());
        setState(() {
          uploading = false;
          uploadProgress = 0.0;
        });

        final response = await dio.post(
          '$baseUrl/upload',
          data: formData,
          onSendProgress: (sent, total) {
            setState(() {
              uploadProgress = sent / total *100;
            });
            showNotification(uploadProgress);
          },
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File uploaded successfully!')));
          fetchUploadedFiles(); // Refresh the uploaded files list
        }


      } catch (e) {

        print('Error uploading file: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file')));
      }
    }
  }

  void previewFile(String filename) {
    if (filename.endsWith('.mp4')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => videoPlayer(videoUrl: '$baseUrl/files/$filename'),
        ),
      );
    } else {
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) =>pdf(),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var height=size.height;
    var width=size.width;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 102, 102, 255),
          title: Text('Media Upload Application',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
            ),
          )),
      body: Center(
        child: Column(
          children: [


            //   Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Visibility(
            //     visible: uploadProgress > 0 && uploadProgress <98,
            //     child: LinearProgressIndicator(
            //       color: Colors.blue,
            //         minHeight: 25,
            //         value: uploadProgress/100),
            //   ),
            // ),

            Expanded(
              child: GridView.builder(
                itemCount: uploadedFiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemBuilder: (context, index) {
                  final filename = uploadedFiles[index];
                  return GestureDetector(
                    onTap: () => previewFile(filename),
                    child: Card(
                      elevation: 2,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                filename.endsWith('.mp4') ? Icons.video_file : Icons.picture_as_pdf,
                                size: 60,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                filename,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis, // Truncate long file names
                                maxLines: 2, // Limit to two lines
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Visibility(
            visible: uploadProgress < 1 || uploadProgress > 99,
            child: Container(
              height: 65.0,
              width: width/4,
              child: FittedBox(
                child: FloatingActionButton(
                  backgroundColor:Color.fromARGB(255, 102, 102, 255),
                  onPressed: uploadFile,
                  child: Icon(Icons.add_circle_rounded,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: uploadProgress > 2 && uploadProgress <99,
            child: Container(
              margin: const EdgeInsets.all(15),
              height: 125,
              width: width/1.2,
              child: Container(
                padding: const EdgeInsets.all(7),
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.white
                ),
                child: Column(
                  children: [
                    Text(
                      '${(uploadProgress).toInt()}%', // Display percentage
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      width: width/1.5,
                      child: LinearProgressIndicator(
                          color: Color.fromARGB(255, 102, 102, 255),
                          minHeight: 30,


                          value: uploadProgress/100),
                    ),
                    Text(
                      'Uploading', // Display percentage
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),


        ],
      ),
    );
  }
}
