import express, { Request, Response } from 'express';
import cors from 'cors';

const app = express();
const PORT = parseInt(process.env.PORT || '7269', 10);

app.use(cors());
app.use(express.json());

// Command queue from Codely → Studio
const commandQueue: Array<{
  id: string;
  action: string;
  data: any;
}> = [];

// Results from Studio → Codely
const commandResults = new Map<string, any>();

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
    pendingCommands: commandQueue.length,
    pendingResults: commandResults.size
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Roblox-Codely Bridge server running on http://localhost:${PORT}`);
  console.log(`📋 Waiting for Codely to send commands...`);
});