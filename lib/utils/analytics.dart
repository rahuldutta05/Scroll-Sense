import '../models/expense.dart';

class Analytics {
  static List<Expense> _cast(List<dynamic> raw) =>
      raw.whereType<Expense>().toList();

  static double dailyAvg(List<dynamic> raw) {
    final all = _cast(raw);
    final n = DateTime.now();
    final m = all.where(
        (e) => e.date.year == n.year && e.date.month == n.month);
    return m.isEmpty ? 0 : m.fold(0.0, (s, e) => s + e.amount) / n.day;
  }

  static String topCat(List<dynamic> raw) {
    final all = _cast(raw);
    if (all.isEmpty) return '—';
    final m = <String, double>{};
    for (final e in all) m[e.category] = (m[e.category] ?? 0) + e.amount;
    return m.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String peakDay(List<dynamic> raw) {
    final all = _cast(raw);
    if (all.isEmpty) return '—';
    final m = <String, double>{};
    for (final e in all) {
      final k = '${e.date.year}-${e.date.month}-${e.date.day}';
      m[k] = (m[k] ?? 0) + e.amount;
    }
    final b = m.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .split('-');
    const mn = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${mn[int.parse(b[1])]} ${b[2]}';
  }

  static List<Map<String, dynamic>> weekly(List<dynamic> raw) {
    final all = _cast(raw);
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final n = DateTime.now();
    return List.generate(7, (i) {
      final d = n.subtract(Duration(days: 6 - i));
      final t = all
          .where((e) =>
              e.date.year == d.year &&
              e.date.month == d.month &&
              e.date.day == d.day)
          .fold(0.0, (s, e) => s + e.amount);
      return {'day': names[d.weekday - 1], 'total': t};
    });
  }
}
