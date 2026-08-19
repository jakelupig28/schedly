const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

const imgPath = path.join(__dirname, '..', 'trans bg.png');

fs.createReadStream(imgPath)
  .pipe(new PNG())
  .on('parsed', function() {
    let minX = this.width, maxX = 0, minY = this.height, maxY = 0;
    let colorCounts = {};

    for (let y = 0; y < this.height; y++) {
      for (let x = 0; x < this.width; x++) {
        const idx = (this.width * y + x) << 2;
        const a = this.data[idx + 3];
        if (a > 20) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;

          const r = this.data[idx];
          const g = this.data[idx + 1];
          const b = this.data[idx + 2];
          const hex = `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${b.toString(16).padStart(2,'0')}`;
          colorCounts[hex] = (colorCounts[hex] || 0) + 1;
        }
      }
    }

    console.log(`Non-transparent bounding box: X [${minX}, ${maxX}], Y [${minY}, ${maxY}]`);
    const sortedColors = Object.entries(colorCounts).sort((a,b) => b[1] - a[1]).slice(0, 15);
    console.log('Top colors:', sortedColors);
  });
