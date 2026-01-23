-- UltraGambler Addon for Turtle WoW (1.12 compatible)

-- Variables
local AcceptOnes = "false"
local AcceptRolls = "false"
local totalrolls = 0
local tierolls = 0
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0
local lowbreak = 0
local tiehigh = 0
local tielow = 0
local whispermethod = false

local chatmethods = { "RAID", "GUILD", "PARTY", "SAY" }
local chatmethod = chatmethods[1]

UG_Settings = { MinimapPos = 75 }

-- Helper function to send chat messages
local function ChatMsg(msg, chatType, language, channel)
	chatType = chatType or chatmethod
	if chatType == "RAID" and not UnitInRaid("player") then
		chatType = UnitInParty("player") and "PARTY" or "SAY"
	elseif chatType == "PARTY" and not UnitInParty("player") then
		chatType = "SAY"
	elseif chatType == "GUILD" and not IsInGuild() then
		chatType = "SAY"
	end
	if chatType == "CHANNEL" and channel then
		SendChatMessage(msg, chatType, language, channel)
	else
		SendChatMessage(msg, chatType, language)
	end
end

local function Print(pre, red, text)
	if red == "" then red = "/UG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre .. "|cff00ff00" .. red .. "|r: " .. text)
end

local function UpdateLayout()
	if not UltraGambling_Frame then return end
	local width = UltraGambling_Frame:GetWidth()
	local editWidth = math.max(60, width - 80)
	UltraGambling_EditBox:SetWidth(editWidth)
	local btnWidth = math.max(80, width - 60)
	UltraGambling_AcceptOnes_Button:SetWidth(btnWidth)
	UltraGambling_LASTCALL_Button:SetWidth(btnWidth)
	UltraGambling_ROLL_Button:SetWidth(btnWidth)
	local bottomBtnWidth = math.max(60, (width - 50) / 2)
	UltraGambling_CHAT_Button:SetWidth(bottomBtnWidth)
	UltraGambling_WHISPER_Button:SetWidth(bottomBtnWidth)
end

local function CreateMainFrame()
	local f = CreateFrame("Frame", "UltraGambling_Frame", UIParent)
	f:SetWidth(250)
	f:SetHeight(220)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetMovable(true)
	f:SetResizable(true)
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG")
	f:SetMinResize(200, 180)
	f:SetMaxResize(400, 350)

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(0, 0, 0, 0.85)
	bg:SetAllPoints(f)

	local borderTop = f:CreateTexture(nil, "BORDER")
	borderTop:SetTexture(0.6, 0.6, 0.6, 1)
	borderTop:SetHeight(2)
	borderTop:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	borderTop:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)

	local borderBottom = f:CreateTexture(nil, "BORDER")
	borderBottom:SetTexture(0.6, 0.6, 0.6, 1)
	borderBottom:SetHeight(2)
	borderBottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
	borderBottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	local borderLeft = f:CreateTexture(nil, "BORDER")
	borderLeft:SetTexture(0.6, 0.6, 0.6, 1)
	borderLeft:SetWidth(2)
	borderLeft:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
	borderLeft:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)

	local borderRight = f:CreateTexture(nil, "BORDER")
	borderRight:SetTexture(0.6, 0.6, 0.6, 1)
	borderRight:SetWidth(2)
	borderRight:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	borderRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	local titleBg = f:CreateTexture(nil, "ARTWORK")
	titleBg:SetTexture(0.2, 0.2, 0.4, 1)
	titleBg:SetHeight(24)
	titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
	titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", f, "TOP", 0, -8)
	title:SetText("|cffFFD700UltraGamble|r")

	f:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" then this:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

	local editbox = CreateFrame("EditBox", "UltraGambling_EditBox", f)
	editbox:SetWidth(100)
	editbox:SetHeight(28)
	editbox:SetPoint("TOP", f, "TOP", 0, -35)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetAutoFocus(false)
	editbox:SetNumeric(true)
	editbox:SetMaxLetters(6)
	editbox:SetJustifyH("CENTER")
	editbox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
	editbox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

	local editBg = editbox:CreateTexture(nil, "BACKGROUND")
	editBg:SetTexture(0.1, 0.1, 0.1, 0.8)
	editBg:SetAllPoints(editbox)

	local acceptBtn = CreateFrame("Button", "UltraGambling_AcceptOnes_Button", f, "GameMenuButtonTemplate")
	acceptBtn:SetWidth(150)
	acceptBtn:SetHeight(22)
	acceptBtn:SetPoint("TOP", editbox, "BOTTOM", 0, -10)
	acceptBtn:SetText("Open Entry")
	acceptBtn:SetScript("OnClick", function() UltraGambling_OnClickACCEPTONES() end)

	local lastcallBtn = CreateFrame("Button", "UltraGambling_LASTCALL_Button", f, "GameMenuButtonTemplate")
	lastcallBtn:SetWidth(150)
	lastcallBtn:SetHeight(22)
	lastcallBtn:SetPoint("TOP", acceptBtn, "BOTTOM", 0, -5)
	lastcallBtn:SetText("Last Call")
	lastcallBtn:SetScript("OnClick", function() UltraGambling_OnClickLASTCALL() end)

	local rollBtn = CreateFrame("Button", "UltraGambling_ROLL_Button", f, "GameMenuButtonTemplate")
	rollBtn:SetWidth(150)
	rollBtn:SetHeight(22)
	rollBtn:SetPoint("TOP", lastcallBtn, "BOTTOM", 0, -5)
	rollBtn:SetText("Roll")
	rollBtn:SetScript("OnClick", function() UltraGambling_OnClickROLL() end)

	local chatBtn = CreateFrame("Button", "UltraGambling_CHAT_Button", f, "GameMenuButtonTemplate")
	chatBtn:SetWidth(80)
	chatBtn:SetHeight(20)
	chatBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 35)
	chatBtn:SetText("RAID")
	chatBtn:SetScript("OnClick", function() UltraGambling_OnClickCHAT() end)

	local whisperBtn = CreateFrame("Button", "UltraGambling_WHISPER_Button", f, "GameMenuButtonTemplate")
	whisperBtn:SetWidth(100)
	whisperBtn:SetHeight(20)
	whisperBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 35)
	whisperBtn:SetText("(No Whispers)")
	whisperBtn:SetScript("OnClick", function() UltraGambling_OnClickWHISPERS() end)

	local closeBtn = CreateFrame("Button", "UltraGambling_CloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	closeBtn:SetScript("OnClick", function() UltraGambling_SlashCmd("hide") end)

	local resizeBtn = CreateFrame("Button", "UltraGambling_ResizeButton", f)
	resizeBtn:SetWidth(16)
	resizeBtn:SetHeight(16)
	resizeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
	resizeBtn:EnableMouse(true)
	local resizeTexture = resizeBtn:CreateTexture(nil, "OVERLAY")
	resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeTexture:SetAllPoints(resizeBtn)
	resizeBtn:SetScript("OnMouseDown", function() UltraGambling_Frame:StartSizing("BOTTOMRIGHT") end)
	resizeBtn:SetScript("OnMouseUp", function() UltraGambling_Frame:StopMovingOrSizing(); UpdateLayout() end)
	f:SetScript("OnSizeChanged", function() UpdateLayout() end)

	return f
end

local function CreateMinimapButton()
	local btn = CreateFrame("Button", "UG_MinimapButton", Minimap)
	btn:SetWidth(32)
	btn:SetHeight(32)
	btn:SetFrameStrata("MEDIUM")
	btn:SetFrameLevel(8)
	btn:EnableMouse(true)
	btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	btn:RegisterForDrag("LeftButton")
	btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	local icon = btn:CreateTexture(nil, "BACKGROUND")
	icon:SetWidth(20)
	icon:SetHeight(20)
	icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
	icon:SetPoint("CENTER", btn, "CENTER", 0, 0)

	local border = btn:CreateTexture(nil, "OVERLAY")
	border:SetWidth(52)
	border:SetHeight(52)
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

	btn:SetScript("OnClick", function() UG_MinimapButton_OnClick() end)
	btn:SetScript("OnDragStart", function()
		this:LockHighlight()
		this:SetScript("OnUpdate", UG_MinimapButton_DraggingFrame_OnUpdate)
	end)
	btn:SetScript("OnDragStop", function()
		this:SetScript("OnUpdate", nil)
		this:UnlockHighlight()
	end)
	btn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:SetText("|cffFFD700UltraGamble|r")
		GameTooltip:AddLine("Click to toggle window", 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	UG_MinimapButton_Reposition()
	return btn
end

function UG_MinimapButton_Reposition()
	if not UG_MinimapButton then return end
	if not UG_Settings then UG_Settings = { MinimapPos = 75 } end
	local angle = math.rad(UG_Settings.MinimapPos)
	local x = 52 - (80 * math.cos(angle))
	local y = (80 * math.sin(angle)) - 52
	UG_MinimapButton:ClearAllPoints()
	UG_MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", x, y)
end

function UG_MinimapButton_DraggingFrame_OnUpdate()
	if not UG_Settings then UG_Settings = { MinimapPos = 75 } end
	local xpos, ypos = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	xpos, ypos = xpos / scale, ypos / scale
	local cx, cy = Minimap:GetCenter()
	UG_Settings.MinimapPos = math.deg(math.atan2(ypos - cy, xpos - cx))
	UG_MinimapButton_Reposition()
end

function UG_MinimapButton_OnClick()
	if UltraGambling and UltraGambling["active"] == 1 then
		UltraGambling_Frame:Hide()
		UltraGambling["active"] = 0
	else
		UltraGambling_Frame:Show()
		if UltraGambling then UltraGambling["active"] = 1 end
	end
end

function UltraGambling_SlashCmd(msg)
	msg = string.lower(msg or "")
	if msg == "" then
		Print("", "", "Commands: show, hide, reset, fullstats, resetstats, minimap, ban, unban, listban")
		return
	end
	if msg == "hide" then
		UltraGambling_Frame:Hide()
		UltraGambling["active"] = 0
	elseif msg == "show" then
		UltraGambling_Frame:Show()
		UltraGambling["active"] = 1
	elseif msg == "reset" then
		UltraGambling_Reset()
		Print("", "", "UltraGamble has been reset.")
	elseif msg == "fullstats" then
		UltraGambling_OnClickSTATS(true)
	elseif msg == "resetstats" then
		UltraGambling["stats"] = {}
		Print("", "", "Stats have been reset.")
	elseif msg == "minimap" then
		UltraGambling["minimap"] = not UltraGambling["minimap"]
		if UltraGambling["minimap"] then UG_MinimapButton:Show() else UG_MinimapButton:Hide() end
	elseif string.sub(msg, 1, 4) == "ban " then
		local name = string.sub(msg, 5)
		if not UltraGambling.bans then UltraGambling.bans = {} end
		table.insert(UltraGambling.bans, name)
		Print("", "", name .. " banned.")
	elseif string.sub(msg, 1, 6) == "unban " then
		local name = string.sub(msg, 7)
		if UltraGambling.bans then
			for i, v in ipairs(UltraGambling.bans) do
				if string.lower(v) == string.lower(name) then
					table.remove(UltraGambling.bans, i)
					Print("", "", name .. " unbanned.")
					return
				end
			end
		end
	elseif msg == "listban" then
		if not UltraGambling.bans or table.getn(UltraGambling.bans) == 0 then
			Print("", "", "No bans.")
		else
			for i, v in ipairs(UltraGambling.bans) do
				DEFAULT_CHAT_FRAME:AddMessage("  " .. v)
			end
		end
	else
		Print("", "", "Unknown command: " .. msg)
	end
end

SLASH_ULTRAGAMBLING1 = "/ultragambler"
SLASH_ULTRAGAMBLING2 = "/ug"
SlashCmdList["ULTRAGAMBLING"] = UltraGambling_SlashCmd

function UltraGambling_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		if not UltraGambling_Frame then CreateMainFrame() end
		if not UG_MinimapButton then CreateMinimapButton() end

		if not UltraGambling then
			UltraGambling = {
				active = 1, chat = 1, channel = "gambling", whispers = false,
				strings = {}, lowtie = {}, hightie = {}, bans = {},
				minimap = true, lastroll = 100, stats = {}, joinstats = {}
			}
		end

		UltraGambling_EditBox:SetText(tostring(UltraGambling["lastroll"] or 100))
		chatmethod = chatmethods[UltraGambling["chat"] or 1] or "RAID"
		UltraGambling_CHAT_Button:SetText(chatmethod)

		if UltraGambling["minimap"] then UG_MinimapButton:Show() else UG_MinimapButton:Hide() end
		whispermethod = UltraGambling["whispers"] or false
		UltraGambling_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")

		if UltraGambling["active"] == 1 then UltraGambling_Frame:Show() else UltraGambling_Frame:Hide() end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00UltraGambler loaded!|r Type |cffFFD700/ug|r for commands.")
	end

	if (event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes == "true" and UltraGambling["chat"] == 1 then
		UltraGambling_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_GUILD" and AcceptOnes == "true" and UltraGambling["chat"] == 2 then
		UltraGambling_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_PARTY" and AcceptOnes == "true" and UltraGambling["chat"] == 3 then
		UltraGambling_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_SAY" and AcceptOnes == "true" and UltraGambling["chat"] == 4 then
		UltraGambling_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_SYSTEM" and AcceptRolls == "true" then
		UltraGambling_ParseRoll(tostring(arg1))
	end
end

function UltraGambling_ParseChatMsg(msg, sender)
	if msg == "1" then
		if UltraGambling_ChkBan(sender) == 0 then
			UltraGambling_Add(sender)
			if totalrolls >= 2 then
				UltraGambling_AcceptOnes_Button:Disable()
			end
		else
			ChatMsg("Sorry, you're banned!")
		end
	elseif msg == "-1" then
		UltraGambling_Remove(sender)
	end
end

function UltraGambling_OnClickCHAT()
	UltraGambling["chat"] = (UltraGambling["chat"] or 1) + 1
	if UltraGambling["chat"] > 4 then UltraGambling["chat"] = 1 end
	chatmethod = chatmethods[UltraGambling["chat"]]
	UltraGambling_CHAT_Button:SetText(chatmethod)
end

function UltraGambling_OnClickWHISPERS()
	UltraGambling["whispers"] = not UltraGambling["whispers"]
	whispermethod = UltraGambling["whispers"]
	UltraGambling_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")
end

function UltraGambling_OnClickACCEPTONES()
	local editText = UltraGambling_EditBox:GetText()
	if editText ~= "" and editText ~= "1" and tonumber(editText) then
		UltraGambling_Reset()
		UltraGambling_ROLL_Button:Disable()
		UltraGambling_LASTCALL_Button:Disable()
		AcceptOnes = "true"
		ChatMsg(string.format(".:Welcome to UltraGamble:. Roll Amount - (%s) - Type 1 to Join (-1 to withdraw)", editText))
		UltraGambling["lastroll"] = editText
		theMax = tonumber(editText)
		low = theMax + 1
		UltraGambling_AcceptOnes_Button:SetText("New Game")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Please enter a valid number.|r")
	end
end

function UltraGambling_OnClickLASTCALL()
	ChatMsg("Last Call to join!")
	UltraGambling_LASTCALL_Button:Disable()
	UltraGambling_ROLL_Button:Enable()
end

function UltraGambling_OnClickROLL()
	if totalrolls > 1 then
		AcceptOnes = "false"
		AcceptRolls = "true"
		ChatMsg("Roll now! Type /random 1-" .. theMax)
		UltraGambling_List()
	elseif AcceptOnes == "true" then
		ChatMsg("Not enough Players!")
	end
end

function UltraGambling_OnClickSTATS(full)
	if not UltraGambling["stats"] or not next(UltraGambling["stats"]) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!")
		return
	end
	DEFAULT_CHAT_FRAME:AddMessage("--- UltraGamble Stats ---")
	for name, amount in pairs(UltraGambling["stats"]) do
		local sign = amount >= 0 and "won" or "lost"
		DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s %d gold", name, sign, math.abs(amount)))
	end
end

function UltraGambling_Report()
	local goldowed = high - low
	if goldowed ~= 0 then
		lowname = string.upper(string.sub(lowname, 1, 1)) .. string.sub(lowname, 2)
		highname = string.upper(string.sub(highname, 1, 1)) .. string.sub(highname, 2)
		UltraGambling["stats"][highname] = (UltraGambling["stats"][highname] or 0) + goldowed
		UltraGambling["stats"][lowname] = (UltraGambling["stats"][lowname] or 0) - goldowed
		ChatMsg(string.format("%s owes %s %d gold.", lowname, highname, goldowed))
	else
		ChatMsg("It was a tie! No payouts!")
	end
	UltraGambling_Reset()
	UltraGambling_AcceptOnes_Button:SetText("Open Entry")
	UltraGambling_CHAT_Button:Enable()
end

function UltraGambling_Reset()
	totalrolls, low, high, lowname, highname = 0, 0, 0, "", ""
	tie, highbreak, lowbreak = 0, 0, 0
	AcceptOnes, AcceptRolls = "false", "false"
	if UltraGambling then
		UltraGambling.strings = {}
		UltraGambling.lowtie = {}
		UltraGambling.hightie = {}
	end
end

function UltraGambling_Add(name)
	if not UltraGambling.strings then UltraGambling.strings = {} end
	for i, v in ipairs(UltraGambling.strings) do
		if string.lower(v) == string.lower(name) then return end
	end
	table.insert(UltraGambling.strings, name)
	totalrolls = table.getn(UltraGambling.strings)
	if whispermethod then SendChatMessage("You joined!", "WHISPER", nil, name) end
	Print("", "", name .. " joined. Players: " .. totalrolls)
	if totalrolls >= 1 then UltraGambling_LASTCALL_Button:Enable() end
end

function UltraGambling_Remove(name)
	if not UltraGambling.strings then return end
	for i, v in ipairs(UltraGambling.strings) do
		if string.lower(v) == string.lower(name) then
			table.remove(UltraGambling.strings, i)
			totalrolls = table.getn(UltraGambling.strings)
			Print("", "", name .. " left. Players: " .. totalrolls)
			return
		end
	end
end

function UltraGambling_ChkBan(name)
	if not UltraGambling or not UltraGambling.bans then return 0 end
	for i, v in ipairs(UltraGambling.bans) do
		if string.lower(v) == string.lower(name) then return 1 end
	end
	return 0
end

function UltraGambling_List()
	if not UltraGambling.strings or table.getn(UltraGambling.strings) == 0 then
		ChatMsg("No players.")
		return
	end
	local list = ""
	for i, v in ipairs(UltraGambling.strings) do
		list = list .. (list ~= "" and ", " or "") .. v
	end
	ChatMsg("Players: " .. list)
end

function UltraGambling_ParseRoll(msg)
	local _, _, name, roll, minroll, maxroll = string.find(msg, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
	if not name then return end
	roll, minroll, maxroll = tonumber(roll), tonumber(minroll), tonumber(maxroll)

	local found, idx = false, nil
	if UltraGambling.strings then
		for i, v in ipairs(UltraGambling.strings) do
			if string.lower(v) == string.lower(name) then
				found, idx = true, i
				break
			end
		end
	end
	if not found then return end
	table.remove(UltraGambling.strings, idx)

	if maxroll ~= theMax or minroll ~= 1 then
		ChatMsg(name .. " rolled wrong range!")
		return
	end

	if roll > high then high, highname = roll, name end
	if roll < low then low, lowname = roll, name end

	totalrolls = totalrolls - 1
	Print("", "", name .. " rolled " .. roll .. ". Waiting: " .. totalrolls)
	if totalrolls == 0 then UltraGambling_Report() end
end

local UltraGambling_EventFrame = CreateFrame("Frame", "UltraGambling_EventFrame", UIParent)
UltraGambling_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_RAID")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_GUILD")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_SAY")
UltraGambling_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
UltraGambling_EventFrame:SetScript("OnEvent", UltraGambling_OnEvent)
