const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

function getGradleHash(url) {
  const md5 = crypto.createHash('md5').update(url, 'utf8').digest();
  const hex = '0x' + md5.toString('hex');
  return BigInt(hex).toString(36);
}

const url = 'https://services.gradle.org/distributions/gradle-9.3.1-bin.zip';
const hash = getGradleHash(url);
console.log('URL:', url);
console.log('Gradle hash:', hash);

const userProfile = process.env.USERPROFILE || 'C:\\Users\\User';
const tempDir = process.env.TEMP || 'C:\\Users\\User\\AppData\\Local\\Temp';
const zipPath = path.join(tempDir, 'gradle-9.3.1-bin.zip');
const destDir = path.join(userProfile, '.gradle', 'wrapper', 'dists', 'gradle-9.3.1-bin', hash);

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
const destZip = path.join(destDir, 'gradle-9.3.1-bin.zip');
fs.copyFileSync(zipPath, destZip);
console.log('Copied zip to:', destZip);

// Extract zip using PowerShell
console.log('Extracting archive...');
execSync(`powershell -Command "Expand-Archive -Path '${destZip}' -DestinationPath '${destDir}' -Force"`, { stdio: 'inherit' });

// Create marker files
fs.writeFileSync(path.join(destDir, 'gradle-9.3.1-bin.zip.ok'), '');
fs.writeFileSync(path.join(destDir, 'gradle-9.3.1-bin.zip.lck'), '');

console.log('Done! Files in dest:');
console.log(fs.readdirSync(destDir));
