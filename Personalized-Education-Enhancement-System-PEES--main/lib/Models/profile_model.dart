// class ProfileModel {
//   final String message;
//   final User user;

//   ProfileModel({required this.message, required this.user});

//   factory ProfileModel.fromJson(Map<String, dynamic> json) {
//     return ProfileModel(
//       message: json['message'],
//       user: User.fromJson(json['user']),
//     );
//   }
// }

// class User {
//   final String userId;
//   final String email;
//   final String role;
//   final String status;
//   final String createdAt;
//   final String lastLogin;
//   final String password; // Store securely
//   final ProfileInfo profileInfo;
//   final AssociatedIds associatedIds;
//   final DeliveryMethod deliveryMethod;

//   User({
//     required this.userId,
//     required this.email,
//     required this.role,
//     required this.status,
//     required this.createdAt,
//     required this.lastLogin,
//     required this.password,
//     required this.profileInfo,
//     required this.associatedIds,
//     required this.deliveryMethod,
//   });

//   factory User.fromJson(Map<String, dynamic> json) {
//     return User(
//       userId: json['userId'],
//       email: json['email'],
//       role: json['role'],
//       status: json['status'],
//       createdAt: json['createdAt'],
//       lastLogin: json['last_login'],
//       password: json['password'],
//       profileInfo: ProfileInfo.fromJson(json['profileInfo']),
//       associatedIds: AssociatedIds.fromJson(json['associatedIds']),
//       deliveryMethod: DeliveryMethod.fromJson(json['delivery_method']),
//     );
//   }
// }

// class ProfileInfo {
//   final String name;

//   ProfileInfo({required this.name});

//   factory ProfileInfo.fromJson(Map<String, dynamic> json) {
//     return ProfileInfo(name: json['name']);
//   }
// }

// class AssociatedIds {
//   final String contactNumber;

//   AssociatedIds({required this.contactNumber});

//   factory AssociatedIds.fromJson(Map<String, dynamic> json) {
//     return AssociatedIds(contactNumber: json['contactNumber']);
//   }
// }

// class DeliveryMethod {
//    bool? app;
//    bool? email;
//    bool? sms;

//   DeliveryMethod({
//      this.app,
//      this.email,
//      this.sms

//   });

//   factory DeliveryMethod.fromJson(Map<String, dynamic> json) {
//     return DeliveryMethod(
//       app: json['app'],
//       email: json['email'],
//       sms: json['sms'],

//       );
//   }
// }
import 'dart:convert';

ProfileModel profileModelFromJson(String str) =>
    ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
  String message;
  User user;

  ProfileModel({
    required this.message,
    required this.user,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
        message: json["message"],
        user: User.fromJson(json["user"]),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "user": user.toJson(),
      };
}

class User {
  String contactNumber;
  DateTime createdAt;
  DeliveryMethod deliveryMethod;
  String email;
  DateTime lastLogin;
  String name;
  bool? notificationStatus; // ✅ Make nullable
  dynamic password;
  String role;
  String status;
  String userId;

  User({
    required this.contactNumber,
    required this.createdAt,
    required this.deliveryMethod,
    required this.email,
    required this.lastLogin,
    required this.name,
    this.notificationStatus, // ✅ Optional
    required this.password,
    required this.role,
    required this.status,
    required this.userId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        contactNumber: json["contactNumber"],
        createdAt: DateTime.parse(json["createdAt"]),
        deliveryMethod: DeliveryMethod.fromJson(json["delivery_method"]),
        email: json["email"],
        lastLogin: DateTime.parse(json["last_login"]),
        name: json["name"],
        notificationStatus:
            json["notification_status"] ?? false, // ✅ Provide default value
        password: json["password"],
        role: json["role"],
        status: json["status"],
        userId: json["userId"],
      );

  Map<String, dynamic> toJson() => {
        "contactNumber": contactNumber,
        "createdAt": createdAt.toIso8601String(),
        "delivery_method": deliveryMethod.toJson(),
        "email": email,
        "last_login": lastLogin.toIso8601String(),
        "name": name,
        "notification_status":
            notificationStatus ?? false, // ✅ Ensure non-null value
        "password": password,
        "role": role,
        "status": status,
        "userId": userId,
      };
}

class DeliveryMethod {
  bool app;
  bool email;
  bool sms;

  DeliveryMethod({
    required this.app,
    required this.email,
    required this.sms,
  });

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) => DeliveryMethod(
        app: json["app"],
        email: json["email"],
        sms: json["sms"],
      );

  Map<String, dynamic> toJson() => {
        "app": app,
        "email": email,
        "sms": sms,
      };
}
