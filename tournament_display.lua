obs = obslua

-- Script settings
local url = ""
local update_interval = 5
local auto_update_enabled = false
local timer_active = false

-- Text source names
local team1_name_source = ""
local team2_name_source = ""
local team1_song1_source = ""
local team1_song2_source = ""
local team1_song3_source = ""
local team1_total_source = ""
local team2_song1_source = ""
local team2_song2_source = ""
local team2_song3_source = ""
local team2_total_source = ""

-- Colors for highlighting
local normal_color = 0xFFFFFF  -- White
local winning_color = 0x00FF00  -- Green
local losing_color = 0xFF6B6B  -- Light red

-- Current data
local current_data = {}

-- Simple JSON parser
function parse_json(json_str)
    if not json_str or json_str == "" then
        return nil
    end
    
    -- Remove whitespace
    json_str = json_str:gsub("%s+", "")
    
    local data = {}
    
    -- Extract team1 data
    local team1_match = json_str:match('"team1":%s*{([^}]*)%}')
    if team1_match then
        data.team1 = {}
        data.team1.name = team1_match:match('"name":%s*"([^"]*)"') or ""
        data.team1.song1 = tonumber(team1_match:match('"song1":%s*(%d+)')) or 0
        data.team1.song2 = tonumber(team1_match:match('"song2":%s*(%d+)')) or 0
        data.team1.song3 = tonumber(team1_match:match('"song3":%s*(%d+)')) or 0
    end
    
    -- Extract team2 data
    local team2_match = json_str:match('"team2":%s*{([^}]*)%}')
    if team2_match then
        data.team2 = {}
        data.team2.name = team2_match:match('"name":%s*"([^"]*)"') or ""
        data.team2.song1 = tonumber(team2_match:match('"song1":%s*(%d+)')) or 0
        data.team2.song2 = tonumber(team2_match:match('"song2":%s*(%d+)')) or 0
        data.team2.song3 = tonumber(team2_match:match('"song3":%s*(%d+)')) or 0
    end
    
    return data
end

-- Calculate totals
function calculate_totals(data)
    if data.team1 then
        data.team1.total = (data.team1.song1 or 0) + (data.team1.song2 or 0) + (data.team1.song3 or 0)
    end
    if data.team2 then
        data.team2.total = (data.team2.song1 or 0) + (data.team2.song2 or 0) + (data.team2.song3 or 0)
    end
    return data
end

-- Determine winning team
function get_winner(data)
    if not data.team1 or not data.team2 then
        return "none"
    end
    
    local total1 = data.team1.total or 0
    local total2 = data.team2.total or 0
    
    if total1 > total2 then
        return "team1"
    elseif total2 > total1 then
        return "team2"
    else
        return "tie"
    end
end

-- Update text source with color
function update_text_source(source_name, text, color)
    if source_name == "" then
        return
    end
    
    local source = obs.obs_get_source_by_name(source_name)
    if source then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", tostring(text))
        obs.obs_data_set_int(settings, "color", color or normal_color)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
end

-- Update all text sources
function update_display(data)
    if not data or not data.team1 or not data.team2 then
        obs.script_log(obs.LOG_WARNING, "Invalid data received")
        return
    end
    
    -- Calculate totals and determine winner
    data = calculate_totals(data)
    local winner = get_winner(data)
    
    -- Determine colors based on winner
    local team1_color = normal_color
    local team2_color = normal_color
    
    if winner == "team1" then
        team1_color = winning_color
        team2_color = losing_color
    elseif winner == "team2" then
        team1_color = losing_color
        team2_color = winning_color
    end
    
    -- Update team names
    update_text_source(team1_name_source, data.team1.name, team1_color)
    update_text_source(team2_name_source, data.team2.name, team2_color)
    
    -- Update song scores
    update_text_source(team1_song1_source, data.team1.song1, team1_color)
    update_text_source(team1_song2_source, data.team1.song2, team1_color)
    update_text_source(team1_song3_source, data.team1.song3, team1_color)
    
    update_text_source(team2_song1_source, data.team2.song1, team2_color)
    update_text_source(team2_song2_source, data.team2.song2, team2_color)
    update_text_source(team2_song3_source, data.team2.song3, team2_color)
    
    -- Update totals
    update_text_source(team1_total_source, data.team1.total, team1_color)
    update_text_source(team2_total_source, data.team2.total, team2_color)
    
    obs.script_log(obs.LOG_INFO, string.format("Updated display - %s: %d, %s: %d", 
        data.team1.name, data.team1.total, data.team2.name, data.team2.total))
end

-- HTTP request callback
function on_http_response(response_data)
    if response_data.status_code == 200 then
        local data = parse_json(response_data.body)
        if data then
            current_data = data
            update_display(data)
        else
            obs.script_log(obs.LOG_ERROR, "Failed to parse JSON data")
        end
    else
        obs.script_log(obs.LOG_ERROR, string.format("HTTP request failed with status %d", response_data.status_code))
    end
end

-- Fetch data from URL
function fetch_tournament_data()
    if url == "" then
        obs.script_log(obs.LOG_WARNING, "No URL configured")
        return
    end
    
    obs.script_log(obs.LOG_INFO, "Fetching tournament data from: " .. url)
    
    local headers = {}
    headers["User-Agent"] = "OBS-Tournament-Display/1.0"
    headers["Accept"] = "application/json"
    
    obs.obs_http_request({
        url = url,
        method = "GET",
        headers = headers,
        timeout = 10,
        callback = on_http_response
    })
end

-- Timer callback
function timer_callback()
    fetch_tournament_data()
end

-- Start/stop auto-update timer
function toggle_auto_update()
    if timer_active then
        obs.timer_remove(timer_callback)
        timer_active = false
        obs.script_log(obs.LOG_INFO, "Auto-update stopped")
    end
    
    if auto_update_enabled and update_interval > 0 then
        obs.timer_add(timer_callback, update_interval * 1000)
        timer_active = true
        obs.script_log(obs.LOG_INFO, string.format("Auto-update started (every %d seconds)", update_interval))
    end
end

-- Manual update button callback
function manual_update_clicked(props, prop)
    fetch_tournament_data()
    return false
end

-- Test connection button callback
function test_connection_clicked(props, prop)
    if url == "" then
        obs.script_log(obs.LOG_WARNING, "Please configure URL first")
        return false
    end
    
    obs.script_log(obs.LOG_INFO, "Testing connection to: " .. url)
    fetch_tournament_data()
    return false
end

-- Clear display button callback
function clear_display_clicked(props, prop)
    update_text_source(team1_name_source, "", normal_color)
    update_text_source(team2_name_source, "", normal_color)
    update_text_source(team1_song1_source, "0", normal_color)
    update_text_source(team1_song2_source, "0", normal_color)
    update_text_source(team1_song3_source, "0", normal_color)
    update_text_source(team1_total_source, "0", normal_color)
    update_text_source(team2_song1_source, "0", normal_color)
    update_text_source(team2_song2_source, "0", normal_color)
    update_text_source(team2_song3_source, "0", normal_color)
    update_text_source(team2_total_source, "0", normal_color)
    
    obs.script_log(obs.LOG_INFO, "Display cleared")
    return false
end

-- Script description
function script_description()
    return [[
<h2>Tournament Display for OBS</h2>
<p>This script fetches tournament data from a JSON endpoint and updates text sources in OBS.</p>
<p><strong>Setup:</strong></p>
<ol>
<li>Create text sources for each data field you want to display</li>
<li>Configure the JSON URL (e.g., http://saltcute.moe/ranrush/data.json)</li>
<li>Set the text source names in the properties</li>
<li>Enable auto-update or use manual update</li>
</ol>
<p><strong>Features:</strong></p>
<ul>
<li>Automatic color coding (green for winner, red for loser)</li>
<li>Separate text sources for flexible layout</li>
<li>Auto-update with configurable interval</li>
<li>Manual update button</li>
</ul>
<p>Version 1.0 - Tournament Dashboard Integration</p>
]]
end

-- Script properties
function script_properties()
    local props = obs.obs_properties_create()
    
    -- URL configuration
    obs.obs_properties_add_text(props, "url", "JSON Data URL", obs.OBS_TEXT_DEFAULT)
    
    -- Auto-update settings
    obs.obs_properties_add_bool(props, "auto_update", "Enable Auto-Update")
    obs.obs_properties_add_int_slider(props, "update_interval", "Update Interval (seconds)", 1, 60, 1)
    
    -- Team 1 sources
    obs.obs_properties_add_text(props, "team1_name_source", "Team 1 Name Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team1_song1_source", "Team 1 Song 1 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team1_song2_source", "Team 1 Song 2 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team1_song3_source", "Team 1 Song 3 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team1_total_source", "Team 1 Total Source", obs.OBS_TEXT_DEFAULT)
    
    -- Team 2 sources
    obs.obs_properties_add_text(props, "team2_name_source", "Team 2 Name Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team2_song1_source", "Team 2 Song 1 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team2_song2_source", "Team 2 Song 2 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team2_song3_source", "Team 2 Song 3 Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "team2_total_source", "Team 2 Total Source", obs.OBS_TEXT_DEFAULT)
    
    -- Action buttons
    obs.obs_properties_add_button(props, "manual_update", "Update Now", manual_update_clicked)
    obs.obs_properties_add_button(props, "test_connection", "Test Connection", test_connection_clicked)
    obs.obs_properties_add_button(props, "clear_display", "Clear Display", clear_display_clicked)
    
    return props
end

-- Script defaults
function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "url", "http://saltcute.moe/ranrush/data.json")
    obs.obs_data_set_default_bool(settings, "auto_update", false)
    obs.obs_data_set_default_int(settings, "update_interval", 5)
end

-- Script update
function script_update(settings)
    url = obs.obs_data_get_string(settings, "url")
    auto_update_enabled = obs.obs_data_get_bool(settings, "auto_update")
    update_interval = obs.obs_data_get_int(settings, "update_interval")
    
    -- Update source names
    team1_name_source = obs.obs_data_get_string(settings, "team1_name_source")
    team2_name_source = obs.obs_data_get_string(settings, "team2_name_source")
    team1_song1_source = obs.obs_data_get_string(settings, "team1_song1_source")
    team1_song2_source = obs.obs_data_get_string(settings, "team1_song2_source")
    team1_song3_source = obs.obs_data_get_string(settings, "team1_song3_source")
    team1_total_source = obs.obs_data_get_string(settings, "team1_total_source")
    team2_song1_source = obs.obs_data_get_string(settings, "team2_song1_source")
    team2_song2_source = obs.obs_data_get_string(settings, "team2_song2_source")
    team2_song3_source = obs.obs_data_get_string(settings, "team2_song3_source")
    team2_total_source = obs.obs_data_get_string(settings, "team2_total_source")
    
    -- Restart timer with new settings
    toggle_auto_update()
end

-- Script unload
function script_unload()
    if timer_active then
        obs.timer_remove(timer_callback)
        timer_active = false
    end
end