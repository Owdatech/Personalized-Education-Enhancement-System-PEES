import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Services/common_service.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/back_button.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotiificationSettingScreen extends StatefulWidget {
  const NotiificationSettingScreen({super.key});

  @override
  State<NotiificationSettingScreen> createState() =>
      _NotiificationSettingScreenState();
}

class _NotiificationSettingScreenState
    extends State<NotiificationSettingScreen> {
  CommonService viewModel = CommonService();
  String selectedLanguage = Get.locale?.languageCode ?? 'en';
  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;

  bool emailSelected = false;
  bool smsSelected = false;
  bool appSelected = false;

  deliveryMethodApi() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    int? code = await viewModel.deliveryMethodApi(
        userId ?? "", emailSelected, smsSelected, appSelected);
    if (context.mounted) {
      if (code == 200) {
        print("delevery method succes");
        print("email : $emailSelected");
        print("sms : $smsSelected");
        print("app : $appSelected");
      } else {
        print("${viewModel.apiError}");
      }
    }
  }

  Future<void> savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('emailSelected', emailSelected);
    await prefs.setBool('smsSelected', smsSelected);
    await prefs.setBool('appSelected', appSelected);
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailSelected = prefs.getBool('emailSelected') ?? false;
      smsSelected = prefs.getBool('smsSelected') ?? false;
      appSelected = prefs.getBool('appSelected') ?? false;
    });
  }

  @override
  void initState() {
    loadPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CommonService>(
        create: (BuildContext context) => viewModel,
        child: Consumer<CommonService>(builder: (context, value, _) {
          return Scaffold(
            body: Stack(
              children: [
                const BackButtonWidget(),
                Padding(
                  padding:
                      const EdgeInsets.only(top: 30, left: 180, right: 180),
                  child: SizedBox(
                    child: Column(
                      children: [notificationSetting()],
                    ),
                  ),
                ),
                viewModel.loading ? const LoaderView() : Container()
              ],
            ),
          );
        }));
  }

  Widget notificationSetting() {
    return Column(
      children: [
        Container(
            height: 40,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColor.buttonGreen,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text("notificationSettings".tr,
                    style: NotoSansArabicCustomTextStyle.bold
                        .copyWith(fontSize: 18, color: AppColor.white)),
              ),
            )),
        Container(
            decoration: const BoxDecoration(
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                      blurRadius: 5,
                      color: AppColor.buttonShadow,
                      offset: Offset(0, 5))
                ],
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10))),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Padding(
                    //   padding: EdgeInsets.only(
                    //       left: selectedLanguage == 'en' ? 20 : 0,
                    //       right: selectedLanguage == 'en' ? 0 : 20),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     mainAxisAlignment: MainAxisAlignment.start,
                    //     children: [
                    //       const SizedBox(height: 10),
                    //       Text("alertTypes".tr,
                    //           style: NotoSansArabicCustomTextStyle.bold
                    //               .copyWith(
                    //                   color: AppColor.black, fontSize: 18)),
                    //       const SizedBox(height: 17),
                    //       Row(
                    //         children: [
                    //           Text("specificAlerts".tr,
                    //               style: NotoSansArabicCustomTextStyle.medium
                    //                   .copyWith(
                    //                       color: AppColor.black, fontSize: 18)),
                    //           const SizedBox(width: 20),
                    //           Checkbox(
                    //             value: isChecked1,
                    //             onChanged: (value) {
                    //               setState(() {
                    //                 isChecked1 = !isChecked1;
                    //               });
                    //             },
                    //           )
                    //         ],
                    //       ),
                    //       Row(
                    //         children: [
                    //           Text("specificAlerts".tr,
                    //               style: NotoSansArabicCustomTextStyle.medium
                    //                   .copyWith(
                    //                       color: AppColor.black, fontSize: 18)),
                    //           const SizedBox(width: 20),
                    //           Checkbox(
                    //             value: isChecked2,
                    //             onChanged: (value) {
                    //               setState(() {
                    //                 isChecked2 = !isChecked2;
                    //               });
                    //             },
                    //           )
                    //         ],
                    //       ),
                    //       Row(
                    //         children: [
                    //           Text("specificAlerts".tr,
                    //               style: NotoSansArabicCustomTextStyle.medium
                    //                   .copyWith(
                    //                       color: AppColor.black, fontSize: 18)),
                    //           const SizedBox(width: 20),
                    //           Checkbox(
                    //             value: isChecked3,
                    //             onChanged: (value) {
                    //               setState(() {
                    //                 isChecked3 = !isChecked3;
                    //               });
                    //             },
                    //           )
                    //         ],
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 15),
                    // Container(
                    //   height: 2,
                    //   color: AppColor.buttonGreen,
                    // ),
                    // const SizedBox(height: 15),
                    const SizedBox(height: 7),
                    Padding(
                      padding: EdgeInsets.only(
                          left: selectedLanguage == 'en' ? 20 : 0,
                          right: selectedLanguage == 'en' ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("deliveryMethods".tr,
                              style: NotoSansArabicCustomTextStyle.bold
                                  .copyWith(
                                      color: AppColor.black, fontSize: 18)),
                          const SizedBox(height: 17),
                          customRadioButton("emailTitle", emailSelected, () {
                            setState(() {
                              emailSelected = !emailSelected;
                            });
                          }),
                          const SizedBox(height: 7),
                          customRadioButton("sms", smsSelected, () {
                            setState(() {
                              smsSelected = !smsSelected;
                            });
                          }),
                          const SizedBox(height: 7),
                          customRadioButton("byOtherAPP", appSelected, () {
                            setState(() {
                              appSelected = !appSelected;
                            });
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ],
            ))
      ],
    );
  }

  Widget customRadioButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
        savePreferences();
        deliveryMethodApi();
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.circle, size: 16, color: Colors.green)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            text.tr,
            style: NotoSansArabicCustomTextStyle.medium
                .copyWith(color: AppColor.black, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
