import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/HeadMaster_Dashboard/Services/headMaster_services.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/custom_class/my_appBar.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

class ReposrtsScreen extends StatefulWidget {
  const ReposrtsScreen({super.key});

  @override
  State<ReposrtsScreen> createState() => _ReposrtsScreenState();
}

class _ReposrtsScreenState extends State<ReposrtsScreen> {
  HeadMasterServices viewModel = HeadMasterServices();

  fetchReport() async {
    int? code = await viewModel.reportsApi();
    if (code == 200) {
      print("Successfully fetch Reports Details");
    } else {
      print("Reports details Error : ${viewModel.apiError}");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    fetchReport();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return ChangeNotifierProvider<HeadMasterServices>(
        create: (BuildContext context) => viewModel,
        child: Consumer<HeadMasterServices>(builder: (context, value, _) {
          return LayoutBuilder(builder: (context, constraints) {
            bool isMobile = constraints.maxWidth <= 800;
            return Scaffold(
              appBar: PreferredSize(
                  preferredSize: const Size(double.infinity, 50),
                  child: isMobile ? MyAppBar("") : const SizedBox()),
              body: Stack(
                children: [
                  isMobile ? const SizedBox() : const BackButtonWidget(),
                  Padding(
                    padding: EdgeInsets.only(
                        top: isMobile ? 5 : 30,
                        left: isMobile ? 12 : 100,
                        right: isMobile ? 12 : 30),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "reports".tr,
                            style: NotoSansArabicCustomTextStyle.bold.copyWith(
                                fontSize: 18,
                                color: themeManager.isHighContrast
                                    ? AppColor.white
                                    : AppColor.buttonGreen),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: viewModel.reports.length,
                            itemBuilder: (context, index) {
                              final report = viewModel.reports[index];
                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: themeManager.isHighContrast
                                          ? AppColor.labelText
                                          : AppColor.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: AppColor.greyShadow,
                                            blurRadius: 5,
                                            offset: Offset(0, 5))
                                      ]),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(report['title'],
                                            style: NotoSansArabicCustomTextStyle
                                                .bold
                                                .copyWith(
                                                    fontSize: 16,
                                                    color: AppColor.black)),
                                        const SizedBox(height: 5),
                                        Text(
                                          report['description'],
                                          style: NotoSansArabicCustomTextStyle
                                              .regular
                                              .copyWith(
                                                  fontSize: 14,
                                                  color: AppColor.black),
                                        ),
                                        const SizedBox(height: 5),
                                        InkWell(
                                          onTap: () {
                                            if (report['link'].isNotEmpty) {
                                              // _openLink(report['link']);
                                              downloadPDFFile(report['link']);
                                            }
                                          },
                                          child: Text(
                                            "download".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .semibold
                                                .copyWith(
                                                    color: AppColor.buttonGreen,
                                                    fontSize: 15),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  viewModel.loading ? const LoaderView() : Container()
                ],
              ),
            );
          });
        }));
  }

  void downloadPDFFile(String url) async {
    final anchorElement = html.AnchorElement(href: url)
      ..setAttribute("download", "reports")
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // void _openLink(String url) async {
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     throw 'Could not launch $url';
  //   }
  // }
}
