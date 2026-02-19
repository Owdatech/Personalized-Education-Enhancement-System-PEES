import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/API_SERVICES/preference_manager.dart';
import 'package:pees/Common_Screen/Pages/settings_screen.dart';
import 'package:pees/Widgets/AppColor.dart';
import 'package:pees/Widgets/custom_style.dart';

class LanguageSelectButton extends StatefulWidget {
  const LanguageSelectButton({super.key});

  @override
  State<LanguageSelectButton> createState() => _LanguageSelectButtonState();
}

class _LanguageSelectButtonState extends State<LanguageSelectButton> {
  Language langType = Language.english;
  updateLanguage(Locale locale) {
    Get.updateLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth <= 800;
        return Container(
            height: isMobile ? 30 : 50,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                languageUI("english", Language.english),
                languageUI("arabic", Language.arabic),
              ],
            ));
      },
    );
  }

  Widget languageUI(String text, Language type) {
    bool isSelected = type == langType;
    return InkWell(
      onTap: () {
        setState(() {
          langType = type;
          print("Type $type");
        });
        if (type == Language.arabic) {
          setState(() {
            Get.updateLocale(const Locale('ar'));
            // PreferencesManager.shared.removeLanguage();
            PreferencesManager.shared.setLanguage('ar');
          });
        } else {
          setState(() {
            Get.updateLocale(const Locale('en'));
            // PreferencesManager.shared.removeLanguage();
            PreferencesManager.shared.setLanguage('en');
          });
        }
      },
      child: Container(
        height: 50,
        width: 120,
        decoration: BoxDecoration(
            color:
                isSelected == true ? AppColor.buttonGreen : Colors.transparent,
            border: Border.all(color: AppColor.white, width: 2),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(isSelected ? 5 : 0),
              topLeft: Radius.circular(isSelected ? 5 : 0),
              bottomRight: Radius.circular(isSelected ? 0 : 5),
              topRight: Radius.circular(isSelected ? 0 : 5),
            )),
        child: Center(
            child: Text(text.tr,
                style: PoppinsCustomTextStyle.medium
                    .copyWith(fontSize: 18, color: AppColor.white))),
      ),
    );
  }
}
