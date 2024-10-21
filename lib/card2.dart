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

final Uri _url1 = Uri.parse(
    'https://web.archive.org/web/20100502013959/http://www.concentric.net/~pvb/ALG/rightpaths.html');

final Uri _url2 = Uri.parse(
    'https://www.youtube.com/watch?v=IUC-8P0zXe8');

final Uri _url3 = Uri.parse(
    'https://www.raulprisacariu.com/lills-method/');

Future<void> _launchUrl(Uri uri) async {
  if (!await launchUrl(uri)) {
    throw Exception('Could not launch $uri');
  }
}

class CardScreen2 extends StatelessWidget {
  const CardScreen2({required this.data, super.key});

  final CardData2 data;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(children: [
              const Spacer(flex: 1),
              if (data.image != null) Flexible(flex: 10, child: data.image!),
              if (data.image != null) const Spacer(flex: 1),
              TeXView(
                child: TeXViewDocument(data.latex),
                style: TeXViewStyle(
                    textAlign: TeXViewTextAlign.center,
                    contentColor: data.titleColor,
                    fontStyle: TeXViewFontStyle(fontSize: 20)),
              ),
              const Spacer(flex: 1),
              if (data.index == 4)...[
                ElevatedButton(
                  onPressed: () => _launchUrl(_url1),
                  child: Text(l!.linkArticle),
                ),
                ElevatedButton(
                  onPressed: () => _launchUrl(_url2),
                  child: Text(l!.linkVideo),
                ),
                ElevatedButton(
                  onPressed: () => _launchUrl(_url3),
                  child: Text(l.linkWebsite),
                )],
              if (data.index != 4) TeXView(
                child: TeXViewDocument(data.text),
                style: TeXViewStyle(
                    textAlign: TeXViewTextAlign.center,
                    contentColor: data.subtitleColor,
                    fontStyle: TeXViewFontStyle(fontSize: 20)),
              ),
              const Spacer(flex: 5)
            ]))
      ],
    );
  }
}
