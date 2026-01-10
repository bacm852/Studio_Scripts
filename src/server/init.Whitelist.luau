-- [[ CONFIGURATION ]]
local SETTINGS = {
	-- List people here who get in for FREE
	WHITELISTED_IDS = {
		[2007759219] = "bellzakung12",
	},

	-- Add as many Game Pass IDs as you want here
	GAMEPASS_IDS = {
		1559658467,
		1559010518
	},

	-- The message they see when kicked
	KICK_MESSAGE = [[
🚫 ACCESS DENIED
Reason: You are not whitelisted and do not own a required Game Pass.

If you believe this is an error, please contact an admin.
]],
}

-- [[ SERVICES ]]
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- [[ LOGIC ]]
local function checkAccess(player)
	-- 1. Check if they are in the manual UserID list
	if SETTINGS.WHITELISTED_IDS[player.UserId] then
		print("✅ " .. player.Name .. " authorized via Manual Whitelist.")
		return true
	end

	-- 2. Check if they own ANY of the Game Passes in the list
	for _, passId in ipairs(SETTINGS.GAMEPASS_IDS) do
		local success, ownsPass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)

		if success and ownsPass then
			print("✅ " .. player.Name .. " authorized via Game Pass: " .. passId)
			return true
		end
	end

	-- 3. If no conditions are met, kick them
	player:Kick(SETTINGS.KICK_MESSAGE)
end

-- Run for players joining
Players.PlayerAdded:Connect(checkAccess)

-- Run for players already in server
for _, player in ipairs(Players:GetPlayers()) do
	checkAccess(player)
end