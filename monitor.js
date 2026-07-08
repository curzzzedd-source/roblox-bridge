#!/usr/bin/env node

/**
 * Codely Bridge Monitor
 *
 * This script monitors the bridge server for incoming requests from Roblox Studio.
 * You can run this in the background and it will show requests as they arrive.
 */

const http = require('http');

const SERVER_URL = 'http://localhost:7269/api/queue';
const POLL_INTERVAL = 2000; // Check every 2 seconds

let lastSeenIds = new Set();

console.log('🔍 Monitoring Roblox-Codely Bridge for incoming requests...');
console.log('   Press Ctrl+C to stop\n');

function pollQueue() {
  http.get(SERVER_URL, (res) => {
    let data = '';

    res.on('data', (chunk) => data += chunk);

    res.on('end', () => {
      try {
        const { requests } = JSON.parse(data);

        requests.forEach(req => {
          if (!lastSeenIds.has(req.id)) {
            lastSeenIds.add(req.id);
            console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log(`📨 NEW REQUEST [${req.id}]`);
            console.log(`   Type: ${req.type}`);
            console.log(`   Query: ${req.query}`);
            if (req.context) {
              console.log(`   Context: ${req.context.substring(0, 200)}${req.context.length > 200 ? '...' : ''}`);
            }
            console.log('\n💡 To respond, use:');
            console.log(`   curl -X POST http://localhost:7269/api/respond -H "Content-Type: application/json" -d '{"requestId":"${req.id}","result":"YOUR_RESPONSE_HERE"}'`);
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
          }
        });
      } catch (err) {
        console.error('Error parsing response:', err.message);
      }
    });
  }).on('error', (err) => {
    console.error('Error connecting to server:', err.message);
  });
}

// Start polling
pollQueue();
setInterval(pollQueue, POLL_INTERVAL);