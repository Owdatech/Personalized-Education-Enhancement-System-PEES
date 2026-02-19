import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/OTP_screen.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/language_button.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';

import '../../Widgets/AppTextField.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  AuthVM viewModel = AuthVM();

  Object? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter an email")));
    }
    // Regular expression for email validation
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    if (!regex.hasMatch(value)) {
      return ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email address')));
    }
    return null;
  }

  forgotAction() async {
    String email = emailController.text.toString();
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);
    if (email.isEmpty) {
      Utils.snackBar("emailEmpty".tr, context);
    } else if (!regex.hasMatch(emailPattern)) {
      Utils.snackBar("validEmail".tr, context);
    } else {
      int? code = await viewModel.sendOTPApi(email);
      if (context.mounted) {
        if (code == 200) {
          Utils.snackBar("otpSuccess".tr, context);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => OTPScreen(email: email)));
        } else {
          print("Error: ${viewModel.apiError}");
          Utils.snackBar("${viewModel.apiError}", context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                              fontSize: isMobile ? 25 : 35,
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
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                          "forgotPasswordTitle".tr,
                                          textAlign: TextAlign.center,
                                          style: PoppinsCustomTextStyle.bold
                                              .copyWith(
                                                  color: AppColor.buttonGreen,
                                                  fontSize: 36),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Text(
                                          "forgotPassowordSubTitle".tr,
                                          textAlign: TextAlign.center,
                                          style: PoppinsCustomTextStyle.medium
                                              .copyWith(
                                                  fontSize: 14,
                                                  color: AppColor.black),
                                        ),
                                      ),
                                      const SizedBox(height: 35),
                                      Text("emailAddressTitle".tr,
                                          style: PoppinsCustomTextStyle.medium
                                              .copyWith(
                                                  fontSize: 16,
                                                  color: AppColor.white)),
                                      const SizedBox(height: 5),
                                      AppTextField(
                                          textController: emailController,
                                          hintText: "emailHint".tr,
                                          icon: null),
                                      const SizedBox(height: 30),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: AppFillButton(
                                                  onPressed: () {
                                                    forgotAction();
                                                  },
                                                  text: "resetPassword")),
                                        ],
                                      ),
                                      const SizedBox(height: 30),
                                      Align(
                                        alignment: Alignment.center,
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "backToLogin".tr,
                                            style: NotoSansArabicCustomTextStyle
                                                .medium
                                                .copyWith(
                                                    color: AppColor.black,
                                                    fontSize: 15),
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
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
                    value.loading ? LoaderView() : Container()
                  ],
                ),
              );
            },
          );
        }));
  }
}
