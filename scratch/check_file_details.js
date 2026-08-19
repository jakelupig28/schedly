const fs = require('fs');

const p1 = 'C:/Users/User/Downloads/template.png';
const p2 = 'c:/Users/User/schedly/prototype/template.png';

console.log('File 1 (Downloads/template.png):');
if (fs.existsSync(p1)) {
  const stat1 = fs.statSync(p1);
  console.log(`Size: ${stat1.size} bytes, Modified: ${stat1.mtime}`);
} else {
  console.log('Does not exist');
}

console.log('File 2 (prototype/template.png):');
if (fs.existsSync(p2)) {
  const stat2 = fs.statSync(p2);
  console.log(`Size: ${stat2.size} bytes, Modified: ${stat2.mtime}`);
} else {
  console.log('Does not exist');
}
