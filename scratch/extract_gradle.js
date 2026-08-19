const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const userProfile = process.env.USERPROFILE || 'C:\\Users\\User';
const tempDir = process.env.TEMP || 'C:\\Users\\User\\AppData\\Local\\Temp';
const zipPath = path.join(tempDir, 'gradle-9.3.1-all.zip');
const destDir = path.join(userProfile, '.gradle', 'wrapper', 'dists', 'gradle-9.3.1-all', '9ot9r568e8zfvvd4mn8rbu1j0');

console.log('Zip source:', zipPath, 'Exists:', fs.existsSync(zipPath));
console.log('Dest dir:', destDir);

fs.mkdirSync(destDir, { recursive: true });

// Clean old files in dest
const files = fs.readdirSync(destDir);
for (const f of files) {
  const p = path.join(destDir, f);
  try {
    fs.rmSync(p, { recursive: true, force: true });
  } catch (e) {}
}

// Copy zip
const destZip = path.join(destDir, 'gradle-9.3.1-all.zip');
fs.copyFileSync(zipPath, destZip);
console.log('Copied zip to:', destZip);

// Extract zip using PowerShell
console.log('Extracting archive...');
execSync(`powershell -Command "Expand-Archive -Path '${destZip}' -DestinationPath '${destDir}' -Force"`, { stdio: 'inherit' });

// Create marker files
fs.writeFileSync(path.join(destDir, 'gradle-9.3.1-all.zip.ok'), '');
fs.writeFileSync(path.join(destDir, 'gradle-9.3.1-all.zip.lck'), '');

console.log('Done! Files in dest:');
console.log(fs.readdirSync(destDir));
