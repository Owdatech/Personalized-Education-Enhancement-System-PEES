import 'package:flutter/material.dart';

class Utils {
  // static var timerUpdateLocal; // for every 2 min update local notification {other user reminder update}

  static double averageRating(List<int> rating) {
    var avgRating = 0;
    for (int i = 0; i < rating.length; i++) {
      avgRating = avgRating + rating[i];
    }
    return double.parse((avgRating / rating.length).toStringAsFixed(1));
  }

  //On pressing done from keyboard it should move to the next text field
  static void fieldFocusChange(
    BuildContext context,
    FocusNode currentNode,
    FocusNode nextNode,
  ) {
    currentNode.unfocus();
    FocusScope.of(context).requestFocus(nextNode);
  }

  //For showing toast
  // static toastMessage(String message) {
  //   Fluttertoast.showToast(
  //     msg: message,
  //     toastLength: Toast.LENGTH_SHORT,
  //   );
  // }

  static void alertShow(String message, BuildContext context) {
    // showFlushbar(
    //   context: context,
    //   flushbar: Flushbar(
    //     message: message,
    //     forwardAnimationCurve: Curves.decelerate,
    //     margin: const EdgeInsets.all(15),
    //     duration: const Duration(seconds: 3),
    //     reverseAnimationCurve: Curves.easeInOut,
    //     icon: const Icon(Icons.error),
    //   )..show(context),
    // );
  }

  static snackBar(String message, BuildContext context) {
    return ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, textAlign: TextAlign.center)));
  }
}