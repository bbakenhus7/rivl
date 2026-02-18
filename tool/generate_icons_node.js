const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

function drawIcon(ctx, size) {
  const s = size / 1024;
  ctx.save();
  ctx.scale(s, s);

  // Background: diagonal split (top-left lighter, bottom-right darker)
  ctx.fillStyle = '#6B5CE7';
  ctx.fillRect(0, 0, 1024, 1024);

  // Lighter region: top-left triangle via diagonal
  ctx.save();
  ctx.beginPath();
  ctx.moveTo(0, 0);
  ctx.lineTo(1024, 0);
  ctx.lineTo(0, 1024);
  ctx.closePath();
  ctx.clip();
  ctx.fillStyle = '#8B7CF6';
  ctx.fillRect(0, 0, 1024, 1024);
  ctx.restore();

  // Smooth diagonal gradient overlay to blend the split
  const diagGrad = ctx.createLinearGradient(0, 0, 1024, 1024);
  diagGrad.addColorStop(0, 'rgba(155, 140, 255, 0.35)');
  diagGrad.addColorStop(0.4, 'rgba(120, 105, 240, 0.15)');
  diagGrad.addColorStop(0.6, 'rgba(90, 75, 210, 0.15)');
  diagGrad.addColorStop(1, 'rgba(80, 65, 200, 0.3)');
  ctx.fillStyle = diagGrad;
  ctx.fillRect(0, 0, 1024, 1024);

  // Subtle glass/shine effect (top-left highlight arc)
  ctx.save();
  const shineGrad = ctx.createRadialGradient(280, 200, 50, 350, 350, 600);
  shineGrad.addColorStop(0, 'rgba(255, 255, 255, 0.18)');
  shineGrad.addColorStop(0.3, 'rgba(255, 255, 255, 0.08)');
  shineGrad.addColorStop(0.7, 'rgba(255, 255, 255, 0.02)');
  shineGrad.addColorStop(1, 'rgba(255, 255, 255, 0)');
  ctx.fillStyle = shineGrad;
  ctx.fillRect(0, 0, 1024, 1024);
  ctx.restore();

  // Diagonal seam subtle highlight
  ctx.save();
  ctx.translate(512, 512);
  ctx.rotate(-Math.PI / 4);
  const seamGrad = ctx.createLinearGradient(-8, 0, 8, 0);
  seamGrad.addColorStop(0, 'rgba(255,255,255,0)');
  seamGrad.addColorStop(0.35, 'rgba(255,255,255,0.06)');
  seamGrad.addColorStop(0.5, 'rgba(255,255,255,0.10)');
  seamGrad.addColorStop(0.65, 'rgba(255,255,255,0.06)');
  seamGrad.addColorStop(1, 'rgba(255,255,255,0)');
  ctx.fillStyle = seamGrad;
  ctx.fillRect(-12, -724, 24, 1448);
  ctx.restore();

  // White R lettermark (centered, slightly smaller)
  const rScale = 0.85;
  const rOffsetX = (1024 - 512 * rScale) / 2;
  const rOffsetY = 180;

  ctx.save();
  ctx.translate(rOffsetX, rOffsetY);
  ctx.scale(rScale, rScale);

  // Draw R using path commands manually (Path2D not available in node-canvas)
  ctx.beginPath();
  // Outer shape
  ctx.moveTo(80, 448);
  ctx.lineTo(80, 64);
  ctx.lineTo(292, 64);
  ctx.bezierCurveTo(408, 64, 440, 120, 440, 192);
  ctx.bezierCurveTo(440, 268, 396, 308, 312, 316);
  ctx.lineTo(432, 448);
  ctx.lineTo(340, 448);
  ctx.lineTo(228, 324);
  ctx.lineTo(164, 324);
  ctx.lineTo(164, 448);
  ctx.closePath();

  // Inner cutout (hole in the R)
  ctx.moveTo(164, 140);
  ctx.lineTo(278, 140);
  ctx.bezierCurveTo(348, 140, 364, 168, 364, 196);
  ctx.bezierCurveTo(364, 224, 348, 252, 278, 252);
  ctx.lineTo(164, 252);
  ctx.closePath();

  ctx.fillStyle = 'white';
  ctx.fill('evenodd');
  ctx.restore();

  // Green heartbeat ECG line
  drawHeartbeatLine(ctx);

  ctx.restore();
}

function drawHeartbeatLine(ctx) {
  const centerY = 700;
  const lineWidth = 5;

  ctx.save();
  ctx.strokeStyle = '#4ADE80';
  ctx.lineWidth = lineWidth;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.shadowColor = '#4ADE80';
  ctx.shadowBlur = 14;

  ctx.beginPath();
  ctx.moveTo(100, centerY);
  ctx.lineTo(250, centerY);

  // Small pre-wave
  ctx.lineTo(270, centerY - 12);
  ctx.lineTo(285, centerY + 6);
  ctx.lineTo(298, centerY);

  ctx.lineTo(340, centerY);

  // First main pulse
  ctx.lineTo(358, centerY + 22);
  ctx.lineTo(382, centerY - 110);
  ctx.lineTo(410, centerY + 55);
  ctx.lineTo(430, centerY - 8);
  ctx.lineTo(445, centerY);

  ctx.lineTo(500, centerY);
  ctx.quadraticCurveTo(525, centerY - 35, 550, centerY);

  ctx.lineTo(590, centerY);

  // Second main pulse
  ctx.lineTo(608, centerY + 20);
  ctx.lineTo(632, centerY - 100);
  ctx.lineTo(660, centerY + 50);
  ctx.lineTo(680, centerY - 6);
  ctx.lineTo(694, centerY);

  ctx.lineTo(740, centerY);
  ctx.quadraticCurveTo(762, centerY - 30, 785, centerY);

  ctx.lineTo(924, centerY);

  ctx.stroke();

  // Glow pass
  ctx.shadowBlur = 0;
  ctx.globalAlpha = 0.35;
  ctx.lineWidth = lineWidth + 5;
  ctx.stroke();
  ctx.restore();
}

function renderIcon(size) {
  const canvas = createCanvas(size, size);
  const ctx = canvas.getContext('2d');
  // Start with fully opaque background to guarantee no transparency anywhere
  ctx.fillStyle = '#6B5CE7';
  ctx.fillRect(0, 0, size, size);
  drawIcon(ctx, size);

  // Final pass: flatten alpha to ensure every pixel is fully opaque (alpha=255)
  // This prevents any semi-transparent edge artifacts from shadows/anti-aliasing
  const imageData = ctx.getImageData(0, 0, size, size);
  const data = imageData.data;
  for (let i = 3; i < data.length; i += 4) {
    if (data[i] < 255) {
      // Pre-multiply with purple background for any semi-transparent pixels
      const a = data[i] / 255;
      data[i - 3] = Math.round(data[i - 3] * a + 107 * (1 - a)); // R (107 = 0x6B)
      data[i - 2] = Math.round(data[i - 2] * a + 92 * (1 - a));  // G (92 = 0x5C)
      data[i - 1] = Math.round(data[i - 1] * a + 231 * (1 - a)); // B (231 = 0xE7)
      data[i] = 255;
    }
  }
  ctx.putImageData(imageData, 0, 0);

  return canvas;
}

function saveIcon(size, outputPath) {
  const canvas = renderIcon(size);
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  const buffer = canvas.toBuffer('image/png');
  fs.writeFileSync(outputPath, buffer);
  console.log(`  Saved: ${outputPath} (${size}x${size}, ${(buffer.length / 1024).toFixed(1)} KB)`);
}

const root = path.resolve(__dirname, '..');

console.log('=== RIVL Icon Generator ===\n');

// iOS icons
console.log('iOS icons:');
const iosDir = path.join(root, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
const iosSizes = [
  { name: 'Icon-App-1024x1024@1x.png', size: 1024 },
  { name: 'Icon-App-20x20@1x.png', size: 20 },
  { name: 'Icon-App-20x20@2x.png', size: 40 },
  { name: 'Icon-App-20x20@3x.png', size: 60 },
  { name: 'Icon-App-29x29@1x.png', size: 29 },
  { name: 'Icon-App-29x29@2x.png', size: 58 },
  { name: 'Icon-App-29x29@3x.png', size: 87 },
  { name: 'Icon-App-40x40@1x.png', size: 40 },
  { name: 'Icon-App-40x40@2x.png', size: 80 },
  { name: 'Icon-App-40x40@3x.png', size: 120 },
  { name: 'Icon-App-60x60@2x.png', size: 120 },
  { name: 'Icon-App-60x60@3x.png', size: 180 },
  { name: 'Icon-App-76x76@1x.png', size: 76 },
  { name: 'Icon-App-76x76@2x.png', size: 152 },
  { name: 'Icon-App-83.5x83.5@2x.png', size: 167 },
];
for (const item of iosSizes) {
  saveIcon(item.size, path.join(iosDir, item.name));
}

// Android icons
console.log('\nAndroid icons:');
const androidResDir = path.join(root, 'android', 'app', 'src', 'main', 'res');
const androidSizes = [
  { name: 'mipmap-mdpi/ic_launcher.png', size: 48 },
  { name: 'mipmap-hdpi/ic_launcher.png', size: 72 },
  { name: 'mipmap-xhdpi/ic_launcher.png', size: 96 },
  { name: 'mipmap-xxhdpi/ic_launcher.png', size: 144 },
  { name: 'mipmap-xxxhdpi/ic_launcher.png', size: 192 },
];
for (const item of androidSizes) {
  saveIcon(item.size, path.join(androidResDir, item.name));
}

// Web icons
console.log('\nWeb icons:');
const webDir = path.join(root, 'web');
saveIcon(512, path.join(webDir, 'icons', 'Icon-512.png'));
saveIcon(512, path.join(webDir, 'icons', 'Icon-maskable-512.png'));
saveIcon(192, path.join(webDir, 'icons', 'Icon-192.png'));
saveIcon(192, path.join(webDir, 'icons', 'Icon-maskable-192.png'));
saveIcon(32, path.join(webDir, 'favicon.png'));

// macOS icons
console.log('\nmacOS icons:');
const macosDir = path.join(root, 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
const macosSizes = [1024, 512, 256, 128, 64, 32, 16];
for (const size of macosSizes) {
  saveIcon(size, path.join(macosDir, `app_icon_${size}.png`));
}

// Windows icon (just use a 256x256 PNG, .ico generation would need another tool)
console.log('\nWindows icon:');
saveIcon(256, path.join(root, 'windows', 'runner', 'resources', 'app_icon_256.png'));

// In-app logo assets
console.log('\nIn-app logos:');
const assetsDir = path.join(root, 'assets', 'images');
saveIcon(128, path.join(assetsDir, 'rivl_logo.png'));
saveIcon(256, path.join(assetsDir, '2.0x', 'rivl_logo.png'));
saveIcon(384, path.join(assetsDir, '3.0x', 'rivl_logo.png'));

// Docs favicon
console.log('\nDocs:');
saveIcon(32, path.join(root, 'docs', 'favicon.png'));

console.log('\nDone! All icons generated.');
