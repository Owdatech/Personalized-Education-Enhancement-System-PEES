import 'package:flutter/material.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/pdf_ocr_show.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:ui' as ui;
import 'package:markdown/markdown.dart' as md;

class EvaluatedScreen extends StatefulWidget {
  String text;
  EvaluatedScreen({required this.text, super.key});

  @override
  State<EvaluatedScreen> createState() => _EvaluatedScreenState();
}

class _EvaluatedScreenState extends State<EvaluatedScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Scaffold(
        backgroundColor: AppColor.bgLavender,
        body: Stack(
          children: [
            isMobile ? const SizedBox() : const BackButtonWidget(),
            Padding(
              padding: EdgeInsets.only(
                  top: 30,
                  left: isMobile ? 12 : 100,
                  right: isMobile ? 12 : 30),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    isMobile ? const BackButtonWidget() : const SizedBox(),
                    SizedBox(height: isMobile ? 5 : 10),
                    Container(
                      decoration: BoxDecoration(
                          color: AppColor.panelDarkSoft,
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: MarkdownBody(
                          data: widget.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(
                                  Theme.of(context))
                              .copyWith(
                            p: const TextStyle(
                                fontSize: 15, color: AppColor.text),
                            h1: const TextStyle(
                                fontSize: 22,
                                color: AppColor.white,
                                fontWeight: FontWeight.bold),
                            h2: const TextStyle(
                                fontSize: 20,
                                color: AppColor.white,
                                fontWeight: FontWeight.bold),
                            h3: const TextStyle(
                                fontSize: 18,
                                color: AppColor.white,
                                fontWeight: FontWeight.bold),
                            listBullet: const TextStyle(
                                fontSize: 15, color: AppColor.text),
                            strong: const TextStyle(
                                fontSize: 15,
                                color: AppColor.white,
                                fontWeight: FontWeight.bold),
                            em: const TextStyle(
                                fontSize: 15, color: AppColor.text),
                            code: const TextStyle(
                                fontSize: 14, color: AppColor.white),
                            blockquote: const TextStyle(
                                fontSize: 15, color: AppColor.text),
                          ),
                          extensionSet: md.ExtensionSet(
                            md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                            [
                              LatexInlineSyntax(),
                              ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                            ],
                          ),
                          builders: {
                            "latex": LatexElementBuilder(
                                textDirection: ui.TextDirection.ltr),
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }
}
