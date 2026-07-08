#!/usr/bin/env node

/**
 * Codely Bridge Helper
 *
 * This script helps Codely CLI execute commands in Roblox Studio.
 * Usage in Codely chat: "Use roblox-bridge to [action]"
 *
 * Available actions:
 * - create_script
 * - update_script
 * - create_object
 * - delete_object
 * - get_object_info
 * - execute_luau
 * - list_objects
 */

const http = require('http');

const SERVER_URL = 'http://localhost:7269';

/**
 * Send a command to Roblox Studio
 * @param {string} action - The action to execute
 * @param {object} data - Data for the action
 * @returns {Promise<object>} - Result from Studio
 */
function sendCommand(action, data = {}) {
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
      let responseData = '';

      res.on('data', (chunk) => {
        responseData += chunk;
      });

      res.on('end', () => {
        try {
          const response = JSON.parse(responseData);
          if (response.success) {
            // Wait for result from Studio
            waitForResult(response.commandId)
              .then(result => resolve(result))
              .catch(err => reject(err));
          } else {
            reject(new Error('Failed to queue command'));
          }
        } catch (err) {
          reject(err);
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Wait for result from Studio
 * @param {string} commandId - The command ID to wait for
 * @returns {Promise<object>} - The result
 */
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

        res.on('data', (chunk) => {
          data += chunk;
        });

        res.on('end', () => {
          if (res.statusCode === 200) {
            resolve(JSON.parse(data));
          } else if (res.statusCode === 404) {
            // Result not ready, try again
            setTimeout(poll, 500);
          } else {
            reject(new Error(`Error: ${res.statusCode}`));
          }
        });
      }).on('error', (err) => {
        reject(err);
      });
    };

    poll();
  });
}

// CLI interface
const action = process.argv[2];
const dataArg = process.argv[3];

if (!action) {
  console.log('Usage: node roblox-bridge.js <action> [json_data]');
  console.log('\nAvailable actions:');
  console.log('  create_script    - Create a script in Studio');
  console.log('  update_script    - Update an existing script');
  console.log('  create_object    - Create any object in Studio');
  console.log('  delete_object    - Delete an object');
  console.log('  get_object_info  - Get info about an object');
  console.log('  execute_luau     - Execute Luau code');
  console.log('  list_objects     - List objects in a path');
  console.log('\nExample:');
  console.log('  node roblox-bridge.js create_script \'{"name":"HealthScript","scriptType":"Script","code":"-- Health system"}\'');
  process.exit(0);
}

const data = dataArg ? JSON.parse(dataArg) : {};

sendCommand(action, data)
  .then(result => {
    console.log('✅ Success!');
    console.log(JSON.stringify(result, null, 2));
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });