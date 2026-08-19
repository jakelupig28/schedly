const fs = require('fs');
const { PNG } = require('pngjs');

const imgPath = 'c:/Users/User/schedly/assets/template.png';
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

const scaleX = png.width / 1080;
const scaleY = png.height / 1920;
const cx = 535 * scaleX;
const cy = 995 * scaleY;
const angle = -2.3859 * Math.PI / 180;

// Schedule rows bounding box
const box = { uxMin: 180, uxMax: 840, uyMin: 940, uyMax: 1600 };

let darkCount = 0;
let darkSamples = [];

for (let y = 0; y < png.height; y++) {
  for (let x = 0; x < png.width; x++) {
    const idx = (png.width * y + x) * 4;
    const a = png.data[idx + 3];
    if (a < 100) continue;

    const dx = x - cx;
    const dy = y - cy;
    const cos = Math.cos(-angle);
    const sin = Math.sin(-angle);
    const ux = (cx + dx * cos - dy * sin) / scaleX;
    const uy = (cy + dx * sin + dy * cos) / scaleY;

    if (ux >= box.uxMin && ux <= box.uxMax && uy >= box.uyMin && uy <= box.uyMax) {
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      
      // If a pixel is dark, count it
      if (lum < 192) {
        darkCount++;
        if (darkSamples.length < 10) {
          darkSamples.push({ x, y, ux: ux.toFixed(1), uy: uy.toFixed(1), r, g, b, lum: lum.toFixed(1) });
        }
      }
    }
  }
}

console.log(`Total dark pixels (lum < 192) inside schedule rows box: ${darkCount}`);
if (darkSamples.length > 0) {
  console.log(`Dark pixel samples:`, darkSamples);
}
