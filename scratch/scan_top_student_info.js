const fs = require('fs');
const { PNG } = require('pngjs');

const imgPath = 'C:/Users/User/Downloads/template.png';
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

const scaleX = png.width / 1080;
const scaleY = png.height / 1920;
const cx = 535 * scaleX;
const cy = 995 * scaleY;
const angle = -2.3859 * Math.PI / 180;

console.log('Scanning top student info region (uy between 700 and 860):');
let topMinX = 9999, topMaxX = -9999, topMinY = 9999, topMaxY = -9999;
let topCount = 0;

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

    if (ux >= 180 && ux <= 840 && uy >= 700 && uy <= 900) {
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      
      if (lum < 192) {
        topCount++;
        if (ux < topMinX) topMinX = ux;
        if (ux > topMaxX) topMaxX = ux;
        if (uy < topMinY) topMinY = uy;
        if (uy > topMaxY) topMaxY = uy;
      }
    }
  }
}

console.log(`Found ${topCount} dark pixels in top region. Bounds: ux [${topMinX.toFixed(1)}, ${topMaxX.toFixed(1)}], uy [${topMinY.toFixed(1)}, ${topMaxY.toFixed(1)}]`);

console.log('\nScanning bottom student info region (uy between 1600 and 1750):');
let botMinX = 9999, botMaxX = -9999, botMinY = 9999, botMaxY = -9999;
let botCount = 0;

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

    if (ux >= 180 && ux <= 840 && uy >= 1600 && uy <= 1750) {
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      
      if (lum < 192) {
        botCount++;
        if (ux < botMinX) botMinX = ux;
        if (ux > botMaxX) botMaxX = ux;
        if (uy < botMinY) botMinY = uy;
        if (uy > botMaxY) botMaxY = uy;
      }
    }
  }
}

console.log(`Found ${botCount} dark pixels in bottom region. Bounds: ux [${botMinX.toFixed(1)}, ${botMaxX.toFixed(1)}], uy [${botMinY.toFixed(1)}, ${botMaxY.toFixed(1)}]`);
