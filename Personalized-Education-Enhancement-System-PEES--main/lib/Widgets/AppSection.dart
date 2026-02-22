import 'package:flutter/material.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColor.buttonGreen,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: NotoSansArabicCustomTextStyle.semibold.copyWith(
                  color: AppColor.white,
                  fontSize: fontSizeProvider.fontSize + 1,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColor.extralightGrey,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(5),
              bottomLeft: Radius.circular(5),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
