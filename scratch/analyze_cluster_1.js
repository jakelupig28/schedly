const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const blankData = fs.readFileSync(path.join(__dirname, '..', 'blank template.png'));
const refData = fs.readFileSync(path.join(__dirname, '..', 'reference.png'));

const blankPng = PNG.sync.read(blankData);
const refPng = PNG.sync.read(refData);

const w = blankPng.width;
const h = blankPng.height;
const scaleX = w / 1080;
const scaleY = h / 1920;

function isTextPixel(x, y) {
  const idx = (w * y + x) * 4;
  const r1 = blankPng.data[idx];
  const g1 = blankPng.data[idx + 1];
  const b1 = blankPng.data[idx + 2];
  
  const r2 = refPng.data[idx];
  const g2 = refPng.data[idx + 1];
  const b2 = refPng.data[idx + 2];
  
  const diff = Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
  return diff > 40;
}

console.log('Analyzing Y profile for Cluster 1 (Y: 840 to 930 in 1080x1920 space)...');
const yStats = [];
for (let uy = 835; uy <= 935; uy += 0.25) {
  let count = 0;
  const y = Math.round(uy * scaleY);
  for (let ux = 220; ux <= 610; ux += 1) {
    const x = Math.round(ux * scaleX);
    if (isTextPixel(x, y)) {
      count++;
    }
  }
  yStats.push({ uy, count });
}

let inText = false;
let startY = 0;
let maxCount = 0;
yStats.forEach(stat => {
  if (stat.count > 5) {
    if (!inText) {
      inText = true;
      startY = stat.uy;
    }
    if (stat.count > maxCount) maxCount = stat.count;
  } else {
    if (inText) {
      console.log(`Line: uy [${startY.toFixed(2)} - ${stat.uy.toFixed(2)}] (Max count: ${maxCount})`);
      inText = false;
      maxCount = 0;
    }
  }
});
if (inText) {
  console.log(`Line: uy [${startY.toFixed(2)} - 935.00] (Max count: ${maxCount})`);
}
