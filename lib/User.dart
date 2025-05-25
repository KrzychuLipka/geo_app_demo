import 'package:latlong2/latlong.dart';

class User {
  final String firstName;
  final String lastName;
  final LatLng position;

  User({
    required this.firstName,
    required this.lastName,
    required this.position,
  });

  factory User.fromJson(
    Map<String, dynamic> json,
  ) {
    final positionString = json['position'] as String;
    final coordinates = positionString
        .replaceAll('POINT (', '')
        .replaceAll(')', '')
        .split(' ')
        .map(double.parse)
        .toList();

    return User(
      firstName: json['first_name'],
      lastName: json['last_name'],
      position: LatLng(coordinates[1], coordinates[0]),
    );
  }
}
