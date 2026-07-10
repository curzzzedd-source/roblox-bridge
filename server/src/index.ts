import express, { Request, Response } from 'express';
import cors from 'cors';
import { MongoClient, Db, Collection } from 'mongodb';

const app = express();
const PORT = parseInt(process.env.PORT || '7269', 10);

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// MongoDB
const MONGO_URI = process.env.MONGO_URL || process.env.MONGODB_URI || 'mongodb://localhost:27017/roblox_bridge';
const DB_NAME = 'roblox_bridge';

let db: Db | null = null;
let commandsCol: Collection<any> | null = null;
let resultsCol: Collection<any> | null = null;
let sessionsCol: Collection<any> | null = null;

async function connectDB() {
  try {
    const client = new MongoClient(MONGO_URI);
    await client.connect();
    db = client.db(DB_NAME);
    commandsCol = db.collection('commands');
    resultsCol = db.collection('results');
    sessionsCol = db.collection('sessions');

    await commandsCol.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });
    await resultsCol.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });
    await sessionsCol.createIndex({ updatedAt: 1 }, { expireAfterSeconds: 60 });

    console.log('✅ Connected to MongoDB');
  } catch (err) {
    console.error('⚠️ MongoDB failed, using in-memory:', (err as Error).message);
  }
}

// In-memory fallback
const memCommands: Array<any> = [];
const memResults = new Map<string, any>();
const memSessions = new Map<string, any>();

// ========== SESSION MANAGEMENT ==========

// Studio registers its current place
app.post('/api/register', async (req: Request, res: Response) => {
  const { sessionId, placeId, placeName, gameId, activated } = req.body;

  if (!sessionId) {
    return res.status(400).json({ success: false, error: 'Missing sessionId' });
  }

  const session = {
    sessionId,
    placeId,
    placeName,
    gameId,
    status: 'active',
    activated: activated || false,
    updatedAt: new Date(),
  };

  if (sessionsCol) {
    await sessionsCol.updateOne(
      { sessionId },
      { $set: session },
      { upsert: true }
    );
  } else {
    memSessions.set(sessionId, session);
  }

  console.log(`[${new Date().toISOString()}] Studio registered: ${placeName} (activated: ${activated || false})`);
  res.json({ success: true, sessionId });
});

// Studio sends heartbeat
app.post('/api/heartbeat', async (req: Request, res: Response) => {
  const { sessionId, placeInfo, activated } = req.body;

  if (!sessionId) {
    return res.status(400).json({ success: false, error: 'Missing sessionId' });
  }

  const update: any = { status: 'active', updatedAt: new Date() };
  if (placeInfo) Object.assign(update, placeInfo);
  if (activated !== undefined) update.activated = activated;

  if (sessionsCol) {
    await sessionsCol.updateOne(
      { sessionId },
      { $set: update }
    );
  } else if (memSessions.has(sessionId)) {
    const s = memSessions.get(sessionId);
    s.updatedAt = new Date();
    s.status = 'active';
    if (activated !== undefined) s.activated = activated;
  }

  res.json({ success: true });
});

// Codely checks which Studio is active
app.get('/api/session', async (req: Request, res: Response) => {
  let session: any = null;

  if (sessionsCol) {
    // Find most recently updated active session
    session = await sessionsCol.findOne(
      { status: 'active' },
      { sort: { updatedAt: -1 } }
    );
  } else {
    let latest: any = null;
    for (const [, s] of memSessions) {
      if (!latest || s.updatedAt > latest.updatedAt) latest = s;
    }
    session = latest;
  }

  if (session) {
    res.json({
      sessionId: session.sessionId,
      placeId: session.placeId,
      placeName: session.placeName,
      gameId: session.gameId,
      status: session.status,
      activated: session.activated || false,
    });
  } else {
    res.status(404).json({ error: 'No active Studio session' });
  }
});

// ========== CODELY → STUDIO ==========

// Send a command TO the active Studio session
app.post('/api/command', async (req: Request, res: Response) => {
  const { action, data, sessionId } = req.body;

  if (!action) {
    return res.status(400).json({ success: false, error: 'Missing action' });
  }

  // If no sessionId provided, try to find the active session
  let targetSession = sessionId;

  if (!targetSession) {
    if (sessionsCol) {
      const active = await sessionsCol.findOne(
        { status: 'active' },
        { sort: { updatedAt: -1 } }
      );
      if (active) targetSession = active.sessionId;
    } else {
      let latest: any = null;
      for (const [, s] of memSessions) {
        if (!latest || s.updatedAt > latest.updatedAt) latest = s;
      }
      if (latest) targetSession = latest.sessionId;
    }
  }

  if (!targetSession) {
    return res.status(404).json({ success: false, error: 'No active Studio session. Open Roblox Studio and ensure the plugin is loaded.' });
  }

  // Check if the session is activated
  let sessionData: any = null;
  if (sessionsCol) {
    sessionData = await sessionsCol.findOne({ sessionId: targetSession });
  } else {
    sessionData = memSessions.get(targetSession);
  }

  if (!sessionData || !sessionData.activated) {
    return res.status(403).json({ 
      success: false, 
      error: 'Studio is not activated. Click ACTIVATE in the Codely Bridge plugin panel in Roblox Studio.',
      activated: false,
    });
  }

  const commandId = `cmd_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const command = {
    id: commandId,
    action,
    data: data || {},
    sessionId: targetSession,
    status: 'pending',
    createdAt: new Date(),
  };

  if (commandsCol) {
    await commandsCol.insertOne(command);
  } else {
    memCommands.push(command);
  }

  console.log(`[${new Date().toISOString()}] Command queued: ${action} → session ${targetSession}`);
  res.json({ success: true, commandId, sessionId: targetSession });
});

// Studio polls for commands (only its own session)
app.get('/api/commands', async (req: Request, res: Response) => {
  const sessionId = req.query.sessionId as string;

  let commands: any[];
  if (commandsCol) {
    const query: any = { status: 'pending' };
    if (sessionId) query.sessionId = sessionId;
    commands = await commandsCol.find(query).toArray();
  } else {
    commands = memCommands.filter(c => {
      if (c.status !== 'pending') return false;
      if (sessionId && c.sessionId !== sessionId) return false;
      return true;
    });
  }

  res.json({ commands });
});

// Studio clears processed commands
app.post('/api/commands/clear', async (req: Request, res: Response) => {
  const { commandIds } = req.body;
  const ids = commandIds || [];

  if (commandsCol && ids.length > 0) {
    await commandsCol.updateMany(
      { id: { $in: ids } },
      { $set: { status: 'processing' } }
    );
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

// Codely polls for result — 202 if pending (no 404)
app.get('/api/result/:commandId', async (req: Request, res: Response) => {
  const { commandId } = req.params;

  let result: any = null;

  if (resultsCol) {
    const found = await resultsCol.findOneAndDelete({ commandId });
    result = found && found.value ? found.value : null;
  } else {
    result = memResults.get(commandId);
    if (result) memResults.delete(commandId);
  }

  if (result) {
    res.json(result);
  } else {
    res.status(202).json({ status: 'pending', commandId });
  }
});

// ========== ROUTES ==========

app.get('/', (req: Request, res: Response) => {
  res.json({
    name: 'Codely Roblox Bridge',
    status: 'running',
    endpoints: {
      health: '/health',
      register: 'POST /api/register',
      session: 'GET /api/session',
      heartbeat: 'POST /api/heartbeat',
      sendCommand: 'POST /api/command',
      getCommands: 'GET /api/commands?sessionId=...',
      clearCommands: 'POST /api/commands/clear',
      sendResult: 'POST /api/result',
      getResult: 'GET /api/result/:commandId',
    },
  });
});

app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok' });
});

// Start
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Codely Bridge running on port ${PORT}`);
    console.log(`📋 Waiting for Studio to register...`);
  });
});