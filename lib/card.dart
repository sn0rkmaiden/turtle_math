import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localization.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CardData {
  final int index;
  final String latex;
  final String text;
  final Widget? image;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Widget? background;

  const CardData({
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

class CardScreen extends StatelessWidget {
  const CardScreen({required this.data, super.key});

  final CardData data;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (data.background != null) data.background!,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Flexible(flex: 10, child: data.image!),
              const Spacer(flex: 1),
              if (data.index == 2)
                TeXView(
                  child: TeXViewDocument(
                      AppLocalizations.of(context)!.page2text.toString()),
                  style: const TeXViewStyle(textAlign: TeXViewTextAlign.center),
                )
              else
                Text(
                    data.index == 1
                        ? AppLocalizations.of(context)!.page1latex.toUpperCase()
                        : AppLocalizations.of(context)!
                            .page3latex
                            .toUpperCase(),
                    style: TextStyle(
                        color: data.titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                    textAlign: TextAlign.center,
                    maxLines: 3),
              const Spacer(flex: 1),
              if (data.index == 3)
                Text(
                  AppLocalizations.of(context)!.page3text,
                  style: TextStyle(color: data.subtitleColor, fontSize: 16),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
              if (data.index == 1)
                InkWell(
                    child: Text(AppLocalizations.of(context)!.page1text,
                        style: TextStyle(
                            color: data.subtitleColor,
                            fontSize: 16,
                            decoration: TextDecoration.underline),
                        textAlign: TextAlign.center,
                        maxLines: 3),
                    onTap: () => launchUrlString(
                        'https://www.youtube.com/watch?v=IUC-8P0zXe8')),
              const Spacer(flex: 10)
            ],
          ),
        ),
      ],
    );
  }
}
