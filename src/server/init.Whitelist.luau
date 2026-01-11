-- [[ ROBLOX WHITELIST SYSTEM ]]
-- Version 2.0 - Enhanced with better error handling and features

-- [[ CONFIGURATION ]]
local SETTINGS = {
	-- List people here who get in for FREE (UserId = "Username" for reference)
	WHITELISTED_IDS = {
		[2007759219] = "bellzakung12",
		-- Add more users like this:
		-- [123456789] = "PlayerName",
	},

	-- Add as many Game Pass IDs as you want here
	GAMEPASS_IDS = {
		1559658467,
		1559010518,
		-- Add more Game Pass IDs here
	},

	-- The message they see when kicked
	KICK_MESSAGE = [[
🚫 ACCESS DENIED
Reason: You are not whitelisted and do not own a required Game Pass.

If you believe this is an error, please contact an admin.
]],

	-- Enable/disable debug logging
	DEBUG_MODE = true,

	-- Retry attempts for Game Pass check (in case of API failures)
	RETRY_ATTEMPTS = 3,
	RETRY_DELAY = 1, -- seconds between retries
}

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

-- [[ UTILITY FUNCTIONS ]]
local function debugLog(message)
	if SETTINGS.DEBUG_MODE then
		print("[WHITELIST DEBUG] " .. message)
	end
end

local function checkGamePassWithRetry(userId, passId, attempts)
	attempts = attempts or SETTINGS.RETRY_ATTEMPTS
	
	for attempt = 1, attempts do
		local success, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(userId, passId)
		end)
		
		if success then
			return true, result
		else
			debugLog("Game Pass check failed (attempt " .. attempt .. "/" .. attempts .. "): " .. tostring(result))
			if attempt < attempts then
				task.wait(SETTINGS.RETRY_DELAY)
			end
		end
	end
	
	return false, nil -- All attempts failed
end

-- [[ MAIN LOGIC ]]
local function checkAccess(player)
	debugLog("Checking access for: " .. player.Name .. " (UserId: " .. player.UserId .. ")")
	
	-- Wait a moment to ensure player is fully loaded
	task.wait(0.1)
	
	-- Verify player is still in game
	if not player.Parent then
		debugLog("Player left before access check completed: " .. player.Name)
		return
	end
	
	-- 1. Check if they are in the manual UserID list
	if SETTINGS.WHITELISTED_IDS[player.UserId] then
		print("✅ " .. player.Name .. " authorized via Manual Whitelist.")
		return true
	end
	
	-- 2. Check if they own ANY of the Game Passes in the list
	for _, passId in ipairs(SETTINGS.GAMEPASS_IDS) do
		local success, ownsPass = checkGamePassWithRetry(player.UserId, passId)
		
		if success and ownsPass then
			print("✅ " .. player.Name .. " authorized via Game Pass: " .. passId)
			return true
		elseif not success then
			-- API error - be lenient and let them in with a warning
			warn("⚠️ Could not verify Game Pass for " .. player.Name .. ". Allowing access due to API error.")
			return true
		end
	end
	
	-- 3. If no conditions are met, kick them
	print("❌ " .. player.Name .. " denied access - no valid credentials found.")
	
	-- Ensure player is still in game before kicking
	if player.Parent then
		player:Kick(SETTINGS.KICK_MESSAGE)
	end
	
	return false
end

-- [[ EVENT CONNECTIONS ]]
-- Run for new players joining
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		checkAccess(player)
	end)
end)

-- Run for players already in server (when script is added to live game)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		checkAccess(player)
	end)
end

-- [[ ADMIN COMMANDS (Optional) ]]
-- You can add this to allow in-game whitelist management
local function setupAdminCommands()
	-- Add your admin user IDs here
	local ADMINS = {
		[2007759219] = true, -- bellzakung12
	}
	
	Players.PlayerAdded:Connect(function(player)
		player.Chatted:Connect(function(message)
			if not ADMINS[player.UserId] then return end
			
			local args = string.split(message, " ")
			local command = args[1]:lower()
			
			-- !whitelist [username] - Add player to whitelist
			if command == "!whitelist" and args[2] then
				local targetPlayer = Players:FindFirstChild(args[2])
				if targetPlayer then
					SETTINGS.WHITELISTED_IDS[targetPlayer.UserId] = targetPlayer.Name
					print("✅ Added " .. targetPlayer.Name .. " to whitelist.")
				end
			end
			
			-- !unwhitelist [username] - Remove from whitelist
			if command == "!unwhitelist" and args[2] then
				local targetPlayer = Players:FindFirstChild(args[2])
				if targetPlayer then
					SETTINGS.WHITELISTED_IDS[targetPlayer.UserId] = nil
					print("❌ Removed " .. targetPlayer.Name .. " from whitelist.")
				end
			end
		end)
	end)
end

-- Uncomment to enable admin commands
-- setupAdminCommands()

print("Whitelist System loaded successfully!")
print("Whitelisted Users: " .. #SETTINGS.WHITELISTED_IDS)
print("Required Game Passes: " .. #SETTINGS.GAMEPASS_IDS)