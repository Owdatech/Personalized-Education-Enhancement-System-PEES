// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:get/get.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Teacher_Dashbord/Pages/Students/student_list.dart';
import 'package:pees/Teacher_Dashbord/Pages/dashboard_screen.dart';
import 'package:pees/Teacher_Dashbord/Pages/teacher_dashboard_UI.dart';
import 'package:pees/Teacher_Dashbord/Services/teacher_service.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;

class PdfOcrScreen extends StatefulWidget {
  final String? pdfText;
  final String? evaluationReport;
  String? examName;
  String? curriculumCoverage;
  String? date;
  String? observation;
  String? studentId;
  String? curriculumId;
  String? curriculumName;
  String? subject;
  String? lang;
  html.File? file;

  PdfOcrScreen(
      {this.pdfText,
      this.evaluationReport,
      this.examName,
      this.curriculumCoverage,
      this.date,
      this.observation,
      this.studentId,
      this.curriculumId,
      this.curriculumName,
      this.subject,
      this.lang,
      super.key,
      this.file});

  @override
  State<PdfOcrScreen> createState() => _PdfOcrScreenState();
}

class _PdfOcrScreenState extends State<PdfOcrScreen> {
  TeacherService teacherViewmodel = TeacherService();
  bool isEvaluate = false;
  String? evaluatedata;
  TextEditingController feedbackController = TextEditingController();
  bool isAccept = false;

  evaluateAction() async {
    String? data = await teacherViewmodel.pdfEvaluateApi(widget.pdfText ?? "");
    if (context.mounted) {
      if (data != null) {
        setState(() {
          isEvaluate = true;
          evaluatedata = data;
          print("Evaluate Successfully");
          Utils.snackBar("Your data is successfully evaluated.", context);
        });
      } else {
        print("Evaluated Api Error : ${teacherViewmodel.apiError}");
        Utils.snackBar("${teacherViewmodel.apiError}", context);
      }
    }
  }

  sendFeedbackAction(String status, String feedback) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? teacherId = prefs.getString('userId');
    int? code = await teacherViewmodel.sendEvaluateFeedback(
        widget.examName ?? "",
        widget.curriculumCoverage ?? "",
        widget.date ?? "",
        widget.observation ?? "",
        widget.studentId ?? '',
        widget.curriculumId ?? "",
        widget.curriculumName ?? "",
        widget.subject ?? "",
        widget.lang ?? "en",
        teacherId ?? "",
        feedback,
        status,
        widget.file);
    if (context.mounted) {
      if (code == 200) {
        status == 'true'
            ? Utils.snackBar("successFeedback".tr, context)
            : Utils.snackBar("analysisDeleted".tr, context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TeacherDashBoardUI()),
        );
      } else {
        Utils.snackBar("${teacherViewmodel.apiError}", context);
      }
    }
  }

  bool isAcceptSelected = false;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<TeacherService>(
        create: (BuildContext context) => teacherViewmodel,
        child: Consumer<TeacherService>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              backgroundColor: AppColor.bgLavender,
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        left: isMobile ? 20 : 100,
                        right: isMobile ? 20 : 100,
                        top: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          isMobile
                              ? const BackButtonWidget()
                              : const SizedBox(),
                          isMobile
                              ? const SizedBox(height: 5)
                              : const SizedBox(),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColor.panelDarkSoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarkdownBody(
                                      data: widget.evaluationReport ??
                                          "No evaluation report available",
                                      selectable: true,
                                      extensionSet: md.ExtensionSet(
                                        md.ExtensionSet.gitHubFlavored
                                            .blockSyntaxes,
                                        [
                                          LatexInlineSyntax(),
                                          ...md.ExtensionSet.gitHubFlavored
                                              .inlineSyntaxes
                                        ],
                                      ),
                                      builders: {
                                        "latex": LatexElementBuilder(
                                            textDirection: TextDirection.ltr),
                                      },
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              isAcceptSelected = true;
                                            });
                                            // sendFeedbackAction("true", "");
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 100,
                                            decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Center(
                                              child: Text("accept".tr,
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .semibold
                                                          .copyWith(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .white)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        InkWell(
                                          onTap: () async {
                                            setState(() {
                                              isAcceptSelected = false;
                                            });

                                            await sendFeedbackAction(
                                                "false", "");
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 100,
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Center(
                                              child: Text("reject".tr,
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .semibold
                                                          .copyWith(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .white)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    if (isAcceptSelected)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("feedbackButton".tr,
                                                  style:
                                                      NotoSansArabicCustomTextStyle
                                                          .bold
                                                          .copyWith(
                                                              fontSize: 14,
                                                              color: AppColor
                                                                  .black)),
                                            ],
                                          ),
                                          const SizedBox(height: 7),
                                          Container(
                                            height: 60,
                                            decoration: BoxDecoration(
                                                color: AppColor.lightGrey,
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                            child: TextField(
                                              controller: feedbackController,
                                              style: PoppinsCustomTextStyle
                                                  .regular
                                                  .copyWith(
                                                      fontSize: 14,
                                                      color: AppColor.black),
                                              decoration: InputDecoration(
                                                border: InputBorder.none,
                                                hintText: "feedbackHint".tr,
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                        left: 8),
                                                hintStyle:
                                                    NotoSansArabicCustomTextStyle
                                                        .regular
                                                        .copyWith(
                                                            color:
                                                                AppColor.text,
                                                            fontSize: 14),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          AppFillButton3(
                                              onPressed: () {
                                                String feedback =
                                                    feedbackController.text;
                                                sendFeedbackAction(
                                                    "true", feedback);
                                              },
                                              text: "generateTeachingPlan",
                                              color: AppColor.buttonGreen),
                                          const SizedBox(height: 15),
                                        ],
                                      )
                                  ],
                                )),
                          ),
                          // : const SizedBox(),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  teacherViewmodel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }
}

class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax()
      : super(
            r'(\$\$\s*([\s\S]+?)\s*\$\$|\$\s*([\s\S]+?)\s*\$|\\\[\s*([\s\S]+?)\s*\\\]|\n?\\\(\s*([\s\S]+?)\s*\\\))');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    String latex = (match.group(2) ??
            match.group(3) ??
            match.group(4) ??
            match.group(5) ??
            '')
        .trim();

    latex = _sanitizeLatex(latex);
    parser.addNode(md.Element.text('latex', latex));
    return true;
  }

  String _sanitizeLatex(String latex) {
    latex = latex.replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E\uFEFF]'), '');

    latex = latex.replaceAllMapped(RegExp(r'\\text\{([^}]*)\}'), (match) {
      String arabicText = match.group(1)!;
      String shapedArabic = arabicText.characters.toList().join();
      List<String> words = shapedArabic.split(RegExp(r'\s+'));
      String fixedText = words.reversed.join(' ');
      return r'\text{' + fixedText + r'}';
    });

    latex = latex.replaceAllMapped(
        RegExp(r'\\left\s*\)\s*(.*?)\s*\\right\s*\('), (match) {
      return r'\left(' + match.group(1)! + r'\right)';
    });

    return latex.trim();
  }
}

class LatexElementBuilder extends MarkdownElementBuilder {
  final TextDirection textDirection;

  LatexElementBuilder({this.textDirection = TextDirection.ltr});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String latexContent = element.textContent;

    if (textDirection == TextDirection.rtl) {
      latexContent = _reverseEquationForRTL(latexContent);
    }

    latexContent = _fixBracketsForRTL(latexContent, textDirection);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Directionality(
        textDirection: textDirection,
        child: Math.tex(
          latexContent,
          textStyle: const TextStyle(
              fontSize: 18.0, fontFamily: 'Inter', color: Colors.black),
        ),
      ),
    );
  }

  String _reverseEquationForRTL(String input) {
    if (input.contains('=')) {
      final parts = input.split('=');
      return '${parts.last.trim()} = ${parts.first.trim()}';
    }
    return input;
  }

  String _fixBracketsForRTL(String input, TextDirection direction) {
    if (direction == TextDirection.rtl) {
      input = input.replaceAll('﴾', '(');
      input = input.replaceAll('﴿', ')');
    }
    return input;
  }
}
