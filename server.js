const express = require('express');
const fs = require('fs');
const path = require('path');
const cors = require('cors');

const app = express();
const PORT = 3000;
const DATA_FILE = path.join(__dirname, 'data.json');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Initialize data file if it doesn't exist
const initializeDataFile = () => {
    const defaultData = {
        team1: {
            name: "",
            song1: 0,
            song2: 0,
            song3: 0
        },
        team2: {
            name: "",
            song1: 0,
            song2: 0,
            song3: 0
        },
        lastUpdated: new Date().toISOString()
    };

    if (!fs.existsSync(DATA_FILE)) {
        fs.writeFileSync(DATA_FILE, JSON.stringify(defaultData, null, 2));
        console.log('Initialized data.json with default values');
    }
};

// Routes
app.get('/api/data', (req, res) => {
    try {
        const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
        res.json(data);
    } catch (error) {
        console.error('Error reading data file:', error);
        res.status(500).json({ error: 'Failed to read data' });
    }
});

app.post('/api/data', (req, res) => {
    try {
        const { team1, team2 } = req.body;
        
        const data = {
            team1: {
                name: team1.name || "",
                song1: parseInt(team1.song1) || 0,
                song2: parseInt(team1.song2) || 0,
                song3: parseInt(team1.song3) || 0
            },
            team2: {
                name: team2.name || "",
                song1: parseInt(team2.song1) || 0,
                song2: parseInt(team2.song2) || 0,
                song3: parseInt(team2.song3) || 0
            },
            lastUpdated: new Date().toISOString()
        };

        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        console.log('Data updated successfully');
        res.json({ success: true, message: 'Data saved successfully' });
    } catch (error) {
        console.error('Error saving data:', error);
        res.status(500).json({ error: 'Failed to save data' });
    }
});

// Start server
initializeDataFile();
app.listen(PORT, () => {
    console.log(`Tournament dashboard server running on http://localhost:${PORT}`);
    console.log(`Data will be saved to: ${DATA_FILE}`);
});