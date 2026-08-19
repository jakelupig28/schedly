const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'ref_top.png');
const png = PNG.sync.read(fs.readFileSync(imgPath));

console.log('Printing EARIST Right row (Y: 135 to 195, X: 400 to 950):');
for (let y = 135; y < 195; y++) {
  let line = '';
  // 1:1 scale (no x-stepping) but narrow columns
  for (let x = 400; x < 950; x++) {
    const idx = (png.width * y + x) * 4;
    const r = png.data[idx];
    const g = png.data[idx + 1];
    const b = png.data[idx + 2];
    const a = png.data[idx + 3];
    const lum = 0.299 * r + 0.587 * g + 0.114 * b;
    if (a > 100 && lum < 140) {
      line += '#';
    } else {
      line += ' ';
    }
  }
  if (line.trim().length > 0) {
    // Print row Y and the characters
    console.log(`${String(y).padStart(3, ' ')}: ${line.substring(0, 120)}`);
  }
}
