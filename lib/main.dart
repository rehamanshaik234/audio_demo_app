import 'dart:io';
import 'package:audio_demo_app/assets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(AudioPlayerApp());
}

class AudioPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  File? _audioFile;
  File? _backgroundImage;
  bool isPlaying = false;
  bool isAsset = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Listen to player's state changes
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((playing){
      if(playing==PlayerState.playing){
        isPlaying=true;
      }else{
        isPlaying=false;
      }
      setState(() {
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _position = Duration.zero;
        if (_audioFile != null) {
          // Playing audio from the file picked
          _audioPlayer.play(DeviceFileSource(_audioFile!.path));
        } else {
          // Playing the asset audio if no file is picked
          _audioPlayer.play(AssetSource(AssetUrls.audio));
          isAsset = true; // Mark that we're playing from assets
        }
      });
    });
  }

  // For picking audio file from gallery or local storage
  Future<void> _pickAudio() async {
    await Permission.audio.request();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'aac', 'wav'],
    );
    if (result != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
        isAsset = false;
        _position=Duration.zero;
        _duration=Duration.zero;
      });
    }
  }

  // For picking image background
  Future<void> _pickBackgroundImage() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      final pickedImage = await FilePicker.platform.pickFiles(type: FileType.image);
      if (pickedImage != null && pickedImage.files.isNotEmpty) {
        setState(() {
          _backgroundImage = File(pickedImage.files.single.path ?? '');
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permission to access gallery is denied")),
      );
    }
  }

  // Play or Pause Audio
  void _playPauseAudio() {
    if (isPlaying) {
      _audioPlayer.pause();
    } else {
      if (_audioFile != null) {
        // Playing audio from the file picked
        _audioPlayer.play(DeviceFileSource(_audioFile!.path));
      } else {
        // Playing the asset audio if no file is picked
        _audioPlayer.play(AssetSource(AssetUrls.audio));
        isAsset = true; // Mark that we're playing from assets
      }
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Audio Player',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _pickBackgroundImage,
            icon: Icon(Icons.image, color: Colors.white),
          )
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            _backgroundImage != null
                ? Expanded(
              child: Image.file(
                _backgroundImage!,
                fit: BoxFit.cover,
              ),
            )
                : Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                       Expanded(child: Image(image: AssetImage(AssetUrls.image,),fit: BoxFit.contain))
                    ],
                  ),
                ),
            Slider(
              value: _duration.inSeconds > 0 ? _position.inSeconds.toDouble() : 0.0,
              min: 0.0,
              max: _duration.inSeconds.toDouble(),
              activeColor: Colors.blue,
              inactiveColor: Colors.grey, onChanged: (double value) {  },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(width: 20,),
                Text(formatDuration(_position.inSeconds),style: TextStyle(color: Colors.grey),)
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    onPressed: _playPauseAudio,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 30,)
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: _pickAudio,
        child: Icon(Icons.mic, color: Colors.white, size: 20),
      ),
    );
  }

  String formatDuration(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }


}
