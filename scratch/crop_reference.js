const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

// We will use pngjs to crop and save the images since Jimp is also available.
// Let's write a helper to crop using pngjs.
function cropPng(inputPath, outputPath, cropX, cropY, cropW, cropH) {
  const data = fs.readFileSync(inputPath);
  const png = PNG.sync.read(data);
  
  const cropped = new PNG({ width: cropW, height: cropH });
  
  for (let y = 0; y < cropH; y++) {
    for (let x = 0; x < cropW; x++) {
      const srcX = cropX + x;
      const srcY = cropY + y;
      
      const srcIdx = (png.width * srcY + srcX) * 4;
      const dstIdx = (cropW * y + x) * 4;
      
      if (srcX >= 0 && srcX < png.width && srcY >= 0 && srcY < png.height) {
        cropped.data[dstIdx] = png.data[srcIdx];
        cropped.data[dstIdx + 1] = png.data[srcIdx + 1];
        cropped.data[dstIdx + 2] = png.data[srcIdx + 2];
        cropped.data[dstIdx + 3] = png.data[srcIdx + 3];
      } else {
        cropped.data[dstIdx] = 0;
        cropped.data[dstIdx + 1] = 0;
        cropped.data[dstIdx + 2] = 0;
        cropped.data[dstIdx + 3] = 0;
      }
    }
  }
  
  const buffer = PNG.sync.write(cropped);
  fs.writeFileSync(outputPath, buffer);
  console.log(`Cropped and saved: ${outputPath}`);
}

const refPath = path.join(__dirname, '..', 'reference.png');

// Image dimensions are 2619x4583.
// Scaling factors are:
const w = 2619;
const h = 4583;
const scaleX = w / 1080;
const scaleY = h / 1920;

// Let's crop:
// 1. Top student info: Y: 840-930 (scaled) -> Y * scaleY. X: 225-600 (scaled) -> X * scaleX
cropPng(
  refPath,
  path.join(__dirname, '..', 'prototype', 'ref_top.png'),
  Math.round(200 * scaleX),
  Math.round(820 * scaleY),
  Math.round(450 * scaleX),
  Math.round(130 * scaleY)
);

// 2. Schedule Row 1: Y: 1040-1120 (scaled), X: 240-800 (scaled)
cropPng(
  refPath,
  path.join(__dirname, '..', 'prototype', 'ref_schedule.png'),
  Math.round(240 * scaleX),
  Math.round(1020 * scaleY),
  Math.round(560 * scaleX),
  Math.round(120 * scaleY)
);

// 3. Total units: Y: 1480-1600 (scaled), X: 700-900 (scaled)
cropPng(
  refPath,
  path.join(__dirname, '..', 'prototype', 'ref_units.png'),
  Math.round(700 * scaleX),
  Math.round(1480 * scaleY),
  Math.round(200 * scaleX),
  Math.round(120 * scaleY)
);

// 4. Course: Y: 1600-1700 (scaled), X: 240-750 (scaled)
cropPng(
  refPath,
  path.join(__dirname, '..', 'prototype', 'ref_course.png'),
  Math.round(240 * scaleX),
  Math.round(1600 * scaleY),
  Math.round(510 * scaleX),
  Math.round(100 * scaleY)
);
