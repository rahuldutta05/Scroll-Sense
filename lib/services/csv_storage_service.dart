import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'usage_stats_service.dart';

class CsvStorageService {
  static const String _fileName = 'daily_usage_log.csv';

  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  /// Appends a new row to the CSV.
  Future<void> appendRow(List<dynamic> row) async {
    final file = await _localFile;
    String csvRow = const ListToCsvConverter().convert([row]) + '\n';
    await file.writeAsString(csvRow, mode: FileMode.append);
  }

  /// Reads all rows from the CSV.
  Future<List<List<dynamic>>> readAllRows() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      return const CsvToListConverter().convert(contents);
    } catch (e) {
      return [];
    }
  }

  /// Format Date to YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Backfills or updates the CSV up to yesterday.
  Future<void> logDailyUsageIfNeeded() async {
    final file = await _localFile;
    List<List<dynamic>> rows = [];
    
    if (!await file.exists()) {
      // Create headers if it's a new file
      await file.writeAsString(
        const ListToCsvConverter().convert([
          ['Date', 'Social', 'Entertainment', 'Productive', 'Other']
        ]) + '\n',
      );
    } else {
      rows = await readAllRows();
    }

    // Determine which dates we already have
    final existingDates = rows.skip(1).map((row) => row[0].toString()).toSet();

    // We want to make sure the last 7 days (excluding today) are in the CSV
    // We can backfill up to 7 days if they are missing
    final now = DateTime.now();
    for (int i = 7; i > 0; i--) {
      final targetDate = DateTime(now.year, now.month, now.day - i);
      final dateStr = _formatDate(targetDate);
      
      if (!existingDates.contains(dateStr)) {
        // Fetch data for this day
        final dayStart = targetDate;
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final stats = await UsageStatsService.getUsageStats(startTime: dayStart, endTime: dayEnd);
        
        double social = 0;
        double entertainment = 0;
        double productive = 0;
        double other = 0;
        
        for (var record in stats) {
          final hours = record.durationSeconds / 3600.0;
          switch (categorizeApp(record.packageName)) {
            case AppCategory.social:
              social += hours;
              break;
            case AppCategory.entertainment:
              entertainment += hours;
              break;
            case AppCategory.productive:
              productive += hours;
              break;
            case AppCategory.other:
              other += hours;
              break;
          }
        }
        
        await appendRow([dateStr, social, entertainment, productive, other]);
      }
    }
  }

  /// Gets the sliding window of data (last [days] days from the CSV, 
  /// plus fetching today's current live data)
  Future<List<DailyCategorizedUsage>> getSlidingWindowData(int days) async {
    await logDailyUsageIfNeeded();
    
    final rows = await readAllRows();
    if (rows.isEmpty) return [];

    // Skip header
    final dataRows = rows.skip(1).toList();
    
    // Get up to (days - 1) from the CSV, since the last day is 'today' which is live
    final csvRows = dataRows.length > (days - 1) 
        ? dataRows.sublist(dataRows.length - (days - 1)) 
        : dataRows;

    List<DailyCategorizedUsage> result = [];
    
    for (var row in csvRows) {
      if (row.length >= 5) {
        result.add(DailyCategorizedUsage(
          (row[1] as num).toDouble(),
          (row[2] as num).toDouble(),
          (row[3] as num).toDouble(),
          (row[4] as num).toDouble(),
        ));
      }
    }
    
    // Pad with empty days if we don't have enough history
    while (result.length < (days - 1)) {
      result.insert(0, DailyCategorizedUsage(0, 0, 0, 0));
    }
    
    // Now fetch 'today' live data and append it
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final stats = await UsageStatsService.getUsageStats(startTime: todayStart, endTime: now);
    
    double social = 0;
    double entertainment = 0;
    double productive = 0;
    double other = 0;
    
    for (var record in stats) {
      final hours = record.durationSeconds / 3600.0;
      switch (categorizeApp(record.packageName)) {
        case AppCategory.social:
          social += hours;
          break;
        case AppCategory.entertainment:
          entertainment += hours;
          break;
        case AppCategory.productive:
          productive += hours;
          break;
        case AppCategory.other:
          other += hours;
          break;
      }
    }
    
    result.add(DailyCategorizedUsage(social, entertainment, productive, other));

    return result;
  }
}

final csvStorageServiceProvider = Provider<CsvStorageService>((ref) {
  return CsvStorageService();
});

/// Fetches categorized daily usage for the last 7 days using the CSV sliding window
final weeklyCategorizedCsvUsageProvider = FutureProvider<List<DailyCategorizedUsage>>((ref) async {
  final service = ref.read(csvStorageServiceProvider);
  return await service.getSlidingWindowData(7);
});
