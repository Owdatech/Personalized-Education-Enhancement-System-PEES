class AIUser {
   static var shared = AIUser();

  String? currrentLogin;
  String? email;
  String? idToken;
  String? jwtToken;
  String? refreshToken;
  String? userId;

  AIUser({
    this.currrentLogin,
    this.email,
    this.idToken,
    this.jwtToken,
    this.refreshToken,
    this.userId,
  });

  factory AIUser.fromJson(Map<String, dynamic> json){
    return AIUser(
      currrentLogin: json["currrent_login"],
      email: json["email"],
      idToken : json["idToken"],
      jwtToken: json["jwtToken"],
      refreshToken: json["refreshToken"],
      userId: json["user_id"],
    );
  }

  Map<String, dynamic> toJson() => {
        "currrent_login": currrentLogin,
        "email": email,
        "idToken": idToken,
        "jwtToken": jwtToken,
        "refreshToken": refreshToken,
        "user_id": userId
      };
}