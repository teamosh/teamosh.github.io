#!/usr/bin/env node
/**
 * Che smotrish sudya?
 * Protected posts are encrypted with AES-256. Good luck.
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const SITE_DIR = path.join(__dirname, '..', '_site');
const TEMPLATE_PATH = path.join(__dirname, 'password-template.html');
const PASSWORD = process.env.STATICRYPT_PASSWORD;

if (!PASSWORD) {
  console.error('ERROR: STATICRYPT_PASSWORD environment variable not set');
  process.exit(1);
}

// Find all HTML files in _site
function findHtmlFiles(dir, files = []) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      findHtmlFiles(fullPath, files);
    } else if (entry.name.endsWith('.html')) {
      files.push(fullPath);
    }
  }
  return files;
}

// Check if HTML file contains the protected marker
function isProtected(htmlPath) {
  const content = fs.readFileSync(htmlPath, 'utf-8');
  // Jekyll outputs a meta tag or data attribute for protected posts
  return content.includes('data-protected="true"') ||
         content.includes('class="protected-post"');
}

// Encrypt a single file
function encryptFile(filePath) {
  const relativePath = path.relative(SITE_DIR, filePath);
  console.log(`Encrypting: ${relativePath}`);

  const sizeBefore = fs.statSync(filePath).size;
  const dir = path.dirname(filePath);
  const filename = path.basename(filePath);
  const tempDir = path.join(dir, '_encrypted_temp');

  try {
    // Create temp directory
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir);
    }

    // StatiCrypt 3.x uses -d for output DIRECTORY (not -o for file)
    // Use custom hieroglyphics template
    const cmd = `staticrypt "${filePath}" -p "${PASSWORD}" -d "${tempDir}" -t "${TEMPLATE_PATH}"`;
    console.log(`  Running staticrypt with custom template`);

    execSync(cmd, { encoding: 'utf-8' });

    // The output file will have the same name in the temp directory
    const encryptedFile = path.join(tempDir, filename);

    if (!fs.existsSync(encryptedFile)) {
      // List what's in temp dir for debugging
      const tempFiles = fs.readdirSync(tempDir);
      console.error(`  Temp dir contents: ${tempFiles.join(', ') || 'empty'}`);
      console.error(`  ERROR: Encrypted file not found at ${encryptedFile}`);
      process.exit(1);
    }

    const sizeAfter = fs.statSync(encryptedFile).size;
    console.log(`  Size: ${sizeBefore} -> ${sizeAfter} bytes`);

    // Replace original with encrypted version
    fs.unlinkSync(filePath);
    fs.renameSync(encryptedFile, filePath);
    fs.rmdirSync(tempDir);
    console.log(`  Success!`);

  } catch (error) {
    console.error(`Failed to encrypt ${relativePath}:`);
    console.error(`  stdout: ${error.stdout || 'none'}`);
    console.error(`  stderr: ${error.stderr || 'none'}`);
    console.error(`  message: ${error.message}`);
    process.exit(1);
  }
}

// Main
console.log('Scanning for protected posts in:', SITE_DIR);
const htmlFiles = findHtmlFiles(SITE_DIR);
console.log(`Found ${htmlFiles.length} HTML files`);

let encryptedCount = 0;

for (const file of htmlFiles) {
  const content = fs.readFileSync(file, 'utf-8');
  const hasMarker = content.includes('data-protected="true"') || content.includes('class="protected-post"');
  console.log(`  ${path.relative(SITE_DIR, file)}: ${hasMarker ? 'PROTECTED' : 'not protected'}`);

  if (hasMarker) {
    encryptFile(file);
    encryptedCount++;
  }
}

console.log(`\nDone! Encrypted ${encryptedCount} file(s).`);
