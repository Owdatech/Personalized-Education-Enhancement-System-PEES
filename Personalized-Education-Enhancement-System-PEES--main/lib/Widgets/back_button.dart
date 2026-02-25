import 'package:flutter/material.dart';
import 'package:pees/Widgets/AppColor.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth <= 800;
        return Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(
                  left: isMobile ? 5 : 45, top: isMobile ? 0 : 30),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context, true);
                },
                child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColor.accentBorder, width: 0.8),
                        color: AppColor.panelDark),
                    child: const Padding(
                      padding: EdgeInsets.all(5.0),
                      child: Icon(Icons.arrow_back,
                          size: 30, color: AppColor.white),
                    )),
              ),
            ));
      },
    );
  }
}
