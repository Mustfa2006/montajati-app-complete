const express = require('express');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

// Test route
app.get('/test', (req, res) => {
  res.json({ message: 'Server is working!' });
});

// Waseet status routes
const waseetStatusRoutes = require('./routes/waseet_statuses');
app.use('/api/waseet-statuses', waseetStatusRoutes);

const PORT = 3003;
app.listen(PORT, () => {
  console.log(`✅ Test server running on port ${PORT}`);
});
