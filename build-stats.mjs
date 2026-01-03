#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Read stats.json
const statsPath = path.join(__dirname, 'dist/angular-release-deployment-frontend/stats.json');

if (!fs.existsSync(statsPath)) {
  console.error('❌ stats.json not found. Run: ng build --stats-json');
  process.exit(1);
}

const stats = JSON.parse(fs.readFileSync(statsPath, 'utf8'));

console.log('\n📊 Build Performance Report\n');
console.log('='.repeat(80));

// Build timing
if (stats.builtAt) {
  const buildDate = new Date(stats.builtAt);
  console.log(`\n⏱️  Build Time: ${buildDate.toLocaleString()}`);
}

// Chunk analysis
const chunks = {};
let totalSize = 0;
let totalGzipEstimate = 0;

for (const [filePath, fileInfo] of Object.entries(stats.outputs || {})) {
  const bytes = fileInfo.bytes;
  totalSize += bytes;

  // Estimate gzip (typically 25-30% of original)
  const gzipEstimate = Math.round(bytes * 0.27);
  totalGzipEstimate += gzipEstimate;

  const fileName = path.basename(filePath);
  const isLazy = filePath.includes('chunk-') && !filePath.includes('main');
  const chunkType = isLazy ? 'Lazy' : 'Initial';

  if (fileName.endsWith('.js')) {
    if (!chunks[chunkType]) {
      chunks[chunkType] = [];
    }
    chunks[chunkType].push({
      name: fileName,
      size: bytes,
      gzip: gzipEstimate
    });
  }
}

// Format bytes
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(2)} ${sizes[i]}`;
}

// Display chunks
console.log('\n📦 Bundle Sizes\n');

['Initial', 'Lazy'].forEach(type => {
  if (chunks[type]) {
    console.log(`${type} Chunks:`);
    chunks[type].forEach(chunk => {
      console.log(`  ${chunk.name.padEnd(30)} ${formatBytes(chunk.size).padStart(10)} → ${formatBytes(chunk.gzip).padStart(10)} (gzipped)`);
    });
    console.log('');
  }
});

console.log('='.repeat(80));
console.log(`\n📈 Total Size: ${formatBytes(totalSize)} (uncompressed)`);
console.log(`📉 Estimated Gzipped: ${formatBytes(totalGzipEstimate)}`);

// Performance budget check
const budgetKB = 512;
const actualGzipKB = totalGzipEstimate / 1024;

console.log('\n💰 Performance Budget\n');
console.log(`  Budget:     ${budgetKB} KB (gzipped)`);
console.log(`  Actual:     ${actualGzipKB.toFixed(2)} KB (gzipped)`);
console.log(`  Status:     ${actualGzipKB <= budgetKB ? '✅ PASS' : '❌ FAIL'}`);
console.log(`  Remaining:  ${(budgetKB - actualGzipKB).toFixed(2)} KB`);

// Build warnings
if (stats.warnings && stats.warnings.length > 0) {
  console.log('\n⚠️  Build Warnings:\n');
  stats.warnings.forEach(warning => {
    console.log(`  • ${warning}`);
  });
}

// Build errors
if (stats.errors && stats.errors.length > 0) {
  console.log('\n❌ Build Errors:\n');
  stats.errors.forEach(error => {
    console.log(`  • ${error}`);
  });
}

console.log('\n' + '='.repeat(80) + '\n');
