/*
 * BSD 3-Clause License

    Copyright (c) 2020, RAY OKAAH - MailTo: ray@flutterengineer.com, Twitter: Rayscode
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
    FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 */

// class WooUser {
//   final int? id;
//   final String? email;
//   final String? username;
//   final String? password;
//   final String? firstName;
//   final String? lastName;
//   final String? name;

//   WooUser(
//       {this.id,
//       required String this.email,
//       required String this.username,
//       required this.password,
//       this.firstName,
//       this.lastName,
//       this.name});

//   WooUser.fromJson(Map<String, dynamic> data)
//       : id = data['id'],
//         email = data['email'],
//         username = data['username'],
//         password = data['password'],
//         firstName = data['first_name'],
//         lastName = data['last_name'],
//         name = data['name'];

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'email': email,
//       'username': username,
//       'password': password,
//       'first_name': firstName,
//       'last_name': lastName,
//       'name': name,
//     };
//   }

//   @override
//   toString() => toJson().toString();
// }
class User {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? userRole;
  String? userStatus;
  String? accessToken;
  String? refreshToken;

  User({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.userRole,
    this.userStatus,
    this.accessToken,
    this.refreshToken,
  });

  User.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    phone = json['phone']?.toString();
    userRole = json['userRole']?.toString();
    userStatus = json['userStatus']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['phone'] = phone;
    data['userRole'] = userRole;
    data['userStatus'] = userStatus;
    return data;
  }

  @override
  String toString() => toJson().toString();

  String get displayName {
    return name ?? email ?? 'User';
  }

  String get initials {
    if (name != null && name!.isNotEmpty) {
      final parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name![0].toUpperCase();
    }
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    return 'U';
  }
}
