import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';

class AppFillButton extends StatelessWidget {
  AppFillButton({required this.onPressed, required this.text, super.key});

  void Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        // height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColor.buttonGreen,
          boxShadow: const [
            BoxShadow(
              color: AppColor.buttonShadow,
              offset: Offset(0, 10),
              blurRadius: 15,
            )
          ],
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 7 : 15.0, vertical: isMobile ? 7 : 15.0),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: EdgeInsets.only(
                top: isMobile ? 3 : 6,
                bottom: isMobile ? 3 : 6,
                left: 20,
                right: 20),
            child: Text(text.tr,
                textAlign: TextAlign.center,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.white,
                    fontSize: fontSizeProvider.fontSize)),
          ),
        ),
      );
    });
  }
}

class AppFillButton2 extends StatelessWidget {
  AppFillButton2({required this.onPressed, required this.text, super.key});

  void Function() onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        // height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: AppColor.buttonGreen,
          boxShadow: const [
            BoxShadow(
              color: AppColor.buttonShadow,
              offset: Offset(0, 10),
              blurRadius: 15,
            )
          ],
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 7 : 15.0, vertical: isMobile ? 7 : 15.0),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: EdgeInsets.only(
                top: isMobile ? 3 : 6,
                bottom: isMobile ? 3 : 6,
                left: 20,
                right: 20),
            child: Text(text.tr,
                textAlign: TextAlign.center,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.white,
                    fontSize: fontSizeProvider.fontSize)),
          ),
        ),
      );
    });
  }
}

class AppFillButton3 extends StatelessWidget {
  AppFillButton3(
      {required this.onPressed,
      required this.text,
      required this.color,
      this.textColor,
      super.key});

  void Function() onPressed;
  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        // height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: color,
          // boxShadow: const [
          //   BoxShadow(
          //     color: AppColor.buttonShadow,
          //     offset: Offset(0, 10),
          //     blurRadius: 15,
          //   )
          // ],
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 7 : 15.0, vertical: isMobile ? 7 : 15.0),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: EdgeInsets.only(
                top: isMobile ? 3 : 6,
                bottom: isMobile ? 3 : 6,
                left: 20,
                right: 20),
            child: Text(text.tr,
                textAlign: TextAlign.center,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: textColor ?? AppColor.white,
                    fontSize: fontSizeProvider.fontSize)),
          ),
        ),
      );
    });
  }
}

class AppFillButtonBoarder extends StatelessWidget {
  AppFillButtonBoarder(
      {required this.onPressed,
      required this.text,
      required this.color,
      super.key});

  void Function() onPressed;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return LayoutBuilder(builder: (context, constraints) {
      bool isMobile = constraints.maxWidth <= 800;
      return Container(
        // height: 40,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColor.buttonGreen,
            border: Border.all(color: AppColor.white, width: 2)
            // boxShadow: const [
            //   BoxShadow(
            //     color: AppColor.buttonShadow,
            //     offset: Offset(0, 10),
            //     blurRadius: 15,
            //   )
            // ],
            ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide.none,
            padding: EdgeInsets.symmetric(
                horizontal: 15.0, vertical: isMobile ? 7 : 15.0),
          ),
          onPressed: onPressed,
          child: Padding(
            padding: EdgeInsets.only(
                top: isMobile ? 3 : 6,
                bottom: isMobile ? 3 : 6,
                left: 20,
                right: 20),
            child: Text(text.tr,
                textAlign: TextAlign.center,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                    color: AppColor.white,
                    fontSize: fontSizeProvider.fontSize)),
          ),
        ),
      );
    });
  }
}
