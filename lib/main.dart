import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:flutter_drawing_board/paint_extension.dart';
import 'package:web/web.dart' as wasm;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    wasm.document.querySelector('div')!;
  }
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    if (kReleaseMode) {
      exit(1);
    }
  };

  runApp(const MyApp());
}

class ImageContent extends PaintContent {
  Offset startPoint = Offset.zero;

  Offset size = Offset.zero;

  final String imageUrl;

  final ui.Image image;
  ImageContent(this.image, {this.imageUrl = ''});
  ImageContent.data({
    required this.startPoint,
    required this.size,
    required this.image,
    required this.imageUrl,
    required Paint paint,
  }) : super.paint(paint);
  factory ImageContent.fromJson(Map<String, dynamic> data) {
    return ImageContent.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      size: jsonToOffset(data['size'] as Map<String, dynamic>),
      imageUrl: data['imageUrl'] as String,
      image: data['image'] as ui.Image,
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  @override
  String get contentType => 'ImageContent';

  @override
  ImageContent copy() => ImageContent(image);

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Rect rect = Rect.fromPoints(startPoint, startPoint + this.size);
    paintImage(canvas: canvas, rect: rect, image: image, fit: BoxFit.fill);
  }

  @override
  void drawing(Offset nowPoint) => size = nowPoint - startPoint;

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'size': size.toJson(),
      'imageUrl': imageUrl,
      'paint': paint.toJson(),
    };
  }
}

class Line extends PaintContent {
  ui.Offset? startPoint;
  ui.Offset? endPoint;

  Line({this.startPoint, this.endPoint});

  @override
  PaintContent copy() {
    return Line(startPoint: startPoint, endPoint: endPoint);
  }

  @override
  void draw(ui.Canvas canvas, ui.Size size, bool deeper) {
    if (startPoint != null && endPoint != null) {
      final paint = ui.Paint()
        ..color = const ui.Color(0xFF000000)
        ..strokeWidth = 3.0
        ..style = ui.PaintingStyle.stroke;

      canvas.drawLine(startPoint!, endPoint!, paint);
    }
  }

  @override
  void drawing(ui.Offset nowPoint) {
    endPoint = nowPoint;
  }

  @override
  void startDraw(ui.Offset startPoint) {
    this.startPoint = startPoint;
    endPoint = startPoint;
  }

  @override
  Map<String, dynamic> toContentJson() {
    return {
      'type': 'line',
      'startPoint': {'x': startPoint?.dx, 'y': startPoint?.dy},
      'endPoint': {'x': endPoint?.dx, 'y': endPoint?.dy},
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Whiteboard',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class TextContent extends PaintContent {
  final String text;
  final Offset position;

  TextContent(this.text, this.position, Paint paint) : super.paint(paint);

  @override
  PaintContent copy() => TextContent(text, position, paint);

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final textStyle = TextStyle(
      color: paint.color,
      fontSize: 24,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, position);
  }

  @override
  void drawing(Offset nowPoint) {}

  @override
  void startDraw(Offset startPoint) {}

  @override
  Map<String, dynamic> toContentJson() {
    return {
      'text': text,
      'position': {'dx': position.dx, 'dy': position.dy},
      'paint': paint.toJson(),
    };
  }
}

class Triangle extends PaintContent {
  Offset startPoint = Offset.zero;

  Offset A = Offset.zero;

  Offset B = Offset.zero;

  Offset C = Offset.zero;

  Triangle();
  Triangle.data({
    required this.startPoint,
    required this.A,
    required this.B,
    required this.C,
    required Paint paint,
  }) : super.paint(paint);
  factory Triangle.fromJson(Map<String, dynamic> data) {
    return Triangle.data(
      startPoint: jsonToOffset(data['startPoint'] as Map<String, dynamic>),
      A: jsonToOffset(data['A'] as Map<String, dynamic>),
      B: jsonToOffset(data['B'] as Map<String, dynamic>),
      C: jsonToOffset(data['C'] as Map<String, dynamic>),
      paint: jsonToPaint(data['paint'] as Map<String, dynamic>),
    );
  }

  @override
  String get contentType => 'Triangle';

  @override
  Triangle copy() => Triangle();

  @override
  void draw(Canvas canvas, Size size, bool deeper) {
    final Path path = Path()
      ..moveTo(A.dx, A.dy)
      ..lineTo(B.dx, B.dy)
      ..lineTo(C.dx, C.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  void drawing(Offset nowPoint) {
    A = Offset(
        startPoint.dx + (nowPoint.dx - startPoint.dx) / 2, startPoint.dy);
    B = Offset(startPoint.dx, nowPoint.dy);
    C = nowPoint;
  }

  @override
  void startDraw(Offset startPoint) => this.startPoint = startPoint;

  @override
  Map<String, dynamic> toContentJson() {
    return <String, dynamic>{
      'startPoint': startPoint.toJson(),
      'A': A.toJson(),
      'B': B.toJson(),
      'C': C.toJson(),
      'paint': paint.toJson(),
    };
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final DrawingController _drawingController = DrawingController();

  final TransformationController _transformationController =
      TransformationController();

  double _colorOpacity = 1;
  final List<ui.Color> customColors = [Colors.black, ...Colors.accents];
  bool isTextInputMode = false;
  Offset? textPosition;
  String inputText = '';
  Type? activeTool;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey,
      appBar: AppBar(
        leading: PopupMenuButton<Color>(
          padding: EdgeInsets.zero,
          color: Colors.white,
          iconSize: 30,
          offset: const Offset(0, 30),
          tooltip: 'Change Color',
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            side: BorderSide(color: Colors.black),
          ),
          icon: const Icon(Icons.color_lens),
          onCanceled: () => _drawingController.setStyle(
            color: _drawingController.drawConfig.value.color,
          ),
          onSelected: (ui.Color value) => _drawingController.setStyle(
            color: value.withOpacity(_colorOpacity),
          ),
          itemBuilder: (_) {
            return <PopupMenuEntry<ui.Color>>[
              PopupMenuItem<Color>(
                child: StatefulBuilder(
                  builder: (BuildContext context,
                      Function(void Function()) setState) {
                    return FittedBox(
                      child: Row(
                        children: [
                          Text('Opacity: ${_colorOpacity.toStringAsFixed(2)}'),
                          Slider(
                            value: _colorOpacity,
                            onChanged: (double v) {
                              setState(() => _colorOpacity = v);
                              _drawingController.setStyle(
                                color: _drawingController.drawConfig.value.color
                                    .withOpacity(_colorOpacity),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              ...customColors.map((ui.Color color) {
                return PopupMenuItem<ui.Color>(
                  value: color,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 5,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    height: 50,
                    child: Text(
                      color.value.toRadixString(16).toUpperCase(),
                      style: const TextStyle(color: Colors.indigo),
                    ),
                  ),
                );
              }),
            ];
          },
        ),
        title: const Text('Whiteboard'),
        centerTitle: true,
        elevation: 15,
        shadowColor: Colors.black,
        foregroundColor: Colors.black,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.check), onPressed: _getImageData),
          IconButton(
            icon: const Icon(Icons.restore_page_rounded),
            onPressed: _restBoard,
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: isTextInputMode
                ? (TapUpDetails details) {
                    setState(() {
                      textPosition = details.localPosition;
                    });
                  }
                : null,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return DrawingBoard(
                  transformationController: _transformationController,
                  controller: _drawingController,
                  background: Container(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    color: Colors.white,
                  ),
                  minScale: 0.8,
                  maxScale: 4.0,
                  showDefaultActions: true,
                  showDefaultTools: true,
                  defaultToolsBuilder: (Type t, _) {
                    return DrawingBoard.defaultTools(t, _drawingController)
                      ..insert(
                        1,
                        DefToolItem(
                          icon: Icons.change_history_rounded,
                          isActive: t == Triangle && activeTool == Triangle,
                          onTap: () {
                            setState(() {
                              activeTool = Triangle;
                              _drawingController.setPaintContent(Triangle());
                              isTextInputMode = false;
                            });
                          },
                        ),
                      )
                      ..insert(
                        2,
                        DefToolItem(
                          icon: Icons.line_style,
                          isActive: t == Line && activeTool == Line,
                          onTap: () {
                            setState(() {
                              activeTool = Line;
                              _drawingController.setPaintContent(Line());
                              isTextInputMode = false;
                            });
                          },
                        ),
                      )
                      ..insert(
                        3,
                        DefToolItem(
                          icon: Icons.text_fields,
                          isActive: activeTool == TextContent,
                          onTap: () {
                            setState(() {
                              activeTool = TextContent;
                              isTextInputMode = true;
                            });
                          },
                        ),
                      );
                  },
                );
              },
            ),
          ),
          if (textPosition != null && activeTool == TextContent)
            Positioned(
              left: textPosition!.dx,
              top: textPosition!.dy,
              child: SizedBox(
                width: 200,
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter text',
                  ),
                  onSubmitted: (String value) {
                    setState(() {
                      inputText = value;
                      _drawingController.addContent(TextContent(
                        inputText,
                        textPosition!,
                        Paint()..color = Colors.black,
                      ));
                      textPosition = null;
                      isTextInputMode = false;
                      activeTool = null;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _drawingController.dispose();
    super.dispose();
  }

  Future<void> _getImageData() async {
    final Uint8List? data =
        (await _drawingController.getImageData())?.buffer.asUint8List();
    if (data == null) {
      debugPrint('获取图片数据失败');
      return;
    }

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (BuildContext c) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(c),
              child: Image.memory(data),
            ),
          );
        },
      );
    }
  }

  void _restBoard() {
    _transformationController.value = Matrix4.identity();
  }
}
