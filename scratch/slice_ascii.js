const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function sliceAscii(filename, startX, endX, startY, endY, threshold) {
  const imgPath = path.join(__dirname, '..', 'prototype', filename);
  if (!fs.existsSync(imgPath)) {
    console.log(`${filename} does not exist.`);
    return;
  }
  const data = fs.readFileSync(imgPath);
  const png = PNG.sync.read(data);

  console.log(`\n======================================================`);
  console.log(`1:1 Slice of ${filename}: X [${startX}-${endX}], Y [${startY}-${endY}]`);
  console.log(`======================================================`);

  for (let y = startY; y < endY; y++) {
    if (y < 0 || y >= png.height) continue;
    let line = '';
    for (let x = startX; x < endX; x++) {
      if (x < 0 || x >= png.width) continue;
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
    // Only print lines that contain some pixels
    if (line.trim().length > 0) {
      console.log(`${String(y).padStart(3, ' ')}: ${line}`);
    }
  }
}

// ref_top.png is 1091x310.
// Let's print slices of ref_top.png
// X=0 to 600, Y=50 to 250
sliceAscii('ref_top.png', 50, 600, 40, 260, 135);

// Let's print ref_units.png (485x286)
sliceAscii('ref_units.png', 0, 480, 0, 280, 135);

// Let's print ref_course.png (1237x239)
sliceAscii('ref_course.png', 0, 800, 0, 230, 135);
