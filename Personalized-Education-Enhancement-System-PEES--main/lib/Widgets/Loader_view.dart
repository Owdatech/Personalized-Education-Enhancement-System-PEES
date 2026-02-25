import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pees/Widgets/AppColor.dart';

class LoaderView extends StatelessWidget {
  const LoaderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center, // Center vertically
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.buttonGreen.withOpacity(0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppColor.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "loadingPleaseWait".tr,
            style: TextStyle(color: AppColor.white),
          ),
        ],
      ),
    );
  }
}
