#!/usr/bin/env node

const http = require('http');

async function sendCommand(action, data = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ action, data });

    const options = {
      hostname: 'localhost',
      port: 7269,
      path: '/api/command',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          resolve(response.commandId);
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
        reject(new Error('Timeout waiting for result'));
        return;
      }

      http.get(`http://localhost:7269/api/result/${commandId}`, (res) => {
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