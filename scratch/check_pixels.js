const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = 'c:/Users/User/schedly/prototype/template.png';
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

const scaleX = png.width / 1080;
const scaleY = png.height / 1920;
const cx = 535 * scaleX;
const cy = 995 * scaleY;
const angle = -2.3859 * Math.PI / 180;

const boxes = [
  { name: 'Top student info', uxMin: 180, uxMax: 840, uyMin: 720, uyMax: 835 },
  { name: 'Schedule rows', uxMin: 180, uxMax: 840, uyMin: 940, uyMax: 1600 },
  { name: 'Bottom student info', uxMin: 180, uxMax: 840, uyMin: 1622, uyMax: 1730 }
];

console.log(`Image size: ${png.width}x${png.height}`);

for (const box of boxes) {
  let darkPixels = [];
  for (let y = 0; y < png.height; y++) {
    for (let x = 0; x < png.width; x++) {
      const idx = (png.width * y + x) * 4;
      const a = png.data[idx + 3];
      if (a < 100) continue; // skip transparent

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
        if (lum < 192) {
          darkPixels.push({ x, y, ux, uy, r, g, b, lum });
        }
      }
    }
  }
  console.log(`Box "${box.name}": found ${darkPixels.length} dark pixels remaining.`);
  if (darkPixels.length > 0) {
    console.log(`Sample of remaining dark pixels:`, darkPixels.slice(0, 5));
  }
}
