const fs = require('fs');
const { PDFParse } = require('c:/Users/User/schedly/frontend/node_modules/pdf-parse');

async function testCompleteAccurateParse() {
  const dataBuffer = fs.readFileSync('C:/Users/User/schedly/frontend/prototype/Certificate_of_registration.pdf');
  const parser = new PDFParse({ data: dataBuffer });
  await parser.load();
  const textObj = await parser.getText();
  const rawText = textObj.text;
  
  // 1. EXTRACT STUDENT HEADER (Name, Student No, Program, Year, Section, Semester, School Year)
  let firstName = '', middleName = '', surname = '', studentNo = '', program = '', yearLevel = '4th Year', semester = '1st Semester', schoolYear = 'S.Y. 2026-2027', section = '4A', email = '';

  const allLines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  for (const line of allLines) {
    // Stop header scanning at table header or fees
    if (line.includes('Total Unit') || line.includes('ASSESSED') || line.includes('SCHEDULE OF PAYMENT')) {
      break;
    }

    // Name: match "Name ::" or "Name\tName\t::"
    if (surname === '' && /Name/i.test(line)) {
      const match = line.match(/(?:Student\s*Name|Name\s*of\s*Student|Student|Name)(?:[\s\t]+(?:Name|Student))?\s*(?:::|:|\-)?\s*([A-Za-z\s,.-]+)/i);
      if (match) {
        let rawVal = match[1].trim();
        rawVal = rawVal.replace(/\s+(?:Program|Major|Curriculum|College|Scholarship|Year|Section|Student|Gender|Age).*$/i, '').trim();
        rawVal = rawVal.replace(/^(?:::|:|\-)\s*/, '').trim();

        if (rawVal.includes(',') && !rawVal.toLowerCase().includes('manila') && !rawVal.toLowerCase().includes('sampaloc')) {
          const firstComma = rawVal.indexOf(',');
          surname = rawVal.substring(0, firstComma).trim();
          let rest = rawVal.substring(firstComma + 1).trim().split(/\s+/).filter(w => w.length > 0);
          const surIdx = rest.findIndex(w => w.toUpperCase() === surname.toUpperCase());
          if (surIdx > 0) rest = rest.slice(0, surIdx);

          if (rest.length === 1) {
            firstName = rest[0];
          } else if (rest.length === 2) {
            firstName = rest[0];
            middleName = rest[1];
          } else if (rest.length >= 3) {
            middleName = rest[rest.length - 1];
            firstName = rest.slice(0, -1).join(' ');
          }
        }
      }
    }

    // Student No
    if (studentNo === '' && /Student\s*No/i.test(line)) {
      const match = line.match(/Student\s*No(?:[\s\t]+Student\s*No)?\s*(?:::|:|\-)\s*([A-Za-z0-9\-]+)/i);
      if (match) studentNo = match[1].trim();
    }

    // Program
    if (program === '' && /Program/i.test(line)) {
      const match = line.match(/Program(?:[\s\t]+Program)?\s*(?:::|:|\-)\s*([^\t\n]+)/i);
      if (match) {
        program = match[1].replace(/Major.*$/i, '').replace(/Curriculum.*$/i, '').trim();
      }
    }

    // Academic Year / Term
    if (/Academic\s*Year/i.test(line)) {
      const match = line.match(/(First|Second|1st|2nd|Summer|Midyear)\s*(?:Semester|Term)?\s*(?:AY\s*)?(\d{4}-\d{4})/i);
      if (match) {
        semester = match[1].toLowerCase().includes('first') || match[1].includes('1st') ? '1st Semester' : '2nd Semester';
        schoolYear = 'S.Y. ' + match[2];
      }
    }

    // Section: find "BSINFOTEC H4A" or "H4A" or "SECTION"
    if (section === '4A' && /BSINFOTEC\s*H?([1-5][A-Z0-9]*)/i.test(line)) {
      const match = line.match(/BSINFOTEC\s*H?([1-5][A-Z0-9]*)/i);
      if (match) section = match[1].toUpperCase();
    }
  }

  // Capitalize full name
  const capitalize = (s) => s ? s.split(' ').map(w => w ? w[0].toUpperCase() + w.substring(1).toLowerCase() : '').join(' ') : '';
  const fullName = `${capitalize(firstName)} ${capitalize(middleName)} ${capitalize(surname)}`.replace(/\s+/g, ' ').trim();

  console.log('=== EXTRACTED STUDENT PROFILE ===');
  console.log({
    fullName,
    studentNo,
    program,
    yearLevel,
    semester,
    schoolYear,
    section
  });

  // 2. PARSE SUBJECTS WITH DEDICATED TABULAR STREAM CHUNKER
  const isCode = (s) => /^[A-Z]{2,8}\d{0,4}[A-Z]{0,3}$/.test(s) && 
    !/^(M|T|W|TH|F|S|SAT|SUN|MWF|TTH|M\/TH|T\/TH|TH-S|CODE|LEC|LAB|CREDIT|TUITION|STUDENT|REGISTRATION|ACADEMIC|NAME|GENDER|AGE|EMAIL|KEEP|NOTE|TOTAL|SHEDULE|SECTION|RULES|PLEDGE|APPROVED|POWERED|LESS|NET|ATHLETIC|CULTURAL|DEVELOPMENT|GUIDANCE|LIBRARY|MEDICAL|COMPUTER|ASSESSED|TUITION|H4A|FIRST|SECOND|SUMMER|ROOM|FACULTY|REPUBLIC|PHILIPPINES|INSTITUTE|COLLEGE|PROGRAM)$/i.test(s);

  const strictTimeRegex = /(?:from\s*)?((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)|(?:0?[1-9]|1[0-2]):[0-5][0-9])\s*(?:[-–—~]|to)+\s*((?:0?[1-9]|1[0-2])(?::[0-5][0-9])?\s*(?:AM|PM|am|pm)|(?:0?[1-9]|1[0-2]):[0-5][0-9])/i;

  const subjects = [];

  for (let i = 0; i < allLines.length; i++) {
    const line = allLines[i];
    if (/Total\s*Unit/i.test(line) || /ASSESSED\s*FEES/i.test(line) || /SCHEDULE\s*OF\s*PAYMENT/i.test(line)) {
      break;
    }

    const firstWord = line.split(/[\s\t]+/)[0];
    if (isCode(firstWord)) {
      const code = firstWord;
      const parts = line.split('\t').map(p => p.trim()).filter(p => p.length > 0);

      // Title
      let rawTitle = parts.length > 1 ? parts[1] : '';
      if (rawTitle.startsWith(code)) {
        rawTitle = rawTitle.substring(code.length).trim();
      }

      // Units
      let units = 3;
      if (parts.length > 2) {
        const uMatch = parts[2].match(/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (uMatch) {
          let credit = parseInt(uMatch[3]);
          if (credit >= 10 && credit % 11 === 0) credit = credit / 11;
          units = credit;
        }
      }

      // Clean Title
      let title = rawTitle
        .replace(new RegExp('\\b' + code + '\\b', 'gi'), '')
        .replace(/\bBS[A-Z0-9\s-]+\b/gi, '')
        .replace(/\b[A-Z]?[1-5][A-Z0-9]*\b/g, '')
        .replace(/\s+/g, ' ')
        .trim();

      if (title.length < 3) title = code;

      // Scan detail lines for Section, Schedule & Faculty
      let schedSection = '4A';
      let rawDays = 'Monday';
      let startTime = '08:00 AM';
      let endTime = '09:30 AM';
      let faculty = 'TBA';

      let j = i + 1;
      while (j < allLines.length) {
        const subLine = allLines[j];
        if (/Total\s*Unit/i.test(subLine) || /ASSESSED/i.test(subLine) || /SCHEDULE\s*OF\s*PAYMENT/i.test(subLine)) break;
        if (isCode(subLine.split(/[\s\t]+/)[0])) break;

        const subParts = subLine.split('\t').map(p => p.trim()).filter(p => p.length > 0);

        // Section line
        if (/^[A-Z]?[1-5][A-Z0-9]*$/i.test(subParts[0])) {
          let sec = subParts[0];
          if (/^H[1-5][A-Z0-9]*$/i.test(sec)) sec = sec.substring(1);
          schedSection = sec;
          section = sec;
        }

        // Schedule line
        const tm = subLine.match(strictTimeRegex);
        if (tm) {
          const beforeTime = subLine.substring(0, tm.index).trim();
          const dayMatch = beforeTime.match(/\b(MON|TUE|WED|THU|FRI|SAT|SUN|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|M-TH|T-TH|M-W-F|T-F|W-S|M\/W|T\/TH|M\/TH|MWF|TTH|TF|TH-S|M|T|W|TH|F|S)\b/i);
          if (dayMatch) rawDays = dayMatch[0];

          startTime = tm[1].trim();
          endTime = tm[2].trim();

          // Faculty
          if (subParts.length >= 3) {
            faculty = subParts[2];
          } else {
            const after = subLine.substring(tm.index + tm[0].length).trim();
            if (after.length > 0) faculty = after;
          }

          if (j + 1 < allLines.length) {
            const nextL = allLines[j + 1].trim();
            const nextParts = nextL.split('\t').map(p => p.trim()).filter(p => p.length > 0);
            if (nextParts.length > 0 && !isCode(nextParts[0].split(/[\s\t]+/)[0]) && !nextL.match(strictTimeRegex) && !/Total\s*Unit/i.test(nextL) && !/ASSESSED/i.test(nextL)) {
              if (/^[A-Za-z\s,.-]+$/i.test(nextParts[0]) && nextParts[0].length < 35 && !/^[A-Z]?[1-5][A-Z0-9]*$/i.test(nextParts[0])) {
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
        if (!norm.includes('AM') && !norm.includes('PM')) {
          const h = parseInt(norm.split(':')[0]);
          if (h >= 7 && h <= 11) norm += ' AM';
          else norm += ' PM';
        }
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

testCompleteAccurateParse().catch(console.error);
