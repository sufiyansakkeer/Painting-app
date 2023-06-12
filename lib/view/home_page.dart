import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:painting_app/resources/services.dart';
import 'package:painting_app/view/widgets/color_icon.dart';
import 'package:painting_app/view/widgets/drawing_painter.dart';
import 'package:painting_app/view/widgets/drawing_points.dart';
import 'dart:ui' as ui;

class DrawingRoomScreen extends StatefulWidget {
  const DrawingRoomScreen({super.key});

  @override
  State<DrawingRoomScreen> createState() => _DrawingRoomScreenState();
}

final GlobalKey screenShotKey = GlobalKey();

class _DrawingRoomScreenState extends State<DrawingRoomScreen> {
  var availableColor = [
    Colors.black,
    Colors.red,
    Colors.amber,
    Colors.blue,
    Colors.green,
    Colors.brown,
  ];

  var historyDrawingPoints = <DrawingPoint>[];
  var drawingPoints = <DrawingPoint>[];

  var selectedColor = Colors.black;
  var selectedWidth = 2.0;

  DrawingPoint? currentDrawingPoint;
  Services services = Services();
  void captureScreenShot() async {
    log("capture screen shot started");
    //get paint bound of your app screen or the widget which is wrapped with RepaintBoundary.
    RenderRepaintBoundary bound = screenShotKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    if (bound.debugNeedsPaint) {
      Timer(const Duration(seconds: 1), () => captureScreenShot());
      return null;
    }
    ui.Image image = await bound.toImage();
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    // this will save image screenshot in gallery
    if (byteData != null) {
      Uint8List pngBytes = byteData.buffer.asUint8List();
      final resultSave = await ImageGallerySaver.saveImage(
          Uint8List.fromList(pngBytes),
          quality: 90,
          name: 'screenshot-${DateTime.now()}.png');
      log(resultSave.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RepaintBoundary(
        key: screenShotKey,
        child: Scaffold(
          body: Stack(
            children: [
              /// Canvas
              GestureDetector(
                // Create a new DrawingPoint object and add it to the drawingPoints list.
                // Set the currentDrawingPoint variable to the new DrawingPoint object.
                onPanStart: (details) {
                  setState(() {
                    currentDrawingPoint = DrawingPoint(
                      id: DateTime.now().microsecondsSinceEpoch,
                      offsets: [
                        details.localPosition,
                      ],
                      color: selectedColor,
                      width: selectedWidth,
                    );

                    if (currentDrawingPoint == null) return;
                    drawingPoints.add(currentDrawingPoint!);
                    historyDrawingPoints = List.of(drawingPoints);
                  });
                },
                // Update the currentDrawingPoint object's offsets property to include the current position of the user's finger.
                // Update the drawingPoints list with the updated currentDrawingPoint object.
                onPanUpdate: (details) {
                  setState(() {
                    if (currentDrawingPoint == null) return;

                    currentDrawingPoint = currentDrawingPoint?.copyWith(
                      offsets: currentDrawingPoint!.offsets
                        ..add(details.localPosition),
                    );
                    drawingPoints.last = currentDrawingPoint!;
                    historyDrawingPoints = List.of(drawingPoints);
                  });
                },
                // Set the currentDrawingPoint variable to null.
                onPanEnd: (_) {
                  currentDrawingPoint = null;
                },
                child: CustomPaint(
                  painter: DrawingPainter(
                    // Specify the list of lines that should be drawn
                    drawingPoints: drawingPoints,
                  ),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),

              /// color pallet
              TextButton(
                onPressed: () {
                  log("function started");
                  captureScreenShot();
                },
                child: Text("save"),
              ),
              colorPallet(context),

              /// pencil size
              Positioned(
                top: MediaQuery.of(context).padding.top + 80,
                right: 0,
                bottom: 150,
                child: RotatedBox(
                  quarterTurns: 3, // 270 degree
                  child: Slider(
                    value: selectedWidth,
                    min: 1,
                    max: 20,
                    onChanged: (value) {
                      setState(() {
                        selectedWidth = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "Undo",
                onPressed: () {
                  if (drawingPoints.isNotEmpty &&
                      historyDrawingPoints.isNotEmpty) {
                    setState(() {
                      drawingPoints.removeLast();
                    });
                  }
                },
                child: const Icon(Icons.undo),
              ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: "Redo",
                onPressed: () {
                  setState(() {
                    if (drawingPoints.length < historyDrawingPoints.length) {
                      // 6 length 7
                      final index = drawingPoints.length;
                      drawingPoints.add(historyDrawingPoints[index]);
                    }
                  });
                },
                child: const Icon(Icons.redo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Positioned colorPallet(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 16,
      right: 16,
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: availableColor.length,
          separatorBuilder: (_, __) {
            return const SizedBox(width: 8);
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = availableColor[index];
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: availableColor[index],
                  shape: BoxShape.circle,
                ),
                foregroundDecoration: BoxDecoration(
                  border: selectedColor == availableColor[index]
                      ? Border.all(color: colors.first, width: 4)
                      : null,
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
