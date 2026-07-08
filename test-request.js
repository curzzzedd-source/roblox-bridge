// Test script to verify the bridge server works

const fetch = require('node-fetch');

async function testRequest() {
  try {
    const response = await fetch('http://localhost:7269/api/request', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        type: 'code_assistant',
        query: 'Create a simple Health script for players',
        context: ''
      })
    });

    const data = await response.json();
    console.log('✅ Test successful!');
    console.log('Response:', data);
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testRequest();