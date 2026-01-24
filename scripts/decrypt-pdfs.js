#!/usr/bin/env node
/**
 * Che smotrish sudya?
 * You cannot see files in _protected_pdfs without the password, yours best bet 
 * is to ask the site owner for it.
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const ALGORITHM = 'aes-256-cbc';
const PROTECTED_DIR = path.join(__dirname, '..', '_protected_pdfs');

function decrypt(encryptedBuffer, password) {
  // Extract salt (16 bytes), iv (16 bytes), and encrypted data
  const salt = encryptedBuffer.slice(0, 16);
  const iv = encryptedBuffer.slice(16, 32);
  const encrypted = encryptedBuffer.slice(32);

  // Derive key from password
  const key = crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256');

  // Decrypt
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  const decrypted = Buffer.concat([decipher.update(encrypted), decipher.final()]);

  return decrypted;
}

// Main
const password = process.env.STATICRYPT_PASSWORD;

if (!password) {
  console.error('ERROR: STATICRYPT_PASSWORD environment variable not set.');
  process.exit(1);
}

if (!fs.existsSync(PROTECTED_DIR)) {
  console.log('No _protected_pdfs directory found. Skipping decryption.');
  process.exit(0);
}

const files = fs.readdirSync(PROTECTED_DIR).filter(f => f.endsWith('.enc'));

if (files.length === 0) {
  console.log('No encrypted files found. Skipping decryption.');
  process.exit(0);
}

console.log(`Decrypting ${files.length} file(s)...`);

for (const file of files) {
  const encPath = path.join(PROTECTED_DIR, file);
  const outPath = path.join(PROTECTED_DIR, file.replace('.enc', ''));

  console.log(`  ${file} -> ${file.replace('.enc', '')}`);

  try {
    const encryptedBuffer = fs.readFileSync(encPath);
    console.log(`    Encrypted size: ${encryptedBuffer.length} bytes`);
    const decrypted = decrypt(encryptedBuffer, password);
    console.log(`    Decrypted size: ${decrypted.length} bytes`);
    fs.writeFileSync(outPath, decrypted);
    console.log(`    Saved to: ${outPath}`);
  } catch (error) {
    console.error(`  ERROR decrypting ${file}: ${error.message}`);
    process.exit(1);
  }
}

console.log('Done!');
