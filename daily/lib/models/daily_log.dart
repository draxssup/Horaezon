class DailyLog {
  int? id; 
  String date;
  int mood;
  String text;
  String? imagePath;
  String? city;

  DailyLog({
    this.id,
    required this.date,
    required this.mood,
    required this.text,
    this.imagePath,
    this.city,
  });

  factory DailyLog.fromJson(Map<String, dynamic> json) => DailyLog(
        id: json['id'],
        date: json['date'],
        mood: json['mood'],
        text: json['text'],
        imagePath: json['imagePath'],
        city: json['city'],
      );

  Map<String, dynamic> toJson() => {
        'date': date,
        'mood': mood,
        'text': text,
        'imagePath': imagePath,
        'city': city,
      };
}
