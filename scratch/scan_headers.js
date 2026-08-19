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

console.log('Scanning for headers and lines (uy between 800 and 960):');

for (let y = 0; y < png.height; y += 4) { // scan every 4th line for speed
  for (let x = 0; x < png.width; x += 4) {
    const idx = (png.width * y + x) * 4;
    const a = png.data[idx + 3];
    if (a < 100) continue;

    const dx = x - cx;
    const dy = y - cy;
    const cos = Math.cos(-angle);
    const sin = Math.sin(-angle);
    const ux = (cx + dx * cos - dy * sin) / scaleX;
    const uy = (cy + dx * sin + dy * cos) / scaleY;

    if (ux >= 180 && ux <= 840 && uy >= 800 && uy <= 960) {
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;
      
      if (lum < 200) {
        // Let's print out samples if we find colored pixels (like blue) or asterisk patterns
        // Blue header text has higher B than R/G
        if (b > r + 30 && b > g + 15) {
          console.log(`[BLUE HEADER] ux: ${ux.toFixed(1)}, uy: ${uy.toFixed(1)}, RGB: (${r}, ${g}, ${b})`);
        }
      }
    }
  }
}

console.log('\nScanning for asterisk dividers at top of schedule (uy 830 to 870 & 910 to 950):');
let line1MinY = 9999, line1MaxY = -9999;
let line2MinY = 9999, line2MaxY = -9999;

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

    if (ux >= 180 && ux <= 840) {
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const lum = 0.299 * r + 0.587 * g + 0.114 * b;

      if (lum < 192) {
        // Line 1 is around uy 830 to 865
        if (uy >= 830 && uy <= 865) {
          if (uy < line1MinY) line1MinY = uy;
          if (uy > line1MaxY) line1MaxY = uy;
        }
        // Line 2 is around uy 910 to 945
        if (uy >= 910 && uy <= 945) {
          if (uy < line2MinY) line2MinY = uy;
          if (uy > line2MaxY) line2MaxY = uy;
        }
      }
    }
  }
}

console.log(`Asterisk Line 1 bounds: uy [${line1MinY.toFixed(1)}, ${line1MaxY.toFixed(1)}]`);
console.log(`Asterisk Line 2 bounds: uy [${line2MinY.toFixed(1)}, ${line2MaxY.toFixed(1)}]`);
