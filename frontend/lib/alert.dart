class Alert {
  final String id;
  final String ts;
  final String msg;
  final int    level;
  final String location;
  final String? imgUrl;
  final bool   resolved;

  Alert({
    required this.id,
    required this.ts,
    required this.msg,
    required this.level,
    required this.location,
    this.imgUrl,
    this.resolved = false,
  });

  factory Alert.fromJson(Map<String, dynamic> j) => Alert(
        id:        j['id'],
        ts:        j['ts'],
        msg:       j['msg'],
        level:     (j['level'] as num).toInt(),
        location:  j['location'],
        imgUrl:    j['imgUrl'],
        resolved:  j['resolved'] ?? false,
      );

  Alert copyWith({bool? resolved}) => Alert(
        id: id,
        ts: ts,
        msg: msg,
        level: level,
        location: location,
        imgUrl: imgUrl,
        resolved: resolved ?? this.resolved,
      );
}

