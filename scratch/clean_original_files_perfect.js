const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function cleanImage(inputPath, outPaths) {
  if (!fs.existsSync(inputPath)) {
    console.error(`Input file not found: ${inputPath}`);
    return;
  }

  const data = fs.readFileSync(inputPath);
  const png = PNG.sync.read(data);
  console.log(`Processing ${path.basename(inputPath)} (${png.width}x${png.height})...`);

  const scaleX = png.width / 1080;
  const scaleY = png.height / 1920;
  const cx = 535 * scaleX;
  const cy = 995 * scaleY;
  const angle = -2.3859 * Math.PI / 180;

  // Expanded unrotated paper bounding boxes (1080x1920 space)
  const boxes = [
    { uxMin: 180, uxMax: 840, uyMin: 720, uyMax: 835 },  // Top student info
    { uxMin: 180, uxMax: 840, uyMin: 940, uyMax: 1600 }, // Schedule rows
    { uxMin: 180, uxMax: 840, uyMin: 1622, uyMax: 1730 } // Bottom student info
  ];

  let cleanedCount = 0;

  for (let y = 0; y < png.height; y++) {
    for (let x = 0; x < png.width; x++) {
      const idx = (png.width * y + x) * 4;
      const a = png.data[idx + 3];
      if (a < 100) continue; // Skip transparent outer area

      // Map to unrotated coordinates
      const dx = x - cx;
      const dy = y - cy;
      const cos = Math.cos(-angle);
      const sin = Math.sin(-angle);
      const ux = (cx + dx * cos - dy * sin) / scaleX;
      const uy = (cy + dx * sin + dy * cos) / scaleY;

      // Check if inside any target cleaning box
      const inBox = boxes.some(box => 
        ux >= box.uxMin && ux <= box.uxMax && uy >= box.uyMin && uy <= box.uyMax
      );

      if (inBox) {
        const r = png.data[idx];
        const g = png.data[idx + 1];
        const b = png.data[idx + 2];
        const lum = 0.299 * r + 0.587 * g + 0.114 * b;

        // More aggressive: replace any pixels darker than 192 (catches faint antialiased text fringes)
        if (lum < 192) {
          let foundReplacement = false;
          let rR = 248, rG = 249, rB = 244; // Default fallback cream color

          // Search in a wider neighborhood up to 50 pixels
          for (let dist = 1; dist <= 50; dist++) {
            const neighbors = [
              { nx: x - dist, ny: y },
              { nx: x + dist, ny: y },
              { nx: x, ny: y - dist },
              { nx: x, ny: y + dist },
              { nx: x - dist, ny: y - dist },
              { nx: x + dist, ny: y + dist },
              { nx: x - dist, ny: y + dist },
              { nx: x + dist, ny: y - dist }
            ];

            for (const n of neighbors) {
              if (n.nx >= 0 && n.nx < png.width && n.ny >= 0 && n.ny < png.height) {
                const nIdx = (png.width * n.ny + n.nx) * 4;
                const nA = png.data[nIdx + 3];
                if (nA > 150) {
                  const nR = png.data[nIdx];
                  const nG = png.data[nIdx + 1];
                  const nB = png.data[nIdx + 2];
                  const nLum = 0.299 * nR + 0.587 * nG + 0.114 * nB;

                  // Must be bright background (lum >= 205)
                  if (nLum >= 205) {
                    // Check if neighbor is on the receipt paper itself, to avoid copying stickers or outside background
                    const ndx = n.nx - cx;
                    const ndy = n.ny - cy;
                    const nux = (cx + ndx * cos - ndy * sin) / scaleX;
                    const nuy = (cy + ndx * sin + ndy * cos) / scaleY;

                    if (nux >= 175 && nux <= 855 && nuy >= 570 && nuy <= 1725) {
                      rR = nR;
                      rG = nG;
                      rB = nB;
                      foundReplacement = true;
                      break;
                    }
                  }
                }
              }
            }
            if (foundReplacement) break;
          }

          png.data[idx] = rR;
          png.data[idx + 1] = rG;
          png.data[idx + 2] = rB;
          cleanedCount++;
        }
      }
    }
  }

  console.log(`Cleaned ${cleanedCount} text/halo pixels.`);

  const buffer = PNG.sync.write(png);
  outPaths.forEach(outPath => {
    const dir = path.dirname(outPath);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(outPath, buffer);
    console.log(`Saved result to: ${outPath}`);
  });
}

// 1. Process template.png from Downloads
cleanImage('C:/Users/User/Downloads/template.png', [
  'c:/Users/User/schedly/template.png',
  'c:/Users/User/schedly/prototype/template.png',
  'c:/Users/User/schedly/assets/template.png'
]);

// 2. Process trans bg.png from Downloads
cleanImage('C:/Users/User/Downloads/trans bg.png', [
  'c:/Users/User/schedly/trans bg.png',
  'c:/Users/User/schedly/prototype/trans bg.png',
  'c:/Users/User/schedly/assets/trans bg.png'
]);

console.log('Template cleaning completed successfully!');
