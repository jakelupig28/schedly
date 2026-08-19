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

// Let's find dark pixels that differ between reference and blank
function isTextPixel(x, y) {
  if (x < 0 || x >= w || y < 0 || y >= h) return false;
  const idx = (w * y + x) * 4;
  const r1 = blankPng.data[idx];
  const g1 = blankPng.data[idx + 1];
  const b1 = blankPng.data[idx + 2];
  
  const r2 = refPng.data[idx];
  const g2 = refPng.data[idx + 1];
  const b2 = refPng.data[idx + 2];
  
  const diff = Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
  return diff > 30;
}

// Let's scan around Y=1060 (scaled) which is the first row of schedule
// Let's trace the center Y of text at X = 300 (scaled) and X = 700 (scaled)
function findTextCenterY(ux, uyStart, uyEnd) {
  const x = Math.round(ux * scaleX);
  let sumY = 0;
  let count = 0;
  for (let uy = uyStart; uy <= uyEnd; uy += 0.5) {
    const y = Math.round(uy * scaleY);
    if (isTextPixel(x, y)) {
      sumY += uy;
      count++;
    }
  }
  return count > 0 ? sumY / count : null;
}

console.log('Tracing Y center of first schedule row text:');
// First schedule row: Y is roughly 1060
const yLeft1 = findTextCenterY(300, 1040, 1100);
const yRight1 = findTextCenterY(700, 1040, 1100);
console.log(`Left Y (at X=300): ${yLeft1}`);
console.log(`Right Y (at X=700): ${yRight1}`);

if (yLeft1 && yRight1) {
  const dx = 700 - 300;
  const dy = yRight1 - yLeft1;
  const angleRad = Math.atan2(dy, dx);
  const angleDeg = angleRad * 180 / Math.PI;
  console.log(`Row 1 Tilt: dy=${dy.toFixed(2)}, dx=${dx}, angle=${angleDeg.toFixed(4)} degrees (${angleRad.toFixed(6)} rad)`);
}

// Let's trace another row: row around Y=1200
const yLeft2 = findTextCenterY(420, 1180, 1220);
const yRight2 = findTextCenterY(700, 1180, 1220);
console.log(`\nRow 2: Left Y (at X=420): ${yLeft2}, Right Y (at X=700): ${yRight2}`);
if (yLeft2 && yRight2) {
  const dx = 700 - 420;
  const dy = yRight2 - yLeft2;
  const angleRad = Math.atan2(dy, dx);
  const angleDeg = angleRad * 180 / Math.PI;
  console.log(`Row 2 Tilt: dy=${dy.toFixed(2)}, dx=${dx}, angle=${angleDeg.toFixed(4)} degrees (${angleRad.toFixed(6)} rad)`);
}

// Let's trace the top section around Y=880
const yLeftTop = findTextCenterY(250, 850, 910);
const yRightTop = findTextCenterY(550, 850, 910);
console.log(`\nTop Section: Left Y (at X=250): ${yLeftTop}, Right Y (at X=550): ${yRightTop}`);
if (yLeftTop && yRightTop) {
  const dx = 550 - 250;
  const dy = yRightTop - yLeftTop;
  const angleRad = Math.atan2(dy, dx);
  const angleDeg = angleRad * 180 / Math.PI;
  console.log(`Top Section Tilt: dy=${dy.toFixed(2)}, dx=${dx}, angle=${angleDeg.toFixed(4)} degrees (${angleRad.toFixed(6)} rad)`);
}

// Let's trace the bottom section around Y=1640
const yLeftBot = findTextCenterY(300, 1610, 1670);
const yRightBot = findTextCenterY(600, 1610, 1670);
console.log(`\nBottom Section: Left Y (at X=300): ${yLeftBot}, Right Y (at X=600): ${yRightBot}`);
if (yLeftBot && yRightBot) {
  const dx = 600 - 300;
  const dy = yRightBot - yLeftBot;
  const angleRad = Math.atan2(dy, dx);
  const angleDeg = angleRad * 180 / Math.PI;
  console.log(`Bottom Section Tilt: dy=${dy.toFixed(2)}, dx=${dx}, angle=${angleDeg.toFixed(4)} degrees (${angleRad.toFixed(6)} rad)`);
}
