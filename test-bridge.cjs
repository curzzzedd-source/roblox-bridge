#!/usr/bin/env node

/**
 * Test and Fix Roblox Bridge Connection
 */

const http = require('http');

function testConnection() {
  return new Promise((resolve, reject) => {
    http.get('http://localhost:7269/health', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`Status: ${res.statusCode}`));
        }
      });
    }).on('error', reject);
  });
}

function sendTestCommand() {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      action: 'get_object_info',
      data: {
        objectPath: 'game.Workspace'
      }
    });

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

function getCommandResult(commandId, timeout = 30000) {
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

async function runTests() {
  console.log('🔍 Testing Roblox Bridge Connection...\n');

  try {
    // Test 1: Server connection
    console.log('Test 1: Server Health Check');
    const health = await testConnection();
    console.log('✅ Server is healthy:', health);
    console.log(`   - Pending Studio Requests: ${health.pendingStudioRequests}`);
    console.log(`   - Pending Commands: ${health.pendingCommands}\n`);

    // Test 2: Send command
    console.log('Test 2: Sending Test Command');
    const commandId = await sendTestCommand();
    console.log('✅ Command queued:', commandId);
    console.log('   Waiting for Studio response...\n');

    // Test 3: Get result
    console.log('Test 3: Waiting for Result');
    const result = await getCommandResult(commandId);
    console.log('✅ Result received:');
    console.log(JSON.stringify(result, null, 2));

    console.log('\n🎉 All tests passed! Bridge is working correctly.');
    console.log('\n💡 You can now ask Codely to execute commands in Roblox Studio!');

  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    console.log('\n🔧 Troubleshooting:');
    console.log('   1. Make sure Roblox Studio is open');
    console.log('   2. Make sure the Codely Bridge plugin is loaded');
    console.log('   3. Check the plugin panel in Studio for errors');
    console.log('   4. Make sure HTTP is enabled in Studio');
    process.exit(1);
  }
}

runTests();