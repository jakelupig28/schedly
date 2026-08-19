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

const diffPixels = [];

// Scan every 2nd pixel to be more precise
for (let y = 0; y < h; y += 2) {
  for (let x = 0; x < w; x += 2) {
    const idx = (w * y + x) * 4;
    const r1 = blankPng.data[idx];
    const g1 = blankPng.data[idx + 1];
    const b1 = blankPng.data[idx + 2];
    
    const r2 = refPng.data[idx];
    const g2 = refPng.data[idx + 1];
    const b2 = refPng.data[idx + 2];
    
    const diff = Math.sqrt((r1 - r2) ** 2 + (g1 - g2) ** 2 + (b1 - b2) ** 2);
    if (diff > 40) { // slightly higher threshold to ignore noise
      diffPixels.push({
        x: x / scaleX,
        y: y / scaleY,
        origX: x,
        origY: y
      });
    }
  }
}

console.log(`Found ${diffPixels.length} difference pixels.`);

// Simple grid-based clustering
// We will partition the screen (1080x1920) into a grid of cell size 15x15.
// Any cell with > 2 diff pixels is "active".
// Then we group connected active cells.
const cellSize = 15;
const gridW = Math.ceil(1080 / cellSize);
const gridH = Math.ceil(1920 / cellSize);
const grid = Array(gridH).fill(null).map(() => Array(gridW).fill(0));

diffPixels.forEach(p => {
  const gx = Math.floor(p.x / cellSize);
  const gy = Math.floor(p.y / cellSize);
  if (gx >= 0 && gx < gridW && gy >= 0 && gy < gridH) {
    grid[gy][gx]++;
  }
});

const visited = Array(gridH).fill(null).map(() => Array(gridW).fill(false));
const components = [];

for (let gy = 0; gy < gridH; gy++) {
  for (let gx = 0; gx < gridW; gx++) {
    if (grid[gy][gx] > 2 && !visited[gy][gx]) {
      // Start BFS
      const comp = [];
      const queue = [{ gx, gy }];
      visited[gy][gx] = true;
      
      while (queue.length > 0) {
        const curr = queue.shift();
        comp.push(curr);
        
        // 8-way connectivity
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            const ny = curr.gy + dy;
            const nx = curr.gx + dx;
            if (ny >= 0 && ny < gridH && nx >= 0 && nx < gridW) {
              if (grid[ny][nx] > 2 && !visited[ny][nx]) {
                visited[ny][nx] = true;
                queue.push({ gx: nx, gy: ny });
              }
            }
          }
        }
      }
      components.push(comp);
    }
  }
}

console.log(`Found ${components.length} text blocks/clusters.`);

// Convert components back to pixel bounds
const clusters = components.map((comp, idx) => {
  let minX = 9999, maxX = -9999, minY = 9999, maxY = -9999;
  comp.forEach(cell => {
    const pxMin = cell.gx * cellSize;
    const pxMax = (cell.gx + 1) * cellSize;
    const pyMin = cell.gy * cellSize;
    const pyMax = (cell.gy + 1) * cellSize;
    if (pxMin < minX) minX = pxMin;
    if (pxMax > maxX) maxX = pxMax;
    if (pyMin < minY) minY = pyMin;
    if (pyMax > maxY) maxY = pyMax;
  });
  
  // Calculate center
  const centerX = (minX + maxX) / 2;
  const centerY = (minY + maxY) / 2;
  
  return {
    id: idx + 1,
    minX, maxX, minY, maxY,
    width: maxX - minX,
    height: maxY - minY,
    centerX, centerY,
    cellCount: comp.length
  };
});

// Sort clusters by Y coordinate
clusters.sort((a, b) => a.minY - b.minY);

clusters.forEach(c => {
  if (c.cellCount > 2) {
    console.log(`Cluster ${c.id}: Y: [${c.minY} - ${c.maxY}] (H: ${c.height}), X: [${c.minX} - ${c.maxX}] (W: ${c.width}), Center: (${c.centerX.toFixed(1)}, ${c.centerY.toFixed(1)}), Cells: ${c.cellCount}`);
  }
});
