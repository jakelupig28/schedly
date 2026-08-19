const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const originalPath = 'C:\\Users\\User\\Downloads\\trans bg.png';
const targets = [
  path.join(__dirname, '..', 'trans bg.png'),
  path.join(__dirname, '..', 'assets', 'trans bg.png'),
  path.join(__dirname, '..', 'prototype', 'trans bg.png')
];

const data = fs.readFileSync(originalPath);
const png = PNG.sync.read(data);

// Paper background color inside receipt: RGB(248, 249, 244), Alpha 255
const paperR = 248, paperG = 249, paperB = 244, paperA = 255;

// Wipe ONLY schedule text rows: X [170, 860], Y [980, 1575]
// (Stopping cleanly at Y=1575 to keep the bottom asterisk line Y=1595-1620 100% sharp and intact with zero fading!)
for (let y = 980; y <= 1575; y++) {
  for (let x = 170; x <= 860; x++) {
    const idx = (png.width * y + x) << 2;
    png.data[idx] = paperR;
    png.data[idx + 1] = paperG;
    png.data[idx + 2] = paperB;
    png.data[idx + 3] = paperA;
  }
}

const buffer = PNG.sync.write(png);

targets.forEach(targetPath => {
  fs.writeFileSync(targetPath, buffer);
  console.log(`Cleaned receipt template (pristine lines) saved to ${targetPath}`);
});
