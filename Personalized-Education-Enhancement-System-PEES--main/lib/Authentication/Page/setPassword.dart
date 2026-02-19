import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/login_screen.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/language_button.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  AuthVM viewModel = AuthVM();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  resetPassword() async {
    String newPassword = newPasswordController.text;
    String confirmPassword = confirmPasswordController.text;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (newPassword.isEmpty) {
      Utils.snackBar("newPasswordEmpty".tr, context);
    } else if (newPassword.length < 8) {
      Utils.snackBar(
          "passwordLength".tr, context);
    } else if (confirmPassword.isEmpty) {
      Utils.snackBar("confirmPasswordEmpty".tr, context);
    } else if (confirmPassword.length < 8) {
      Utils.snackBar(
          "newPasswordLength".tr, context);
    } else {
      int? code = await viewModel.resetPassword(
          userId ?? "", newPassword, confirmPassword);
      if (context.mounted) {
        if (code == 200) {
          Utils.snackBar("successResetPassword".tr, context);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false);
        } else {
          Utils.snackBar(" ${viewModel.apiError}", context);
          print("Api Failed Error :  ${viewModel.apiError}");
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        "setPasswordTitle".tr,
                                        textAlign: TextAlign.center,
                                        style: PoppinsCustomTextStyle.bold
                                            .copyWith(
                                                color: AppColor.buttonGreen,
                                                fontSize: 36),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        "setPasswordSubTitle".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                fontSize: 14,
                                                color: AppColor.black),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    Text("newPasswordTitle".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                fontSize: 16,
                                                color: AppColor.buttonGreen)),
                                    const SizedBox(height: 5),
                                    AppTextField(
                                      textController: newPasswordController,
                                      isObscure: !_newPasswordVisible,
                                      hintText: "newPasswordHint".tr,
                                      icon: null,
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _newPasswordVisible =
                                                  !_newPasswordVisible;
                                            });
                                          },
                                          icon: Icon(
                                            _newPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: AppColor.labelText,
                                          )),
                                    ),
                                    const SizedBox(height: 30),
                                    Text("confirmPasswordTitle".tr,
                                        style: PoppinsCustomTextStyle.medium
                                            .copyWith(
                                                fontSize: 16,
                                                color: AppColor.buttonGreen)),
                                    const SizedBox(height: 5),
                                    AppTextField(
                                      textController: confirmPasswordController,
                                      isObscure: !_confirmPasswordVisible,
                                      hintText: "confirmPasswordHint".tr,
                                      icon: null,
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _confirmPasswordVisible =
                                                  !_confirmPasswordVisible;
                                            });
                                          },
                                          icon: Icon(
                                            _confirmPasswordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: AppColor.labelText,
                                          )),
                                    ),
                                    const SizedBox(height: 13),
                                    const SizedBox(height: 35),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: AppFillButton(
                                                onPressed: () {
                                                  resetPassword();
                                                },
                                                text: "resetPassword".tr)),
                                      ],
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
                    viewModel.loading ? const LoaderView() : Container()
                  ],
                ),
              );
            },
          );
        }));
  }
}
