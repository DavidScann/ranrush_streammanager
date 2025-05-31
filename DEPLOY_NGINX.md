# Deployment Guide for nginx.conf Management

If you manage all your server configurations through a main `nginx.conf` file, here's how to deploy the tournament dashboard:

## 1. Process Management Setup

Choose one of these options to keep your Node.js app running:

### Option A: Using PM2 (Recommended)
```bash
# Install PM2 globally
npm install -g pm2

# Install app dependencies
npm install --production

# Start the application
pm2 start ecosystem.config.js

# Save PM2 process list and enable startup
pm2 save
pm2 startup
```

### Option B: Using Systemd Service
```bash
# Copy the service file
sudo cp tournament-dashboard.service /etc/systemd/system/

# Edit the service file to update paths
sudo nano /etc/systemd/system/tournament-dashboard.service
# Update these lines:
# - WorkingDirectory=/your/actual/path/to/ranrush_streammanager
# - User=your-username
# - ReadWritePaths=/your/actual/path/to/ranrush_streammanager

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable tournament-dashboard
sudo systemctl start tournament-dashboard
```

## 2. Nginx Configuration

Add this server block to your main `nginx.conf` file inside the `http` block:

```nginx
server {
    listen 80;
    server_name your-domain.com;  # Replace with your domain or IP
    
    # Basic security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
    
    # Main application - proxy to Node.js
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 60;
        proxy_connect_timeout 60;
        proxy_send_timeout 60;
    }
    
    # Direct access to data.json (for streaming software)
    location /data.json {
        alias /full/path/to/your/ranrush_streammanager/data.json;  # UPDATE THIS PATH
        add_header Access-Control-Allow-Origin *;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Pragma "no-cache";
        add_header Expires "0";
    }
    
    # API endpoint for external access
    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Access-Control-Allow-Origin *;
    }
}
```

## 3. Important Configuration Updates

Before deploying, update these values:

1. **Domain/IP**: Replace `your-domain.com` with your actual domain or server IP
2. **Data file path**: Replace `/full/path/to/your/ranrush_streammanager/data.json` with the actual full path
3. **Service user**: If using systemd, update the `User=` line in the service file

## 4. Deployment Steps

```bash
# 1. Install dependencies
npm install --production

# 2. Start the Node.js application (choose PM2 or systemd from above)

# 3. Add the server block to your nginx.conf
sudo nano /etc/nginx/nginx.conf

# 4. Test nginx configuration
sudo nginx -t

# 5. Reload nginx
sudo systemctl reload nginx
```

## 5. Verification

After deployment, verify everything works:

```bash
# Check if Node.js app is running
curl http://localhost:3000

# Check if nginx is serving the app
curl http://your-domain.com

# Check if data.json is accessible
curl http://your-domain.com/data.json
```

## 6. Management Commands

### For PM2:
```bash
pm2 status                    # Check status
pm2 restart tournament-dashboard  # Restart app
pm2 logs tournament-dashboard     # View logs
pm2 stop tournament-dashboard     # Stop app
```

### For Systemd:
```bash
sudo systemctl status tournament-dashboard    # Check status
sudo systemctl restart tournament-dashboard   # Restart app
sudo journalctl -u tournament-dashboard -f    # View logs
sudo systemctl stop tournament-dashboard      # Stop app
```

### For Nginx:
```bash
sudo nginx -t                 # Test configuration
sudo systemctl reload nginx   # Reload configuration
sudo systemctl restart nginx  # Restart nginx
```

## 7. Accessing Your Dashboard

- **Main Dashboard**: `http://your-domain.com`
- **Data File**: `http://your-domain.com/data.json`
- **API Endpoint**: `http://your-domain.com/api/data`

## 8. File Permissions

Make sure your web server user can read the data.json file:

```bash
# Set appropriate permissions
chmod 644 data.json
chown your-user:your-group data.json

# If using www-data user, you might need:
sudo chown your-user:www-data data.json
chmod 664 data.json
```

## 9. Firewall Configuration

If using UFW, allow HTTP traffic:

```bash
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'  # If using SSL
```

## Troubleshooting

- **502 Bad Gateway**: Node.js app is not running on port 3000
- **404 for /data.json**: Check the file path in nginx configuration
- **Permission denied**: Check file permissions and nginx user
- **Connection refused**: Check firewall settings and port availability

Your tournament dashboard should now be accessible and ready for use!