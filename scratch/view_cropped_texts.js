const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function renderAscii(filename, targetW, threshold) {
  const imgPath = path.join(__dirname, '..', 'prototype', filename);
  if (!fs.existsSync(imgPath)) {
    console.log(`${filename} does not exist.`);
    return;
  }
  const data = fs.readFileSync(imgPath);
  const png = PNG.sync.read(data);
  const targetH = Math.round(png.height * (targetW / png.width) * 0.5);

  console.log(`\n--- ASCII Art of ${filename} (${png.width}x${png.height}) ---`);
  for (let y = 0; y < targetH; y++) {
    let line = '';
    for (let x = 0; x < targetW; x++) {
      const srcX = Math.floor(x * (png.width / targetW));
      const srcY = Math.floor(y * (png.height / targetH));
      const idx = (png.width * srcY + srcX) * 4;
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const a = png.data[idx + 3];
      
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      // High contrast check
      if (a > 50 && lum < threshold) {
        line += '#';
      } else {
        line += ' ';
      }
    }
    console.log(line);
  }
}

// Let's run with reasonable parameters
renderAscii('ref_top.png', 100, 160);
renderAscii('ref_units.png', 80, 160);
renderAscii('ref_course.png', 80, 160);
renderAscii('ref_schedule.png', 100, 160);
