import 'package:flutter/material.dart';
import 'package:pees/Widgets/AppColor.dart';

class RegulerTextStyle {
  double fontSize = 20;
  TextStyle init() {
    return TextStyle(fontSize: fontSize);
  }
}

class PoppinsCustomTextStyle {
  static const TextStyle regular = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w400);

  static const TextStyle medium = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w500);

  static const TextStyle semibold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600);

  static const TextStyle bold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w700);
}


class UrbanistCustomTextStyle {
  static const TextStyle regular = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w400);

  static const TextStyle medium = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w500);

  static const TextStyle semibold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w600);

  static const TextStyle bold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'Urbanist',
      fontWeight: FontWeight.w700);
}


class NotoSansArabicCustomTextStyle {
  static const TextStyle regular = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.w400);

  static const TextStyle medium = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.w500);

  static const TextStyle semibold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.w600);

  static const TextStyle bold = TextStyle(
      fontSize: 20,
      color: AppColor.text,
      fontFamily: 'NotoSansArabic',
      fontWeight: FontWeight.w700);
}

