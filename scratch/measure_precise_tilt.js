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

// Let's sample columns at ux = 280, 420, 560, 700
// We will look at Y ranges corresponding to the schedule rows
const rows = [
  { name: 'Row 1', yMin: 1040, yMax: 1110 },
  { name: 'Row 2', yMin: 1140, yMax: 1210 },
  { name: 'Row 3', yMin: 1220, yMax: 1280 },
  { name: 'Row 4', yMin: 1280, yMax: 1360 },
  { name: 'Row 5', yMin: 1360, yMax: 1440 },
  { name: 'Row 6', yMin: 1420, yMax: 1490 }
];

function findTextCenterY(ux, uyStart, uyEnd) {
  const x = Math.round(ux * scaleX);
  let sumY = 0;
  let count = 0;
  for (let uy = uyStart; uy <= uyEnd; uy += 0.25) {
    const y = Math.round(uy * scaleY);
    if (isTextPixel(x, y)) {
      sumY += uy;
      count++;
    }
  }
  return count > 10 ? sumY / count : null;
}

const angles = [];

rows.forEach(row => {
  // Let's find centers at two X coordinates
  const ux1 = 410;
  const ux2 = 680;
  const y1 = findTextCenterY(ux1, row.yMin, row.yMax);
  const y2 = findTextCenterY(ux2, row.yMin, row.yMax);
  
  if (y1 && y2) {
    const dx = ux2 - ux1;
    const dy = y2 - y1;
    const rad = Math.atan2(dy, dx);
    const deg = rad * 180 / Math.PI;
    angles.push(deg);
    console.log(`${row.name}: Center at X=${ux1} is Y=${y1.toFixed(2)}, at X=${ux2} is Y=${y2.toFixed(2)} -> Tilt = ${deg.toFixed(4)}°`);
  } else {
    console.log(`${row.name}: Could not find center on both columns.`);
  }
});

if (angles.length > 0) {
  const avgAngle = angles.reduce((sum, val) => sum + val, 0) / angles.length;
  console.log(`\nAverage Tilt Angle: ${avgAngle.toFixed(4)}°`);
}
