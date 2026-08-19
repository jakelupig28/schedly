const fs = require('fs');
const { PNG } = require('pngjs');

const imgPath = 'c:/Users/User/schedly/prototype/template.png';
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

// Check color at original text coordinates
const x = 1200;
const y = 2350;
const idx = (png.width * y + x) * 4;
const r = png.data[idx];
const g = png.data[idx + 1];
const b = png.data[idx + 2];
const a = png.data[idx + 3];
const lum = 0.299 * r + 0.587 * g + 0.114 * b;

console.log(`At original text pixel (1200, 2350) inside cleaned image:`);
console.log(`RGB: (${r}, ${g}, ${b}), Alpha: ${a}, Lum: ${lum.toFixed(1)}`);
