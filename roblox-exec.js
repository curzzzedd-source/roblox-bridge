#!/usr/bin/env node

/**
 * Roblox Studio Bridge for Codely CLI
 * Simple command-line tool to execute actions in Roblox Studio
 */

const http = require('http');

const SERVER_URL = 'http://localhost:7269';

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
        try {
          const response = JSON.parse(data);
          if (response.success) {
            // Wait for result from Studio
            waitForResult(response.commandId).then(resolve).catch(reject);
          } else {
            reject(new Error('Failed to queue command'));
          }
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function waitForResult(commandId, timeout = 30000) {
  return new Promise((resolve, reject) => {
    const startTime = Date.now();

    const poll = () => {
      if (Date.now() - startTime > timeout) {
        reject(new Error('Timeout waiting for result'));
        return;
      }

      http.get(`${SERVER_URL}/api/result/${commandId}`, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else if (res.statusCode === 404) {
            setTimeout(poll, 500);
          } else {
            reject(new Error(`Error: ${res.statusCode}`));
          }
        });
      }).on('error', reject);
    };

    poll();
  });
}

// CLI interface
if (require.main === module) {
  const action = process.argv[2];
  const dataArg = process.argv[3];

  if (!action) {
    console.log('Usage: node roblox-exec.js <action> [json_data]');
    console.log('Actions: create_script, update_script, create_object, delete_object, get_object_info, list_objects');
    process.exit(1);
  }

  const data = dataArg ? JSON.parse(dataArg) : {};

  sendCommand(action, data)
    .then(result => {
      console.log('✅ Result:', JSON.stringify(result, null, 2));
      process.exit(0);
    })
    .catch(err => {
      console.error('❌ Error:', err.message);
      process.exit(1);
    });
}

module.exports = { sendCommand };