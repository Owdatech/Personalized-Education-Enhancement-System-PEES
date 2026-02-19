import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/setPassword.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/language_button.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

class OTPScreen extends StatefulWidget {
  String? email;
  OTPScreen({this.email, super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  AuthVM viewModel = AuthVM();

  continueAction() async {
    String otp = otpController.text.toString();
    String email = widget.email.toString();
    if (otp.isEmpty) {
      Utils.snackBar("otpEmpty".tr, context);
    } else {
      int? code = await viewModel.verifyOTPApi(email, otp);
      if (context.mounted) {
        if (code == 200) {
          Utils.snackBar("otpVerifySuccess".tr, context);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SetPasswordScreen()));
        } else {
          print("Error: ${viewModel.apiError}");
          Utils.snackBar("${viewModel.apiError}", context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 50,
      // margin: EdgeInsets.only(left: 6.5),
      textStyle: PoppinsCustomTextStyle.medium.copyWith(
        fontSize: 24,
        color: AppColor.black,
      ),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(width: 2, color: AppColor.darkGreen),
        borderRadius: BorderRadius.circular(10),
      ),
    );

    return ChangeNotifierProvider<AuthVM>(
        create: (BuildContext context) => viewModel,
        child: Consumer<AuthVM>(builder: (context, value, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth <= 800;
              return Scaffold(
                body: Stack(
                  children: [
                    Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                tileMode: TileMode.clamp,
                                colors: [
                              AppColor.yellowGreen,
                              AppColor.lightGrren,
                              AppColor.darkGreen
                            ])),
                        child: Image.asset(
                          AppImage.loginBackground,
                          fit: BoxFit.cover,
                        )),
                    Column(
                      children: [
                        const SizedBox(height: 50),
                        Text(
                          "appName".tr,
                          textAlign: TextAlign.center,
                          style: PoppinsCustomTextStyle.medium.copyWith(
                              fontSize: isMobile ? 20 : 35,
                              color: AppColor.white),
                        ),
                        const SizedBox(height: 30),
                        Align(
                          alignment: Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : 0),
                            child: Container(
                              width: 450,
                              decoration: BoxDecoration(
                                  color: AppColor.whiteBorder,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 2, color: AppColor.whiteBorder)),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 25, right: 25, top: 20, bottom: 65),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        "resetPassword".tr,
                                        style: PoppinsCustomTextStyle.bold
                                            .copyWith(
                                                color: AppColor.buttonGreen,
                                                fontSize: 36),
                                      ),
                                    ),

                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        "resetPasswordsubTitle".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                fontSize: 14,
                                                color: AppColor.black),
                                      ),
                                    ),
                                    const SizedBox(height: 35),
                                    //pinput
                                    Align(
                                      alignment: Alignment.center,
                                      child: Pinput(
                                        controller: otpController,
                                        defaultPinTheme: defaultPinTheme,
                                        keyboardType: TextInputType.number,
                                        length: 6,
                                        pinputAutovalidateMode:
                                            PinputAutovalidateMode.onSubmit,
                                        showCursor: true,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: AppFillButton(
                                                onPressed: () {
                                                  continueAction();
                                                },
                                                text: "continue")),
                                      ],
                                    ),
                                    const SizedBox(height: 30),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text("didntemail".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .medium
                                                      .copyWith(
                                                          color: AppColor.black,
                                                          fontSize: 15)),
                                          InkWell(
                                            onTap: () {
                                              //resend Action
                                            },
                                            child: Text(
                                              "resendIt".tr,
                                              style:
                                                  NotoSansArabicCustomTextStyle
                                                      .medium
                                                      .copyWith(
                                                          color: AppColor
                                                              .buttonGreen,
                                                          fontSize: 15),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                     Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                          // padding: const EdgeInsets.only(bottom: 10),
                          padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 10,
                          ),
                          child: Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(children: [
                                TextSpan(
                                  text: "copyrightInformation".tr,
                                  style: PoppinsCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 16,
                                          color: AppColor.lightPink),
                                ),
                                TextSpan(
                                  text: ' / ',
                                  style: PoppinsCustomTextStyle.regular
                                      .copyWith(
                                          fontSize: 16,
                                          color: AppColor.lightPink),
                                ),
                                TextSpan(
                                    text: "termsandPrivacyPolicy".tr,
                                    style: PoppinsCustomTextStyle.regular
                                        .copyWith(
                                            fontSize: 16,
                                            color: AppColor.lightPink))
                              ]))),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 15, right: 15),
                      child: LanguageSelectButton(),
                    ),
                    viewModel.loading ? LoaderView() : Container()
                  ],
                ),
              );
            },
          );
        }));
  }
}
