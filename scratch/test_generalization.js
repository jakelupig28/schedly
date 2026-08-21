const fs = require('fs');

// We test the engine against 4 different university COR formats

const testCases = [
  {
    name: 'Single Line Standard COR (PUP / PLM style)',
    rawText: `
      Republic of the Philippines
      Polytechnic University of the Philippines
      CERTIFICATE OF REGISTRATION
      Student No: 2023-00123-MN-0
      Name: DELA CRUZ, JUAN PEDRO
      Course: Bachelor of Science in Information Technology
      Year Level: 3rd Year
      Semester: 1st Semester AY 2026-2027
      Section: BSIT 3-1
      
      SCHEDULE OF CLASSES
      CODE SUBJECT TITLE UNITS SECTION SCHEDULE ROOM FACULTY
      IT 301 Web Development 3.0 3-1 M-TH 08:00 AM - 10:00 AM CL 1 Prof. Garcia, Maria
      IT 302 Database Administration 3.0 3-1 T-F 01:00 PM - 03:00 PM CL 2 Engr. Santos, Roberto
      GE 105 Purposive Communication 3.0 3-1 WED 09:00 AM - 12:00 PM Rm 304 Prof. Diaz, Elena
      PE 3 Physical Education 2.0 3-1 SAT 08:00 AM - 10:00 AM GYM Coach Ramos
      
      Total Units: 11.0
      ASSESSED FEES:
      Tuition Fee: 0.00
    `
  },
  {
    name: 'Multi-Schedule per Subject (UST / DLSU / State Univ style)',
    rawText: `
      University of Santo Tomas
      OFFICIAL ENROLMENT FORM
      Student ID: 2022145890
      Student Name: Santos, Maria Clara
      Program: Bachelor of Science in Computer Science
      Academic Year: 2026-2027 1st Term
      
      COURSE CODE | DESCRIPTIVE TITLE | UNITS | TIME & DAY | ROOM | INSTRUCTOR
      CS211 Data Structures and Algorithms 4.0
      MW 08:00 AM - 10:00 AM Rm 401 Dr. Mendoza, Alex
      F 08:00 AM - 11:00 AM CL 4 Dr. Mendoza, Alex
      CS212 Operating Systems Architecture 3.0
      TTH 01:00 PM - 02:30 PM Rm 302 Prof. Alcantara, Dan
      CS213 Software Engineering 1 3.0
      M/TH 03:00 PM - 04:30 PM Rm 205 Engr. Bautista, Carl
      
      Total Units Enrolled: 10.0
      SCHEDULE OF PAYMENT
    `
  },
  {
    name: 'EARIST Prototype Tabular Stream',
    rawLines: JSON.parse(fs.readFileSync('C:/Users/User/schedly/scratch/prototype_raw_lines.json', 'utf8'))
  }
];

// Let's run parser on all test cases!
console.log('Testing general parsing engine across all formats...');
