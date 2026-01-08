class ReadingRecord {
  final String date;
  final bool swaminiVato;
  final bool vachnamrut;
  final DateTime? timestamp;

  ReadingRecord({required this.date, this.swaminiVato = false, this.vachnamrut = false, this.timestamp});

  Map<String, dynamic> toMap() {
    return {'date': date, 'swaminiVato': swaminiVato, 'vachnamrut': vachnamrut, 'timestamp': timestamp?.toIso8601String()};
  }

  factory ReadingRecord.fromMap(Map<String, dynamic> map) {
    return ReadingRecord(
      date: map['date'] ?? '',
      swaminiVato: map['swaminiVato'] ?? false,
      vachnamrut: map['vachnamrut'] ?? false,
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) : null,
    );
  }

  ReadingRecord copyWith({String? date, bool? swaminiVato, bool? vachnamrut, DateTime? timestamp}) {
    return ReadingRecord(
      date: date ?? this.date,
      swaminiVato: swaminiVato ?? this.swaminiVato,
      vachnamrut: vachnamrut ?? this.vachnamrut,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
