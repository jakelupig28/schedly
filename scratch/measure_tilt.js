const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'trans bg.png');
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

console.log(`Image dimensions: ${png.width}x${png.height}`);

// Let's find the top asterisk line (around Y=900-980)
// We will scan column by column at X=200 and X=800
function findFirstDarkPixelY(x) {
  for (let y = 900; y < 980; y++) {
    const idx = (png.width * y + x) << 2;
    const r = png.data[idx];
    const g = png.data[idx + 1];
    const b = png.data[idx + 2];
    const a = png.data[idx + 3];

    // Check for dark brown color of the printed text/asterisks
    if (a > 150 && (r < 120 && g < 100 && b < 90)) {
      return y;
    }
  }
  return null;
}

const yLeft = findFirstDarkPixelY(200);
const yRight = findFirstDarkPixelY(800);

console.log(`At X=200, first dark pixel Y=${yLeft}`);
console.log(`At X=800, first dark pixel Y=${yRight}`);

if (yLeft && yRight) {
  const dx = 800 - 200;
  const dy = yRight - yLeft;
  const rad = Math.atan2(dy, dx);
  const deg = rad * 180 / Math.PI;
  console.log(`Difference: dy=${dy} pixels over dx=${dx} pixels`);
  console.log(`Tilt Angle: ${deg.toFixed(4)} degrees (${rad.toFixed(6)} radians)`);
} else {
  console.log("Could not find the dark pixels at the specified X coordinates.");
}
