const fs = require('fs');
const lines = JSON.parse(fs.readFileSync('C:/Users/User/schedly/scratch/prototype_raw_lines.json', 'utf8'));

function isSubjectHeaderLine(line, prevLine) {
  const trimmed = line.trim();
  if (!trimmed) return false;
  
  if (prevLine && prevLine.trim().endsWith(',')) {
    return false;
  }
  
  const parts = trimmed.split(/[\t\s]+/).filter(w => w.length > 0);
  if (parts.length === 0) return false;
  
  const firstWord = parts[0].replace(/^[\*\#\•\d\.\(\)\[\]\-]+/, '').toUpperCase().replace(/[^A-Z0-9\-]/g, '');
  if (!firstWord || firstWord.length < 2 || firstWord.length > 10) return false;
  
  const nonCodes = new Set([
    'M', 'T', 'W', 'TH', 'F', 'S', 'SU', 'SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI',
    'MWF', 'TTH', 'MTH', 'TF', 'M/TH', 'T/TH', 'M-TH', 'T-TH', 'W-S', 'WS', 'CODE', 'LEC',
    'LAB', 'CREDIT', 'TUITION', 'STUDENT', 'REGISTRATION', 'ACADEMIC', 'NAME', 'GENDER', 'AGE',
    'EMAIL', 'KEEP', 'NOTE', 'TOTAL', 'SHEDULE', 'SCHEDULE', 'SECTION', 'RULES', 'PLEDGE',
    'APPROVED', 'POWERED', 'LESS', 'NET', 'ATHLETIC', 'CULTURAL', 'DEVELOPMENT', 'GUIDANCE',
    'LIBRARY', 'MEDICAL', 'COMPUTER', 'ASSESSED', 'FIRST', 'SECOND', 'SUMMER', 'ROOM', 'FACULTY',
    'REPUBLIC', 'PHILIPPINES', 'INSTITUTE', 'COLLEGE', 'PROGRAM', 'GENERAL', 'INFORMATION',
    'FEES', 'FEE', 'PAYMENT', 'DUE', 'DATE', 'OFFICIAL', 'RECEIPT', 'YEAR', 'LEVEL', 'TERM',
    'MAJOR', 'CURRICULUM', 'SCHOLARSHIP', 'DISCOUNT', 'ASSESSMENT', 'REMARK', 'REMARKS',
    'OUTSTANDING', 'BALANCE', 'REGISTRAR'
  ]);
  
  if (nonCodes.has(firstWord)) return false;
  if (/^[A-Z]?[1-5][A-Z0-9]*$/.test(firstWord) && parts.length === 1) return false;
  
  const isCodeFormat = /^[A-Z]{2,8}\d{0,4}[A-Z0-9]*$/.test(firstWord) || /^[A-Z]{2,6}[-\s]?[0-9]{1,4}[A-Z0-9]*$/.test(firstWord);
  if (!isCodeFormat) return false;
  
  if (parts.length === 1 && /^[A-Z]+$/.test(firstWord) && firstWord.length > 8) return false;
  
  return true;
}

function parseDays(str) {
  const days = [];
  const s = str.toUpperCase().trim();
  
  if (/M[\/\-]TH\b|M\s*,\s*TH\b|M\s+TH\b/.test(s)) {
    days.push('Monday', 'Thursday');
  } else if (/T[\/\-]TH\b|TTH\b|T\s*,\s*TH\b|T\s+TH\b/.test(s)) {
    days.push('Tuesday', 'Thursday');
  } else if (/M[\/\-]W[\/\-]F\b|MWF\b|M\s*,\s*W\s*,\s*F\b/.test(s)) {
    days.push('Monday', 'Wednesday', 'Friday');
  } else if (/T[\/\-]F\b|TF\b|T\s*,\s*F\b/.test(s)) {
    days.push('Tuesday', 'Friday');
  } else if (/M[\/\-]W\b|MW\b|M\s*,\s*W\b/.test(s)) {
    days.push('Monday', 'Wednesday');
  } else if (/W[\/\-]S\b|WS\b|W\s*,\s*S\b/.test(s)) {
    days.push('Wednesday', 'Saturday');
  } else if (/TH[\/\-]S\b|THS\b|TH\s*,\s*S\b/.test(s)) {
    days.push('Thursday', 'Saturday');
  } else {
    if (/\b(?:MON|MONDAY)\b/.test(s) || (/\bM\b/.test(s) && !/\bAM\b|\bPM\b/.test(s))) days.push('Monday');
    if (/\b(?:TUE|TUES|TUESDAY)\b/.test(s) || /\bT\b/.test(s)) days.push('Tuesday');
    if (/\b(?:WED|WEDNESDAY)\b/.test(s) || /\bW\b/.test(s)) days.push('Wednesday');
    if (/\b(?:THU|THUR|THURS|THURSDAY)\b/.test(s) || /\bTH\b/.test(s)) days.push('Thursday');
    if (/\b(?:FRI|FRIDAY)\b/.test(s) || /\bF\b/.test(s)) days.push('Friday');
    if (/\b(?:SAT|SATURDAY)\b/.test(s) || /\bS\b/.test(s)) days.push('Saturday');
    if (/\b(?:SUN|SUNDAY)\b/.test(s) || /\bSU\b/.test(s)) days.push('Sunday');
  }
  return [...new Set(days)];
}

function normalizeTime(raw, defaultAmPm) {
  let cleaned = raw.trim().toUpperCase();
  if (!cleaned.includes(':')) {
    const num = parseInt(cleaned.replace(/[^0-9]/g, ''));
    if (!isNaN(num)) cleaned = `${num}:00`;
  }
  if (!cleaned.includes('AM') && !cleaned.includes('PM')) {
    if (defaultAmPm && (defaultAmPm.includes('AM') || defaultAmPm.includes('PM'))) {
      cleaned = `${cleaned} ${defaultAmPm}`;
    } else {
      const hour = parseInt(cleaned.split(':')[0]) || 8;
      if (hour >= 7 && hour <= 11) cleaned = `${cleaned} AM`;
      else cleaned = `${cleaned} PM`;
    }
  }
  const parts = cleaned.split(':');
  if (parts.length >= 2 && parts[0].length === 1) {
    cleaned = `0${cleaned}`;
  }
  return cleaned.replace(/\s+/g, ' ');
}

function deduplicateText(str) {
  if (!str) return '';
  let s = str.trim();
  
  if (s.includes('\t')) {
    const tabParts = s.split('\t').map(p => p.trim()).filter(p => p.length > 0);
    const uniqueParts = [];
    for (const p of tabParts) {
      if (uniqueParts.length === 0 || uniqueParts[uniqueParts.length - 1] !== p) {
        uniqueParts.push(p);
      }
    }
    s = uniqueParts.join(' ');
  }
  
  s = s.replace(/\s+/g, ' ').trim();
  const halfLen = Math.floor(s.length / 2);
  for (let len = halfLen; len >= 3; len--) {
    const firstHalf = s.substring(0, len).trim();
    const secondHalf = s.substring(len).trim();
    if (firstHalf.length > 0 && secondHalf.startsWith(firstHalf)) {
      s = firstHalf + secondHalf.substring(firstHalf.length);
      s = s.replace(/\s+/g, ' ').trim();
    }
  }
  
  const words = s.split(' ');
  const cleanWords = [];
  for (let i = 0; i < words.length; i++) {
    if (cleanWords.length > 0 && cleanWords[cleanWords.length - 1].toLowerCase() === words[i].toLowerCase()) {
      continue;
    }
    if (cleanWords.length >= 2 && i + 1 < words.length &&
        cleanWords[cleanWords.length - 2].toLowerCase() === words[i].toLowerCase() &&
        cleanWords[cleanWords.length - 1].toLowerCase() === words[i + 1].toLowerCase()) {
      i++;
      continue;
    }
    cleanWords.push(words[i]);
  }
  
  return cleanWords.join(' ').trim();
}

function cleanFacultyName(raw) {
  let s = deduplicateText(raw);
  
  // Remove any time tokens / ranges
  s = s.replace(/(?:from\s*)?\b\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\s*(?:[-–—~]|to)+\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\b/gi, ' ');
  s = s.replace(/\b\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?\b/gi, ' ');
  s = s.replace(/\b(?:AM|PM|am|pm)\b/g, ' ');
  
  // Remove day tokens / combinations
  s = s.replace(/\b(?:MON|TUE|WED|THU|FRI|SAT|SUN|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|M[\/\-]TH|T[\/\-]TH|M[\/\-]W[\/\-]F|T[\/\-]F|W[\/\-]S|M[\/\-]W|MWF|TTH|TF|THS|MTH|TH|SU|M|T|W|F|S)\b/gi, ' ');
  
  // Remove room tokens
  s = s.replace(/\b(Rm\s*\.?\s*\d+|Room\s*\d+|CL\s*\d+|Lab\s*\d+|ComLab\s*\d+|AVR\s*\d*|Gym|Online|TBA|LR\s*\d+|Bldg\s*\w+|ICT[-\s]?\d+|NB\s*\d+|LB\s*\d+)\b/gi, ' ');
  
  // Remove section tokens
  s = s.replace(/\b(BSINFOTECH?\s*H?[1-5][A-Z0-9]*|H[1-5][A-Z0-9]*|[1-5][A-Z0-9]*)\b/gi, ' ');
  
  s = s.replace(/[\t\r\n|;_\-–—]/g, ' ');
  s = s.replace(/\s+/g, ' ').trim();
  s = s.replace(/^,\s*/, '').replace(/,\s*$/, '').trim();
  
  s = deduplicateText(s);
  
  if (!s || s.length < 2 || s.toUpperCase() === 'TBA') return 'TBA';
  
  return capitalize(s);
}

function capitalize(s) {
  if (!s) return '';
  return s.split(' ').map(w => {
    if (!w) return '';
    const hasComma = w.endsWith(',');
    const cleanW = hasComma ? w.slice(0, -1) : w;
    const cap = cleanW.length > 0 ? cleanW[0].toUpperCase() + cleanW.substring(1).toLowerCase() : '';
    return hasComma ? cap + ',' : cap;
  }).join(' ');
}

// Chunker
const tableLines = [];
let insideTable = false;

for (let i = 0; i < lines.length; i++) {
  const l = lines[i].trim();
  if (!l) continue;
  if (/Total\s*Unit/i.test(l) || /ASSESSED\s*FEES/i.test(l) || /SCHEDULE\s*OF\s*PAYMENT/i.test(l) || /RULES\s*OF\s*REFUND/i.test(l)) {
    break;
  }
  if (l.toUpperCase().includes('CODE') && (l.toUpperCase().includes('SUBJECT') || l.toUpperCase().includes('UNIT') || l.toUpperCase().includes('SHEDULE') || l.toUpperCase().includes('SECTION'))) {
    insideTable = true;
    continue;
  }
  if (insideTable) {
    tableLines.push(l);
  }
}

// Build subject blocks
const blocks = [];
let currBlock = null;

for (let i = 0; i < tableLines.length; i++) {
  const line = tableLines[i].trim();
  const prevLine = i > 0 ? tableLines[i - 1] : null;
  
  if (isSubjectHeaderLine(line, prevLine)) {
    if (currBlock) blocks.push(currBlock);
    currBlock = { header: line, details: [] };
  } else if (currBlock) {
    currBlock.details.push(line);
  }
}
if (currBlock) blocks.push(currBlock);

const timeRangeRegex = /(?:from\s*)?((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)?|(?:0?[1-9]|1[0-2]):[0-5][0-9])\s*(?:[-–—~]|to)+\s*((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)|(?:0?[1-9]|1[0-2]):[0-5][0-9])/i;

const sessions = [];
let sessId = 1;

for (const b of blocks) {
  const headerParts = b.header.split(/[\t\s]+/).filter(w => w.length > 0);
  const code = headerParts[0].replace(/^[\*\#\•\d\.\(\)\[\]\-]+/, '').toUpperCase().replace(/[^A-Z0-9\-]/g, '');
  
  let rawHeader = b.header;
  
  // Extract units before title cleaning
  let units = 3;
  const quadMatch = rawHeader.match(/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
  if (quadMatch) {
    let credit = parseInt(quadMatch[3]);
    if (credit >= 10 && credit % 11 === 0) credit = Math.round(credit / 11);
    units = credit > 0 ? credit : 3;
    rawHeader = rawHeader.substring(0, quadMatch.index);
  } else {
    const singleU = rawHeader.match(/\b([1-6](?:\.0)?)\s*(?:units?|credit|u)?\b/i);
    if (singleU) {
      units = Math.round(parseFloat(singleU[1]));
    }
  }
  
  // Clean subject title
  let title = rawHeader
    .replace(new RegExp('\\b' + code + '\\b', 'gi'), ' ')
    .replace(/\bBS[A-Z0-9\s-]+\b/gi, ' ')
    .replace(/\bH[1-5][A-Z0-9]*\b/gi, ' ')
    .replace(/\b[1-5][A-Z]{1,2}\b/g, ' ')
    .replace(/[|:;_\-–—]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
    
  title = deduplicateText(title);
  if (title.length < 3) title = code;
  
  // Process detail lines for Section, Room, Schedule(s), and Faculty
  let section = '4A';
  let room = 'TBA';
  let faculty = 'TBA';
  
  const schedEntries = [];
  
  for (let dIdx = 0; dIdx < b.details.length; dIdx++) {
    const dLine = b.details[dIdx].trim();
    if (!dLine) continue;
    
    // Check if section line (e.g. 'H4A')
    const secMatch = dLine.match(/\b(BSINFOTECH?\s*H?[1-5][A-Z0-9]*|H[1-5][A-Z0-9]*|[1-5][A-Z0-9]*)\b/i);
    if (secMatch && !dLine.includes(':') && !dLine.toUpperCase().includes('PM') && !dLine.toUpperCase().includes('AM')) {
      const sVal = secMatch[1].toUpperCase().replace(/^BSINFOTECH?\s*/, '').replace(/^H/, '');
      if (sVal.length <= 4) section = sVal;
    }
    
    // Check if room is present
    const roomMatch = dLine.match(/\b(Rm\s*\.?\s*\d+|Room\s*\d+|CL\s*\d+|Lab\s*\d+|ComLab\s*\d+|AVR\s*\d*|Gym|Online|TBA|LR\s*\d+|Bldg\s*\w+|ICT[-\s]?\d+|NB\s*\d+|LB\s*\d+)\b/i);
    if (roomMatch) {
      room = roomMatch[0].trim();
    }
    
    // Check if time is present on this line
    const tMatch = dLine.match(timeRangeRegex);
    if (tMatch) {
      const rawStart = tMatch[1].trim();
      const rawEnd = tMatch[2].trim();
      
      const endAmPm = rawEnd.toUpperCase().includes('PM') ? 'PM' : (rawEnd.toUpperCase().includes('AM') ? 'AM' : null);
      let startAmPm = rawStart.toUpperCase().includes('PM') ? 'PM' : (rawStart.toUpperCase().includes('AM') ? 'AM' : null);
      if (!startAmPm && endAmPm) {
        const startHour = parseInt(rawStart.split(':')[0]) || 8;
        const endHour = parseInt(rawEnd.split(':')[0]) || 12;
        if (endAmPm === 'PM' && startHour >= 7 && startHour <= 11 && (endHour === 12 || endHour <= 6)) {
          startAmPm = 'AM';
        } else {
          startAmPm = endAmPm;
        }
      }
      
      const startTime = normalizeTime(rawStart, startAmPm || 'AM');
      const endTime = normalizeTime(rawEnd, endAmPm || startAmPm || 'PM');
      
      // Days on this line or before time
      const days = parseDays(dLine.substring(0, tMatch.index));
      const resolvedDays = days.length > 0 ? days : parseDays(dLine);
      
      // Faculty after time or on next lines
      let facCandidate = dLine.substring(tMatch.index + tMatch[0].length).trim();
      
      if (facCandidate.endsWith(',') && dIdx + 1 < b.details.length) {
        facCandidate += ' ' + b.details[dIdx + 1].trim();
        dIdx++;
      } else if (facCandidate.length === 0 && dIdx + 1 < b.details.length) {
        const nextL = b.details[dIdx + 1].trim();
        if (!nextL.match(timeRangeRegex) && !isSubjectHeaderLine(nextL, dLine)) {
          facCandidate = nextL;
          if (facCandidate.endsWith(',') && dIdx + 2 < b.details.length) {
            facCandidate += ' ' + b.details[dIdx + 2].trim();
            dIdx++;
          }
          dIdx++;
        }
      }
      
      // Clean faculty
      faculty = cleanFacultyName(facCandidate);
      
      schedEntries.push({
        days: resolvedDays.length > 0 ? resolvedDays : ['Monday'],
        startTime,
        endTime,
        room,
        faculty
      });
    }
  }
  
  if (schedEntries.length === 0) {
    schedEntries.push({
      days: ['Monday'],
      startTime: '08:00 AM',
      endTime: '09:30 AM',
      room,
      faculty
    });
  }
  
  for (const entry of schedEntries) {
    for (const d of entry.days) {
      sessions.push({
        id: `cor_${sessId++}_${d.substring(0, 3).toLowerCase()}`,
        code,
        title,
        units,
        day: d,
        startTime: entry.startTime,
        endTime: entry.endTime,
        room: entry.room,
        faculty: entry.faculty,
        section
      });
    }
  }
}

// Calculate distinct units
const seenCodes = new Set();
let totalUnits = 0;
for (const s of sessions) {
  if (!seenCodes.has(s.code)) {
    seenCodes.add(s.code);
    totalUnits += s.units;
  }
}

console.log(`\n======================================================`);
console.log(`PARSED ${sessions.length} CLASS SESSIONS | DISTINCT UNITS: ${totalUnits}`);
console.log(`======================================================`);
sessions.forEach((s, i) => {
  console.log(`${String(i + 1).padStart(2, ' ')}. [${s.code.padEnd(8, ' ')}] "${s.title}" (${s.units}u) | ${s.day.padEnd(9, ' ')} ${s.startTime} - ${s.endTime} | Room: ${s.room.padEnd(5, ' ')} | Prof: ${s.faculty.padEnd(25, ' ')} | Sec: ${s.section}`);
});
