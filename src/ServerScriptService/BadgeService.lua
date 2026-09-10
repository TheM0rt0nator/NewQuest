local Players = game:GetService("Players")
local RobloxBadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")

local BadgeService = {}

-- Called only by server code after validating the reward's completion condition.
function BadgeService.Award(player, badgeId)
	if RunService:IsStudio() then
		return true, "StudioSkipped"
	end

	local lastError

	for attempt = 1, 3 do
		if player.Parent ~= Players then
			return false, "PlayerLeft"
		end

		local ok, awarded = pcall(function()
			if RobloxBadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
				return true
			end

			if player.Parent ~= Players then
				return false
			end

			return RobloxBadgeService:AwardBadgeAsync(player.UserId, badgeId)
		end)

		if ok and awarded then
			return true, "Awarded"
		end

		lastError = ok and "Roblox did not award the badge" or tostring(awarded)

		if attempt < 3 then
			task.wait(attempt)
		end
	end

	warn(string.format("[BadgeService] Badge %d for %d: %s", badgeId, player.UserId, lastError))

	return false, "Failed"
end

return BadgeService
