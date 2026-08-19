const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'ref_top.png');
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

console.log(`Dimensions: ${png.width}x${png.height}`);
// Let's print out some pixels that differ from blank template.png
const blankData = fs.readFileSync(path.join(__dirname, '..', 'blank template.png'));
const blankPng = PNG.sync.read(blankData);

const scaleX = blankPng.width / 1080;
const scaleY = blankPng.height / 1920;

// The crop started at X = 200 (scaled), Y = 820 (scaled)
const cropX = Math.round(200 * scaleX);
const cropY = Math.round(820 * scaleY);

let samples = [];
for (let y = 0; y < png.height; y += 5) {
  for (let x = 0; x < png.width; x += 5) {
    const rx = cropX + x;
    const ry = cropY + y;
    if (rx >= blankPng.width || ry >= blankPng.height) continue;
    
    const idxRef = (png.width * y + x) * 4;
    const idxBlank = (blankPng.width * ry + rx) * 4;
    
    const r1 = blankPng.data[idxBlank];
    const g1 = blankPng.data[idxBlank + 1];
    const b1 = blankPng.data[idxBlank + 2];
    
    const r2 = png.data[idxRef];
    const g2 = png.data[idxRef + 1];
    const b2 = png.data[idxRef + 2];
    
    const diff = Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
    if (diff > 45 && samples.length < 30) {
      const lumRef = 0.299 * r2 + 0.587 * g2 + 0.114 * b2;
      const lumBlank = 0.299 * r1 + 0.587 * g1 + 0.114 * b1;
      samples.push({ x, y, blankRGB: `(${r1},${g1},${b1})`, refRGB: `(${r2},${g2},${b2})`, diff: diff.toFixed(1), lumRef: lumRef.toFixed(1), lumBlank: lumBlank.toFixed(1) });
    }
  }
}

console.log('Sample different pixels:');
console.log(samples);
