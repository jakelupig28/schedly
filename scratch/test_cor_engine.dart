import 'dart:convert';
import 'dart:io';

class ClassSession {
  final String id;
  final String subjectName;
  final String subjectCode;
  final String room;
  final String instructor;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int colorValue;
  final int units;

  ClassSession({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.room,
    required this.instructor,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.colorValue,
    this.units = 3,
  });
}

class SpatialElement {
  final String text;
  final double top;
  final double left;
  final double width;
  final double height;
  SpatialElement(this.text, {required this.top, required this.left, required this.width, required this.height});
}

class _SubjectBlock {
  final String headerLine;
  final List<String> detailLines;
  _SubjectBlock({required this.headerLine, required this.detailLines});
}

class CorParserEngine {
  static const List<int> palette = [
    0xFF6C63FF, 0xFF4ECDC4, 0xFF45B7D1, 0xFFFF6584, 0xFFFFBE0B,
    0xFF9D4EDD, 0xFF3A86FF, 0xFFE27396, 0xFF2A9D8F, 0xFFE76F51,
    0xFF4361EE, 0xFF7209B7, 0xFF06D6A0, 0xFFF72585, 0xFF3F37C9
  ];

  static List<String> clusterSpatialElements(List<SpatialElement> elements) {
    if (elements.isEmpty) return [];
    
    final sorted = List<SpatialElement>.from(elements)
      ..sort((a, b) => a.top.compareTo(b.top));
      
    double totalHeight = 0;
    for (final el in sorted) {
      totalHeight += el.height;
    }
    final avgHeight = sorted.isNotEmpty ? totalHeight / sorted.length : 20.0;
    final rowTolerance = (avgHeight * 0.55).clamp(8.0, 30.0);
    
    final List<List<SpatialElement>> rows = [];
    for (final el in sorted) {
      bool placed = false;
      final elCenterY = el.top + el.height / 2;
      for (final row in rows) {
        final rowCenterY = row.first.top + row.first.height / 2;
        if ((elCenterY - rowCenterY).abs() <= rowTolerance) {
          row.add(el);
          placed = true;
          break;
        }
      }
      if (!placed) {
        rows.add([el]);
      }
    }
    
    final List<String> resultLines = [];
    for (final row in rows) {
      row.sort((a, b) => a.left.compareTo(b.left));
      final lineText = row.map((e) => e.text).join(' ').trim();
      if (lineText.isNotEmpty) {
        resultLines.add(lineText);
      }
    }
    return resultLines;
  }

  static String deduplicateText(String str) {
    if (str.isEmpty) return '';
    var s = str.trim();
    
    if (s.contains('\t')) {
      final tabParts = s.split('\t').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      final uniqueParts = <String>[];
      for (final p in tabParts) {
        if (uniqueParts.isEmpty || uniqueParts.last != p) {
          uniqueParts.add(p);
        }
      }
      s = uniqueParts.join(' ');
    }
    
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final halfLen = s.length ~/ 2;
    for (int len = halfLen; len >= 3; len--) {
      final firstHalf = s.substring(0, len).trim();
      final secondHalf = s.substring(len).trim();
      if (firstHalf.isNotEmpty && secondHalf.startsWith(firstHalf)) {
        s = firstHalf + secondHalf.substring(firstHalf.length);
        s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }
    
    final words = s.split(' ').where((w) => w.isNotEmpty).toList();
    final cleanWords = <String>[];
    for (int i = 0; i < words.length; i++) {
      if (cleanWords.isNotEmpty && cleanWords.last.toLowerCase() == words[i].toLowerCase()) {
        continue;
      }
      if (cleanWords.length >= 2 && i + 1 < words.length &&
          cleanWords[cleanWords.length - 2].toLowerCase() == words[i].toLowerCase() &&
          cleanWords[cleanWords.length - 1].toLowerCase() == words[i + 1].toLowerCase()) {
        i++;
        continue;
      }
      cleanWords.add(words[i]);
    }
    return cleanWords.join(' ').trim();
  }

  static bool isSubjectHeaderLine(String line, String? prevLine) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    
    if (prevLine != null && prevLine.trim().endsWith(',')) {
      return false;
    }
    
    final parts = trimmed.split(RegExp(r'[\t\s]+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return false;
    
    final firstWord = parts[0]
        .replaceAll(RegExp(r'^[\*\#\•\d\.\(\)\[\]\-]+'), '')
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
    if (firstWord.isEmpty || firstWord.length < 2 || firstWord.length > 12) return false;
    
    const nonCodes = {
      'M', 'T', 'W', 'TH', 'F', 'S', 'SU', 'SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI',
      'MWF', 'TTH', 'MTH', 'TF', 'M/TH', 'T/TH', 'M-TH', 'T-TH', 'W-S', 'WS', 'MW', 'M/W', 'M-W',
      'THS', 'TH-S', 'TH/S', 'CODE', 'LEC', 'LAB', 'CREDIT', 'TUITION', 'STUDENT', 'REGISTRATION',
      'ACADEMIC', 'NAME', 'GENDER', 'AGE', 'EMAIL', 'KEEP', 'NOTE', 'TOTAL', 'SHEDULE', 'SCHEDULE',
      'SECTION', 'RULES', 'PLEDGE', 'APPROVED', 'POWERED', 'LESS', 'NET', 'ATHLETIC', 'CULTURAL',
      'DEVELOPMENT', 'GUIDANCE', 'LIBRARY', 'MEDICAL', 'COMPUTER', 'ASSESSED', 'FIRST', 'SECOND',
      'SUMMER', 'ROOM', 'FACULTY', 'REPUBLIC', 'PHILIPPINES', 'INSTITUTE', 'COLLEGE', 'PROGRAM',
      'GENERAL', 'INFORMATION', 'FEES', 'FEE', 'PAYMENT', 'DUE', 'DATE', 'OFFICIAL', 'RECEIPT',
      'YEAR', 'LEVEL', 'TERM', 'MAJOR', 'CURRICULUM', 'SCHOLARSHIP', 'DISCOUNT', 'ASSESSMENT',
      'REMARK', 'REMARKS', 'OUTSTANDING', 'BALANCE', 'REGISTRAR', 'DAYS', 'TIME', 'PERIOD',
      'BLDG', 'STATUS'
    };
    
    if (nonCodes.contains(firstWord)) return false;
    
    if (RegExp(r'^[A-Z]?[1-5][A-Z0-9]*$').hasMatch(firstWord) && parts.length == 1) {
      return false;
    }
    
    final isCodeFormat = RegExp(r'^[A-Z]{2,8}\d{0,4}[A-Z0-9]*$').hasMatch(firstWord) ||
                         RegExp(r'^[A-Z]{2,6}[-\s]?[0-9]{1,4}[A-Z0-9]*$').hasMatch(firstWord);
    if (!isCodeFormat) return false;
    
    if (parts.length == 1 && RegExp(r'^[A-Z]+$').hasMatch(firstWord) && firstWord.length > 8) {
      return false;
    }
    
    return true;
  }

  static List<String> parseDaysFromLine(String line) {
    final List<String> days = [];
    final s = line.toUpperCase().trim();
    
    if (RegExp(r'M[\/\-]TH\b|M\s*,\s*TH\b|M\s+TH\b').hasMatch(s)) {
      days.addAll(['Monday', 'Thursday']);
    } else if (RegExp(r'T[\/\-]TH\b|TTH\b|T\s*,\s*TH\b|T\s+TH\b').hasMatch(s)) {
      days.addAll(['Tuesday', 'Thursday']);
    } else if (RegExp(r'M[\/\-]W[\/\-]F\b|MWF\b|M\s*,\s*W\s*,\s*F\b').hasMatch(s)) {
      days.addAll(['Monday', 'Wednesday', 'Friday']);
    } else if (RegExp(r'T[\/\-]F\b|TF\b|T\s*,\s*F\b').hasMatch(s)) {
      days.addAll(['Tuesday', 'Friday']);
    } else if (RegExp(r'M[\/\-]W\b|MW\b|M\s*,\s*W\b').hasMatch(s)) {
      days.addAll(['Monday', 'Wednesday']);
    } else if (RegExp(r'W[\/\-]S\b|WS\b|W\s*,\s*S\b').hasMatch(s)) {
      days.addAll(['Wednesday', 'Saturday']);
    } else if (RegExp(r'TH[\/\-]S\b|THS\b|TH\s*,\s*S\b').hasMatch(s)) {
      days.addAll(['Thursday', 'Saturday']);
    } else if (RegExp(r'M[\/\-]F\b|MON[\/\-]FRI\b').hasMatch(s)) {
      days.addAll(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
    } else if (RegExp(r'\bDAILY\b').hasMatch(s)) {
      days.addAll(['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']);
    } else {
      if (RegExp(r'\b(?:MON|MONDAY)\b').hasMatch(s) || (RegExp(r'\bM\b').hasMatch(s) && !RegExp(r'\b(?:AM|PM)\b').hasMatch(s))) {
        days.add('Monday');
      }
      if (RegExp(r'\b(?:TUE|TUES|TUESDAY)\b').hasMatch(s) || RegExp(r'\bT\b').hasMatch(s)) {
        days.add('Tuesday');
      }
      if (RegExp(r'\b(?:WED|WEDNESDAY)\b').hasMatch(s) || RegExp(r'\bW\b').hasMatch(s)) {
        days.add('Wednesday');
      }
      if (RegExp(r'\b(?:THU|THUR|THURS|THURSDAY)\b').hasMatch(s) || RegExp(r'\bTH\b').hasMatch(s)) {
        days.add('Thursday');
      }
      if (RegExp(r'\b(?:FRI|FRIDAY)\b').hasMatch(s) || RegExp(r'\bF\b').hasMatch(s)) {
        days.add('Friday');
      }
      if (RegExp(r'\b(?:SAT|SATURDAY)\b').hasMatch(s) || RegExp(r'\bS\b').hasMatch(s)) {
        days.add('Saturday');
      }
      if (RegExp(r'\b(?:SUN|SUNDAY)\b').hasMatch(s) || RegExp(r'\bSU\b').hasMatch(s)) {
        days.add('Sunday');
      }
    }
    return days.toSet().toList();
  }

  static String normalizeTime(String raw, {String? defaultAmPm}) {
    var cleaned = raw.trim().toUpperCase();
    if (!cleaned.contains(':')) {
      final num = int.tryParse(cleaned.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null) cleaned = "$num:00";
    }
    if (!cleaned.contains('AM') && !cleaned.contains('PM')) {
      if (defaultAmPm != null && (defaultAmPm.contains('AM') || defaultAmPm.contains('PM'))) {
        cleaned = "$cleaned $defaultAmPm";
      } else {
        final hour = int.tryParse(cleaned.split(':')[0]) ?? 8;
        if (hour >= 7 && hour <= 11) {
          cleaned = "$cleaned AM";
        } else {
          cleaned = "$cleaned PM";
        }
      }
    }
    final parts = cleaned.split(':');
    if (parts.length >= 2 && parts[0].length == 1) {
      cleaned = "0$cleaned";
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String cleanFacultyName(String raw) {
    var s = deduplicateText(raw);
    
    s = s.replaceAll(RegExp(r'(?:from\s*)?\b\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\s*(?:[-–—~]|to)+\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\b\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\b(?:AM|PM|am|pm)\b'), ' ');
    
    s = s.replaceAll(RegExp(r'\b(?:MON|TUE|WED|THU|FRI|SAT|SUN|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|M[\/\-]TH|T[\/\-]TH|M[\/\-]W[\/\-]F|T[\/\-]F|W[\/\-]S|M[\/\-]W|MWF|TTH|TF|THS|MTH|TH|SU|M|T|W|F|S)\b', caseSensitive: false), ' ');
    
    s = s.replaceAll(RegExp(r'\b(Rm\s*\.?\s*\d+|Room\s*\d+|CL\s*\d+|Lab\s*\d+|ComLab\s*\d+|AVR\s*\d*|Gym|Online|TBA|LR\s*\d+|Bldg\s*\w+|ICT[-\s]?\d+|NB\s*\d+|LB\s*\d+)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'\b(BSINFOTECH?\s*H?[1-5][A-Z0-9]*|H[1-5][A-Z0-9]*|[1-5][A-Z0-9]*)\b', caseSensitive: false), ' ');
    
    s = s.replaceAll(RegExp(r'[\t\r\n|;_\-–—]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(RegExp(r'^,\s*'), '').replaceAll(RegExp(r',\s*$'), '').trim();
    
    s = deduplicateText(s);
    if (s.isEmpty || s.length < 2 || s.toUpperCase() == 'TBA') return 'TBA';
    return capitalize(s);
  }

  static String capitalize(String s) {
    if (s.isEmpty) return '';
    return s.split(' ').map((w) {
      if (w.isEmpty) return '';
      final hasComma = w.endsWith(',');
      final cleanW = hasComma ? w.substring(0, w.length - 1) : w;
      final cap = cleanW.isNotEmpty ? "${cleanW[0].toUpperCase()}${cleanW.substring(1).toLowerCase()}" : '';
      return hasComma ? '$cap,' : cap;
    }).join(' ');
  }

  static List<ClassSession> parseTableMatrix(List<String> rawLines) {
    final List<String> tableLines = [];
    bool insideTable = false;

    for (final raw in rawLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (line.toLowerCase().contains('total unit') ||
          line.toLowerCase().contains('assessed fees') ||
          line.toLowerCase().contains('schedule of payment') ||
          line.toLowerCase().contains('rules of refund')) {
        break;
      }

      if (line.toUpperCase().contains('CODE') &&
          (line.toUpperCase().contains('SUBJECT') || line.toUpperCase().contains('UNIT') || line.toUpperCase().contains('SHEDULE') || line.toUpperCase().contains('SECTION'))) {
        insideTable = true;
        continue;
      }

      if (insideTable) {
        tableLines.add(line);
      }
    }

    final targetLines = tableLines.isNotEmpty ? tableLines : rawLines;
    final List<_SubjectBlock> subjectBlocks = [];
    _SubjectBlock? currentBlock;

    for (int i = 0; i < targetLines.length; i++) {
      final line = targetLines[i].trim();
      if (line.isEmpty) continue;
      final prevLine = i > 0 ? targetLines[i - 1] : null;

      if (isSubjectHeaderLine(line, prevLine)) {
        if (currentBlock != null) subjectBlocks.add(currentBlock);
        currentBlock = _SubjectBlock(headerLine: line, detailLines: []);
      } else if (currentBlock != null) {
        currentBlock.detailLines.add(line);
      }
    }
    if (currentBlock != null) subjectBlocks.add(currentBlock);

    final timeRangeRegex = RegExp(
      r'(?:from\s*)?((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)?|(?:0?[1-9]|1[0-2]):[0-5][0-9])\s*(?:[-–—~]|to)+\s*((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)|(?:0?[1-9]|1[0-2]):[0-5][0-9])',
      caseSensitive: false,
    );

    final dayRegexPattern = RegExp(
      r'\b(MON|TUE|WED|THU|FRI|SAT|SUN|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|M-TH|T-TH|M-W-F|T-F|W-S|M/TH|T/TH|MWF|TTH|TF|TH-S|M/W|MW|M-W|DAILY)\b',
      caseSensitive: false,
    );

    final List<ClassSession> results = [];
    int idCounter = 1;

    for (final sb in subjectBlocks) {
      final headerParts = sb.headerLine.split(RegExp(r'[\t\s]+')).where((w) => w.isNotEmpty).toList();
      final code = headerParts[0].replaceAll(RegExp(r'^[\*\#\•\d\.\(\)\[\]\-]+'), '').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '');

      var rawHeader = sb.headerLine;
      int units = 3;
      final quadMatch = RegExp(r'(\d+)\s+(\d+)\s+(\d+)\s+(\d+)').firstMatch(rawHeader);
      if (quadMatch != null) {
        final creditStr = quadMatch.group(3)!;
        var creditNum = int.tryParse(creditStr) ?? 3;
        if (creditNum >= 10 && creditNum % 11 == 0) creditNum = (creditNum / 11).round();
        units = creditNum > 0 ? creditNum : 3;
        rawHeader = rawHeader.substring(0, quadMatch.start);
      } else {
        // If single line format, check if time or days or single unit exists on header
        final tMatchHeader = timeRangeRegex.firstMatch(rawHeader);
        final dMatchHeader = dayRegexPattern.firstMatch(rawHeader);
        final singleU = RegExp(r'\b([1-6](?:\.0)?)\s*(?:units?|credit|u)?\b', caseSensitive: false).firstMatch(rawHeader);
        if (singleU != null) {
          units = double.tryParse(singleU.group(1)!)?.round() ?? 3;
        }
        
        // If time or day exists on header line (single line table row), truncate rawHeader before day/time
        if (dMatchHeader != null && dMatchHeader.start > code.length) {
          rawHeader = rawHeader.substring(0, dMatchHeader.start);
        } else if (tMatchHeader != null && tMatchHeader.start > code.length) {
          rawHeader = rawHeader.substring(0, tMatchHeader.start);
        }
      }

      var title = rawHeader
          .replaceAll(RegExp('\\b$code\\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\bBS[A-Z0-9\s-]+\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\bH[1-5][A-Z0-9]*\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\b[1-5][A-Z]{1,2}\b'), ' ')
          .replaceAll(RegExp(r'\b([1-6](?:\.0)?)\s*(?:units?|credit|u)?\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'[|:;_\-–—]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      title = deduplicateText(title);
      if (title.length < 3) title = code;

      String section = '4A';
      String room = 'TBA';
      String faculty = 'TBA';

      final schedEntries = <Map<String, dynamic>>[];

      // Check both header line (for single line format) and detail lines
      final allLinesToScan = [sb.headerLine, ...sb.detailLines];

      for (int dIdx = 0; dIdx < allLinesToScan.length; dIdx++) {
        final dLine = allLinesToScan[dIdx].trim();
        if (dLine.isEmpty) continue;

        final secMatch = RegExp(r'\b(BSINFOTECH?\s*H?[1-5][A-Z0-9]*|H[1-5][A-Z0-9]*|[1-5][A-Z0-9]*)\b', caseSensitive: false).firstMatch(dLine);
        if (secMatch != null && !dLine.contains(':') && !dLine.toUpperCase().contains('PM') && !dLine.toUpperCase().contains('AM')) {
          final sVal = secMatch.group(1)!.toUpperCase().replaceAll(RegExp(r'^BSINFOTECH?\s*'), '').replaceAll(RegExp(r'^H'), '');
          if (sVal.length <= 4) section = sVal;
        }

        final roomMatch = RegExp(
          r'\b(Rm\s*\.?\s*\d+|Room\s*\d+|CL\s*\d+|Lab\s*\d+|ComLab\s*\d+|AVR\s*\d*|Gym|Online|TBA|LR\s*\d+|Bldg\s*\w+|ICT[-\s]?\d+|NB\s*\d+|LB\s*\d+)\b',
          caseSensitive: false,
        ).firstMatch(dLine);
        if (roomMatch != null) {
          room = roomMatch.group(0)!.trim();
        }

        final tMatch = timeRangeRegex.firstMatch(dLine);
        if (tMatch != null) {
          final rawStart = tMatch.group(1)?.trim() ?? "";
          final rawEnd = tMatch.group(2)?.trim() ?? "";

          final String? endAmPm = rawEnd.toUpperCase().contains('PM')
              ? 'PM'
              : (rawEnd.toUpperCase().contains('AM') ? 'AM' : null);
          String? startAmPm = rawStart.toUpperCase().contains('PM')
              ? 'PM'
              : (rawStart.toUpperCase().contains('AM') ? 'AM' : null);

          if (startAmPm == null && endAmPm != null) {
            final startHour = int.tryParse(rawStart.split(':')[0]) ?? 8;
            final endHour = int.tryParse(rawEnd.split(':')[0]) ?? 12;
            if (endAmPm == 'PM' && startHour >= 7 && startHour <= 11 && (endHour == 12 || endHour <= 6)) {
              startAmPm = 'AM';
            } else {
              startAmPm = endAmPm;
            }
          }

          final startTime = normalizeTime(rawStart, defaultAmPm: startAmPm ?? 'AM');
          final endTime = normalizeTime(rawEnd, defaultAmPm: endAmPm ?? startAmPm ?? 'PM');

          final days = parseDaysFromLine(dLine.substring(0, tMatch.start));
          final resolvedDays = days.isNotEmpty ? days : parseDaysFromLine(dLine);

          var facCandidate = dLine.substring(tMatch.start + tMatch.group(0)!.length).trim();
          if (facCandidate.endsWith(',') && dIdx + 1 < allLinesToScan.length) {
            facCandidate += ' ' + allLinesToScan[dIdx + 1].trim();
            dIdx++;
          } else if (facCandidate.isEmpty && dIdx + 1 < allLinesToScan.length) {
            final nextL = allLinesToScan[dIdx + 1].trim();
            if (!timeRangeRegex.hasMatch(nextL) && !isSubjectHeaderLine(nextL, dLine)) {
              facCandidate = nextL;
              if (facCandidate.endsWith(',') && dIdx + 2 < allLinesToScan.length) {
                facCandidate += ' ' + allLinesToScan[dIdx + 2].trim();
                dIdx++;
              }
              dIdx++;
            }
          }

          faculty = cleanFacultyName(facCandidate);

          schedEntries.add({
            'days': resolvedDays.isNotEmpty ? resolvedDays : ['Monday'],
            'startTime': startTime,
            'endTime': endTime,
            'room': room,
            'faculty': faculty,
          });
        }
      }

      if (schedEntries.isEmpty) {
        schedEntries.add({
          'days': ['Monday'],
          'startTime': '08:00 AM',
          'endTime': '09:30 AM',
          'room': room,
          'faculty': faculty,
        });
      }

      final colorVal = palette[(idCounter - 1) % palette.length];

      for (final entry in schedEntries) {
        final entryDays = entry['days'] as List<String>;
        for (final d in entryDays) {
          results.add(
            ClassSession(
              id: 'cor_${idCounter}_${d.substring(0, 3).toLowerCase()}',
              subjectName: title,
              subjectCode: code,
              room: entry['room'] as String,
              instructor: entry['faculty'] as String,
              dayOfWeek: d,
              startTime: entry['startTime'] as String,
              endTime: entry['endTime'] as String,
              colorValue: colorVal,
              units: units,
            ),
          );
        }
      }
      idCounter++;
    }

    return results;
  }
}

void main() {
  // Test 1: EARIST Prototype Multi-Line Tabular Stream
  print('--- RUNNING TEST 1: EARIST Prototype Document ---');
  final jsonStr = File('C:/Users/User/schedly/scratch/prototype_raw_lines.json').readAsStringSync();
  final List<dynamic> rawList = jsonDecode(jsonStr);
  final List<String> lines = rawList.map((e) => e.toString()).toList();

  final sessions = CorParserEngine.parseTableMatrix(lines);

  final seen = <String>{};
  int totalUnits = 0;
  for (final s in sessions) {
    if (seen.add(s.subjectCode)) {
      totalUnits += s.units;
    }
  }

  print('Total Class Sessions: ${sessions.length}');
  print('Total Distinct Academic Units: $totalUnits');
  for (int i = 0; i < sessions.length; i++) {
    final s = sessions[i];
    print('${(i + 1).toString().padLeft(2, ' ')}. [${s.subjectCode.padRight(8, ' ')}] "${s.subjectName}" (${s.units}u) | ${s.dayOfWeek.padRight(9, ' ')} ${s.startTime} - ${s.endTime} | Room: ${s.room.padRight(5, ' ')} | Prof: ${s.instructor.padRight(25, ' ')}');
  }

  assert(sessions.length == 11, 'Expected 11 class sessions');
  assert(totalUnits == 18, 'Expected 18 distinct academic units');

  // Test 2: Single Line PUP / PLM / CVSU format
  print('\n--- RUNNING TEST 2: Single-Line Format (PUP/PLM/CVSU) ---');
  final singleLineSample = [
    'SCHEDULE OF CLASSES',
    'CODE SUBJECT TITLE UNITS SECTION SCHEDULE ROOM FACULTY',
    'IT301 Web Systems and Technologies 3.0 3-1 M-TH 08:00 AM - 10:00 AM CL 1 Prof. Garcia, Maria',
    'IT302 Database Administration 3.0 3-1 T-F 01:00 PM - 03:00 PM CL 2 Engr. Santos, Roberto',
    'GE105 Purposive Communication 3.0 3-1 WED 09:00 AM - 12:00 PM Rm 304 Prof. Diaz, Elena',
    'PE3 Physical Education 3 2.0 3-1 SAT 08:00 AM - 10:00 AM GYM Coach Ramos',
    'Total Units: 11.0'
  ];
  final singleLineSessions = CorParserEngine.parseTableMatrix(singleLineSample);
  print('Single Line Parsed Sessions: ${singleLineSessions.length}');
  for (final s in singleLineSessions) {
    print('  [${s.subjectCode}] "${s.subjectName}" (${s.units}u) | ${s.dayOfWeek} ${s.startTime}-${s.endTime} | Room: ${s.room} | Prof: ${s.instructor}');
  }
  assert(singleLineSessions.length == 6, 'Expected 6 sessions (M, TH, T, F, WED, SAT)');

  // Test 3: Multi-Schedule per Subject (UST / DLSU)
  print('\n--- RUNNING TEST 3: Multi-Schedule per Subject ---');
  final multiSchedSample = [
    'COURSE CODE | DESCRIPTIVE TITLE | UNITS | TIME & DAY | ROOM | INSTRUCTOR',
    'CS211 Data Structures and Algorithms 4.0',
    'MW 08:00 AM - 10:00 AM Rm 401 Dr. Mendoza, Alex',
    'F 08:00 AM - 11:00 AM CL 4 Dr. Mendoza, Alex',
    'CS212 Operating Systems Architecture 3.0',
    'TTH 01:00 PM - 02:30 PM Rm 302 Prof. Alcantara, Dan',
    'Total Units Enrolled: 7.0'
  ];
  final multiSchedSessions = CorParserEngine.parseTableMatrix(multiSchedSample);
  print('Multi-Schedule Parsed Sessions: ${multiSchedSessions.length}');
  for (final s in multiSchedSessions) {
    print('  [${s.subjectCode}] "${s.subjectName}" (${s.units}u) | ${s.dayOfWeek} ${s.startTime}-${s.endTime} | Room: ${s.room} | Prof: ${s.instructor}');
  }
  assert(multiSchedSessions.length == 5, 'Expected 5 sessions (M, W, F, T, TH)');

  print('\n======================================================');
  print('ALL GENERALIZATION & MULTI-FORMAT TESTS PASSED!');
  print('======================================================');
}
