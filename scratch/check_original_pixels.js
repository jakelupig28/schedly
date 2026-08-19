const fs = require('fs');
const { PNG } = require('pngjs');

const imgPath = 'C:/Users/User/Downloads/template.png';
if (!fs.existsSync(imgPath)) {
  console.log('Original download file does not exist!');
  process.exit(1);
}

const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

const scaleX = png.width / 1080;
const scaleY = png.height / 1920;
const cx = 535 * scaleX;
const cy = 995 * scaleY;
const angle = -2.3859 * Math.PI / 180;

console.log(`Original size: ${png.width}x${png.height}`);

// Let's sample pixels in the Y range of the schedule text on the original image (Y = 2200 to 3800)
// and check if they are dark (lum < 190).
// Let's print out a few dark pixels to see their coordinates.
let samples = [];
for (let y = 2200; y < 4000; y += 50) {
  for (let x = 400; x < 2200; x += 100) {
    const idx = (png.width * y + x) * 4;
    const r = png.data[idx];
    const g = png.data[idx + 1];
    const b = png.data[idx + 2];
    const a = png.data[idx + 3];
    const lum = 0.299 * r + 0.587 * g + 0.114 * b;
    if (lum < 150) {
      // Map to unrotated 1080x1920 coordinates
      const dx = x - cx;
      const dy = y - cy;
      const cos = Math.cos(-angle);
      const sin = Math.sin(-angle);
      const ux = (cx + dx * cos - dy * sin) / scaleX;
      const uy = (cy + dx * sin + dy * cos) / scaleY;
      
      samples.push({ x, y, ux: ux.toFixed(1), uy: uy.toFixed(1), r, g, b, lum: lum.toFixed(1) });
      if (samples.length >= 30) break;
    }
  }
  if (samples.length >= 30) break;
}

console.log('Sample dark pixels in original template.png:', samples);
