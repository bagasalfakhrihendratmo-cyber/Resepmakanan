// ============================================================================
// generate_icons.js
// Menghasilkan ikon aplikasi "Resep Nusantara" (sendok & garpu di atas latar
// oranye bergradasi) untuk Android & web — tanpa dependensi eksternal.
//
// Jalankan:  node tool/generate_icons.js
//
// Yang dihasilkan:
//   - android/app/src/main/res/mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png
//   - android/app/src/main/res/drawable-{m,h,xh,xxh,xxxh}dpi/ic_launcher_foreground.png
//   - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml
//   - android/app/src/main/res/drawable/ic_launcher_background.xml
//   - android/app/src/main/res/values/colors.xml  (ic_launcher_background)
//   - web/icons/Icon-192.png, Icon-512.png, Icon-maskable-192.png, Icon-maskable-512.png
//   - web/favicon.png
// ============================================================================

'use strict';
const zlib = require('zlib');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');

// ─── Utilitas PNG ───────────────────────────────────────────────────────────
const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crc]);
}

function encodePNG(width, height, rgba) {
  const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8; // bit depth
  ihdr[9] = 6; // color type: RGBA
  const stride = width * 4 + 1;
  const raw = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    raw[y * stride] = 0; // filter: none
    rgba.copy(raw, y * stride + 1, y * width * 4, (y + 1) * width * 4);
  }
  const idat = zlib.deflateSync(raw, { level: 9 });
  return Buffer.concat([sig, pngChunk('IHDR', ihdr), pngChunk('IDAT', idat), pngChunk('IEND', Buffer.alloc(0))]);
}

// ─── Warna tema aplikasi ────────────────────────────────────────────────────
const GRAD_TOP = [0xff, 0xb2, 0x7a]; // #FFB27A
const GRAD_BOTTOM = [0xd3, 0x4e, 0x17]; // #D34E17
const UTENSIL_COLOR = [0xff, 0xff, 0xff]; // putih
const SHADOW_COLOR = [0x7a, 0x24, 0x06]; // bayangan kemerahan gelap

// ─── Geometri (ruang desain: kanvas 1.0, pusat (0,0), y ke bawah) ──────────
const FORK_ANGLE = -Math.PI / 4; // garpu: atas-kiri -> bawah-kanan
const SPOON_ANGLE = Math.PI / 4; // sendok: atas-kanan -> bawah-kiri

// SDF persegi panjang dengan sudut membulat
function sdRoundRect(x, y, cx, cy, hw, hh, r) {
  const dx = Math.abs(x - cx) - (hw - r);
  const dy = Math.abs(y - cy) - (hh - r);
  const ox = Math.max(dx, 0);
  const oy = Math.max(dy, 0);
  return Math.hypot(ox, oy) + Math.min(Math.max(dx, dy), 0) - r;
}

// SDF lingkaran
function sdCircle(x, y, cx, cy, r) {
  return Math.hypot(x - cx, y - cy) - r;
}

// SDF elips (perkiraan)
function sdEllipse(x, y, cx, cy, rx, ry) {
  const px = (x - cx) / rx;
  const py = (y - cy) / ry;
  return Math.hypot(px, py) - 1;
}

function rotate(x, y, ang) {
  const c = Math.cos(ang);
  const s = Math.sin(ang);
  return [x * c - y * s, x * s + y * c];
}

// SDF garpu (lokal, tegak, y ke bawah: ujung gigi di atas)
function forkSDF(x, y) {
  let d = Infinity;
  const tines = [-0.155, -0.052, 0.052, 0.155];
  for (const tc of tines) {
    d = Math.min(d, sdRoundRect(x, y, tc, -0.165, 0.045, 0.135, 0.025));
  }
  d = Math.min(d, sdRoundRect(x, y, 0, 0.015, 0.185, 0.06, 0.05)); // pangkal gigi
  d = Math.min(d, sdRoundRect(x, y, 0, 0.27, 0.055, 0.185, 0.03)); // gagang
  return d;
}

// SDF sendok (lokal, tegak, y ke bawah: cekungan di atas)
function spoonSDF(x, y) {
  const bowl = sdEllipse(x, y, 0, -0.12, 0.185, 0.21);
  const handle = sdRoundRect(x, y, 0, 0.22, 0.05, 0.20, 0.028);
  return Math.min(bowl, handle);
}

// Coverage (0..1) dari peralatan makan di titik tertentu (ruang kanvas).
function utensilCoverage(x, y, smooth) {
  const f = rotate(x, y, -FORK_ANGLE);
  const s = rotate(x, y, -SPOON_ANGLE);
  const d = Math.min(forkSDF(f[0], f[1]), spoonSDF(s[0], s[1]));
  return Math.max(0, Math.min(1, 0.5 - d / smooth));
}

function hex(c) {
  return c.map((v) => Math.max(0, Math.min(255, Math.round(v))));
}

// Render satu ikon menjadi buffer RGBA.
// opts: contentScale (perbesaran peralatan), rounded (sudut latar membulat),
//       fullBleed (latar menutup penuh, untuk maskable), shadow (bayangan).
function renderIcon(size, opts) {
  const { contentScale = 1, rounded = true, fullBleed = false, shadow = true, contentOnly = false } = opts;
  const out = Buffer.alloc(size * size * 4);
  const SAMPLES = 3;
  const cornerRadius = 0.2;
  const smooth = (1.5 * contentScale) / size;

  for (let j = 0; j < size; j++) {
    for (let i = 0; i < size; i++) {
      let r = 0, g = 0, b = 0, a = 0;
      for (let sy = 0; sy < SAMPLES; sy++) {
        for (let sx = 0; sx < SAMPLES; sx++) {
          const u = (i + (sx + 0.5) / SAMPLES) / size - 0.5;
          const v = (j + (sy + 0.5) / SAMPLES) / size - 0.5;
          let cr = 0, cg = 0, cb = 0, ca = 0;

          // Latar belakang (dilewati untuk foreground adaptive icon)
          if (!contentOnly && (fullBleed || !rounded || sdRoundRect(u, v, 0, 0, 0.5, 0.5, cornerRadius) < 0)) {
            const t = Math.max(0, Math.min(1, (v + 0.5)));
            cr = GRAD_TOP[0] + (GRAD_BOTTOM[0] - GRAD_TOP[0]) * t;
            cg = GRAD_TOP[1] + (GRAD_BOTTOM[1] - GRAD_TOP[1]) * t;
            cb = GRAD_TOP[2] + (GRAD_BOTTOM[2] - GRAD_TOP[2]) * t;
            ca = 1;
          }

          // Peralatan makan (dengan bayangan lembut)
          if (shadow) {
            const sh = utensilCoverage(
              (u - 0.022 * contentScale) * contentScale,
              (v - 0.028 * contentScale) * contentScale,
              smooth
            );
            if (sh > 0) {
              cr = cr + (SHADOW_COLOR[0] - cr) * sh * 0.28;
              cg = cg + (SHADOW_COLOR[1] - cg) * sh * 0.28;
              cb = cb + (SHADOW_COLOR[2] - cb) * sh * 0.28;
            }
          }
          const cov = utensilCoverage(u * contentScale, v * contentScale, smooth);
          if (cov > 0) {
            cr = cr + (UTENSIL_COLOR[0] - cr) * cov;
            cg = cg + (UTENSIL_COLOR[1] - cg) * cov;
            cb = cb + (UTENSIL_COLOR[2] - cb) * cov;
            ca = Math.max(ca, cov);
          }

          r += cr; g += cg; b += cb; a += ca;
        }
      }
      const n = SAMPLES * SAMPLES;
      const idx = (j * size + i) * 4;
      // Skala alpha 0..1 -> 0..255 (sama seperti RGB)
      const [pr, pg, pb, pa] = hex([r / n, g / n, b / n, (a / n) * 255]);
      out[idx] = pr;
      out[idx + 1] = pg;
      out[idx + 2] = pb;
      out[idx + 3] = pa;
    }
  }
  return out;
}

function writePng(file, width, height, rgba) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, encodePNG(width, height, rgba));
  console.log('  ✓', path.relative(ROOT, file).replace(/\\/g, '/'), `(${width}x${height})`);
}

// ─── Tulis file ikon Android ────────────────────────────────────────────────
function generateAndroid() {
  console.log('Android icons…');
  const densities = [
    { name: 'mdpi', size: 48, fg: 108 },
    { name: 'hdpi', size: 72, fg: 162 },
    { name: 'xhdpi', size: 96, fg: 216 },
    { name: 'xxhdpi', size: 144, fg: 324 },
    { name: 'xxxhdpi', size: 192, fg: 432 },
  ];
  const res = path.join(ROOT, 'android', 'app', 'src', 'main', 'res');

  for (const d of densities) {
    // Ikon legacy (API < 26)
    const legacy = renderIcon(d.size, { contentScale: 1.35, rounded: true, shadow: true });
    writePng(path.join(res, `mipmap-${d.name}`, 'ic_launcher.png'), d.size, d.size, legacy);

    // Foreground adaptive icon (API 26+): HANYA peralatan makan (transparan di
    // luar), latar oranye disediakan XML. contentScale 0.66 agar seluruh
    // konten berada dalam zona aman 66dp (jari-jari 0.306 dari kanvas).
    const fg = renderIcon(d.fg, { contentScale: 0.66, contentOnly: true, shadow: false });
    writePng(path.join(res, `drawable-${d.name}`, 'ic_launcher_foreground.png'), d.fg, d.fg, fg);
  }

  // Adaptive icon XML (API 26+)
  const anydpi = path.join(res, 'mipmap-anydpi-v26');
  fs.mkdirSync(anydpi, { recursive: true });
  fs.writeFileSync(
    path.join(anydpi, 'ic_launcher.xml'),
    `<?xml version="1.0" encoding="utf-8"?>\n` +
    `<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n` +
    `    <background android:drawable="@drawable/ic_launcher_background" />\n` +
    `    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n` +
    `</adaptive-icon>\n`
  );
  console.log('  ✓ res/mipmap-anydpi-v26/ic_launcher.xml');

  // Background gradient drawable
  const drawableDir = path.join(res, 'drawable');
  fs.mkdirSync(drawableDir, { recursive: true });
  fs.writeFileSync(
    path.join(drawableDir, 'ic_launcher_background.xml'),
    `<?xml version="1.0" encoding="utf-8"?>\n` +
    `<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n` +
    `    <gradient\n` +
    `        android:angle="270"\n` +
    `        android:startColor="#FFB27A"\n` +
    `        android:endColor="#D34E17" />\n` +
    `</shape>\n`
  );
  console.log('  ✓ res/drawable/ic_launcher_background.xml');

  // Warna fallback (dipakai sistem bila gradient tidak tersedia)
  const valuesDir = path.join(res, 'values');
  fs.mkdirSync(valuesDir, { recursive: true });
  const colorsPath = path.join(valuesDir, 'colors.xml');
  const colorsContent =
    `<?xml version="1.0" encoding="utf-8"?>\n` +
    `<resources>\n` +
    `    <color name="ic_launcher_background">#E8733A</color>\n` +
    `</resources>\n`;
  if (!fs.existsSync(colorsPath)) fs.writeFileSync(colorsPath, colorsContent);
  console.log('  ✓ res/values/colors.xml (ic_launcher_background)');
}

// ─── Tulis file ikon web ────────────────────────────────────────────────────
function generateWeb() {
  console.log('Web icons…');
  const web = path.join(ROOT, 'web', 'icons');
  writePng(path.join(web, 'Icon-192.png'), 192, 192, renderIcon(192, { contentScale: 1.35, rounded: true, shadow: true }));
  writePng(path.join(web, 'Icon-512.png'), 512, 512, renderIcon(512, { contentScale: 1.35, rounded: true, shadow: true }));
  // Maskable: latar penuh, konten di dalam zona aman 80% (jari-jari 0.4)
  writePng(path.join(web, 'Icon-maskable-192.png'), 192, 192, renderIcon(192, { contentScale: 0.8, rounded: false, fullBleed: true, shadow: true }));
  writePng(path.join(web, 'Icon-maskable-512.png'), 512, 512, renderIcon(512, { contentScale: 0.8, rounded: false, fullBleed: true, shadow: true }));
  writePng(path.join(ROOT, 'web', 'favicon.png'), 64, 64, renderIcon(64, { contentScale: 1.35, rounded: true, shadow: true }));
}

generateAndroid();
generateWeb();
console.log('Selesai.');
