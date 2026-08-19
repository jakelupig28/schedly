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

// Scan vertically to find groups of dark pixels
const rowStats = [];
for (let uy = 1580; uy <= 1780; uy += 0.5) {
  let darkCount = 0;
  for (let ux = 180; ux <= 840; ux += 1) {
    const cos = Math.cos(angle);
    const sin = Math.sin(angle);
    const dx = ux * scaleX - cx;
    const dy = uy * scaleY - cy;
    
    const x = Math.round(cx + dx * cos - dy * sin);
    const y = Math.round(cy + dx * sin + dy * cos);

    if (x >= 0 && x < png.width && y >= 0 && y < png.height) {
      const idx = (png.width * y + x) * 4;
      const r = png.data[idx];
      const g = png.data[idx + 1];
      const b = png.data[idx + 2];
      const a = png.data[idx + 3];
      if (a > 100) {
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;
        if (lum < 192) {
          darkCount++;
        }
      }
    }
  }
  rowStats.push({ uy, darkCount });
}

let inText = false;
let startY = 0;
let maxDark = 0;

for (const stat of rowStats) {
  if (stat.darkCount > 10) {
    if (!inText) {
      inText = true;
      startY = stat.uy;
    }
    if (stat.darkCount > maxDark) maxDark = stat.darkCount;
  } else {
    if (inText) {
      console.log(`Text row: uy [${startY.toFixed(1)} - ${stat.uy.toFixed(1)}] (Max dark pixels: ${maxDark})`);
      inText = false;
      maxDark = 0;
    }
  }
}
if (inText) {
  console.log(`Text row: uy [${startY.toFixed(1)} - 1780.0] (Max dark pixels: ${maxDark})`);
}
