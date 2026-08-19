const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function renderHighResAscii(filename, targetW, threshold) {
  const imgPath = path.join(__dirname, '..', 'prototype', filename);
  if (!fs.existsSync(imgPath)) {
    console.log(`${filename} does not exist.`);
    return;
  }
  const data = fs.readFileSync(imgPath);
  const png = PNG.sync.read(data);
  // Calculate aspect ratio. We want the text to look normal (height of character is about 1.8x width in standard font console)
  const targetH = Math.round(png.height * (targetW / png.width) * 0.5);

  console.log(`\n======================================================`);
  console.log(`ASCII Art: ${filename} (${png.width}x${png.height})`);
  console.log(`======================================================`);
  
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
      
      if (a > 100 && lum < threshold) {
        line += '#';
      } else {
        line += ' ';
      }
    }
    console.log(line);
  }
}

renderHighResAscii('ref_top.png', 160, 150);
renderHighResAscii('ref_units.png', 100, 150);
renderHighResAscii('ref_course.png', 120, 150);
