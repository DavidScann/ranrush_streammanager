# OBS Tournament Display Setup Guide

This guide will help you set up the OBS Lua script to display tournament data from your dashboard.

## Prerequisites

- OBS Studio (version 27.0 or newer recommended)
- Tournament dashboard running and accessible via HTTP
- Basic familiarity with OBS text sources

## Step 1: Create Text Sources in OBS

You'll need to create separate text sources for each piece of data. Here's the recommended setup:

### Text Sources to Create:

1. **Team 1 Name** - `team1_name`
2. **Team 2 Name** - `team2_name` 
3. **Team 1 Song 1 Score** - `team1_song1`
4. **Team 1 Song 2 Score** - `team1_song2`
5. **Team 1 Song 3 Score** - `team1_song3`
6. **Team 1 Total** - `team1_total`
7. **Team 2 Song 1 Score** - `team2_song1`
8. **Team 2 Song 2 Score** - `team2_song2`
9. **Team 2 Song 3 Score** - `team2_song3`
10. **Team 2 Total** - `team2_total`

### How to Create Text Sources:

1. Right-click in the Sources box
2. Select "Add" → "Text (GDI+)" or "Text (FreeType 2)"
3. Name the source (use the names above for easy reference)
4. Configure font, size, and color as desired
5. Position the text sources in your scene layout

### Recommended Layout:

```
Team Alpha          Team Beta
-----------         -----------
Song 1: 95          Song 1: 89
Song 2: 87          Song 2: 94  
Song 3: 92          Song 3: 88
-----------         -----------
Total: 274          Total: 271
```

## Step 2: Install the Lua Script

1. Open OBS Studio
2. Go to **Tools** → **Scripts**
3. Click the **+** button or **Add Scripts**
4. Navigate to and select `tournament_display.lua`
5. The script should now appear in the scripts list

## Step 3: Configure the Script

In the Scripts window, select the Tournament Display script and configure:

### Basic Settings:

- **JSON Data URL**: `http://saltcute.moe/ranrush/data.json`
- **Enable Auto-Update**: Check this for automatic updates
- **Update Interval**: Set to 5 seconds (or your preference)

### Text Source Mapping:

Map each field to your text source names:

- **Team 1 Name Source**: `team1_name`
- **Team 1 Song 1 Source**: `team1_song1`
- **Team 1 Song 2 Source**: `team1_song2`
- **Team 1 Song 3 Source**: `team1_song3`
- **Team 1 Total Source**: `team1_total`
- **Team 2 Name Source**: `team2_name`
- **Team 2 Song 1 Source**: `team2_song1`
- **Team 2 Song 2 Source**: `team2_song2`
- **Team 2 Song 3 Source**: `team2_song3`
- **Team 2 Total Source**: `team2_total`

## Step 4: Test the Connection

1. Click **Test Connection** to verify the script can reach your JSON endpoint
2. Check the Script Log tab for any error messages
3. Click **Update Now** to manually fetch data
4. Verify that your text sources update with the current tournament data

## Step 5: Enable Auto-Update

1. Check **Enable Auto-Update** 
2. Set your preferred **Update Interval** (5 seconds recommended)
3. The script will now automatically fetch and update data

## Features

### Automatic Color Coding
- **Green**: Winning team
- **Red**: Losing team  
- **White**: Tied or no data

### Manual Controls
- **Update Now**: Immediate data fetch
- **Test Connection**: Verify URL accessibility
- **Clear Display**: Reset all text sources to default

### Logging
Check the Script Log tab for:
- Connection status
- Data fetch confirmations
- Error messages
- Update notifications

## Troubleshooting

### Common Issues:

**Text sources not updating:**
- Verify text source names match exactly (case-sensitive)
- Check that sources exist in the current scene
- Ensure URL is accessible from your computer

**Connection errors:**
- Verify the JSON URL is correct and accessible
- Check firewall/network settings
- Ensure the tournament dashboard is running

**Script not loading:**
- Verify OBS version compatibility
- Check Script Log for error messages
- Ensure the .lua file is not corrupted

**Color coding not working:**
- Some text source types don't support color changes
- Try using "Text (GDI+)" instead of "Text (FreeType 2)"
- Manually set colors if automatic coloring fails

### Log Messages:

- `"Fetching tournament data"` - Normal operation
- `"Updated display"` - Successful data update
- `"HTTP request failed"` - Connection issue
- `"Failed to parse JSON"` - Data format error
- `"No URL configured"` - Missing URL setting

## Advanced Usage

### Custom Layout Ideas:

1. **Scoreboard Style**: Traditional side-by-side layout
2. **Overlay Style**: Semi-transparent overlay on gameplay
3. **Lower Third**: Horizontal strip at bottom of screen
4. **Corner Display**: Compact corner information

### Integration with Stream Deck:

You can trigger manual updates via Stream Deck using OBS hotkeys:
1. Set up a hotkey for the script (if supported)
2. Use Stream Deck to trigger the hotkey
3. Instant tournament data updates

### Multiple Scenes:

The script works across all scenes - text sources will update regardless of which scene is active.

## Data Format

The script expects JSON in this format:

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

Your tournament dashboard already outputs this exact format, so no changes are needed.

## Performance Notes

- The script uses minimal CPU resources
- HTTP requests are asynchronous and won't block OBS
- 5-second update interval is optimal for live tournaments
- Shorter intervals (1-2 seconds) work but may increase network usage

Your tournament display is now ready for live streaming!