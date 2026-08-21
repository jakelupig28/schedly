const fs = require('fs');
const { PDFParse } = require('c:/Users/User/schedly/frontend/node_modules/pdf-parse');

async function parseEaristPDF() {
  const dataBuffer = fs.readFileSync('C:/Users/User/schedly/frontend/prototype/Certificate_of_registration.pdf');
  const parser = new PDFParse({ data: dataBuffer });
  await parser.load();
  const textObj = await parser.getText();
  const rawText = textObj.text || '';
  
  // Extract Student Info
  let firstName = '', middleName = '', surname = '', program = '', yearLevel = '', semester = '1st Semester', schoolYear = 'S.Y. 2026-2027', studentNo = '', email = '', age = '', section = 'H4A';
  
  const rawLines = rawText.split('\n');
  for (const l of rawLines) {
    if (l.includes('Name') && l.includes('::')) {
      const match = l.match(/Name\s*(?:::|:)\s*([A-Z\s]+),\s*([A-Z\s]+)/i);
      if (match) {
        surname = match[1].trim();
        const parts = match[2].trim().split(/\s+/);
        if (parts.length > 1) {
          middleName = parts[parts.length - 1];
          firstName = parts.slice(0, -1).join(' ');
        } else {
          firstName = parts[0];
        }
      }
    }
    if (l.includes('Program') && (l.includes('::') || l.includes(':'))) {
      const match = l.match(/Program\s*(?:::|:)\s*([^\t\n]+)/i);
      if (match) {
        program = match[1].replace(/Major.*$/, '').replace(/Curriculum.*$/, '').trim();
      }
    }
    if (l.includes('Email Address') && (l.includes('::') || l.includes(':'))) {
      const match = l.match(/([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/);
      if (match) email = match[1].trim();
    }
    if (l.includes('Age') && (l.includes('::') || l.includes(':'))) {
      const match = l.match(/Age\s*(?:::|:)\s*(\d+)/i);
      if (match) age = match[1].trim();
    }
    if (l.includes('Student No') && (l.includes('::') || l.includes(':'))) {
      const match = l.match(/Student\s*No\s*(?:::|:)\s*([A-Z0-9-]+)/i);
      if (match) studentNo = match[1].trim();
    }
    if (l.includes('Academic Year/Term') && l.includes(':')) {
      const match = l.match(/(First|Second|1st|2nd|Summer|Midyear)\s*(?:Semester|Term)?\s*(?:AY\s*)?(\d{4}-\d{4})/i);
      if (match) {
        semester = match[1].toLowerCase().includes('first') || match[1].includes('1st') ? '1st Semester' : '2nd Semester';
        schoolYear = 'S.Y. ' + match[2];
      }
    }
    if (l.includes('Year Level') && (l.includes('::') || l.includes(':'))) {
      const match = l.match(/Year\s*Level\s*(?:::|:)\s*([^\t]+)/i);
      if (match) {
        const yStr = match[1].toLowerCase();
        if (yStr.includes('first')) yearLevel = '1st Year';
        else if (yStr.includes('second')) yearLevel = '2nd Year';
        else if (yStr.includes('third')) yearLevel = '3rd Year';
        else if (yStr.includes('fourth')) yearLevel = '4th Year';
        else if (yStr.includes('fifth')) yearLevel = '5th Year+';
      }
    }
  }
  
  console.log('=== EXTRACTED STUDENT INFO ===');
  console.log({ firstName, middleName, surname, studentNo, program, yearLevel, semester, schoolYear, email, age });

  // Parse Table Lines
  const timeRegex = /(?:([MTWTHFSAmtwthfsa\/\-\s]+)\s+)?(\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)\s*[-–—~to]+\s*(\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?)/i;
  const isCode = (s) => /^[A-Z]{2,8}\d{0,4}[A-Z]{0,3}$/.test(s) && 
    !/^(M|T|W|TH|F|S|SAT|SUN|MWF|TTH|M\/TH|T\/TH|TH-S|CODE|LEC|LAB|CREDIT|TUITION|STUDENT|REGISTRATION|ACADEMIC|NAME|GENDER|AGE|EMAIL|KEEP|NOTE|TOTAL|SHEDULE|SECTION|RULES|PLEDGE|APPROVED|POWERED|LESS|NET|ATHLETIC|CULTURAL|DEVELOPMENT|GUIDANCE|LIBRARY|MEDICAL|COMPUTER|ASSESSED|TUITION|H4A)$/i.test(s);

  const subjects = [];

  for (let i = 0; i < rawLines.length; i++) {
    const rawLine = rawLines[i].trim();
    if (!rawLine) continue;
    if (rawLine.includes('Total Unit') || rawLine.includes('ASSESSED FEES')) break;

    const parts = rawLine.split('\t').map(p => p.trim()).filter(p => p.length > 0);
    if (parts.length === 0) continue;

    const codeCandidate = parts[0];
    if (isCode(codeCandidate)) {
      const code = codeCandidate;

      // Extract title from parts[1] (e.g. "GECONTWO The Contemporary World" -> "The Contemporary World")
      let rawTitle = parts.length > 1 ? parts[1] : '';
      if (rawTitle.startsWith(code)) {
        rawTitle = rawTitle.substring(code.length).trim();
      }

      // Extract units from parts[2] (e.g. "The Contemporary World 33 00 33 33 BSINFOTEC")
      let units = 3;
      if (parts.length > 2) {
        const uMatch = parts[2].match(/(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        if (uMatch) {
          let credit = parseInt(uMatch[3]);
          if (credit >= 10 && credit % 11 === 0) credit = credit / 11;
          units = credit;
        } else {
          const singleU = parts[2].match(/\b([1-6])\b/);
          if (singleU) units = parseInt(singleU[1]);
        }
      }

      const title = rawTitle.replace(/\s+/g, ' ').trim();

      // Look ahead for Section and Schedule / Faculty
      let schedSection = 'H4A';
      let rawDays = 'Monday';
      let startTime = '08:00 AM';
      let endTime = '09:30 AM';
      let faculty = 'TBA';

      let j = i + 1;
      while (j < rawLines.length) {
        const subLine = rawLines[j].trim();
        if (!subLine || subLine.includes('Total Unit') || subLine.includes('ASSESSED')) break;

        const subParts = subLine.split('\t').map(p => p.trim()).filter(p => p.length > 0);
        if (subParts.length === 0) { j++; continue; }

        if (isCode(subParts[0])) break; // Reached next subject

        // Check if section line (e.g. 'H4A')
        if (/^[A-Z][0-9][A-Z0-9]*$/.test(subParts[0]) || /^BS[A-Z0-9\s-]+$/.test(subParts[0])) {
          schedSection = subParts[0];
        }

        // Check for schedule line
        const tm = subLine.match(timeRegex);
        if (tm) {
          if (tm[1]) rawDays = tm[1].trim();
          startTime = tm[2].trim();
          endTime = tm[3].trim();

          // Faculty is in subParts[2] or after time match
          if (subParts.length >= 3) {
            faculty = subParts[2];
          } else {
            const after = subLine.substring(tm.index + tm[0].length).trim();
            if (after.length > 0) faculty = after;
          }

          // Check if faculty name continues to next line (e.g. 'ERWINALDGERIKO')
          if (j + 1 < rawLines.length) {
            const nextL = rawLines[j + 1].trim();
            const nextParts = nextL.split('\t').map(p => p.trim()).filter(p => p.length > 0);
            if (nextParts.length > 0 && !isCode(nextParts[0]) && !nextL.match(timeRegex) && !nextL.includes('Total Unit') && !nextL.includes('ASSESSED')) {
              if (/^[A-Z\s,.-]+$/i.test(nextParts[0]) && nextParts[0].length < 35 && !/^[A-Z][0-9][A-Z0-9]*$/.test(nextParts[0])) {
                faculty += ' ' + nextParts[0];
                j++;
              }
            }
          }
        }

        j++;
      }

      i = j - 1;

      // Clean faculty formatting
      faculty = faculty.replace(/\s+/g, ' ').replace(/^,\s*/, '').trim();

      // Normalize Day Tokens
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

  console.log('\n=== PARSED ALL ' + subjects.length + ' CLASS SESSIONS ===');
  subjects.forEach((s, idx) => {
    console.log(`${String(idx + 1).padStart(2, ' ')}. [${s.code.padEnd(8, ' ')}] ${s.title.padEnd(52, ' ')} | ${s.units} Units | ${s.day.padEnd(9, ' ')} ${s.startTime} - ${s.endTime} | Prof: ${s.faculty} | Sec: ${s.section}`);
  });
}

parseEaristPDF().catch(console.error);
