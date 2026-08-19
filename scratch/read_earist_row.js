const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'ref_top.png');
const png = PNG.sync.read(fs.readFileSync(imgPath));

console.log('Printing EARIST row (Y: 135 to 195, X: 50 to 1050):');
for (let y = 135; y < 195; y++) {
  let line = '';
  // Print in groups of 4 pixels to make it fit in console width (1000 pixels / 4 = 250 characters)
  for (let x = 50; x < 1050; x += 4) {
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
    console.log(`${String(y).padStart(3, ' ')}: ${line}`);
  }
}
