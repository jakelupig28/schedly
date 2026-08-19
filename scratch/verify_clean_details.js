const fs = require('fs');
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
  { name: "Top student info (4th Year, etc.)", uxMin: 180, uxMax: 840, uyMin: 700, uyMax: 825 },
  { name: "Schedule left col (Day & Subject)", uxMin: 180, uxMax: 520, uyMin: 940, uyMax: 1600 },
  { name: "Schedule right col (Time)", uxMin: 605, uxMax: 840, uyMin: 940, uyMax: 1600 },
  { name: "Bottom student info (Item Count & Total)", uxMin: 180, uxMax: 840, uyMin: 1620, uyMax: 1650 },
  { name: "Bottom student info (Course text)", uxMin: 180, uxMax: 840, uyMin: 1695, uyMax: 1725 }
];

boxes.forEach(box => {
  let darkCount = 0;
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
        if (lum < 192) {
          darkCount++;
        }
      }
    }
  }
  console.log(`Box "${box.name}": found ${darkCount} dark pixels.`);
});
