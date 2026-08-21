const fs = require('fs');

function cleanFacultyName(raw) {
  let s = deduplicateText(raw);
  
  // Remove any time tokens / ranges
  s = s.replace(/(?:from\s*)?\b\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\s*(?:[-–—~]|to)+\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM|am|pm)?\b/gi, ' ');
  s = s.replace(/\b\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?\b/gi, ' ');
  s = s.replace(/\b(?:AM|PM|am|pm)\b/g, ' ');
  
  // Remove day tokens / combinations
  s = s.replace(/\b(?:MON|TUE|WED|THU|FRI|SAT|SUN|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)\b/gi, ' ');
  s = s.replace(/\b(?:M[\/\-]TH|T[\/\-]TH|M[\/\-]W[\/\-]F|T[\/\-]F|W[\/\-]S|M[\/\-]W|MWF|TTH|TF|THS|MTH)\b/gi, ' ');
  s = s.replace(/\b[MTWFS]\b/g, ' ');
  
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

console.log('Cleaned Prof 1:', cleanFacultyName('M/th 01:00pm-02:30pm Tebang, Ricky'));
console.log('Cleaned Prof 2:', cleanFacultyName('T 07:00am-10:00am Lagda, Erwinaldgeriko'));
console.log('Cleaned Prof 3:', cleanFacultyName('Th 06:00pm-09:00pm Carlos, Ernanie'));
