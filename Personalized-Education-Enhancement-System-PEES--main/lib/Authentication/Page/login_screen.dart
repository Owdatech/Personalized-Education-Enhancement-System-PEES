// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Authentication/Page/forgot_pw_page.dart';
import 'package:pees/Authentication/Services/auth_service.dart';
import 'package:pees/Common_Screen/Pages/language_button.dart';
import 'package:pees/HeadMaster_Dashboard/Pages/headMaster_dashboard_UI.dart';
import 'package:pees/Parent_Dashboard/Pages/parent_dashboard_UI.dart';
import 'package:pees/Teacher_Dashbord/Pages/teacher_dashboard_UI.dart';
import 'package:pees/Widgets/AppButton.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/AppImage.dart';
import 'package:pees/Widgets/AppTextField.dart';
import 'package:pees/Widgets/Loader_view.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:pees/Widgets/utils.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthVM viewModel = AuthVM();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isRememberMe = false;
  bool _passwordVisible = false;
  final GlobalKey<FormState> _loginkey = GlobalKey<FormState>();

  loginAction() async {
    if (_loginkey.currentState?.validate() ?? false) {
      // Ensures form validation runs
      if (emailController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty) {
        Utils.snackBar("email/passAlert".tr, context);
        return;
      }

      Map<String, String?> response = await viewModel.loginApicall(
          emailController.text.trim(), passwordController.text.trim());

      String? role = response["role"];
      String? error = response["error"];

      if (role != null) {
        if (role == "headmaster") {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HeadMasterDashboardUI()),
              (route) => false);
        } else if (role == "teacher") {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => TeacherDashBoardUI()),
              (route) => false);
        } else if (role == "parent") {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ParentDashboardUI()),
              (route) => false);
        }
      } else {
        print("Error: $error");
        Utils.snackBar(error ?? "loginFailed".tr, context);
      }
    }
  }

  forgotPwAction() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
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
                resizeToAvoidBottomInset: true,
                extendBodyBehindAppBar: true,
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
                                    left: 25, right: 25, top: 65, bottom: 65),
                                child: Form(
                                  key: _loginkey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("emailAddressTitle".tr,
                                          style: PoppinsCustomTextStyle.medium
                                              .copyWith(
                                                  fontSize: 16,
                                                  color: AppColor.white)),
                                      const SizedBox(height: 5),
                                      AppTextField(
                                          textController: emailController,
                                          hintText: "emailHint".tr,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'emailEmpty'.tr;
                                            } else if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'validEmail'.tr;
                                            }
                                            return null;
                                          },
                                          icon: null),
                                      const SizedBox(height: 30),
                                      Text("passwordTitle".tr,
                                          style: PoppinsCustomTextStyle.medium
                                              .copyWith(
                                                  fontSize: 16,
                                                  color: AppColor.white)),
                                      const SizedBox(height: 5),
                                      AppTextField(
                                        textController: passwordController,
                                        isObscure: !_passwordVisible,
                                        hintText: "passwordHint".tr,
                                        icon: null,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'passwordEmpty'.tr;
                                          }
                                          return null;
                                        },
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _passwordVisible =
                                                    !_passwordVisible;
                                              });
                                            },
                                            icon: Icon(
                                              _passwordVisible
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                              color: AppColor.labelText,
                                            )),
                                      ),
                                      const SizedBox(height: 13),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 25),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Checkbox(
                                                    value: isRememberMe,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        isRememberMe =
                                                            !isRememberMe;
                                                      });
                                                    },
                                                    activeColor:
                                                        AppColor.darkGreen,
                                                    checkColor: AppColor.white,
                                                    side: const BorderSide(
                                                        color: AppColor.white,
                                                        width: 2)),
                                                Text(
                                                  "rememberMe".tr,
                                                  style: UrbanistCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          color: AppColor.white,
                                                          fontSize: 13),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 7),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: InkWell(
                                                onTap: () {
                                                  forgotPwAction();
                                                },
                                                child: Text(
                                                  "forgotPassword".tr,
                                                  style: UrbanistCustomTextStyle
                                                      .semibold
                                                      .copyWith(
                                                          color: AppColor.black,
                                                          fontSize: 13),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 35),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: AppFillButton(
                                                  onPressed: () {
                                                    loginAction();
                                                  },
                                                  text: "login")),
                                        ],
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
                    viewModel.loading ? const LoaderView() : Container()
                  ],
                ),
              );
            },
          );
        }));
  }
}
