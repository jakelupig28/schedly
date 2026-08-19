const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

console.log('Reading blank template.png and reference.png...');
const blankData = fs.readFileSync(path.join(__dirname, '..', 'blank template.png'));
const refData = fs.readFileSync(path.join(__dirname, '..', 'reference.png'));

const blankPng = PNG.sync.read(blankData);
const refPng = PNG.sync.read(refData);

if (blankPng.width !== refPng.width || blankPng.height !== refPng.height) {
  console.error('Images have different dimensions!');
  process.exit(1);
}

const w = blankPng.width;
const h = blankPng.height;
console.log(`Image dimensions: ${w}x${h}`);

// We will find pixels that are different.
// Since we want coordinates in 1080x1920, let's map them.
const scaleX = w / 1080;
const scaleY = h / 1920;

// Let's collect different pixels
const diffPixels = [];
for (let y = 0; y < h; y += 4) { // step by 4 to be fast
  for (let x = 0; x < w; x += 4) {
    const idx = (w * y + x) * 4;
    const r1 = blankPng.data[idx];
    const g1 = blankPng.data[idx + 1];
    const b1 = blankPng.data[idx + 2];
    const a1 = blankPng.data[idx + 3];

    const r2 = refPng.data[idx];
    const g2 = refPng.data[idx + 1];
    const b2 = refPng.data[idx + 2];
    const a2 = refPng.data[idx + 3];

    // Distance in RGB
    const diff = Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
    if (diff > 30) {
      diffPixels.push({
        x: x / scaleX,
        y: y / scaleY,
        origX: x,
        origY: y,
        colorDiff: diff
      });
    }
  }
}

console.log(`Found ${diffPixels.length} different pixel samples.`);

// Let's write the different pixels to a text file or analyze clusters.
// We can cluster them vertically. Let's group pixels that are close in Y.
const yBuckets = {};
diffPixels.forEach(p => {
  const yKey = Math.floor(p.y / 10) * 10;
  if (!yBuckets[yKey]) yBuckets[yKey] = [];
  yBuckets[yKey].push(p);
});

console.log('Vertical profile of differences (every 10px Y in 1080x1920 space):');
Object.keys(yBuckets)
  .map(Number)
  .sort((a, b) => a - b)
  .forEach(y => {
    if (yBuckets[y].length > 5) {
      // Find X range
      const xs = yBuckets[y].map(p => p.x);
      const minX = Math.min(...xs);
      const maxX = Math.max(...xs);
      console.log(`Y: [${y} - ${y + 10}]: Count = ${yBuckets[y].length}, X range = [${minX.toFixed(1)} - ${maxX.toFixed(1)}]`);
    }
  });

// Let's find specific regions.
// 1. Top region (e.g. Y < 900)
// 2. Schedule region (e.g. 900 < Y < 1600)
// 3. Bottom region (e.g. Y > 1600)
