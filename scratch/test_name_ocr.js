const lines = [
  "Republic of the Philippines\tRepublic of the Philippines",
  "Eulogio Amang Rodriguez\tEulogio Amang Rodriguez",
  "Institute of Science and Technology\tInstitute of Science and Technology",
  "Nagtahan St. Sampaloc, Manila\tNagtahan St. Sampaloc, Manila",
  "C E R T I F I C A T E O F R E G I S T R A T I O N\tC E R T I F I C A T E O F R E G I S T R A T I O N",
  "Registration No :\tRegistration No : 2147483647\t2147483647 Academic Year/Term :\tAcademic Year/Term : First Semester AY 2026-2027\tFirst Semester AY 2026-2027",
  "STUDENT GENERAL INFORMATION\tSTUDENT GENERAL INFORMATION",
  "Student No\tStudent No\t:: 234-03154M\t234-03154M College\tCollege :: College of Computing Studies\tCollege of Computing Studies",
  "Name\tName\t:: LUPIG, JAKE GRUBA\tLUPIG, JAKE GRUBA Program\tProgram :: Bachelor of Science in Information Technology\tBachelor of Science in Information Technology",
  "Gender\tGender\t:: Male\tMale Major\tMajor :: Curriculum\tCurriculum :: 2018-2019\t2018-2019",
  "Age:\tAge:\t:: 23\t23 Year Level\tYear Level :: Fourth Year-Regular\tFourth Year-Regular Scholarship/Discount\tScholarship/Discount::",
  "Email Address:\tEmail Address:\t:: jakelupig28@gmail.com\tjakelupig28@gmail.com"
];

let extractedFName = '', extractedMName = '', extractedLName = '';

for (const line of lines) {
  // Normalize tabs to spaces first
  const normalized = line.replace(/\t+/g, ' ').trim();
  
  if (extractedFName === '') {
    // Check if line contains labeled student name (e.g. "Name :: LUPIG, JAKE GRUBA")
    const match = normalized.match(/(?:Student\s*Name|Name\s*of\s*Student|Student|Name)\s*(?:::|:|\-)\s*([A-Za-z\s,.-]+)/i);
    if (match) {
      let rawVal = match[1].trim();
      rawVal = rawVal.replace(/\s+(?:Program|Major|Curriculum|College|Scholarship|Year|Section|Student|Gender|Age).*$/i, '').trim();
      rawVal = rawVal.replace(/^(?:::|:|\-)\s*/, '').trim();

      if (rawVal.includes(',') && !rawVal.toLowerCase().includes('manila') && !rawVal.toLowerCase().includes('sampaloc')) {
        const parts = rawVal.split(',');
        extractedLName = parts[0].trim();
        const rest = parts[1].trim().split(/\s+/).filter(w => w.length > 0);
        if (rest.length === 1) {
          extractedFName = rest[0];
        } else if (rest.length === 2) {
          extractedFName = rest[0];
          extractedMName = rest[1];
        } else if (rest.length >= 3) {
          extractedMName = rest[rest.length - 1];
          extractedFName = rest.slice(0, -1).join(' ');
        }
      }
    }
  }
}

console.log('Extracted Name with normalized tabs:', { extractedFName, extractedMName, extractedLName });
