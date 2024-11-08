import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:arrow_path/arrow_path.dart';
import 'package:concentric_transition/concentric_transition.dart';
import 'package:draw_on_path/draw_on_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'package:turtle_maths/card2.dart';
import 'package:turtle_maths/l10n/l10n.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:equations/equations.dart' as equations;
import 'package:toastification/toastification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
  runApp(MyApp(
    onBoardingComplete: onboardingComplete,
  ));
}

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final data = [
      CardData2(
        index: 1,
        latex: (l!.page1latex),
        text: l.page1text,
        image: LottieBuilder.asset("assets/animation/turtle2.json"),
        backgroundColor: Colors.yellow.shade200,
        titleColor: const ui.Color.fromARGB(255, 37, 30, 233),
        subtitleColor: const ui.Color.fromARGB(255, 15, 120, 20),
      ),
      CardData2(index: 6,
        latex: (l.page6latex),
        text: l.page6text,
        image: null,
        backgroundColor: Colors.yellow.shade200,
        titleColor: Colors.deepOrange,
        subtitleColor: Colors.orange),
      CardData2(
        index: 2,
        latex: (l.page2latex),
        text: l.page2text,
        image: Image.asset("assets/images/quadratic3.PNG"),
        backgroundColor: Colors.white,
        titleColor: const ui.Color.fromARGB(255, 37, 30, 233),
        subtitleColor: const ui.Color.fromARGB(255, 15, 120, 20),
      ),
      CardData2(
        index: 5,
        latex: (l.page5latex),
        text: l.page5text,
        image: Image.asset("assets/images/quadratic2.PNG"),
        backgroundColor: Colors.grey.shade200,
        titleColor: const ui.Color.fromARGB(255, 37, 30, 233),
        subtitleColor: const ui.Color.fromARGB(255, 15, 120, 20),
      ),
      CardData2(
        index: 3,
        latex: l.page3latex,
        text: l.page3text,
        image: Image.asset('assets/images/complex.PNG'),
        backgroundColor: Colors.white,
        titleColor: Colors.purple,
        subtitleColor: const Color.fromRGBO(0, 10, 56, 1),
      ),
      CardData2(
        index: 7,
        latex: l.page7latex,
        text: l.page7text,
        image: Image.asset('assets/images/cubic.PNG'),
        backgroundColor: Colors.white,
        titleColor: Colors.blue,
        subtitleColor: Colors.white,
      ),
      CardData2(
        index: 4,
        latex: l.page4latex,
        text: l.page4text,
        image: LottieBuilder.asset("assets/animation/turtle2.json"),
        backgroundColor: const Color.fromRGBO(71, 59, 117, 1),
        titleColor: Colors.yellow,
        subtitleColor: Colors.white,
      )
    ];

    return Scaffold(
        body: ConcentricPageView(
      colors: data.map((e) => e.backgroundColor).toList(),
      itemCount: data.length,
      itemBuilder: (int index) {
        return CardScreen2(data: data[index]);
      },
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onboardingComplete', true);

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ShowCaseWidget(builder: (context) => const MyHomePage())));
      },
    ));
  }
}

class MyApp extends StatelessWidget {
  final bool onBoardingComplete;

  // MyApp(bool onboardingComplete, {super.key});

  MyApp({required this.onBoardingComplete, super.key});

  final Locale _locale = Locale(Platform.localeName.substring(0, 2));

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Turtle Maths',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          useMaterial3: false,
        ),
        // home: ShowCaseWidget(builder: (context) => const MyHomePage()),
        home: onBoardingComplete
            ? ShowCaseWidget(builder: (context) => const MyHomePage())
            : OnBoardingScreen(),
        supportedLocales: L10n.all,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: _locale,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  static const PREFERENCES_IS_FIRST_LAUNCH_STRING =
      "PREFERENCES_IS_FIRST_LAUNCH_STRING";

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final myController1 = TextEditingController();
  final myController2 = TextEditingController();
  final myController3 = TextEditingController();
  final myController4 = TextEditingController();
  bool isComplete = false;
  double ratio1 = 10;
  double ratio2 = 10;
  double ratio3 = 10;
  double ratio4 = 10;
  double _progress1 = 0.0;
  late Animation<double> animation1;
  late AnimationController controller1;
  var tappedPoint = const Offset(0, 0);
  double _scaleFactor = 35.0;
  double _baseScaleFactor = 35.0;
  bool _dragging = false;
  var xPos = 0.0;
  var yPos = 0.0;

  int _numRoots = 0;
  final List<double> _trueRealRoots = [];
  final List<int> _binRes = [];
  bool shown = false;
  bool foundRealRoot = false;
  bool hasComplexRoots = false;

  final GlobalKey run = GlobalKey();
  final GlobalKey input = GlobalKey();
  final GlobalKey xPoint = GlobalKey();
  final GlobalKey pOfX = GlobalKey();
  final GlobalKey keyNumRoots = GlobalKey();
  final GlobalKey drawing = GlobalKey();

  late Future<ui.Image> _imageFuture;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _isFirstLaunch().then((result) {
        if (result) {
          ShowCaseWidget.of(context)
              .startShowCase([input, run, xPoint, pOfX, keyNumRoots, drawing]);
        }
      });
    });

    controller1 = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          isComplete = true;
        } else {
          isComplete = false;
        }
      });

    animation1 = Tween(begin: 0.0, end: 1.0).animate(controller1)
      ..addListener(() {
        setState(() {
          _progress1 = animation1.value;
        });
      });

    _imageFuture = _loadImage("assets/images/turtle.png");
  }

  Future<bool> _isFirstLaunch() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    bool isFirstLaunch = sharedPreferences
            .getBool(MyHomePage.PREFERENCES_IS_FIRST_LAUNCH_STRING) ??
        true;
    if (isFirstLaunch) {
      sharedPreferences.setBool(
          MyHomePage.PREFERENCES_IS_FIRST_LAUNCH_STRING, false);
    }
    return isFirstLaunch;
  }

  @override
  void dispose() {
    myController1.dispose();
    myController2.dispose();
    myController3.dispose();
    myController4.dispose();
    super.dispose();
  }

  Future<ui.Image> _loadImage(String imagePath) async {
    ByteData bd = await rootBundle.load(imagePath);
    final Uint8List bytes = Uint8List.view(bd.buffer);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes,
        targetHeight: 60, targetWidth: 60);
    final ui.Image image = (await codec.getNextFrame()).image;

    return image;
  }

  onPan(double x, double y) {
    setState(() {
      tappedPoint = Offset(x, y);
      MyPainter.setScale(_scaleFactor.toInt());
    });
  }

  String calcK(width, height) {
    double x = MyPainter.getK();
    if (x.isNaN) {
      return "0";
    } else {
      return (-x).toStringAsFixed(5);
    }
  }

  String calcDistance(String solution) {
    double p = MyPainter.getP();
    if (p.isNaN) {
      return "0";
    } else {
      if ((p.abs() <= 0.5) & (isComplete == true)) {
        if (_trueRealRoots.isNotEmpty) {
          // print("Real roots: $_trueRealRoots");
          bool found = false;
          double x = double.parse(solution);
          double closestValue = 0;

          for (int i = 0; i < _trueRealRoots.length; i++) {
            if (((_trueRealRoots[i] - x).abs() <= 0.1) & (_binRes[i] == 0)) {
              closestValue = _trueRealRoots[i];
              _binRes[i] = 1;
              found = true;
              _numRoots += 1;
            }
          }

          if (found & !foundRealRoot) {
            foundRealRoot = true;
          }

          if ((_numRoots == _binRes.length) & (shown == false)) {
            shown = true;
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                toastification.show(
                    title: Text(AppLocalizations.of(context)!.allRoots),
                    style: ToastificationStyle.flatColored,
                    primaryColor: Colors.green,
                    autoCloseDuration: const Duration(seconds: 5)));
          }
          if (found) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                toastification.show(
                    title: Text(
                        AppLocalizations.of(context)!.congrats +
                            closestValue.toStringAsFixed(2),
                        maxLines: 2),
                    autoCloseDuration: const Duration(seconds: 3)));
          }
        }
      }
      return p.toStringAsFixed(5);
    }
  }

  String getCoefficients(String t1, String t2, String t3, String t4) {
    if (t1.isNotEmpty & t2.isNotEmpty & t3.isNotEmpty & t4.isNotEmpty) {
      double x1 = double.parse(t1);
      double x2 = double.parse(t2);
      double x3 = double.parse(t3);
      double x4 = double.parse(t4);

      if (x1 != 0) {
        x2 = x2 / x1;
        x3 = x3 / x1;
        x4 = x4 / x1;
        x1 = 1;
      }

      String c1 = x1 == 1
          ? "x\u{00B3}"
          : x1 == -1
              ? "- x\u{00B3}"
              : "${x1.toStringAsFixed(2)}x\u{00B3}";
      String c2 = x2 >= 0 ? " + ${x2.toStringAsFixed(2)}x\u{00B2}" : " - ${(-x2).toStringAsFixed(2)}x\u{00B2}";
      String c3 = x3 >= 0 ? " + ${x3.toStringAsFixed(2)}x" : " - ${(-x3).toStringAsFixed(2)}x";
      String c4 = x4 >= 0 ? " + $x4 = 0" : " - ${(-x4).toStringAsFixed(2)} = 0";
      return c1 + c2 + c3 + c4;
    } else {
      return "";
    }
  }

  void getRoots(String t1, String t2, String t3, String t4) {
    if (t1.isNotEmpty & t2.isNotEmpty & t3.isNotEmpty & t4.isNotEmpty) {
      double x1 = double.parse(t1);
      double x2 = double.parse(t2);
      double x3 = double.parse(t3);
      double x4 = double.parse(t4);

      if (x1 != 0) {
        x2 = x2 / x1;
        x3 = x3 / x1;
        x4 = x4 / x1;
        x1 = 1;
      }

      final equations.Algebraic equation;

      if (x1 != 0) {
        equation = equations.Cubic(
            a: equations.Complex.fromReal(x1.toDouble()),
            b: equations.Complex.fromReal(x2.toDouble()),
            c: equations.Complex.fromReal(x3.toDouble()),
            d: equations.Complex.fromReal(x4.toDouble()));
      } else {
        equation = equations.Quadratic(
            a: equations.Complex.fromReal(x2.toDouble()),
            b: equations.Complex.fromReal(x3.toDouble()),
            c: equations.Complex.fromReal(x4.toDouble()));
      }

      try {
        for (final root in equation.solutions()) {
          if (root.imaginary.abs() >= 10e-2) {
            hasComplexRoots = true;
          }
          setState(() {
            if (root.imaginary.abs() < 10e-2) {
              _trueRealRoots.add(root.real);
              _binRes.add(0);
            }
          });
        }
      } catch (e) {
        WidgetsBinding.instance.addPostFrameCallback((_) => toastification.show(
            title: Text(e.toString(), maxLines: 3),
            style: ToastificationStyle.fillColored,
            primaryColor: Colors.redAccent,
            autoCloseDuration: const Duration(seconds: 5)));
      }

      if (hasComplexRoots) {
        WidgetsBinding.instance.addPostFrameCallback((_) => toastification.show(
            title: Text(AppLocalizations.of(context)!.hasComplexRoots,
                maxLines: 3),
            style: ToastificationStyle.fillColored,
            primaryColor: Colors.orangeAccent,
            autoCloseDuration: const Duration(seconds: 5)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Turtle Math"), actions: <Widget>[
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OnBoardingScreen()));
              },
              icon: const Icon(Icons.help_outline, color: Colors.white))
        ]),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: [
                AnimatedBuilder(
                  animation: controller1,
                  builder: (BuildContext context, _) {
                    return Showcase(
                      key: input,
                      description: AppLocalizations.of(context)!.coefficients,
                      child: Row(
                        children: [
                          const Spacer(flex: 1),
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: myController1,
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(hintText: "#1"),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: myController2,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  // prefixIcon: const Icon(PiSymbol.pi_outline),
                                  hintText: "#2",
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: myController3,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  // prefixIcon: const Icon(PiSymbol.pi_outline),
                                  hintText: "#3",
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 5,
                            child: SizedBox(
                              height: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: myController4,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  // prefixIcon: const Icon(PiSymbol.pi_outline),
                                  hintText: "#4",
                                ),
                              ),
                            ),
                          ),
                          Showcase(
                              key: run,
                              description:
                                  AppLocalizations.of(context)!.startButton,
                              child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (myController1.text.isNotEmpty &
                                          myController2.text.isNotEmpty &
                                          myController3.text.isNotEmpty &
                                          myController4.text.isNotEmpty) {
                                        foundRealRoot = false;
                                        hasComplexRoots = false;
                                        shown = false;
                                        _trueRealRoots.clear();
                                        _binRes.clear();
                                        _numRoots = 0;

                                        ratio1 = double.parse(myController1.text);
                                        ratio2 = double.parse(myController2.text);
                                        ratio3 = double.parse(myController3.text);
                                        ratio4 = double.parse(myController4.text);

                                        if ((ratio1 != 0) & (ratio1 != 1)) {
                                          ratio2 = ratio2 / ratio1;
                                          ratio3 = ratio3 / ratio1;
                                          ratio4 = ratio4 / ratio1;
                                          ratio1 = 1;
                                        }

                                        getRoots(
                                            myController1.text,
                                            myController2.text,
                                            myController3.text,
                                            myController4.text);

                                        controller1.reset();
                                        controller1.forward();
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .error)));
                                      }
                                    });
                                  },
                                  child:
                                      Text(AppLocalizations.of(context)!.run))),
                          const Spacer(
                              flex: 1), // child: Text(Platform.localeName)),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                      getCoefficients(myController1.text, myController2.text,
                          myController3.text, myController4.text),
                      style: const TextStyle(fontSize: 18)),
                ),
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Showcase(
                          key: xPoint,
                          description: AppLocalizations.of(context)!.xPoint,
                          child: Text(
                              "x = ${calcK(constraints.maxWidth / 2, constraints.maxHeight / 2)}",
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center),
                        ),
                      ),
                      Expanded(
                        child: Showcase(
                          key: pOfX,
                          description: AppLocalizations.of(context)!.pOfX,
                          child: Text(
                              "p(x) = ${calcDistance(calcK(constraints.maxWidth / 2, constraints.maxHeight / 2))}",
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: Showcase(
                      key: keyNumRoots,
                      description:
                          AppLocalizations.of(context)!.rootsDescription,
                      child: Text(
                          "${AppLocalizations.of(context)!.numRoots} $_numRoots",
                          style: const TextStyle(fontSize: 18),
                          textAlign: TextAlign.center),
                    )),
                Expanded(
                    child: FutureBuilder<ui.Image>(
                        future: _imageFuture,
                        builder: (BuildContext context,
                            AsyncSnapshot<ui.Image> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return GestureDetector(
                              // scaling
                              onScaleStart: (details) {
                                _dragging = true;
                                _baseScaleFactor = _scaleFactor;
                              },
                              onDoubleTapDown: ((d) {
                                if (d.localPosition.dx >
                                    constraints.maxWidth / 2) {
                                  setState(() {
                                    _scaleFactor += 2;
                                    MyPainter.setScale(_scaleFactor.toInt());
                                  });
                                } else {
                                  setState(() {
                                    _scaleFactor -= 2;
                                    MyPainter.setScale(_scaleFactor.toInt());
                                  });
                                }
                              }),
                              onScaleUpdate: (scaleDetails) {
                                if (scaleDetails.pointerCount == 1) {
                                  onPan(scaleDetails.localFocalPoint.dx,
                                      scaleDetails.localFocalPoint.dy);
                                }
                                if (scaleDetails.pointerCount == 2) {
                                  if (_dragging) {
                                    setState(() {
                                      xPos += scaleDetails.focalPointDelta.dx;
                                      yPos += scaleDetails.focalPointDelta.dy;
                                    });
                                  }
                                }
                              },
                              onScaleEnd: (scaleDetails) {
                                _dragging = false;
                              },
                              child: Showcase(
                                key: drawing,
                                description:
                                    AppLocalizations.of(context)!.drawing,
                                child: ClipRect(
                                  child: CustomPaint(
                                      painter: MyPainter(
                                          constraints.maxWidth / 2,
                                          constraints.maxHeight / 2,
                                          ratio1,
                                          ratio2,
                                          ratio3,
                                          ratio4,
                                          isComplete,
                                          foundRealRoot,
                                          hasComplexRoots,
                                          _progress1,
                                          tappedPoint,
                                          xPos,
                                          yPos,
                                          snapshot.data),
                                      size: Size(constraints.maxWidth,
                                          constraints.maxHeight)),
                                ),
                              ),
                            );
                          } else {
                            return GestureDetector(
                              onScaleStart: (details) {
                                _baseScaleFactor = _scaleFactor;
                              },
                              onScaleUpdate: (scaleDetails) {
                                /*if (scaleDetails.pointerCount == 1) {
                                  onPan(scaleDetails.localFocalPoint.dx,
                                      scaleDetails.localFocalPoint.dy);
                                }*/
                              },
                              child: CustomPaint(
                                  painter: MyPainter(
                                      constraints.maxWidth / 2,
                                      constraints.maxHeight / 2,
                                      ratio1,
                                      ratio2,
                                      ratio3,
                                      ratio4,
                                      isComplete,
                                      foundRealRoot,
                                      hasComplexRoots,
                                      _progress1,
                                      tappedPoint,
                                      xPos,
                                      yPos),
                                  size: Size(constraints.maxWidth,
                                      constraints.maxHeight)),
                            );
                          }
                        })),
              ],
            );
          },
        ));
  }
}

class MyPainter extends CustomPainter {
  ui.Image? image;
  double _width = 0;
  double _height = 0;
  static double _ratio1 = 0;
  static double _ratio2 = 0;
  static double _ratio3 = 0;
  static double _ratio4 = 0;
  static int _scale = 35;
  final double _progress;
  Offset tappedPoint;
  static bool _isComplete = false;
  static double k = 0;
  double _xPos = 0;
  double _yPos = 0;
  bool firstZero = false;
  bool _foundRealRoot = false;
  bool _hasComplexRoots = false;
  final _textPainter = TextPainter(textDirection: TextDirection.ltr);

  MyPainter(
      width,
      height,
      ratio1,
      ratio2,
      ratio3,
      ratio4,
      isComplete,
      foundRealRoot,
      hasComplexRoots,
      this._progress,
      this.tappedPoint,
      this._xPos,
      this._yPos,
      [this.image]) {
    _width = width;
    _height = height;
    _ratio1 = ratio1;
    _ratio2 = ratio2;
    _ratio3 = ratio3;
    _ratio4 = ratio4;
    _isComplete = isComplete;
    _foundRealRoot = foundRealRoot;
    _hasComplexRoots = hasComplexRoots;
    // _scale = (_width / 10).toInt();
  }

  static void setScale(int newScale) {
    _scale = newScale;
  }

  static double getP() {
    if (_isComplete == true) {
      return (_ratio4 - k * (_ratio3 - k * (_ratio2 - k * _ratio1))) / _scale;
    } else {
      return -1;
    }
  }

  Path getPathForText(int offset) {
    return Path()
      ..moveTo(_width - offset, _height - offset)
      ..lineTo(_width - offset, _height - _ratio1 - offset)
      ..lineTo(_width - _ratio2 + offset, _height - _ratio1 - offset)
      ..lineTo(_width - _ratio2 + offset, _height - _ratio1 + _ratio3 + offset)
      ..lineTo(
          _width - _ratio2 + _ratio4, _height - _ratio1 + _ratio3 + offset);
  }

  Path getSubPathForText(int offset, double tangent) {
    return Path()
      ..moveTo(_width - offset, _height - offset)
      ..lineTo(_width - tangent * _ratio1, _height - _ratio1)
      ..lineTo(_width - _ratio2,
          _height - _ratio1 + tangent * (_ratio2 - tangent * _ratio1))
      ..lineTo(
          _width -
              _ratio2 +
              tangent * (_ratio3 - tangent * (_ratio2 - tangent * _ratio1)),
          _height - _ratio1 + _ratio3);
  }

  static double getK() {
    return k;
  }

  void paintText(Canvas canvas, Size size, String text, Offset point) {
    final textSpan = TextSpan(
        text: text, style: const TextStyle(color: Colors.black, fontSize: 20));
    final textPainter =
        TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, point);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint = Paint()
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    Paint solutionPaint = Paint()
      ..strokeWidth = 8
      ..strokeCap = ui.StrokeCap.butt
      ..style = ui.PaintingStyle.stroke
      ..color = Colors.redAccent;

    Paint imaginaryPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = ui.StrokeCap.butt
      ..style = ui.PaintingStyle.stroke
      ..color = const Color.fromRGBO(105, 105, 105, 0.5);

    Paint axisPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    Paint imaginaryRootsPaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke
      ..color = Colors.lightBlue;

    if (_ratio1 == 0) {
      firstZero = true;
      _ratio1 = _ratio2;
      _ratio2 = _ratio3;
      _ratio3 = _ratio4;
      _ratio4 = 0;
    }

    _ratio1 *= _scale;
    _ratio2 *= _scale;
    _ratio3 *= _scale;
    _ratio4 *= _scale;

    _width += _xPos;
    _height += _yPos;

    _width += (math.max(_ratio1, _ratio3) / 2) - _ratio1;
    _height += (math.max(_ratio2, _ratio4) / 2);

    var path = getPath2();
    Path textPath = getPathForText(20);
    Rect bounds = path.getBounds();
    if (bounds.bottom >= size.height) {
      path = path
          .shift(Offset(0, -(bounds.bottom - _height + bounds.center.dy / 10)));
      textPath = textPath
          .shift(Offset(0, -(bounds.bottom - _height + bounds.center.dy / 10)));
    }

    ui.PathMetrics pathMetrics = path.computeMetrics();

    ui.PathMetric pathMetric = pathMetrics.elementAt(0);
    final pos = pathMetric.getTangentForOffset(pathMetric.length * _progress);
    Path extracted = pathMetric.extractPath(0.0, pathMetric.length * _progress);

    linePaint.strokeWidth = 6;

    canvas.drawPath(extracted, linePaint);

    if (image == null) {
      canvas.drawCircle(pos!.position, linePaint.strokeWidth / 2, linePaint);
    } else {
      Offset location = Offset(pos!.position.dx - image!.width / 2,
          pos.position.dy - image!.height / 2);
      canvas.save();
      double cx = pos.position.dx;
      double cy = pos.position.dy;
      double angle = pos.angle;
      if (angle == math.pi / 2) {
        angle = -angle;
      } else if (angle == -(math.pi / 2)) {
        angle = math.pi / 2;
      }
      rotateTurtle(canvas: canvas, cx: cx, cy: cy, angle: angle);
      canvas.drawPoints(ui.PointMode.points, [Offset(cx, cy)], linePaint);
      canvas.drawImage(image!, location, linePaint);
      canvas.restore();
      if (_isComplete) {
        canvas.drawTextOnPath(
          "${(_ratio1 ~/ _scale).abs()}  ${(_ratio2 ~/ _scale).abs()}  ${(_ratio3 ~/ _scale).abs()}  ${(_ratio4 ~/ _scale).abs()}",
          textPath,
          textStyle: const TextStyle(
              color: ui.Color.fromARGB(255, 0, 166, 6),
              fontSize: 25,
              fontWeight: ui.FontWeight.bold),
          autoSpacing: true,
          textAlignment: TextAlignment.mid,
          isClosed: true,
        );

        // canvas.drawLine(Offset(_width, _height), tappedPoint, solutionPaint);
        // k = (tappedPoint.dy - _height) / (_width - tappedPoint.dx);
        k = (_width - tappedPoint.dx) / (_height - tappedPoint.dy);
        var solution = firstZero ? getSolution2_2(k) : getSolution2(k);
        double shift = 0;

        if (bounds.bottom >= size.height) {
          shift = (bounds.bottom - _height + bounds.center.dy / 10);
          solution = solution.shift(
              Offset(0, -(bounds.bottom - _height + bounds.center.dy / 10)));
        }

        Path axisY = Path();
        Path axisX = Path();
        axisY.moveTo(_width, _height - _ratio1 - shift);
        axisY.lineTo(_width, 0);
        axisY = ArrowPath.addTip(axisY);

        axisX.moveTo(_width, _height - _ratio1 - shift);
        axisX.lineTo(0, _height - _ratio1 - shift);
        axisX = ArrowPath.addTip(axisX);

        canvas.drawPath(axisY, axisPaint);
        canvas.drawPath(axisX, axisPaint);

        // draw units
        /*int coef = _ratio1 != 0 ? _ratio1 : _ratio2;
        for (int i = 1; i < _width / coef; i++) {
          canvas.drawLine(
              Offset(_width - i * coef, _height - coef - shift + coef / 4),
              Offset(_width - i * coef, _height - coef - shift - coef / 4),
              axisPaint);
        }
        for (int i = 1; i < _height - coef - shift / coef; i++) {
          canvas.drawLine(
              Offset(_width - coef / 4, _height - coef - shift - i * coef),
              Offset(_width + coef / 4, _height - coef - shift - i * coef),
              axisPaint);
        }*/

        Offset endPoint = firstZero
            ? Offset(_width - _ratio2, _height - _ratio1 + _ratio3 - shift)
            : Offset(
                _width - _ratio2 + k * (_ratio3 - k * (_ratio2 - k * _ratio1)),
                _height - _ratio1 + _ratio3 - shift);
        Offset startPoint = Offset(_width, _height - shift);
        Offset circleCenter = Offset(_width + (endPoint.dx - startPoint.dx) / 2,
            _height + (endPoint.dy - startPoint.dy) / 2 - shift);
        double radius = (circleCenter - startPoint).distance;
        canvas.drawCircle(circleCenter, radius, imaginaryPaint);

        // imaginary lines
        checkSolution(canvas, k, imaginaryPaint, extracted, shift);

        canvas.drawPath(solution, solutionPaint);
        if (!firstZero) {
          // first coefficient
          canvas.drawTextOnPath(
            ((math.sqrt(math.pow(_ratio1, 2) + math.pow(k * _ratio1, 2))) /
                    _scale)
                .abs()
                .toStringAsFixed(1),
            Path()
              ..moveTo(
                  _width + (-k * _ratio1) / 2, _height + (-_ratio1) / 2 - shift)
              ..lineTo(_width - k * _ratio1, _height - _ratio1 - shift),
            textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: ui.FontWeight.bold),
            textAlignment: TextAlignment.mid,
          );
          // second coefficient
          canvas.drawTextOnPath(
            ((math.sqrt(math.pow(_ratio2 - k * _ratio1, 2) +
                        math.pow(k * (_ratio2 - k * _ratio1), 2))) /
                    _scale)
                .abs()
                .toStringAsFixed(1),
            Path()
              ..moveTo(_width - k * _ratio1 + (k * _ratio1 - _ratio2) / 2,
                  _height - _ratio1 + (k * (_ratio2 - k * _ratio1)) / 2 - shift)
              ..lineTo(_width - _ratio2,
                  _height - _ratio1 + k * (_ratio2 - k * _ratio1) - shift),
            textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: ui.FontWeight.bold),
            textAlignment: TextAlignment.mid,
          );
          // third coefficient
          canvas.drawTextOnPath(
            ((math.sqrt(math.pow(_ratio3 - k * (_ratio2 - k * _ratio1), 2) +
                        math.pow(
                            k * (_ratio3 - k * (_ratio2 - k * _ratio1)), 2))) /
                    _scale)
                .abs()
                .toStringAsFixed(1),
            Path()
              ..moveTo(
                  _width -
                      _ratio2 +
                      (k * (_ratio3 - k * (_ratio2 - k * _ratio1))) / 2,
                  _height -
                      _ratio1 +
                      k * (_ratio2 - k * _ratio1) +
                      (_ratio3 - k * (_ratio2 - k * _ratio1)) / 2 -
                      shift)
              ..lineTo(
                  _width -
                      _ratio2 +
                      k * (_ratio3 - k * (_ratio2 - k * _ratio1)),
                  _height - _ratio1 + _ratio3 - shift),
            textStyle: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: ui.FontWeight.bold),
          );
        }
        // if circle does not intersect b-line
        // quadratic equation
        if (firstZero &
            (((_height - _ratio1 - shift) < (circleCenter.dy - radius)) |
                ((_height - _ratio1 - shift) > (circleCenter.dy + radius)))) {
          double blueRadius = (_ratio3 + _ratio1) / 2;
          Offset blueCenter = Offset(
              _width - _ratio2, _height - shift + blueRadius - 2 * _ratio1);
          canvas.drawCircle(blueCenter, blueRadius, imaginaryRootsPaint);
          Offset yellowCenter =
              Offset(_width - _ratio2, _height - _ratio1 - shift);
          double yellowRadius = (math.sqrt(blueRadius * blueRadius -
              (blueRadius - _ratio1) * (blueRadius - _ratio1)));
          canvas.drawCircle(yellowCenter, yellowRadius,
              imaginaryRootsPaint..color = Colors.yellow.shade600);
          double complexRoot =
              (math.sqrt(math.pow(yellowRadius, 2) - math.pow(_ratio2 / 2, 2)));
          Offset root1 = Offset(
              _width - _ratio2 / 2, _height - _ratio1 - shift - complexRoot);
          Offset root2 = Offset(
              _width - _ratio2 / 2, _height - _ratio1 - shift + complexRoot);
          canvas.drawPoints(
              ui.PointMode.points,
              [root1, root2],
              imaginaryRootsPaint
                ..color = Colors.green
                ..strokeWidth = 8);
          canvas.drawLine(root1, root2, imaginaryRootsPaint..strokeWidth = 2);
          paintText(
              canvas,
              size,
              "(${(-_ratio2 / (2 * _scale)).toStringAsFixed(1)}, ${((complexRoot) / _scale).toStringAsFixed(1)}i)",
              root1);
          paintText(
              canvas,
              size,
              "(${(-_ratio2 / (2 * _scale)).toStringAsFixed(1)}, ${((-complexRoot) / _scale).toStringAsFixed(1)}i)",
              root2);
        }
        // cubic equation
        if (!firstZero & _foundRealRoot & _hasComplexRoots) {
          Offset pointOne =
              Offset(_width - k * _ratio1, _height - _ratio1 - shift);
          Offset pointTwo = Offset(_width - _ratio2,
              _height - 2 * _ratio1 + k * (_ratio2 - k * _ratio1) - shift);
          Offset pointThree = Offset(
              _width - _ratio2 + k * (_ratio3 - k * (_ratio2 - k * _ratio1)),
              _height - _ratio1 + _ratio3 - shift);
          double blueRadius = (pointThree - pointTwo).distance.abs() / 2;
          Offset blueCenter = Offset((pointThree.dx + pointTwo.dx) / 2,
              (pointThree.dy + pointTwo.dy) / 2);
          canvas.drawCircle(blueCenter, blueRadius, imaginaryRootsPaint);
          Offset yellowCenter = Offset(_width - _ratio2,
              _height - _ratio1 + k * (_ratio2 - k * _ratio1) - shift);
          double yellowRadius = (math.sqrt(blueRadius * blueRadius -
              (blueRadius - _ratio1) * (blueRadius - _ratio1)));
          canvas.drawCircle(yellowCenter, yellowRadius,
              imaginaryRootsPaint..color = Colors.yellow.shade600);
          Offset centerPointOneTwo = Offset((pointOne.dx + yellowCenter.dx) / 2,
              (pointOne.dy + yellowCenter.dy) / 2);
          double complexRoot = (math.sqrt(math.pow(yellowRadius, 2) -
              ((centerPointOneTwo - yellowCenter).distanceSquared)));
          Offset root1 = Offset(
              centerPointOneTwo.dx - complexRoot * math.sin(math.atan(k)),
              centerPointOneTwo.dy - complexRoot * math.cos(math.atan(k)));
          Offset root2 = Offset(
              centerPointOneTwo.dx + complexRoot * math.sin(math.atan(k)),
              centerPointOneTwo.dy + complexRoot * math.cos(math.atan(k)));
          canvas.drawPoints(
              ui.PointMode.points,
              [root1, root2],
              imaginaryRootsPaint
                ..color = Colors.green
                ..strokeWidth = 8);
          canvas.drawLine(root1, root2, imaginaryRootsPaint..strokeWidth = 2);
          double redPathFirst =
              (math.sqrt(math.pow(_ratio1, 2) + math.pow(k * _ratio1, 2))) /
                  _scale;
          double redPathSecond = (math.sqrt(math.pow(_ratio2 - k * _ratio1, 2) +
                  math.pow(k * (_ratio2 - k * _ratio1), 2))) / _scale;
          paintText(
              canvas,
              size,
              "(${(- (redPathSecond / redPathFirst) / (2)).toStringAsFixed(1)}, ${((root1 - root2).distance / (2 * _scale)).toStringAsFixed(1)}i)",
              root1);
          paintText(
              canvas,
              size,
              "(${(- (redPathSecond / redPathFirst) / (2)).toStringAsFixed(1)}, ${((root1 - root2).distance / (2 * _scale)).toStringAsFixed(1)}i)",
              root2);
        }
      }
    }
  }

  void checkSolution(
      Canvas canvas, double k, Paint paint, Path extracted, double shift) {
    if (!extracted.contains(Offset(_width - k * _ratio1, _height - _ratio1))) {
      canvas.drawLine(Offset(_width - k * _ratio1, _height - _ratio1 - shift),
          Offset(_width, _height - _ratio1 - shift), paint);
    }
    if (!extracted.contains(Offset(
        _width - _ratio2, _height - _ratio1 + k * (_ratio2 - k * _ratio1)))) {
      canvas.drawLine(
          Offset(_width - _ratio2,
              _height - _ratio1 + k * (_ratio2 - k * _ratio1) - shift),
          Offset(_width - _ratio2, _height - _ratio1 - shift),
          paint);
    }
    if (!firstZero &
        !extracted.contains(Offset(
            _width - _ratio2 + k * (_ratio3 - k * (_ratio2 - k * _ratio1)),
            _height - _ratio1 + _ratio3))) {
      canvas.drawLine(
          Offset(_width - _ratio2 + k * (_ratio3 - k * (_ratio2 - k * _ratio1)),
              _height - _ratio1 + _ratio3 - shift),
          Offset(_width - _ratio2, _height - _ratio1 + _ratio3 - shift),
          paint);
    }
  }

  Path getSolution(tangent) {
    return Path()
      ..moveTo(_width, _height)
      ..lineTo(_width + _ratio1, _height - tangent * _ratio1)
      ..lineTo(_width + _ratio1 - tangent * (_ratio2 - tangent * _ratio1),
          _height - _ratio2)
      ..lineTo(
          _width + _ratio1 - _ratio3,
          _height -
              _ratio2 +
              tangent * (_ratio3 - tangent * (_ratio2 - tangent * _ratio1)));
  }

  Path getSolution2(tangent) {
    return Path()
      ..moveTo(_width, _height)
      ..lineTo(_width - tangent * _ratio1, _height - _ratio1)
      ..lineTo(_width - _ratio2,
          _height - _ratio1 + tangent * (_ratio2 - tangent * _ratio1))
      ..lineTo(
          _width -
              _ratio2 +
              tangent * (_ratio3 - tangent * (_ratio2 - tangent * _ratio1)),
          _height - _ratio1 + _ratio3);
  }

  Path getSolution2_2(tangent) {
    return Path()
      ..moveTo(_width, _height)
      ..lineTo(_width - tangent * _ratio1, _height - _ratio1)
      ..lineTo(_width - _ratio2,
          _height - _ratio1 + tangent * (_ratio2 - tangent * _ratio1));
  }

  void rotateTurtle(
      {required Canvas canvas,
      required double cx,
      required double cy,
      required double angle}) {
    canvas.translate(cx, cy);
    canvas.rotate(angle);
    canvas.translate(-cx, -cy);
  }

  Path getPath() {
    return Path()
      ..moveTo(_width, _height)
      ..lineTo(_width + _ratio1, _height)
      ..lineTo(_width + _ratio1, _height - _ratio2)
      ..lineTo(_width + _ratio1 - _ratio3, _height - _ratio2)
      ..lineTo(_width + _ratio1 - _ratio3, _height - _ratio2 + _ratio4);
  }

  Path getPath2() {
    return Path()
      ..moveTo(_width, _height)
      ..lineTo(_width, _height - _ratio1)
      ..lineTo(_width - _ratio2, _height - _ratio1)
      ..lineTo(_width - _ratio2, _height - _ratio1 + _ratio3)
      ..lineTo(_width - _ratio2 + _ratio4, _height - _ratio1 + _ratio3);
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return (oldDelegate._progress != _progress);
    // return false;
  }
}
