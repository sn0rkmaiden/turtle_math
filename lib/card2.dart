import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:tex_text/tex_text.dart';

class CardData2 {
  final int index;
  final String latex;
  final String text;
  final Widget? image;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Widget? background;

  const CardData2({
    required this.index,
    required this.latex,
    required this.text,
    required this.image,
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    this.background,
  });
}

class CardScreen2 extends StatelessWidget {
  const CardScreen2({required this.data, super.key});

  final CardData2 data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(children: [
              const Spacer(flex: 1),
              Flexible(flex: 10, child: data.image!),
              const Spacer(flex: 1),
              TeXView(
                child: TeXViewDocument(data.latex),                
                style: TeXViewStyle(textAlign: TeXViewTextAlign.center, contentColor: data.titleColor, fontStyle: TeXViewFontStyle(fontSize: 20)),
              ),                                      
              const Spacer(flex: 1),
              TeXView(
                child: TeXViewDocument(data.text),                
                style: TeXViewStyle(textAlign: TeXViewTextAlign.center, contentColor: data.subtitleColor, fontStyle: TeXViewFontStyle(fontSize: 20)),
              ),
              const Spacer(flex: 5)
            ]))
      ],
    );
  }
}
