import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Estado de bienestar guardado localmente por usuario.
///
/// Complementa los datos del backend con información que no requiere
/// servidor: meta diaria, check-in de ánimo y sesiones completadas en el día.
class WellnessData {
  final int dailyGoal;
  final Map<String, MoodEntry> moods;
  final Map<String, SessionSummary> sessions;

  const WellnessData({
    this.dailyGoal = 3,
    this.moods = const {},
    this.sessions = const {},
  });

  factory WellnessData.empty() => const WellnessData();

  SessionSummary todaySessions() =>
      sessions[WellnessService.dateKey(DateTime.now())] ??
      const SessionSummary();

  MoodEntry? todayMood() =>
      moods[WellnessService.dateKey(DateTime.now())];

  int get streak {
    var count = 0;
    var cursor = DateTime.now();
    final todayKey = WellnessService.dateKey(cursor);
    if ((sessions[todayKey]?.count ?? 0) == 0) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    while (true) {
      final item = sessions[WellnessService.dateKey(cursor)];
      if (item == null || item.count <= 0) break;
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  WellnessData copyWith({
    int? dailyGoal,
    Map<String, MoodEntry>? moods,
    Map<String, SessionSummary>? sessions,
  }) {
    return WellnessData(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      moods: moods ?? this.moods,
      sessions: sessions ?? this.sessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyGoal': dailyGoal,
      'moods': moods.map((key, value) => MapEntry(key, value.toJson())),
      'sessions': sessions.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory WellnessData.fromJson(Map<String, dynamic> json) {
    final moods = <String, MoodEntry>{};
    final rawMoods = json['moods'];
    if (rawMoods is Map) {
      rawMoods.forEach((key, value) {
        if (value is Map) {
          moods['$key'] = MoodEntry.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final sessions = <String, SessionSummary>{};
    final rawSessions = json['sessions'];
    if (rawSessions is Map) {
      rawSessions.forEach((key, value) {
        if (value is Map) {
          sessions['$key'] = SessionSummary.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final goal = json['dailyGoal'];
    return WellnessData(
      dailyGoal: goal is int ? goal : int.tryParse('$goal') ?? 3,
      moods: moods,
      sessions: sessions,
    );
  }
}

class SessionSummary {
  final int count;
  final int minutes;

  const SessionSummary({this.count = 0, this.minutes = 0});

  Map<String, dynamic> toJson() => {'count': count, 'minutes': minutes};

  factory SessionSummary.fromJson(Map<String, dynamic> json) {
    return SessionSummary(
      count: json['count'] is int
          ? json['count'] as int
          : int.tryParse('${json['count']}') ?? 0,
      minutes: json['minutes'] is int
          ? json['minutes'] as int
          : int.tryParse('${json['minutes']}') ?? 0,
    );
  }
}

class MoodEntry {
  final int score;
  final String note;

  const MoodEntry({required this.score, this.note = ''});

  Map<String, dynamic> toJson() => {'score': score, 'note': note};

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      score: json['score'] is int
          ? json['score'] as int
          : int.tryParse('${json['score']}') ?? 3,
      note: (json['note'] ?? '').toString(),
    );
  }
}

class MoodOption {
  final int score;
  final String emoji;
  final String label;
  final int color;

  const MoodOption({
    required this.score,
    required this.emoji,
    required this.label,
    required this.color,
  });

  static const List<MoodOption> options = [
    MoodOption(score: 1, emoji: '😖', label: 'Muy cargado', color: 0xFFEF4444),
    MoodOption(score: 2, emoji: '😕', label: 'Cansado', color: 0xFFF59E0B),
    MoodOption(score: 3, emoji: '😐', label: 'Normal', color: 0xFF64748B),
    MoodOption(score: 4, emoji: '🙂', label: 'Bien', color: 0xFF1F7FC0),
    MoodOption(score: 5, emoji: '😄', label: 'Excelente', color: 0xFF16A34A),
  ];

  static MoodOption forScore(int score) {
    return options.firstWhere(
      (option) => option.score == score,
      orElse: () => options[2],
    );
  }
}

class WellnessService {
  WellnessService({int? userId}) : _fixedUserId = userId;

  final int? _fixedUserId;

  static String _key(int userId) => 'wellness_data_$userId';

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<WellnessData> load([int? userId]) async {
    final id = _fixedUserId ?? userId ?? 0;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(id));
    if (raw == null || raw.isEmpty) return WellnessData.empty();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return WellnessData.fromJson(Map<String, dynamic>.from(decoded));
      }
    } on FormatException {
      return WellnessData.empty();
    }
    return WellnessData.empty();
  }

  Future<void> save(WellnessData data, [int? userId]) async {
    final id = _fixedUserId ?? userId ?? 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(id), jsonEncode(data.toJson()));
  }

  Future<void> setDailyGoal(int goal, [int? userId]) async {
    final data = await load(userId);
    final normalized = goal.clamp(1, 12);
    await save(data.copyWith(dailyGoal: normalized), userId);
  }

  Future<void> saveMood(
    int score, {
    String note = '',
    int? userId,
  }) async {
    final data = await load(userId);
    final moods = Map<String, MoodEntry>.from(data.moods);
    moods[dateKey(DateTime.now())] = MoodEntry(score: score, note: note);
    await save(data.copyWith(moods: moods), userId);
  }

  Future<void> recordSession({
    int minutes = 0,
    int? userId,
  }) async {
    final data = await load(userId);
    final sessions = Map<String, SessionSummary>.from(data.sessions);
    final key = dateKey(DateTime.now());
    final current = sessions[key] ?? const SessionSummary();
    sessions[key] = SessionSummary(
      count: current.count + 1,
      minutes: current.minutes + (minutes <= 0 ? 0 : minutes),
    );
    await save(data.copyWith(sessions: sessions), userId);
  }

  Future<void> resetToday([int? userId]) async {
    final data = await load(userId);
    final sessions = Map<String, SessionSummary>.from(data.sessions);
    sessions.remove(dateKey(DateTime.now()));
    await save(data.copyWith(sessions: sessions), userId);
  }
}
