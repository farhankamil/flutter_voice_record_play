import 'package:hive/hive.dart';

part 'recording.g.dart';

@HiveType(typeId: 1)
class Recording {
  @HiveField(0)
  final String filePath;

  @HiveField(1)
  final DateTime timestamp;

  Recording({required this.filePath, required this.timestamp});
}
