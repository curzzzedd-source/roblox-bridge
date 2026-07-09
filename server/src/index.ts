import express, { Request, Response } from 'express';
import cors from 'cors';
import { MongoClient, Db, Collection } from 'mongodb';

const app = express();
const PORT = parseInt(process.env.PORT || '7269', 10);

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// MongoDB connection
const MONGO_URI = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/roblox_bridge';
const DB_NAME = 'roblox_bridge';

let db: Db | null = null;
let commandsCol: Collection<any> | null = null;
let resultsCol: Collection<any> | null = null;

async function connectDB() {
  try {
    const client = new MongoClient(MONGO_URI);
    await client.connect();
    db = client.db(DB_NAME);
    commandsCol = db.collection('commands');
    resultsCol = db.collection('results');

    // Auto-expire old commands (TTL index - 1 hour)
    await commandsCol.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });
    await resultsCol.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });

    console.log('✅ Connected to MongoDB');
  } catch (err) {
    console.error('⚠️ MongoDB connection failed, using in-memory fallback:', (err as Error).message);
  }
}

// In-memory fallback
const memCommands: Array<any> = [];
const memResults = new Map<string, any>();

// Root route - no more 404 on Railway health checks
app.get('/', (req: Request, res: Response) => {
  res.json({
    name: 'Codely Roblox Bridge',
    status: 'running',
    endpoints: {
      health: '/health',
      sendCommand: 'POST /api/command',
      getCommands: 'GET /api/commands',
      clearCommands: 'POST /api/commands/clear',
      sendResult: 'POST /api/result',
      getResult: 'GET /api/result/:commandId',
    },
  });
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

// ========== CODELY → STUDIO ==========

// Send a command TO Studio
app.post('/api/command', async (req: Request, res: Response) => {
  const { action, data } = req.body;

  if (!action) {
    return res.status(400).json({ success: false, error: 'Missing action' });
  }

  const commandId = `cmd_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const command = {
    id: commandId,
    action,
    data: data || {},
    status: 'pending',
    createdAt: new Date(),
  };

  if (commandsCol) {
    await commandsCol.insertOne(command);
  } else {
    memCommands.push(command);
  }

  console.log(`[${new Date().toISOString()}] Command queued: ${action} (${commandId})`);
  res.json({ success: true, commandId });
});

// Studio polls for pending commands
app.get('/api/commands', async (req: Request, res: Response) => {
  let commands: any[];
  if (commandsCol) {
    commands = await commandsCol.find({ status: 'pending' }).toArray();
  } else {
    commands = memCommands.filter(c => c.status === 'pending');
  }
  res.json({ commands });
});

// Studio clears processed commands
app.post('/api/commands/clear', async (req: Request, res: Response) => {
  const { commandIds } = req.body;
  const ids = commandIds || [];

  if (commandsCol) {
    if (ids.length > 0) {
      await commandsCol.updateMany(
        { id: { $in: ids } },
        { $set: { status: 'processing' } }
      );
    }
  } else {
    for (const id of ids) {
      const cmd = memCommands.find(c => c.id === id);
      if (cmd) cmd.status = 'processing';
    }
  }

  res.json({ success: true });
});

// ========== STUDIO → CODELY ==========

// Studio sends result back
app.post('/api/result', async (req: Request, res: Response) => {
  const { commandId, result, error } = req.body;

  if (!commandId) {
    return res.status(400).json({ success: false, error: 'Missing commandId' });
  }

  const doc = {
    commandId,
    result: result || null,
    error: error || null,
    createdAt: new Date(),
  };

  if (resultsCol) {
    await resultsCol.insertOne(doc);
    // Mark command as completed
    if (commandsCol) {
      await commandsCol.updateOne(
        { id: commandId },
        { $set: { status: 'completed' } }
      );
    }
  } else {
    memResults.set(commandId, doc);
    const cmd = memCommands.find(c => c.id === commandId);
    if (cmd) cmd.status = 'completed';
  }

  console.log(`[${new Date().toISOString()}] Result received: ${commandId}`);
  res.json({ success: true });
});

// Codely polls for result - returns 202 if pending (NO MORE 404!)
app.get('/api/result/:commandId', async (req: Request, res: Response) => {
  const { commandId } = req.params;

  let result: any = null;

  if (resultsCol) {
    result = await resultsCol.findOneAndDelete({ commandId });
    result = result.value;
  } else {
    result = memResults.get(commandId);
    if (result) memResults.delete(commandId);
  }

  if (result) {
    res.json(result);
  } else {
    // Return 202 Accepted = still processing (not 404!)
    res.status(202).json({ status: 'pending', commandId });
  }
});

// Start server
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Codely Bridge running on port ${PORT}`);
    console.log(`📋 Waiting for commands...`);
  });
});