const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const originalPath = 'C:\\Users\\User\\Downloads\\trans bg.png';
const data = fs.readFileSync(originalPath);
const png = PNG.sync.read(data);

console.log(`Original image dimensions: ${png.width}x${png.height}`);

// Let's inspect rows from Y=900 to Y=1680 to find exact Y of asterisk lines and schedule text!
for (let y = 920; y <= 1680; y++) {
  let asteriskCount = 0;
  let darkPixelCount = 0;
  
  for (let x = 160; x <= 880; x++) {
    const idx = (png.width * y + x) << 2;
    const r = png.data[idx];
    const g = png.data[idx + 1];
    const b = png.data[idx + 2];
    const a = png.data[idx + 3];

    // Dark brown asterisk/text color
    if (a > 150 && (r < 120 && g < 100 && b < 90)) {
      darkPixelCount++;
    }
  }

  if (darkPixelCount > 30) {
    console.log(`y=${y}: ${darkPixelCount} dark pixels`);
  }
}
