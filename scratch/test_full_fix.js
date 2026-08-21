const fs = require('fs');
const { PDFParse } = require('c:/Users/User/schedly/frontend/node_modules/pdf-parse');

async function testFullFix() {
  const dataBuffer = fs.readFileSync('C:/Users/User/schedly/frontend/prototype/Certificate_of_registration.pdf');
  const parser = new PDFParse({ data: dataBuffer });
  await parser.load();
  const textObj = await parser.getText();
  const rawText = textObj.text || '';
  const rawLines = rawText.split('\n');

  // 1. EXTRACT STUDENT HEADER
  let firstName = '', middleName = '', surname = '', studentNo = '', program = '', yearLevel = '', semester = '', schoolYear = '', section = '', email = '', age = '';

  for (const l of rawLines) {
    const line = l.trim();
    if (!line) continue;

    // Stop header extraction once table begins
    if (line.includes('Total Unit') || line.includes('ASSESSED') || line.includes('SCHEDULE OF PAYMENT')) {
      break;
    }

    // Name: strictly match "Name ::" or "Student Name :"
    if (surname === '' && /Name\s*(?:::|:)/i.test(line)) {
      const match = line.match(/Name\s*(?:::|:)\s*([A-Za-z\s]+),\s*([A-Za-z\s]+)/i);
      if (match) {
        surname = match[1].trim();
        const parts = match[2].trim().replace(/\s+(Program|Major|College|Curriculum).*$/i, '').trim().split(/\s+/);
        if (parts.length > 1) {
          middleName = parts[parts.length - 1];
          firstName = parts.slice(0, -1).join(' ');
        } else {
          firstName = parts[0];
        }
      }
    }

    // Student No
    if (studentNo === '' && /Student\s*No\s*(?:::|:)/i.test(line)) {
      const match = line.match(/Student\s*No\s*(?:::|:)\s*([A-Za-z0-9\-]+)/i);
      if (match) studentNo = match[1].trim();
    }

    // Program / Course
    if (program === '' && /Program\s*(?:::|:)/i.test(line)) {
      const match = line.match(/Program\s*(?:::|:)\s*([^\t\n]+)/i);
      if (match) {
        program = match[1].replace(/Major.*$/i, '').replace(/Curriculum.*$/i, '').trim();
      }
    }

    // Year Level
    if (yearLevel === '' && /Year\s*Level\s*(?:::|:)/i.test(line)) {
      const match = line.match(/Year\s*Level\s*(?:::|:)\s*([^\t\n]+)/i);
      if (match) {
        const yStr = match[1].toLowerCase();
        if (yStr.includes('first') || yStr.includes('1st')) yearLevel = '1st Year';
        else if (yStr.includes('second') || yStr.includes('2nd')) yearLevel = '2nd Year';
        else if (yStr.includes('third') || yStr.includes('3rd')) yearLevel = '3rd Year';
        else if (yStr.includes('fourth') || yStr.includes('4th')) yearLevel = '4th Year';
        else if (yStr.includes('fifth') || yStr.includes('5th')) yearLevel = '5th Year+';
      }
    }

    // Academic Year / Term (DO NOT match Payment Schedule!)
    if (semester === '' && /Academic\s*Year\/Term\s*(?:::|:)/i.test(line)) {
      const match = line.match(/(First|Second|1st|2nd|Summer|Midyear)\s*(?:Semester|Term)?\s*(?:AY\s*)?(\d{4}-\d{4})/i);
      if (match) {
        semester = match[1].toLowerCase().includes('first') || match[1].includes('1st') ? '1st Semester' : '2nd Semester';
        schoolYear = 'S.Y. ' + match[2];
      }
    }

    // Email
    if (email === '' && /Email\s*Address/i.test(line)) {
      const match = line.match(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/);
      if (match) email = match[1].trim();
    }

    // Age
    if (age === '' && /Age\s*(?:::|:)/i.test(line)) {
      const match = line.match(/Age\s*(?:::|:)\s*(\d{1,2})/i);
      if (match) age = match[1].trim();
    }
  }

  // Section cleaner
  function cleanSection(raw) {
    var s = raw.trim();
    s = s.replace(/^(?:Section|Sec|Block)\s*[:\-]?\s*/i, '').trim();
    const hMatch = s.match(/^H[-\s]?([1-5][A-Z0-9]*)$/i);
    if (hMatch) return hMatch[1].toUpperCase();
    const techMatch = s.match(/BSINFOTECH?\s*H?([1-5][A-Z0-9]*)/i);
    if (techMatch) return techMatch[1].toUpperCase();
    const directSec = s.match(/\b([1-5][A-Z0-9]*)\b/);
    if (directSec && !s.includes(':') && s.length <= 8) {
      return directSec[1].toUpperCase();
    }
    return s.length > 0 ? s : '4A';
  }

  console.log('=== FIXED STUDENT PROFILE ===');
  console.log({
    fullName: `${firstName} ${middleName} ${surname}`.trim(),
    studentNo,
    program,
    yearLevel,
    semester,
    schoolYear,
    email,
    age
  });

  // 2. EXTRACT TABLE SUBJECTS (Stop strictly before fees/payment)
  const isCode = (s) => /^[A-Z]{2,8}\d{0,4}[A-Z]{0,3}$/.test(s) && 
    !/^(M|T|W|TH|F|S|SAT|SUN|MWF|TTH|M\/TH|T\/TH|TH-S|CODE|LEC|LAB|CREDIT|TUITION|STUDENT|REGISTRATION|ACADEMIC|NAME|GENDER|AGE|EMAIL|KEEP|NOTE|TOTAL|SHEDULE|SECTION|RULES|PLEDGE|APPROVED|POWERED|LESS|NET|ATHLETIC|CULTURAL|DEVELOPMENT|GUIDANCE|LIBRARY|MEDICAL|COMPUTER|ASSESSED|TUITION|H4A|FIRST|SECOND|SUMMER|ROOM|FACULTY|REPUBLIC|PHILIPPINES|INSTITUTE|COLLEGE|PROGRAM)$/i.test(s);

  const timeRegex = /(?:([MTWTHFSAmtwthfsa\/\-\s]+)\s+)?(\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)\s*[-–—~to]+\s*(\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)/i;

  const subjects = [];

  for (let i = 0; i < rawLines.length; i++) {
    const rawLine = rawLines[i].trim();
    if (!rawLine) continue;

    // Hard boundary: STOP parsing table at footer/fees
    if (/Total\s*Unit/i.test(rawLine) || /ASSESSED\s*FEES/i.test(rawLine) || /SCHEDULE\s*OF\s*PAYMENT/i.test(rawLine) || /RULES\s*OF\s*REFUND/i.test(rawLine)) {
      break;
    }

    const parts = rawLine.split('\t').map(p => p.trim()).filter(p => p.length > 0);
    if (parts.length === 0) continue;

    const firstWord = parts[0].split(/\s+/)[0];
    if (isCode(firstWord)) {
      const code = firstWord;

      // Extract title: strip code, numbers, BSINFOTEC
      let rawTitle = parts.length > 1 ? parts[1] : '';
      if (rawTitle.startsWith(code)) {
        rawTitle = rawTitle.substring(code.length).trim();
      }

      // Extract units
      let units = 3;
      if (parts.length > 2) {
        const uMatch = parts[2].match(/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (uMatch) {
          let credit = parseInt(uMatch[3]);
          if (credit >= 10 && credit % 11 === 0) credit = credit / 11;
          units = credit;
        }
      }

      // Clean title: NEVER include subject code in title!
      let title = rawTitle
        .replace(new RegExp('\\b' + code + '\\b', 'gi'), '')
        .replace(/\bBS[A-Z0-9\s-]+\b/gi, '')
        .replace(/\b[A-Z][0-9][A-Z0-9]*\b/g, '')
        .replace(/\s+/g, ' ')
        .trim();

      if (title.length < 3) {
        title = code;
      }

      // Look ahead for Section & Schedule
      let schedSection = '4A';
      let rawDays = 'Monday';
      let startTime = '08:00 AM';
      let endTime = '09:30 AM';
      let faculty = 'TBA';

      let j = i + 1;
      while (j < rawLines.length) {
        const subLine = rawLines[j].trim();
        if (!subLine || /Total\s*Unit/i.test(subLine) || /ASSESSED/i.test(subLine) || /SCHEDULE\s*OF\s*PAYMENT/i.test(subLine)) break;

        const subParts = subLine.split('\t').map(p => p.trim()).filter(p => p.length > 0);
        if (subParts.length === 0) { j++; continue; }

        if (isCode(subParts[0].split(/\s+/)[0])) break;

        // Check if section line (e.g. 'H4A')
        if (/^[A-Z]?[1-5][A-Z0-9]*$/i.test(subParts[0]) || /^BS[A-Z0-9\s-]+$/i.test(subParts[0])) {
          schedSection = cleanSection(subParts[0]);
          section = schedSection;
        }

        // Check for schedule line
        const tm = subLine.match(timeRegex);
        if (tm) {
          if (tm[1]) rawDays = tm[1].trim();
          startTime = tm[2].trim();
          endTime = tm[3].trim();

          if (subParts.length >= 3) {
            faculty = subParts[2];
          } else {
            const after = subLine.substring(tm.index + tm[0].length).trim();
            if (after.length > 0) faculty = after;
          }

          if (j + 1 < rawLines.length) {
            const nextL = rawLines[j + 1].trim();
            const nextParts = nextL.split('\t').map(p => p.trim()).filter(p => p.length > 0);
            if (nextParts.length > 0 && !isCode(nextParts[0].split(/\s+/)[0]) && !nextL.match(timeRegex) && !/Total\s*Unit/i.test(nextL) && !/ASSESSED/i.test(nextL)) {
              if (/^[A-Z\s,.-]+$/i.test(nextParts[0]) && nextParts[0].length < 35 && !/^[A-Z]?[1-5][A-Z0-9]*$/i.test(nextParts[0])) {
                faculty += ' ' + nextParts[0];
                j++;
              }
            }
          }
        }
        j++;
      }

      i = j - 1;

      faculty = faculty.replace(/\s+/g, ' ').replace(/^,\s*/, '').trim();

      // Normalize Days (M/TH -> Monday, Thursday)
      const days = [];
      const normD = rawDays.toUpperCase().replace(/\s+/g, '');
      if (normD.includes('M/TH') || (normD.includes('M') && normD.includes('TH'))) {
        days.push('Monday', 'Thursday');
      } else if (normD.includes('MWF')) {
        days.push('Monday', 'Wednesday', 'Friday');
      } else if (normD.includes('TTH') || normD.includes('T/TH')) {
        days.push('Tuesday', 'Thursday');
      } else if (normD.includes('TH')) {
        days.push('Thursday');
      } else if (normD.includes('T')) {
        days.push('Tuesday');
      } else if (normD.includes('M')) {
        days.push('Monday');
      } else if (normD.includes('W')) {
        days.push('Wednesday');
      } else if (normD.includes('F')) {
        days.push('Friday');
      } else if (normD.includes('S')) {
        days.push('Saturday');
      } else {
        days.push('Monday');
      }

      const formatTime = (t) => {
        let norm = t.toUpperCase().replace(/\s+/g, '');
        if (!norm.includes('AM') && !norm.includes('PM')) norm += ' AM';
        const m = norm.match(/(\d{1,2})(?::(\d{2}))?\s*(AM|PM)/);
        if (m) {
          const hh = m[1].padStart(2, '0');
          const mm = m[2] || '00';
          const p = m[3];
          return `${hh}:${mm} ${p}`;
        }
        return t;
      };

      for (const day of days) {
        subjects.push({
          code,
          title,
          units,
          day,
          startTime: formatTime(startTime),
          endTime: formatTime(endTime),
          room: 'TBA',
          faculty,
          section: schedSection
        });
      }
    }
  }

  // Calculate distinct total units
  const seen = new Set();
  let totalUnits = 0;
  for (const s of subjects) {
    if (!seen.has(s.code)) {
      seen.add(s.code);
      totalUnits += s.units;
    }
  }

  console.log(`\n=== SCANNED ${subjects.length} CLASSES | DISTINCT UNITS: ${totalUnits} | SECTION: ${section} ===`);
  subjects.forEach((s, idx) => {
    console.log(`${String(idx + 1).padStart(2, ' ')}. [${s.code.padEnd(8, ' ')}] "${s.title}" | ${s.units} Units | ${s.day.padEnd(9, ' ')} ${s.startTime} - ${s.endTime} | Prof: ${s.faculty} | Sec: ${s.section}`);
  });
}

testFullFix().catch(console.error);
