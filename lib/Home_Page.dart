import 'dart:io';
import 'dart:core';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera_app/video_Player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as cam;
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:list_wheel_scroll_view_nls/list_wheel_scroll_view_nls.dart';
import 'package:path/path.dart' as p;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:native_camera_sound/native_camera_sound.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class FocusCirclePainter extends CustomPainter {
  final Offset focusPoint;

  FocusCirclePainter(this.focusPoint);

  @override
  void paint(Canvas canvas, Size size) {
    if (focusPoint != null) {
      final paint = Paint()
        ..color = const Color.fromARGB(255, 255, 255, 255)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(focusPoint, 30, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Home_Page extends StatefulWidget {
  final List<cam.CameraDescription> cameras;

  const Home_Page({
    super.key,
    required this.cameras,
  });

  @override
  State<Home_Page> createState() => _Home_PageState();
}

class _Home_PageState extends State<Home_Page> {
  late cam.CameraController cameraController;
  late Future<void> cameraValue;
  int isFlashOn = 0;
  bool isRearCamera = true;
  bool Fselectmenu = true;
  bool Sselectmenu = false;
  num isblink = 100;
  bool isVideo = false;
  bool isRecording = false;
  bool countUp = false;
  bool is05 = false;
  bool is1 = false;
  bool isBlinking = false;
  late String Vpath;
  Offset? focusPoint;
  Timer? _focusTimer;
  bool videoRecorded = false;
  double _currentZoomLevel = 1.0;
  double _baseZoomLevel = 1.0;
  double _minZoomLevel = 1.0; // Default min zoom level
  double _maxZoomLevel = 8.0;

  final List<String> items = [
    '230P',
    '720P',
    '2160P',
  ];
  String selectedValue = "2160P";

  late File vfile;
  int camera = 0;
  late File Capturedimage = File('img1.jpg');
  late cam.XFile imagee;

  final StopWatchTimer _stopWatchTimer = StopWatchTimer();

  Future<void> initializeCamera(camera, res) async {
    final cameras = await cam.availableCameras();

    if (res == "230P") {
      cameraController = cam.CameraController(
          cameras[camera], cam.ResolutionPreset.low,
          enableAudio: true);
    } else if (res == "720P") {
      cameraController = cam.CameraController(
          cameras[camera], cam.ResolutionPreset.high,
          enableAudio: true);
    } else if (res == "2160P") {
      cameraController = cam.CameraController(
          cameras[camera], cam.ResolutionPreset.ultraHigh,
          enableAudio: true);
    }
    cameraValue = cameraController.initialize();
    await cameraValue;

    _minZoomLevel = await cameraController.getMinZoomLevel();
    _maxZoomLevel = await cameraController.getMaxZoomLevel();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initializeCamera(camera, selectedValue);
  }

  @override
  void dispose() async {
    super.dispose();
    _focusTimer?.cancel();
    await _stopWatchTimer.dispose(); // Need to call dispose function.
  }

  Future<cam.XFile> saveImage(cam.XFile image) async {
    GallerySaver.saveImage(image.path);
    return image;
  }

  Future<void> FLash() async {
    setState(() {
      if (isFlashOn == 2) {
        isFlashOn = 0;
      } else {
        isFlashOn = isFlashOn + 1;
      }
    });

    if (isFlashOn == 2) {
      await cameraController.setFlashMode(cam.FlashMode.torch);
    } else if (isFlashOn == 0) {
      await cameraController.setFlashMode(cam.FlashMode.off);
    }
  }

  void _toggleBlink() {
    setState(() {
      isBlinking = true;
    });

    Future.delayed(Duration(milliseconds: 200), () {
      setState(() {
        isBlinking = false;
      });
    });
  }

  void onViewFinderTap(TapDownDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);

    final adjustedOffset = Offset(offset.dx, offset.dy - 70);

    print("Tapped position: ${details.globalPosition}");
    print("Local offset: $offset");

    setFocusPoint(cameraController!, adjustedOffset);
  }

  Future<void> setFocusPoint(
      cam.CameraController controller, Offset offset) async {
    final double dx = offset.dx / MediaQuery.of(context).size.width;
    final double dy = offset.dy / MediaQuery.of(context).size.height;
    await controller.setFocusPoint(Offset(dx, dy));

    print(dy);

    setState(() {
      focusPoint = offset;
    });

    _focusTimer?.cancel(); // Cancel any previous timer
    _focusTimer = Timer(Duration(seconds: 1), () {
      setState(() {
        focusPoint = null;
      });
    });
  }

  void takePicture() async {
    cam.XFile? image;

    if (cameraController.value.isTakingPicture ||
        !cameraController.value.isInitialized) {
      return;
    }
    if (isFlashOn == 1) {
      await cameraController.setFlashMode(cam.FlashMode.auto);
    } else if (isFlashOn == 0) {
      await cameraController.setFlashMode(cam.FlashMode.off);
    }

    image = await cameraController.takePicture();
    NativeCameraSound.playShutter();
    _toggleBlink();
    final file = await saveImage(image);

    setState(() {
      isblink = 0;
      videoRecorded = false;
    });

    setState(() {
      Capturedimage = File(image!.path);
      isblink = 100;
    });

    //if (cameraController.value.flashMode == cam.FlashMode.torch) {
    //setState(() {
    // cameraController.setFlashMode(cam.FlashMode.off);
    //});
    //}

    setState(() {
      Capturedimage = File(image!.path);
    });
  }

  void zoom05() async {
    setState(() {
      is05 = !is05;
      is1 = false;
    });
    await cameraController.initialize();
    is05
        ? await cameraController.setZoomLevel(1.5)
        : await cameraController.setZoomLevel(0);
  }

  void zoom1() async {
    setState(() {
      is1 = !is1;
      is05 = false;
    });
    await cameraController.initialize();
    is1
        ? await cameraController.setZoomLevel(3)
        : await cameraController.setZoomLevel(0);
  }

  //take video function
  void takeVideo() {
    if (isRecording) {
      stopVideoRecording();
    } else {
      startVideoRecording();
    }
  }

  void startVideoRecording() async {
    if (!cameraController.value.isRecordingVideo) {
      final directory = await getTemporaryDirectory();

      print("D path is $directory");
      final path =
          '${directory.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      print(path);

      try {
        //await cameraController.initialize();

        if (isFlashOn == 1) {
          await cameraController.setFlashMode(cam.FlashMode.auto);
        }
        NativeCameraSound.playStartRecord();
        _toggleBlink();
        cameraController.startVideoRecording();

        _stopWatchTimer.onResetTimer();
        _stopWatchTimer.onStartTimer();

        setState(() {
          isRecording = true;
          Vpath = path;
        });
      } catch (e) {
        print(e);
        return;
      }
    }
  }

  void stopVideoRecording() async {
    if (cameraController.value.isRecordingVideo) {
      if (isFlashOn == 0) {
        await cameraController.setFlashMode(cam.FlashMode.off);
      } else {
        await cameraController.setFlashMode(cam.FlashMode.off);
      }
      final cam.XFile videoFile = await cameraController.stopVideoRecording();
      NativeCameraSound.playStopRecord();
      _stopWatchTimer.onStopTimer();

      setState(() {
        isRecording = false;
        isFlashOn = 0;
      });

      if (Vpath.isNotEmpty) {
        setState(() {});
        final File file = File(videoFile.path);
        await file.copy(Vpath);
        await GallerySaver.saveVideo(Vpath);
        cam.XFile? Vpreview = await cameraController.takePicture();
        setState(() {
          Capturedimage = File(Vpreview.path);
          vfile = file;
          videoRecorded = true;
        });
      }
    }
  }

  void viewImageorVideo() {
    final imageProvider = Image.file(Capturedimage).image;

    if (videoRecorded == true) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => SamplePlayer(path: vfile)));
      print("video");
    } else {
      print("photo");
      showImageViewer(context, imageProvider, onViewerDismissed: () {
        print("dismissed");
      });
    }

    print(vfile.path);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    num yScale = 1;
    return Scaffold(
        appBar: AppBar(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
            ),
            backgroundColor: Color.fromARGB(150, 0, 0, 0),
            surfaceTintColor: Colors.transparent,
            foregroundColor: Colors.transparent,
            actions: [
              Container(
                  margin: EdgeInsets.only(right: 18),
                  child: isRecording
                      ? Icon(
                          CupertinoIcons.color_filter,
                          size: 30,
                          color: Colors.white,
                        )
                      : Icon(
                          CupertinoIcons.color_filter,
                          size: 30,
                          color: Colors.white,
                        ))
            ],
            centerTitle: true,
            title: isRecording
                ? StreamBuilder<int>(
                    stream: _stopWatchTimer.rawTime,
                    initialData: _stopWatchTimer.rawTime.value,
                    builder: (context, snap) {
                      final value = snap.data;
                      final displayTime =
                          StopWatchTimer.getDisplayTime(value!, hours: true);
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromARGB(255, 235, 4, 4),
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              displayTime,
                              style: GoogleFonts.robotoCondensed(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                              isExpanded: true,
                              hint: Text(
                                'Max',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              items: items
                                  .map(
                                      (String item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color.fromARGB(
                                                      255, 255, 255, 255)),
                                            ),
                                          ))
                                  .toList(),
                              value: selectedValue,

                              onChanged: (String? value) {
                                initializeCamera(camera, value);
                                setState(() {
                                  selectedValue = value!;
                                });
                              },
                              buttonStyleData: ButtonStyleData(
                                  padding: EdgeInsets.symmetric(horizontal: 5),
                                  height: size.height*0.030,
                                  width: size.width*0.21,
                                  decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    borderRadius: BorderRadius.circular(5),
                                  )),
                              dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                color: Color.fromARGB(255, 0, 0, 0),
                                borderRadius: BorderRadius.circular(5),
                              )),
                              menuItemStyleData: MenuItemStyleData(
                                height: 40,
                              )),
                        ),
            leadingWidth: 78,
            leading: GestureDetector(
                onTap: FLash,
                child: Row(
                  children: [
                    Container(
                        margin: EdgeInsets.only(left: 18),
                        child: isFlashOn == 0
                            ? Icon(
                                CupertinoIcons.bolt_circle,
                                size: 25,
                                color: Colors.white,
                              )
                            : isFlashOn == 1
                                ? Row(
                                    children: [
                                      Icon(
                                        CupertinoIcons.bolt_circle,
                                        size: 25,
                                        color:
                                            Color.fromARGB(255, 255, 255, 255),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                      Text(
                                        "Auto",
                                        style: GoogleFonts.robotoCondensed(
                                            color: Colors.white,
                                            fontSize: size.width * 0.038,
                                            letterSpacing: 1,
                                            fontWeight: FontWeight.w500),
                                      )
                                    ],
                                  )
                                : isFlashOn == 2
                                    ? Icon(
                                        CupertinoIcons.bolt_circle_fill,
                                        size: 25,
                                        color: Colors.white,
                                      )
                                    : Container()),
                  ],
                ))),
        bottomNavigationBar: BottomAppBar(
          height: 170,
          padding: EdgeInsets.all(0),
          color: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: zoom05,
                      child: Text("0.5",
                          style: GoogleFonts.robotoCondensed(
                              color: is05 ? Colors.amber : Colors.white,
                              fontSize: size.width * 0.030,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    GestureDetector(
                      onTap: zoom1,
                      child: Text("1x",
                          style: GoogleFonts.robotoCondensed(
                              color: is1 ? Colors.amber : Colors.white,
                              fontSize: size.width * 0.030,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color.fromARGB(0, 51, 255, 0),
                ),
                child: ListWheelScrollViewX(
                  diameterRatio: 10,
                  onSelectedItemChanged: (value) {
                    if (value == 0) {
                      setState(() {
                        Fselectmenu = true;
                        Sselectmenu = false;
                        isVideo = false;
                      });
                    } else {
                      print(1);
                      setState(() {
                        Fselectmenu = false;
                        Sselectmenu = true;
                        isVideo = true;
                      });
                    }
                  },
                  itemExtent: 95,
                  scrollDirection: Axis.horizontal,
                  children: [
                    Center(
                      child: Text("PHOTO",
                          style: GoogleFonts.robotoCondensed(
                              color: Fselectmenu ? Colors.amber : Colors.white,
                              fontSize: size.width * 0.038,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500)),
                    ),
                    Center(
                      child: Text("VIDEO",
                          style: GoogleFonts.robotoCondensed(
                              color: Sselectmenu ? Colors.amber : Colors.white,
                              fontSize: size.width * 0.038,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(150, 0, 0, 0),
                    border: Border.all(
                        width: 0, color: Color.fromARGB(0, 255, 0, 0))),
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: viewImageorVideo,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 250),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: const Color.fromARGB(0, 255, 255, 255),
                              image: DecorationImage(
                                  image: FileImage(Capturedimage),
                                  fit: BoxFit.cover)),
                        ),
                      ),
                      isVideo
                          ? GestureDetector(
                              onTap: takeVideo,
                              child: AnimatedContainer(
                                  padding: EdgeInsets.all(13),
                                  duration: Duration(milliseconds: 500),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: isRecording
                                          ? Color.fromARGB(105, 255, 255, 255)
                                          : Color.fromARGB(255, 235, 4, 4),
                                      border: Border.all(
                                          width: 2, color: Colors.white)),
                                  child: isRecording
                                      ? Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.rectangle,
                                              color: Color.fromARGB(
                                                  255, 235, 4, 4),
                                              borderRadius:
                                                  BorderRadius.circular(3)),
                                        )
                                      : SizedBox()))
                          : GestureDetector(
                              onTap: takePicture,
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 500),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: Color.fromARGB(105, 255, 255, 255),
                                    border: Border.all(
                                        width: 2, color: Colors.white)),
                              ),
                            ),
                      GestureDetector(
                        onTap: () {
                          if (camera == 0) {
                            setState(() {
                              camera = 1;
                              initializeCamera(camera, selectedValue);
                            });
                          }else{
                            setState(() {
                              camera = 0;
                              initializeCamera(camera, selectedValue);
                            });
                          }
                        },
                        child: Container(
                            width: 50,
                            height: 50,
                            child: Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              color: Colors.white,
                              size: 30,
                            )),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        body: Stack(
          children: [
            GestureDetector(
              onTapDown: (details) => onViewFinderTap(details),
              onScaleStart: (ScaleStartDetails details) {
                _baseZoomLevel = _currentZoomLevel;
              },
              onScaleUpdate: (ScaleUpdateDetails details) {
                setState(() {
                  _currentZoomLevel = (_baseZoomLevel * details.scale)
                      .clamp(_minZoomLevel, _maxZoomLevel);
                  cameraController.setZoomLevel(_currentZoomLevel);
                });
              },
              child: AnimatedOpacity(
                opacity: isBlinking ? 0.0 : 1.0,
                duration: Duration(milliseconds: 200),
                child: Container(
                    child: FutureBuilder(
                        future: cameraValue,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            var camera = cameraController.value;
                            // fetch screen size
                            final size = MediaQuery.of(context).size;

                            // calculate scale depending on screen and camera ratios
                            // this is actually size.aspectRatio / (1 / camera.aspectRatio)
                            // because camera preview size is received as landscape
                            // but we're calculating for portrait orientation
                            var scale = size.aspectRatio * camera.aspectRatio;

                            // to prevent scaling down, invert the value
                            final valuee = size.width * 0.0055;
                            if (scale < valuee) scale = valuee / scale;

                            return Transform.scale(
                              scale: scale,
                              child: Center(
                                child: Container(
                                    margin: EdgeInsets.only(top: 50),
                                    child: cam.CameraPreview(cameraController)),
                              ),
                            );
                          } else {
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.black,
                            );
                          }
                        })),
              ),
            ),
            if (focusPoint != null)
              CustomPaint(
                painter: FocusCirclePainter(focusPoint!),
                child: Container(),
              ),
          ],
        ));
  }
}