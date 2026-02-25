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
  static const Color _bgDark = Color(0xFF0D111B);
  static const Color _bgDarkSoft = Color(0xFF171A22);
  static const Color _accent = Color(0xFF8E7CFF);
  static const Color _textMuted = Color(0xFFB2B6C6);

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
                backgroundColor: _bgDark,
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_bgDark, _bgDarkSoft],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -120,
                      left: -80,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withValues(alpha: 0.20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -160,
                      right: -100,
                      child: Container(
                        width: 380,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accent.withValues(alpha: 0.14),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.08,
                        child: Image.asset(
                          AppImage.loginBackground,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(isMobile ? 20 : 28,
                              isMobile ? 16 : 20, isMobile ? 20 : 28, 18),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1020),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    AppColor.panelDark.withValues(alpha: 0.84),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: AppColor.lightGrey, width: 1),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x55000000),
                                    blurRadius: 28,
                                    offset: Offset(0, 16),
                                  )
                                ],
                              ),
                              padding: EdgeInsets.all(isMobile ? 18 : 26),
                              child: isMobile
                                  ? _buildLoginForm(
                                      isMobile: true, showBranding: true)
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: _buildBrandingPanel(),
                                        ),
                                        const SizedBox(width: 26),
                                        SizedBox(
                                          width: 430,
                                          child: _buildLoginForm(
                                              isMobile: false,
                                              showBranding: false),
                                        )
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 15, right: 15),
                      child: LanguageSelectButton(),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom + 10),
                        child: Text.rich(
                          textAlign: TextAlign.center,
                          TextSpan(children: [
                            TextSpan(
                              text: "copyrightInformation".tr,
                              style: PoppinsCustomTextStyle.regular
                                  .copyWith(fontSize: 13, color: _textMuted),
                            ),
                            TextSpan(
                              text: ' / ',
                              style: PoppinsCustomTextStyle.regular
                                  .copyWith(fontSize: 13, color: _textMuted),
                            ),
                            TextSpan(
                                text: "termsandPrivacyPolicy".tr,
                                style: PoppinsCustomTextStyle.regular
                                    .copyWith(fontSize: 13, color: _textMuted))
                          ]),
                        ),
                      ),
                    ),
                    viewModel.loading ? const LoaderView() : Container()
                  ],
                ),
              );
            },
          );
        }));
  }

  Widget _buildBrandingPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "appName".tr,
            style: PoppinsCustomTextStyle.bold
                .copyWith(fontSize: 40, color: AppColor.white),
          ),
          const SizedBox(height: 14),
          Text(
            "loginHeroSubtitle".tr,
            style: PoppinsCustomTextStyle.regular
                .copyWith(fontSize: 17, color: _textMuted),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.panelDarkSoft.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColor.lightGrey, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_graph_rounded, size: 18, color: _accent),
                const SizedBox(width: 10),
                Text(
                  "loginHeroBadge".tr,
                  style: PoppinsCustomTextStyle.medium
                      .copyWith(fontSize: 14, color: AppColor.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm({required bool isMobile, required bool showBranding}) {
    return Form(
      key: _loginkey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBranding) ...[
            Text(
              "appName".tr,
              style: PoppinsCustomTextStyle.bold
                  .copyWith(fontSize: 30, color: AppColor.white),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            "login".tr,
            style: PoppinsCustomTextStyle.bold
                .copyWith(fontSize: 30, color: AppColor.white),
          ),
          const SizedBox(height: 6),
          Text(
            "loginFormSubtitle".tr,
            style: PoppinsCustomTextStyle.regular
                .copyWith(fontSize: 14, color: _textMuted),
          ),
          const SizedBox(height: 24),
          Text("emailAddressTitle".tr,
              style: PoppinsCustomTextStyle.medium
                  .copyWith(fontSize: 15, color: AppColor.white)),
          const SizedBox(height: 6),
          AppTextField(
              textController: emailController,
              hintText: "emailHint".tr,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'emailEmpty'.tr;
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                    .hasMatch(value)) {
                  return 'validEmail'.tr;
                }
                return null;
              },
              icon: Icons.alternate_email_rounded),
          const SizedBox(height: 18),
          Text("passwordTitle".tr,
              style: PoppinsCustomTextStyle.medium
                  .copyWith(fontSize: 15, color: AppColor.white)),
          const SizedBox(height: 6),
          AppTextField(
            textController: passwordController,
            isObscure: !_passwordVisible,
            hintText: "passwordHint".tr,
            icon: Icons.lock_outline_rounded,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'passwordEmpty'.tr;
              }
              return null;
            },
            suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
                icon: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppColor.labelText,
                )),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Transform.scale(
                scale: 0.92,
                child: Checkbox(
                    value: isRememberMe,
                    onChanged: (value) {
                      setState(() {
                        isRememberMe = !isRememberMe;
                      });
                    },
                    activeColor: _accent,
                    checkColor: AppColor.white,
                    side:
                        const BorderSide(color: AppColor.lightGrey, width: 1)),
              ),
              Text(
                "rememberMe".tr,
                style: UrbanistCustomTextStyle.semibold
                    .copyWith(color: AppColor.white, fontSize: 13),
              ),
              const Spacer(),
              InkWell(
                onTap: forgotPwAction,
                child: Text(
                  "forgotPassword".tr,
                  style: UrbanistCustomTextStyle.semibold
                      .copyWith(color: _accent, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AppFillButton(
              onPressed: loginAction,
              text: "login",
            ),
          ),
          if (isMobile) const SizedBox(height: 14),
        ],
      ),
    );
  }
}
