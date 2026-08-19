const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'ref_top.png');
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

const targetW = 120;
const targetH = Math.round(png.height * (targetW / png.width) * 0.55); // account for font aspect ratio

console.log(`ASCII Art of ref_top.png (${png.width}x${png.height} scaled to ${targetW}x${targetH}):`);

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
    
    // Check if pixel is dark (text color is dark brown/black)
    const lum = 0.299 * r + 0.587 * g + 0.114 * b;
    if (a > 100 && lum < 150) {
      line += '#';
    } else {
      line += ' ';
    }
  }
  console.log(line);
}
