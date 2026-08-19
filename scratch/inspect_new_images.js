const fs = require('fs');
const path = require('path');
const { PNG } = require('pngjs');

function inspectImage(filename) {
  const filePath = path.join(__dirname, '..', filename);
  if (!fs.existsSync(filePath)) {
    console.log(`${filename} does not exist at ${filePath}`);
    return;
  }
  const data = fs.readFileSync(filePath);
  const png = PNG.sync.read(data);
  console.log(`${filename}: ${png.width}x${png.height}`);
}

inspectImage('blank template.png');
inspectImage('reference.png');
inspectImage('prototype/template.png');
