const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

// 1. Delete trans bg.png from all locations
const transBgPaths = [
  'c:/Users/User/schedly/trans bg.png',
  'c:/Users/User/schedly/prototype/trans bg.png',
  'c:/Users/User/schedly/assets/trans bg.png'
];

transBgPaths.forEach(p => {
  if (fs.existsSync(p)) {
    fs.unlinkSync(p);
    console.log(`Deleted redundant trans bg.png at: ${p}`);
  }
});

// 2. Clean template.png cleanly, preserving dashes
const inputPath = 'C:/Users/User/Downloads/template.png';
const outPaths = [
  'c:/Users/User/schedly/template.png',
  'c:/Users/User/schedly/prototype/template.png',
  'c:/Users/User/schedly/assets/template.png'
];

if (fs.existsSync(inputPath)) {
  const data = fs.readFileSync(inputPath);
  const png = PNG.sync.read(data);
  console.log(`Processing template.png (${png.width}x${png.height})...`);

  const scaleX = png.width / 1080;
  const scaleY = png.height / 1920;
  const cx = 535 * scaleX;
  const cy = 995 * scaleY;
  const angle = -2.3859 * Math.PI / 180;

  // Split schedule rows into left (Day/Subject) and right (Time) columns
  // to avoid erasing the middle column dashes (-)!
  const boxes = [
    { uxMin: 180, uxMax: 840, uyMin: 700, uyMax: 825 },  // Top student info (4th Year, Sem, School)
    { uxMin: 180, uxMax: 520, uyMin: 940, uyMax: 1600 }, // Schedule left col (Day & Subject)
    { uxMin: 605, uxMax: 840, uyMin: 940, uyMax: 1600 }, // Schedule right col (Time)
    { uxMin: 180, uxMax: 840, uyMin: 1620, uyMax: 1650 }, // Bottom student info (Item Count & Total Units)
    { uxMin: 180, uxMax: 840, uyMin: 1695, uyMax: 1725 }  // Bottom student info (Course text)
  ];

  let cleanedCount = 0;

  for (let y = 0; y < png.height; y++) {
    for (let x = 0; x < png.width; x++) {
      const idx = (png.width * y + x) * 4;
      const a = png.data[idx + 3];
      if (a < 100) continue; // Skip transparent outer margins

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

        if (lum < 192) {
          let foundReplacement = false;
          let rR = 248, rG = 249, rB = 244; // Default fallback cream color

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

                  if (nLum >= 205) {
                    const ndx = n.nx - cx;
                    const ndy = n.ny - cy;
                    const nux = (cx + ndx * cos - ndy * sin) / scaleX;
                    const nuy = (cy + ndx * sin + ndy * cos) / scaleY;

                    // Samples must be strictly on receipt paper background
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
} else {
  console.error("Downloads/template.png not found!");
}

console.log('Task completed successfully!');
