import express from 'express';
import 'dotenv/config';
import routes from './routes/index';

const app = express();
const PORT = process.env.PORT || 3000;

// CORS middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Shopify webhooks need raw body for signature verification
app.use('/api/webhooks/shopify', express.raw({ type: 'application/json' }));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploads
app.use('/uploads', express.static('uploads'));

// API routes
app.use('/api', routes);

const portNumber = typeof PORT === 'string' ? parseInt(PORT, 10) : PORT;

app.listen(portNumber, '0.0.0.0', () => {
  console.log(`Server is running on:`);
  console.log(`  - Local:   http://localhost:${PORT}`);
  console.log(`  - Network: http://192.168.5.4:${PORT}`);
  console.log(`\nMobile app can connect using: http://192.168.5.4:${PORT}/api`);
});