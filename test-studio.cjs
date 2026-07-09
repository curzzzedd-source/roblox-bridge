#!/usr/bin/env node

const https = require('https');

const SERVER_URL = 'https://web-production-f04e1.up.railway.app';

async function sendCommand(action, data = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ action, data });

    const options = {
      hostname: 'web-production-f04e1.up.railway.app',
      path: '/api/command',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data).commandId);
        } else {
          reject(new Error(`Status: ${res.statusCode}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function getResult(commandId, timeout = 30000) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const poll = () => {
      if (Date.now() - startTime > timeout) {
        reject(new Error('Timeout'));
        return;
      }

      https.get(`${SERVER_URL}/api/result/${commandId}`, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else if (res.statusCode === 404) {
            setTimeout(poll, 500);
          } else {
            reject(new Error(`Status: ${res.statusCode}`));
          }
        });
      }).on('error', reject);
    };

    poll();
  });
}

// Test: List objects in Workspace
sendCommand('list_objects', { parentPath: '' })
  .then(commandId => {
    console.log('✅ Command sent:', commandId);
    console.log('⏳ Waiting for Studio response...');
    return getResult(commandId);
  })
  .then(result => {
    console.log('🎉 Result:', JSON.stringify(result, null, 2));
  })
  .catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });