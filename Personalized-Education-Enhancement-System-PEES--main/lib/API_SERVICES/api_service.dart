
// import 'package:flutter/material.dart';
// import 'package:pees/API_SERVICES/config.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:pees/Models/user_model.dart';


// class Success {
//   int code;
//   Object successResponse;
//   Success({required this.code, required this.successResponse});
// }

// class Failure {
//   int code;
//   Object errorResponse;
//   Failure({required this.code, required this.errorResponse});
// }

// class ApiService {
//   static final shared = ApiService();
//   Future<Object> callPostApi(String endUrl, Map<String, dynamic>? jsonBody,
//       {bool headersRequired = true}) async {
//     final url = Uri.parse(Config.baseURL + endUrl);
//     Map<String, String>? headers = {
//       "Content-Type": "application/json",
//     };
//     if (headersRequired) {
//       headers['Authorization'] = 'Bearer ${AIUser.shared.token}';
//       debugPrint('TOKEN : ${AIUser.shared.token}');
//     }
//     String? strBody = jsonEncode(jsonBody);
//     debugPrint("\nAPI: $url");
//     debugPrint("PARAM: $strBody");
//     debugPrint("HEADER: $headers");
//     dynamic responseJson;
//     try {
//       final response = await http.post((url), headers: headers, body: strBody);
//       responseJson = jsonDecode(response.body);
//       debugPrint("RESPONSE: $url");
//       debugPrint(response.body);
//       if (responseJson["status_code"] == 200) {
//         return Success(successResponse: responseJson, code: 200);
//       }
//       return Failure(
//           code: responseJson["status_code"], errorResponse: responseJson["msg"]);
//     } on HttpException {
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } on SocketException {
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } catch (error) {
//       return Failure(
//           code: 500, errorResponse: 'Something went wrong, Please try again');
//     }
//   }

//   Future<Object> callGetApi(String endUrl,
//       {bool headersRequired = true}) async {
//     final url = Uri.parse(Config.baseURL + endUrl);
//     final headers = <String, String>{'Content-Type': 'application/json'};

//     if (headersRequired) {
//       headers['Authorization'] = 'Bearer ${AIUser.shared.token}';
//     }
//     debugPrint("\nAPI: $url");
//     debugPrint("HEADER: $headers");

//     dynamic responseJson;
//     try {
//       final response = await http.get(url, headers: headers);
//       responseJson = jsonDecode(response.body);
//       debugPrint("RESPONSE: $url");
//       debugPrint(response.body);
//       if (responseJson["statuscode"] == 200) {
//         return Success(successResponse: responseJson, code: 200);
//       }
//       return Failure(
//           code: responseJson["statuscode"], errorResponse: responseJson["msg"]);
//     } on HttpException {
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } on SocketException {
//       //throw Exception('No Internet Connection');
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } catch (error) {
//       return Failure(
//           code: 500, errorResponse: 'Something went wrong, Please try again');
//     }
//   }

//   Future<Object> callDeleteApi(String endUrl,
//       {bool headersRequired = true}) async {
//     final url = Uri.parse(Config.baseURL + endUrl);
//     final headers = <String, String>{'Content-Type': 'application/json'};

//     if (headersRequired) {
//       headers['Authorization'] = 'Bearer ${AIUser.shared.token}';
//     }

//     debugPrint("\nAPI: $url");
//     debugPrint("HEADER: $headers");

//     dynamic responseJson;
//     try {
//       final response = await http.delete(url, headers: headers);
//       responseJson = jsonDecode(response.body);
//       debugPrint("RESPONSE: $url");
//       debugPrint(response.body);
//       if (responseJson["statuscode"] == 200) {
//         return Success(successResponse: responseJson, code: 200);
//       }
//       return Failure(
//           code: responseJson["statuscode"], errorResponse: responseJson["msg"]);
//     } on HttpException {
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } on SocketException {
//       return Failure(code: 404, errorResponse: 'No Internet Connection');
//     } catch (error) {
//       return Failure(
//           code: 500, errorResponse: 'Something went wrong, Please try again');
//     }
//   }
// }
