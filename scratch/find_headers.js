const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'prototype', 'trans bg.png');
const data = fs.readFileSync(imgPath);
const png = PNG.sync.read(data);

console.log(`Image size: ${png.width}x${png.height}`);

// The blue headers "Day", "Subject", "Time" are located around Y=850 to 920
// Let's scan and print all blue-ish pixels in this vertical band
// Blue color has high B, lower R and G.
let blueGroups = [];
for (let y = 840; y < 920; y++) {
  for (let x = 100; x < 980; x++) {
    const idx = (png.width * y + x) << 2;
    const r = png.data[idx];
    const g = png.data[idx + 1];
    const b = png.data[idx + 2];
    const a = png.data[idx + 3];

    if (a > 150) {
      // Find blue pixels where B is significantly higher than R and G
      // e.g. blue color like RGB(33, 150, 243) or similar
      if (b > 150 && r < 120 && g < 150) {
        blueGroups.push({ x, y, r, g, b });
      }
    }
  }
}

console.log(`Found ${blueGroups.length} blue-ish pixels in header region.`);

// Let's group them by X to find the centers of the three words: "Day", "Subject", "Time"
if (blueGroups.length > 0) {
  // Let's find clusters along X
  let xCoords = blueGroups.map(p => p.x).sort((a, b) => a - b);
  let clusters = [];
  let currentCluster = [xCoords[0]];
  for (let i = 1; i < xCoords.length; i++) {
    if (xCoords[i] - xCoords[i - 1] < 30) {
      currentCluster.push(xCoords[i]);
    } else {
      clusters.push(currentCluster);
      currentCluster = [xCoords[i]];
    }
  }
  clusters.push(currentCluster);

  clusters.forEach((c, idx) => {
    const minX = c[0];
    const maxX = c[c.length - 1];
    const avgX = c.reduce((sum, val) => sum + val, 0) / c.length;
    console.log(`Cluster ${idx + 1}: X range [${minX}, ${maxX}], Center X = ${avgX.toFixed(2)}`);
  });
}
