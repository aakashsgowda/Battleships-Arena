class GameInfo {
  final int id;
  final List<String> ships;
  final List<String> shots;
  final List<String> sunk;
  final List<String> wrecks;
  final int status;

  GameInfo({
    required this.id,
    required this.ships,
    required this.shots,
    required this.sunk,
    required this.wrecks,
    required this.status,
  });

  // Factory method to create a GameInfo object from a JSON map
  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json['id'],
      ships: List<String>.from(json['ships']),
      shots: List<String>.from(json['shots']),
      sunk: List<String>.from(json['sunk']),
      wrecks: List<String>.from(json['wrecks']),
      status: json['status'],
    );
  }
}
