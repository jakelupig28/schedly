const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function printSubSlice(filename, startX, endX, startY, endY, threshold) {
  const imgPath = path.join(__dirname, '..', 'prototype', filename);
  if (!fs.existsSync(imgPath)) return;
  const png = PNG.sync.read(fs.readFileSync(imgPath));

  console.log(`\n--- ${filename} [${startX}-${endX}] ---`);
  for (let y = startY; y < endY; y++) {
    let line = '';
    for (let x = startX; x < endX; x++) {
      const idx = (png.width * y + x) * 4;
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const a = png.data[idx + 3];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      if (a > 100 && lum < threshold) {
        line += '#';
      } else {
        line += ' ';
      }
    }
    if (line.trim().length > 0) {
      console.log(`${String(y).padStart(3, ' ')}: ${line}`);
    }
  }
}

// Let's print slices of ref_top.png
printSubSlice('ref_top.png', 50, 400, 60, 220, 130);

// Let's print slices of ref_units.png
printSubSlice('ref_units.png', 10, 350, 10, 120, 130);

// Let's print slices of ref_course.png
printSubSlice('ref_course.png', 10, 500, 10, 150, 130);
