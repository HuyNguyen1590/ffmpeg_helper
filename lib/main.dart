import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String inputFile = "";
  ValueNotifier<String> ffmpegPathVal = ValueNotifier("");
  ValueNotifier<String> message = ValueNotifier("Please pick file");
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async{
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      ffmpegPathVal.value = prefs.getString("ffmpeg") ?? "";

    });

  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ValueListenableBuilder<String>(
              valueListenable: message,
                builder: (context,mess, _) {
                  return Container(
                    color: Colors.green,
                    child: Text(mess, style: TextStyle(fontSize: 20, color: Colors.black),),
                  );
                }
            ),
            SizedBox(
              height: 10,
            ),
            ValueListenableBuilder<String>(
              valueListenable: ffmpegPathVal,
                builder: (context,p, _) {
                  return GestureDetector(
                    onTap: ()async{
                      FilePickerResult? fileResult = await FilePicker.platform.pickFiles();
                      if(fileResult != null){
                        if(fileResult.files.first.path.toString().contains("ffmpeg.exe")){
                          ffmpegPathVal.value = fileResult.files.first.path!;
                          final SharedPreferences prefs = await SharedPreferences.getInstance();
                          prefs.setString("ffmpeg", ffmpegPathVal.value);
                        }
                      }
                    },
                    child: Container(
                      width: 200,
                      height: 50,
                      color: Colors.green,
                      child: Center(
                        child: Text("Pick FFMPEG: $p"),
                      ),
                    ),
                  );
                }
            ),
            SizedBox(
              height: 10,
            ),
            StatefulBuilder(
              builder: (context,ss) {
                return GestureDetector(
                  onTap: ()async{
                    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
                    if(selectedDirectory != null){
                      ss(() {
                        inputFile = selectedDirectory;
                      });
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 50,
                    color: Colors.green,
                    child: Center(
                      child: Text("Input: $inputFile"),
                    ),
                  ),
                );
              }
            ),
            SizedBox(
              height: 10,
            ),
            StatefulBuilder(
                builder: (context,ss) {
                  return GestureDetector(
                    onTap: ()async{
                      compressOGG(Directory(inputFile),(count, total){
                        message.value = "Processing... $count/$total";
                      },(amount, result){
                        message.value = "$amount files compressed, $result% smaller";
                      });
                    },
                    child: Container(
                      width: 100,
                      height: 50,
                      color: Colors.green,
                      child: Center(
                        child: Text("Reduce Size"),
                      ),
                    ),
                  );
                }
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  Future<void> compressOGG(Directory directory, Function(int amountFile, int total) onProcess, Function(int amountFile, int compressResult) onFinish) async {
    List<String> filePaths = listFilesBiggerThan1Mb(directory);
    Directory temp = await getTemporaryDirectory();
    print("Create output directory...");
    int totalSize = 0;
    int reducedSize = 0;
    int total = filePaths.length;
    int count = 0;
    List<String> tempPath = [];

    print("filePaths.length: ${filePaths}");
    for (var i = 0; i<filePaths.length;i++) {
      File inputFile = File(filePaths[i]);
      totalSize+=inputFile.lengthSync();
      File tempFile = File("${temp.path}\\${inputFile.path.split("\\").last}");
      tempPath.add(tempFile.path);
      await tempFile.create();
      await inputFile.copy(tempFile.path);
      await inputFile.delete();
      ProcessResult process = Process.runSync('${ffmpegPathVal.value}', ['-y','-i', '${tempFile.path}', '-c:a', 'libvorbis', '-b:a', '64k', '${inputFile.path}'], runInShell: true,);
      print("success ${process.stdout} ${process.stderr} ${process.exitCode} ${process.pid}");
      ///Error != 0 nghĩa là có gì đó bị sai nên recovery file
      if(process.exitCode != 0){
        await inputFile.create();
        await tempFile.copy(inputFile.path);
        print("recover: ${inputFile.path}");
      }
      count++;
      onProcess.call(count, total);
    }
    await Future.delayed(Duration(seconds: 5));
    for (var i = 0; i<filePaths.length;i++) {
      File inputFile = File(filePaths[i]);
      reducedSize+=inputFile.lengthSync();
    }
    print("totalsize: $totalSize");
    print("reducedSize: $reducedSize");
    print("percent: ${(((totalSize.toDouble() - reducedSize.toDouble())/totalSize.toDouble()) * 100.0)}");
    onFinish.call(total, (((totalSize.toDouble() - reducedSize.toDouble())/totalSize.toDouble()) * 100.0).toInt());
  }
  // This function lists all files in a directory and its subdirectories.
  static List<String> listFilesBiggerThan1Mb(Directory directory) {
    return _listFiles(directory);
  }
  static List<String> _listFiles(Directory dir){
    List<String> files = [];
    // Get all the files in the directory.
    List<FileSystemEntity> data = dir.listSync();
    for(var i = 0; i < data.length; i++){
      FileSystemEntity file = data[i];
      if (file is File && file.path.endsWith(".ogg")) {
        // Get the file size in bytes.
        int fileSizeInBytes = file.lengthSync();

        // Check if the file size is larger than 1MB.
        // if (fileSizeInBytes > 1048576) {
        files.add(file.path);
        // print("${fileSizeInBytes} bigger 1048576");
        // }
      } else if (file is Directory) {
        // Recursively list all files in the subdirectory.
        files.addAll(_listFiles(file));
      }
    }

    return files;
  }
}
