// Verifikasi cepat: dimensi & statistik warna PNG ikon yang dihasilkan.
'use strict';
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

function info(file) {
  const full = path.join(ROOT, file);
  if (!fs.existsSync(full)) {
    console.log('MISSING:', file);
    return;
  }
  const b = fs.readFileSync(full);
  const w = b.readUInt32BE(16);
  const h = b.readUInt32BE(20);
  const idatStart = b.indexOf(Buffer.from('IDAT')) + 4;
  const idatEnd = b.indexOf(Buffer.from('IEND')) - 4;
  const raw = zlib.inflateSync(b.slice(idatStart, idatEnd));
  const stride = w * 4 + 1;
  let opaque = 0, white = 0, orange = 0, transparent = 0, total = 0;
  for (let y = 0; y < h; y++) {
    const row = y * stride + 1;
    for (let x = 0; x < w; x++) {
      const i = row + x * 4;
      const a = raw[i + 3];
      total++;
      if (a > 200) opaque++;
      else if (a < 30) transparent++;
      if (a > 200) {
        if (raw[i] > 235 && raw[i + 1] > 235 && raw[i + 2] > 235) white++;
        else if (raw[i] > 200 && raw[i + 1] > 90 && raw[i + 1] < 170 && raw[i + 2] < 90) orange++;
      }
    }
  }
  const pct = (n) => (Math.round((n / total) * 1000) / 10) + '%';
  console.log(
    file.padEnd(55) + ' | ' + w + 'x' + h +
    ' | opaque:' + pct(opaque) +
    ' | white:' + pct(white) +
    ' | orange:' + pct(orange) +
    ' | transparent:' + pct(transparent)
  );
}

console.log('=== VERIFIKASI IKON ===');
[
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
  'web/icons/Icon-192.png',
  'web/icons/Icon-512.png',
  'web/icons/Icon-maskable-512.png',
  'web/favicon.png',
].forEach(info);
