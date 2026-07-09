#!/usr/bin/env node

/**
 * Codely → Roblox Studio Bridge
 * Usage: node studio.cjs <action> [json_data]
 * 
 * Actions:
 *   list_objects <parentPath>     - List children of a path
 *   create_script <json>           - Create a script
 *   update_script <json>           - Update a script
 *   create_object <json>           - Create an object
 *   delete_object <path>           - Delete an object
 *   get_object_info <path>         - Get info about an object
 *   execute_luau <code>            - Execute Luau code
 *   test                           - Test connection
 */

const https = require('https');

const SERVER = 'https://web-production-f04e1.up.railway.app';

function sendCommand(action, data = {}) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({ action, data });
    const req = https.request(`${SERVER}/api/command`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(postData) }
    }, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        if (res.statusCode === 200) resolve(JSON.parse(d).commandId);
        else reject(new Error(`HTTP ${res.statusCode}: ${d}`));
      });
    });
    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

function getResult(commandId, timeout = 30000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const poll = () => {
      if (Date.now() - start > timeout) { reject(new Error('Timeout - Studio not responding')); return; }
      https.get(`${SERVER}/api/result/${commandId}`, (res) => {
        let d = '';
        res.on('data', c => d += c);
        res.on('end', () => {
          if (res.statusCode === 200) resolve(JSON.parse(d));
          else if (res.statusCode === 202 || res.statusCode === 404) setTimeout(poll, 500);
          else reject(new Error(`HTTP ${res.statusCode}: ${d}`));
        });
      }).on('error', reject);
    };
    poll();
  });
}

async function run(action, data) {
  const cmdId = await sendCommand(action, data);
  const result = await getResult(cmdId);
  return result;
}

// CLI
const action = process.argv[2];
const dataArg = process.argv[3];

if (!action) {
  console.log('Usage: node studio.cjs <action> [json_data]');
  console.log('Actions: list_objects, create_script, update_script, create_object, delete_object, get_object_info, execute_luau, test');
  process.exit(0);
}

(async () => {
  try {
    if (action === 'test') {
      const health = await new Promise((resolve, reject) => {
        https.get(`${SERVER}/health`, (res) => {
          let d = '';
          res.on('data', c => d += c);
          res.on('end', () => resolve(JSON.parse(d)));
        }).on('error', reject);
      });
      console.log('Server:', JSON.stringify(health));
      console.log('Sending test command to Studio...');
      const result = await run('list_objects', { parentPath: 'Workspace' });
      console.log('Studio response:', JSON.stringify(result, null, 2));
    } else if (action === 'list_objects') {
      const result = await run('list_objects', { parentPath: dataArg || '' });
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'create_script') {
      const data = JSON.parse(dataArg);
      const result = await run('create_script', data);
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'create_object') {
      const data = JSON.parse(dataArg);
      const result = await run('create_object', data);
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'delete_object') {
      const result = await run('delete_object', { objectPath: dataArg });
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'get_object_info') {
      const result = await run('get_object_info', { objectPath: dataArg });
      console.log(JSON.stringify(result, null, 2));
    } else if (action === 'execute_luau') {
      const result = await run('execute_luau', { code: dataArg });
      console.log(JSON.stringify(result, null, 2));
    } else {
      console.error('Unknown action:', action);
      process.exit(1);
    }
  } catch (err) {
    console.error('❌', err.message);
    process.exit(1);
  }
})();