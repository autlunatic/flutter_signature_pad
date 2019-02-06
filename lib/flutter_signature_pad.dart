import 'dart:ui' as ui;

import 'package:flutter/material.dart';

final _signatureKey = GlobalKey<SignatureState>();

class Signature extends StatefulWidget {
  final Color color;
  final double strokeWidth;
  final CustomPainter backgroundPainter;
  final Function onSign;
  final GlobalKey<SignatureState> _key;

  /// Skips as much points when tapping before saving the next point
  /// this results in less points for saving and drawing
  /// e.g. 1 always skips one point (only every 2nd point is recognized)
  final int skipPoints;

  Signature(
      {this.color = Colors.black,
      this.strokeWidth = 5.0,
      this.skipPoints = 1,
      this.backgroundPainter,
      this.onSign,
      GlobalKey key})
      : _key = key ?? _signatureKey,
        super(key: key ?? _signatureKey);

  SignatureState createState() => SignatureState();

  ui.Image getData() {
    return _key.currentState.getData();
  }

  clear() {
    return _key.currentState.clear();
  }
}

class _SignaturePainter extends CustomPainter {
  Size _lastSize;
  final double strokeWidth;
  final List<Offset> points;
  final Color strokeColor;
  Paint _linePaint;

  _SignaturePainter(
      {@required this.points,
      @required this.strokeColor,
      @required this.strokeWidth}) {
    _linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }

  void paint(Canvas canvas, Size size) {
    _lastSize = size;
    Path path = Path();

    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[0].dx, points[0].dy);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        if (((i == 0) && points[i] != null && points[i + 1] == null) ||
            (i > 0 &&
                (points[i - 1] == null &&
                    points[i] != null &&
                    points[i + 1] == null))) {
          path.moveTo(points[i].dx, points[i].dy);
          path.lineTo(points[i].dx, points[i].dy);
        } else if ((i == points.length - 2) &&
            points[i + 1] != null &&
            points[i] == null) {
          path.moveTo(points[i + 1].dx, points[i + 1].dy);
          path.lineTo(points[i + 1].dx, points[i + 1].dy);
        } else if (points[i] != null && points[i + 1] != null) {
          path.moveTo(points[i].dx, points[i].dy);
          path.lineTo(points[i + 1].dx, points[i + 1].dy);
        }
      }
    }
    canvas.drawPath(path, _linePaint);
  }

  @override
  bool shouldRepaint(_SignaturePainter other) => other.points != points;
}

class SignatureState extends State<Signature> {
  List<Offset> _points = <Offset>[];
  int skipPoint = -1;
  _SignaturePainter _painter;
  Size _lastSize;

  SignatureState();

  bool canAddPoint() {
    skipPoint++;
    if (skipPoint >= widget.skipPoints) {
      skipPoint = 0;
    }
    return skipPoint == 0;
  }

  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterFirstLayout(context));
    _painter = _SignaturePainter(
        points: _points,
        strokeColor: widget.color,
        strokeWidth: widget.strokeWidth);
    return ClipRect(
      child: CustomPaint(
        painter: widget.backgroundPainter,
        foregroundPainter: _painter,
        child: GestureDetector(
          onTapUp: (details) {
            _points.add(null);
          },
          onTapDown: (details) {
            _addpoint(context, details.globalPosition);
            print("pandown");
          },
          onPanUpdate: (DragUpdateDetails details) {
            if (canAddPoint()) {
              _addpoint(context, details.globalPosition);
            }
          },
          onPanEnd: (DragEndDetails details) => _points.add(null),
        ),
      ),
    );
  }

  void _addpoint(BuildContext context, Offset position) {
    RenderBox referenceBox = context.findRenderObject();
    Offset localPosition = referenceBox.globalToLocal(position);

    setState(() {
      _points = List.from(_points)..add(localPosition);
      if (widget.onSign != null) {
        widget.onSign();
      }
    });
  }

  ui.Image getData() {
    var recorder = ui.PictureRecorder();
    var origin = Offset(0.0, 0.0);
    var paintBounds = Rect.fromPoints(
        _lastSize.topLeft(origin), _lastSize.bottomRight(origin));
    var canvas = Canvas(recorder, paintBounds);
    widget.backgroundPainter.paint(canvas, _lastSize);
    _painter.paint(canvas, _lastSize);
    var picture = recorder.endRecording();
    return picture.toImage(_lastSize.width.round(), _lastSize.height.round());
  }

  void clear() {
    setState(() {
      _points = [];
    });
  }

  afterFirstLayout(BuildContext context) {
    _lastSize = context.size;
  }
}
