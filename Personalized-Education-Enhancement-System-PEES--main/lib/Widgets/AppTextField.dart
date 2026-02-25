import 'package:flutter/material.dart';
import 'package:pees/Common_Screen/Pages/themeWidget.dart';
import 'package:pees/Common_Screen/Services/font_size_provider.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/custom_style.dart';
import 'package:provider/provider.dart';

class AppTextField extends StatelessWidget {
  int? maxLength;
  final TextEditingController textController;
  final String hintText;
  final IconData? icon;
  IconButton? suffixIcon;
  Widget? prefix;
  bool isObscure;
  bool enabled;
  bool readOnly;
  EdgeInsets insets;
  TextAlign textAlignment;
  TextInputType inputType;
  TextInputAction? textInputAction;
  FocusNode? focusNode;
  TextCapitalization? textCapitalization;
  Color? backgroundColor;
  Function(String)? onSubmit;
  Function(String)? onChange;
  Function()? onTapped;
  Color? borderColor;
  final String? Function(String?)? validator;

  AppTextField({
    Key? key,
    this.maxLength,
    required this.textController,
    required this.hintText,
    required this.icon,
    this.insets = const EdgeInsets.only(left: 0, right: 0),
    this.textAlignment = TextAlign.left,
    this.inputType = TextInputType.text,
    this.enabled = true,
    this.isObscure = false,
    this.readOnly = false,
    this.suffixIcon,
    this.prefix,
    this.backgroundColor,
    this.focusNode,
    this.textInputAction,
    this.textCapitalization,
    this.onSubmit,
    this.onChange,
    this.onTapped,
    this.borderColor,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      margin: insets,
      child: TextFormField(
        readOnly: readOnly ? true : false,
        maxLength: maxLength,
        enabled: enabled ? true : false,
        obscureText: isObscure ? true : false,
        controller: textController,
        textCapitalization: textCapitalization == null
            ? TextCapitalization.none
            : textCapitalization!,
        style: PoppinsCustomTextStyle.regular.copyWith(
            fontSize: fontSizeProvider.fontSize, color: AppColor.white),
        focusNode: focusNode,
        textAlign: textAlignment,
        keyboardType: inputType,
        textInputAction: textInputAction,
        onChanged: onChange,
        onTap: onTapped,
        decoration: InputDecoration(
            fillColor: AppColor.textField,
            filled: true,
            counter: const Offstage(),
            suffixIcon: suffixIcon,
            prefix: prefix,
            //hintText,
            hintText: hintText,
            contentPadding: EdgeInsets.only(left: 33),
            hintStyle: PoppinsCustomTextStyle.medium.copyWith(
                color: AppColor.labelText,
                fontSize: fontSizeProvider.fontSize), //AppColor.textHintColor
            // prefixIcon
            prefixIcon:
                icon != null ? Icon(icon, color: AppColor.textGrey) : null,
            // focusedBorder
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    width: 1.5, color: AppColor.accentPrimary)),
            //enabled Border
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.lightGrey)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.lightGrey)),

            // border
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.lightGrey))),
      ),
    );
  }
}

class AppFillTextField extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final IconData? icon;
  bool isObscure;
  bool enabled;
  IconButton? suffixIcon;
  Widget? prefix;
  EdgeInsets insets;
  FocusNode? focusNode;
  bool readOnly;
  TextAlign textAlignment;
  TextInputType inputType;
  int? maxLines;
  int? maxLength;
  Color? backgroundColor;
  TextCapitalization? textCapitalization;
  final String? Function(String?)? validator;
  String? color;
  AppFillTextField(
      {Key? key,
      required this.textController,
      required this.hintText,
      required this.icon,
      this.insets = const EdgeInsets.only(left: 0, right: 0),
      this.textAlignment = TextAlign.left,
      this.inputType = TextInputType.text,
      this.isObscure = false,
      this.enabled = true,
      this.focusNode,
      this.readOnly = false,
      this.suffixIcon,
      this.prefix,
      this.maxLines,
      this.maxLength,
      this.backgroundColor,
      this.textCapitalization,
      this.validator,
      this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    return Container(
      margin: insets,
      height: 25,
      child: TextField(
        enabled: enabled,
        obscureText: isObscure ? true : false,
        controller: textController,
        maxLength: maxLength,
        focusNode: focusNode,
        textCapitalization: textCapitalization == null
            ? TextCapitalization.none
            : textCapitalization!,
        style: NotoSansArabicCustomTextStyle.medium.copyWith(
            fontSize: 13,
            color: color == "true" ? Colors.grey.shade400 : AppColor.textGrey),
        textAlign: textAlignment,
        keyboardType: inputType,
        readOnly: readOnly ? true : false,
        maxLines: maxLines,
        enableIMEPersonalizedLearning: false,
        decoration: InputDecoration(
          fillColor: AppColor.textField,
          contentPadding: EdgeInsets.only(left: 20),
          //  color: borderColor != null
          //             ? AppColor.redBorder
          //             : AppColor.greyBorder
          filled: true,
          suffixIcon: suffixIcon,
          prefix: prefix,
          //hintText,
          hintText: hintText,
          hintStyle: NotoSansArabicCustomTextStyle.regular.copyWith(
              color: themeManager.isHighContrast
                  ? AppColor.black
                  : AppColor.labelText,
              fontSize: 13),
          // prefixIcon
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,

          // border
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2),
              borderSide: BorderSide(color: AppColor.textGrey)),
        ),
      ),
    );
  }
}

// With shadow
/*
class AppTextField extends StatelessWidget {
  final TextEditingController textController;
  final String hintText;
  final IconData? icon;
  bool isObscure;
  EdgeInsets insets;
  TextAlign textAlignment;

  AppTextField({Key? key,
    required this.textController,
    required this.hintText,
    required this.icon,
    this.insets = const EdgeInsets.only(left: 20, right: 20),
    this.textAlignment = TextAlign.left,
    this.isObscure=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(

      margin: insets,
      decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            const BoxShadow(
              color: Colors.grey,
              offset: Offset(4, 4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 15,
              spreadRadius: 1,
            ),

          ]
      ),
      child: TextField(
        obscureText: isObscure?true:false,
        controller: textController,
        decoration: InputDecoration(
            fillColor: Colors.grey[300],
            filled: true,
            //hintText,
            hintText: hintText,
            // prefixIcon
            prefixIcon: icon != null ? Icon(icon, color:Colors.grey) : null,
            
            //focusedBorder
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  width: 0.0,
                  color:Colors.white,
                )
            ),
            //enabled Border
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  width: 0.0,
                  color:Colors.white,
                )
            ),
            // enabledBorder
            //
            // border
            border:OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),

            )
        ),
      ),
    );
  }
}
*/

class AppTextFieldBlank extends StatelessWidget {
  int? maxLength;
  final TextEditingController textController;
  final String hintText;
  final IconData? icon;
  IconButton? suffixIcon;
  Widget? prefix;
  bool isObscure;
  bool enabled;
  bool readOnly;
  EdgeInsets insets;
  TextAlign textAlignment;
  TextInputType inputType;
  TextInputAction? textInputAction;
  FocusNode? focusNode;
  TextCapitalization? textCapitalization;
  Color? backgroundColor;
  Function(String)? onSubmit;
  Function(String)? onChange;
  Function()? onTapped;
  Color? borderColor;

  AppTextFieldBlank({
    Key? key,
    this.maxLength,
    required this.textController,
    required this.hintText,
    required this.icon,
    this.insets = const EdgeInsets.only(left: 0, right: 0),
    this.textAlignment = TextAlign.left,
    this.inputType = TextInputType.text,
    this.enabled = true,
    this.isObscure = false,
    this.readOnly = false,
    this.suffixIcon,
    this.prefix,
    this.backgroundColor,
    this.focusNode,
    this.textInputAction,
    this.textCapitalization,
    this.onSubmit,
    this.onChange,
    this.onTapped,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    return Container(
      margin: insets,
      child: TextField(
        readOnly: readOnly ? true : false,
        maxLength: maxLength,
        enabled: enabled ? true : false,
        obscureText: isObscure ? true : false,
        controller: textController,
        textCapitalization: textCapitalization == null
            ? TextCapitalization.none
            : textCapitalization!,
        style: PoppinsCustomTextStyle.regular.copyWith(
            fontSize: fontSizeProvider.fontSize, color: AppColor.black),
        focusNode: focusNode,
        textAlign: textAlignment,
        keyboardType: inputType,
        textInputAction: textInputAction,
        onChanged: onChange,
        onTap: onTapped,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
            fillColor: Colors.transparent,
            filled: true,
            counter: const Offstage(),
            suffixIcon: suffixIcon,
            prefix: prefix,
            //hintText,
            hintText: hintText,
            contentPadding: EdgeInsets.only(left: 25),
            hintStyle: PoppinsCustomTextStyle.regular.copyWith(
                color: themeManager.isHighContrast
                    ? Colors.grey.shade700
                    : AppColor.labelText,
                fontSize: fontSizeProvider.fontSize), //AppColor.textHintColor
            // prefixIcon
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            // focusedBorder
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.black)),
            //enabled Border
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.black)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.black)),

            // border
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.black))),
      ),
    );
  }
}

class MarksTextField extends StatelessWidget {
  int? maxLength;
  final TextEditingController textController;
  final String hintText;
  final IconData? icon;
  IconButton? suffixIcon;
  Widget? prefix;
  bool isObscure;
  bool enabled;
  bool readOnly;
  EdgeInsets insets;
  TextAlign textAlignment;
  TextInputType inputType;
  TextInputAction? textInputAction;
  FocusNode? focusNode;
  TextCapitalization? textCapitalization;
  Color? backgroundColor;
  Function(String)? onSubmit;
  Function(String)? onChange;
  Function()? onTapped;
  Color? borderColor;

  MarksTextField({
    Key? key,
    this.maxLength,
    required this.textController,
    required this.hintText,
    required this.icon,
    this.insets = const EdgeInsets.only(left: 0, right: 0),
    this.textAlignment = TextAlign.left,
    this.inputType = TextInputType.text,
    this.enabled = true,
    this.isObscure = false,
    this.readOnly = false,
    this.suffixIcon,
    this.prefix,
    this.backgroundColor,
    this.focusNode,
    this.textInputAction,
    this.textCapitalization,
    this.onSubmit,
    this.onChange,
    this.onTapped,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: insets,
      width: 36,
      height: 36,
      child: TextField(
        readOnly: readOnly ? true : false,
        maxLength: maxLength,
        enabled: enabled ? true : false,
        obscureText: isObscure ? true : false,
        controller: textController,
        textCapitalization: textCapitalization == null
            ? TextCapitalization.none
            : textCapitalization!,
        style: PoppinsCustomTextStyle.regular
            .copyWith(fontSize: 13, color: AppColor.black),
        focusNode: focusNode,
        textAlign: textAlignment,
        keyboardType: inputType,
        textInputAction: textInputAction,
        onChanged: onChange,
        onTap: onTapped,
        onSubmitted: onSubmit,
        decoration: InputDecoration(
            fillColor: Colors.transparent,
            filled: true,
            counter: const Offstage(),
            suffixIcon: suffixIcon,
            prefix: prefix,
            //hintText,
            hintText: hintText,
            // contentPadding: EdgeInsets.only(left: 25),
            hintStyle: PoppinsCustomTextStyle.medium.copyWith(
                color: AppColor.labelText,
                fontSize: 18), //AppColor.textHintColor
            // prefixIcon
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            // focusedBorder
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.buttonGreen)),
            //enabled Border
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.buttonGreen)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.buttonGreen)),
            // border
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide:
                    const BorderSide(width: 1.0, color: AppColor.buttonGreen))),
      ),
    );
  }
}
