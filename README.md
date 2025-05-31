# Tournament Dashboard

A simple web-based dashboard for managing tournament data during live streams. This application allows you to input team names and song scores, then outputs the data to a JSON file for use with streaming software or other applications.

## Features

- Input fields for two team names
- Score tracking for 3 songs per team
- Real-time data saving to `data.json`
- Load existing data from file
- Clear form functionality
- Simple, functional interface

## Requirements

- Node.js (version 14 or higher)
- npm (comes with Node.js)

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Start the server:
   ```bash
   npm start
   ```

3. Open your browser and go to:
   ```
   http://localhost:3000
   ```

## Usage

### Dashboard Interface

1. **Team Names**: Enter the names of both competing teams
2. **Song Scores**: Input scores for each of the 3 songs for both teams
3. **Save**: Click "Save to data.json" to write the current data to the JSON file
4. **Load**: Click "Load Current Data" to reload data from the existing JSON file
5. **Clear**: Click "Clear All" to reset all form fields

### Data Output

The application saves data to `data.json` in the project root directory with the following structure:

```json
{
  "team1": {
    "name": "Team Alpha",
    "song1": 95,
    "song2": 87,
    "song3": 92
  },
  "team2": {
    "name": "Team Beta",
    "song1": 89,
    "song2": 94,
    "song3": 88
  },
  "lastUpdated": "2024-01-15T10:30:00.000Z"
}
```

### Using with Streaming Software

The `data.json` file can be read by various streaming software applications:

- **OBS Studio**: Use a text source with file input
- **Streamlabs**: Use text widgets that read from files
- **XSplit**: Use text sources with file monitoring

## API Endpoints

If you need to integrate with other applications:

- `GET /api/data` - Retrieve current tournament data
- `POST /api/data` - Update tournament data

## File Structure

```
ranrush_streammanager/
├── package.json          # Node.js dependencies
├── server.js            # Express server
├── data.json           # Tournament data output (created automatically)
├── public/
│   └── index.html      # Dashboard interface
└── README.md           # This file
```

## Development

To run in development mode:
```bash
npm run dev
```

The server will restart automatically when you make changes to the code.

## Troubleshooting

### Port Already in Use
If port 3000 is already in use, you can modify the `PORT` variable in `server.js`:
```javascript
const PORT = 3001; // or any other available port
```

### Data File Issues
- The `data.json` file is created automatically when the server starts
- If the file becomes corrupted, simply delete it and restart the server
- Make sure the application has write permissions in the project directory

### Browser Cache
If you don't see updates in the interface, try:
- Hard refresh (Ctrl+F5 or Cmd+Shift+R)
- Clear browser cache
- Open in incognito/private browsing mode

## Deployment with Nginx

For production deployment with nginx as a reverse proxy, you have two options:

### Option 1: Automated Deployment Script

The easiest way to deploy is using the included deployment script:

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment
./deploy.sh deploy
```

The script will:
- Install Node.js dependencies
- Set up systemd service
- Configure nginx as reverse proxy
- Start all services
- Configure firewall (optional)

### Option 2: Manual Deployment

#### Prerequisites
- Node.js and npm installed
- Nginx installed
- PM2 installed globally: `npm install -g pm2`

#### Steps

1. **Install dependencies:**
   ```bash
   npm install --production
   ```

2. **Start the application with PM2:**
   ```bash
   pm2 start ecosystem.config.js
   pm2 save
   pm2 startup
   ```

3. **Configure nginx:**
   ```bash
   # Copy the nginx configuration
   sudo cp nginx.conf /etc/nginx/sites-available/tournament-dashboard
   
   # Edit the configuration file and update:
   # - Replace 'your-domain.com' with your actual domain
   # - Update the path to data.json file
   sudo nano /etc/nginx/sites-available/tournament-dashboard
   
   # Enable the site
   sudo ln -s /etc/nginx/sites-available/tournament-dashboard /etc/nginx/sites-enabled/
   
   # Test nginx configuration
   sudo nginx -t
   
   # Restart nginx
   sudo systemctl restart nginx
   ```

4. **Configure firewall (if using UFW):**
   ```bash
   sudo ufw allow 'Nginx Full'
   ```

#### Alternative: Using Systemd Service

Instead of PM2, you can use the included systemd service:

```bash
# Copy service file
sudo cp tournament-dashboard.service /etc/systemd/system/

# Edit the service file to update paths and user
sudo nano /etc/systemd/system/tournament-dashboard.service

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable tournament-dashboard
sudo systemctl start tournament-dashboard
```

### Managing the Deployment

```bash
# Using the deployment script
./deploy.sh status    # Check service status
./deploy.sh restart   # Restart services
./deploy.sh logs      # View logs
./deploy.sh update    # Update application

# Using systemd directly
sudo systemctl status tournament-dashboard
sudo systemctl restart tournament-dashboard
sudo journalctl -u tournament-dashboard -f

# Using PM2
pm2 status
pm2 restart tournament-dashboard
pm2 logs tournament-dashboard
```

### Accessing Your Dashboard

After deployment, your dashboard will be available at:
- `http://your-domain.com` (or your server IP)
- `https://your-domain.com` (if SSL is configured)

The `data.json` file will be accessible at:
- `http://your-domain.com/data.json` (for external streaming software)

## License

MIT License - feel free to modify and use for your tournament needs.