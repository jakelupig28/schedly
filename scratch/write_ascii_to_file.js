const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

let output = '';

function printSubSlice(filename, startX, endX, startY, endY, threshold) {
  const imgPath = path.join(__dirname, '..', 'prototype', filename);
  if (!fs.existsSync(imgPath)) return;
  const png = PNG.sync.read(fs.readFileSync(imgPath));

  output += `\n======================================================\n`;
  output += `${filename} [X: ${startX}-${endX}, Y: ${startY}-${endY}]\n`;
  output += `======================================================\n`;
  
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
      output += `${String(y).padStart(3, ' ')}: ${line}\n`;
    }
  }
}

// Write top info parts:
// We'll print three horizontal parts of the top section:
printSubSlice('ref_top.png', 50, 450, 60, 240, 130);
printSubSlice('ref_top.png', 450, 950, 60, 240, 130);

// Write units part:
printSubSlice('ref_units.png', 10, 450, 10, 150, 130);

// Write course part:
printSubSlice('ref_course.png', 10, 700, 10, 180, 130);

fs.writeFileSync(path.join(__dirname, 'ascii_output.txt'), output);
console.log('Saved ASCII output to scratch/ascii_output.txt');
