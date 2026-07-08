import express, { Request, Response } from 'express';
import cors from 'cors';

const app = express();
const PORT = 7269;

app.use(cors());
app.use(express.json());

// Request queue from Studio → Codely
const studioRequests: Array<{
  id: string;
  type: string;
  query: string;
  context?: string;
  resolve: (response: string) => void;
}> = [];

// Command queue from Codely → Studio (new!)
const commandQueue: Array<{
  id: string;
  action: string;
  data: any;
}> = [];

// Results from Studio → Codely (new!)
const commandResults = new Map<string, any>();

// Endpoint for Roblox plugin to send requests
app.post('/api/request', (req: Request, res: Response) => {
  const { type, query, context } = req.body;

  if (!type || !query) {
    return res.status(400).json({ error: 'Missing type or query' });
  }

  const requestId = `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

  // Create a promise that resolves when Codely responds
  const responsePromise = new Promise<string>((resolve) => {
    // Add to queue for Codely to process
    console.log(`[${new Date().toISOString()}] New request:`, { id: requestId, type, query, context });
    studioRequests.push({ id: requestId, type, query, context, resolve });
  });

  // Wait for response (with timeout)
  Promise.race([
    responsePromise,
    new Promise<string>((_, reject) =>
      setTimeout(() => reject(new Error('Timeout')), 60000)
    )
  ])
    .then((result) => {
      res.json({ id: requestId, result });
    })
    .catch((error) => {
      res.status(500).json({ error: error.message });
    });
});

// ========== STUDIO → CODELY (for AI assistance) ==========

// Endpoint for Codely CLI to poll for pending requests from Studio
app.get('/api/studio-requests', (req: Request, res: Response) => {
  const requests = studioRequests.map(req => ({
    id: req.id,
    type: req.type,
    query: req.query,
    context: req.context
  }));
  res.json({ requests });
});

// Endpoint for Codely CLI to send responses back to Studio
app.post('/api/studio-respond', (req: Request, res: Response) => {
  const { requestId, result } = req.body;

  const request = studioRequests.find(r => r.id === requestId);
  if (request) {
    const index = studioRequests.indexOf(request);
    if (index > -1) {
      studioRequests.splice(index, 1);
    }
    request.resolve(result);
    console.log(`[${new Date().toISOString()}] Responded to Studio request ${requestId}`);
    res.json({ success: true });
  } else {
    res.status(404).json({ error: 'Studio request not found' });
  }
});

// ========== CODELY → STUDIO (for executing commands) ==========

// Endpoint for Codely CLI to send commands TO Studio
app.post('/api/command', (req: Request, res: Response) => {
  const { action, data } = req.body;

  const commandId = `cmd_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  const command = { id: commandId, action, data, timestamp: Date.now() };

  commandQueue.push(command);
  console.log(`[${new Date().toISOString()}] Command queued for Studio:`, command);

  res.json({ success: true, commandId });
});

// Endpoint for Studio plugin to poll for commands
app.get('/api/commands', (req: Request, res: Response) => {
  res.json({ commands: commandQueue });
});

// Endpoint for Studio plugin to clear completed commands
app.post('/api/commands/clear', (req: Request, res: Response) => {
  const { commandIds } = req.body;
  const idsToRemove = commandIds || [];
  commandQueue.splice(0, commandQueue.length, ...commandQueue.filter(cmd => !idsToRemove.includes(cmd.id)));
  res.json({ success: true });
});

// Endpoint for Studio plugin to send results back to Codely
app.post('/api/result', (req: Request, res: Response) => {
  const { commandId, result, error } = req.body;

  commandResults.set(commandId, { result, error, timestamp: Date.now() });
  console.log(`[${new Date().toISOString()}] Result received for command ${commandId}`);

  res.json({ success: true });
});

// Endpoint for Codely CLI to get command results
app.get('/api/result/:commandId', (req: Request, res: Response) => {
  const { commandId } = req.params;
  const result = commandResults.get(commandId);

  if (result) {
    commandResults.delete(commandId);
    res.json(result);
  } else {
    res.status(404).json({ error: 'Result not found' });
  }
});

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    pendingStudioRequests: studioRequests.length,
    pendingCommands: commandQueue.length,
    pendingResults: commandResults.size
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Roblox-Codely Bridge server running on http://localhost:${PORT}`);
  console.log(`📋 Waiting for requests from Roblox Studio plugin...`);
});