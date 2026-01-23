-- PhantomGamble Addon for Turtle WoW (1.12 compatible)

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

PG_Settings = { MinimapPos = 75 }

-- Sorted stats cache
local sortedStats = {}
local statsNeedUpdate = true

-- Helper function to send chat messages
local function ChatMsg(msg, chatType, language, channel)
	if not msg or msg == "" then return end
	
	chatType = chatType or chatmethod
	
	if chatType == "RAID" then
		if not UnitInRaid("player") then
			if UnitInParty("player") then
				chatType = "PARTY"
			elseif IsInGuild() then
				chatType = "GUILD"
			else
				chatType = "SAY"
			end
		end
	elseif chatType == "PARTY" then
		if not UnitInParty("player") then
			if IsInGuild() then
				chatType = "GUILD"
			else
				chatType = "SAY"
			end
		end
	elseif chatType == "GUILD" then
		if not IsInGuild() then
			if UnitInParty("player") then
				chatType = "PARTY"
			else
				chatType = "SAY"
			end
		end
	end
	
	if chatType == "CHANNEL" and channel then
		SendChatMessage(msg, chatType, nil, channel)
	else
		SendChatMessage(msg, chatType)
	end
end

local function Print(pre, red, text)
	if red == "" then red = "/PG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre .. "|cff00ff00" .. red .. "|r: " .. text)
end

-- Sort stats for display
local function UpdateSortedStats()
	sortedStats = {}
	if not PhantomGamble or not PhantomGamble["stats"] then return end
	
	for name, amount in pairs(PhantomGamble["stats"]) do
		table.insert(sortedStats, { name = name, amount = amount })
	end
	
	-- Sort by amount descending (winners first)
	table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
	statsNeedUpdate = false
end

-- Report stats to chat
local function ReportStats(count, fromBottom)
	if not PhantomGamble or not PhantomGamble["stats"] or not next(PhantomGamble["stats"]) then
		Print("", "", "No stats to report!")
		return
	end
	
	if statsNeedUpdate then UpdateSortedStats() end
	
	local total = table.getn(sortedStats)
	if total == 0 then
		Print("", "", "No stats to report!")
		return
	end
	
	local startIdx, endIdx
	local header
	
	if fromBottom then
		-- Bottom players (losers)
		if count == 1 then
			header = "Biggest Loser"
			startIdx = total
			endIdx = total
		else
			header = "Bottom " .. count .. " Losers"
			startIdx = math.max(1, total - count + 1)
			endIdx = total
		end
	else
		-- Top players (winners)
		header = "Top " .. count .. " Winners"
		startIdx = 1
		endIdx = math.min(count, total)
	end
	
	ChatMsg("--- PhantomGamble " .. header .. " ---")
	
	if fromBottom then
		for i = endIdx, startIdx, -1 do
			local entry = sortedStats[i]
			if entry then
				local sign = entry.amount >= 0 and "+" or ""
				ChatMsg(string.format("%d. %s: %s%d gold", (total - i + 1), entry.name, sign, entry.amount))
			end
		end
	else
		for i = startIdx, endIdx do
			local entry = sortedStats[i]
			if entry then
				local sign = entry.amount >= 0 and "+" or ""
				ChatMsg(string.format("%d. %s: %s%d gold", i, entry.name, sign, entry.amount))
			end
		end
	end
end

-- Stats window scroll frame line pool
local statsLines = {}
local STATS_LINE_HEIGHT = 16
local MAX_STATS_LINES = 50

local function UpdateStatsWindowLayout()
	if not PhantomGamble_StatsFrame then return end
	local width = PhantomGamble_StatsFrame:GetWidth()
	
	-- Update button widths
	local btnWidth = math.max(40, (width - 30) / 5)
	if PhantomGamble_StatsTop5Btn then PhantomGamble_StatsTop5Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsTop10Btn then PhantomGamble_StatsTop10Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsTop15Btn then PhantomGamble_StatsTop15Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsBot5Btn then PhantomGamble_StatsBot5Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsLastBtn then PhantomGamble_StatsLastBtn:SetWidth(btnWidth) end
end

local function RefreshStatsDisplay()
	if not PhantomGamble_StatsFrame or not PhantomGamble_StatsFrame:IsVisible() then return end
	
	if statsNeedUpdate then UpdateSortedStats() end
	
	-- Hide all lines first
	for i = 1, MAX_STATS_LINES do
		if statsLines[i] then
			statsLines[i]:Hide()
		end
	end
	
	-- Show stats
	local yOffset = 0
	for i, entry in ipairs(sortedStats) do
		if i > MAX_STATS_LINES then break end
		
		local line = statsLines[i]
		if not line then
			line = PhantomGamble_StatsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			line:SetJustifyH("LEFT")
			statsLines[i] = line
		end
		
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", PhantomGamble_StatsScrollChild, "TOPLEFT", 5, -yOffset)
		line:SetPoint("TOPRIGHT", PhantomGamble_StatsScrollChild, "TOPRIGHT", -5, -yOffset)
		
		local color
		if entry.amount > 0 then
			color = "|cff00ff00" -- Green for positive
		elseif entry.amount < 0 then
			color = "|cffff0000" -- Red for negative
		else
			color = "|cffffff00" -- Yellow for zero
		end
		
		local sign = entry.amount >= 0 and "+" or ""
		line:SetText(string.format("%d. %s%s: %s%d gold|r", i, color, entry.name, sign, entry.amount))
		line:Show()
		
		yOffset = yOffset + STATS_LINE_HEIGHT
	end
	
	-- Update scroll child height
	local totalHeight = math.max(yOffset, 100)
	PhantomGamble_StatsScrollChild:SetHeight(totalHeight)
end

local function CreateStatsWindow()
	local f = CreateFrame("Frame", "PhantomGamble_StatsFrame", UIParent)
	f:SetWidth(280)
	f:SetHeight(350)
	f:SetPoint("LEFT", PhantomGamble_Frame, "RIGHT", 10, 0)
	f:SetMovable(true)
	f:SetResizable(true)
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG")
	f:SetMinResize(250, 200)
	f:SetMaxResize(450, 500)
	
	-- Background
	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetTexture(0, 0, 0, 0.85)
	bg:SetAllPoints(f)
	
	-- Borders
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
	
	-- Title bar
	local titleBg = f:CreateTexture(nil, "ARTWORK")
	titleBg:SetTexture(0.2, 0.2, 0.4, 1)
	titleBg:SetHeight(24)
	titleBg:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
	titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", f, "TOP", 0, -8)
	title:SetText("|cffFFD700Gambling Stats|r")
	
	-- Draggable
	f:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" then this:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
	
	-- Close button
	local closeBtn = CreateFrame("Button", "PhantomGamble_StatsCloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	closeBtn:SetScript("OnClick", function() PhantomGamble_StatsFrame:Hide() end)
	
	-- Scroll frame
	local scrollFrame = CreateFrame("ScrollFrame", "PhantomGamble_StatsScrollFrame", f)
	scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
	scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 60)
	
	-- Scroll child
	local scrollChild = CreateFrame("Frame", "PhantomGamble_StatsScrollChild", scrollFrame)
	scrollChild:SetWidth(scrollFrame:GetWidth())
	scrollChild:SetHeight(400)
	scrollFrame:SetScrollChild(scrollChild)
	
	-- Scroll bar
	local scrollBar = CreateFrame("Slider", "PhantomGamble_StatsScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
	scrollBar:SetMinMaxValues(0, 400)
	scrollBar:SetValueStep(STATS_LINE_HEIGHT)
	scrollBar:SetValue(0)
	scrollBar:SetWidth(16)
	scrollBar:SetScript("OnValueChanged", function()
		scrollFrame:SetVerticalScroll(this:GetValue())
	end)
	
	-- Mouse wheel scrolling
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function()
		local current = scrollBar:GetValue()
		local step = STATS_LINE_HEIGHT * 3
		if arg1 > 0 then
			scrollBar:SetValue(math.max(0, current - step))
		else
			scrollBar:SetValue(current + step)
		end
	end)
	
	-- Report buttons
	local btnY = 35
	local btnHeight = 20
	local btnSpacing = 2
	
	local top5Btn = CreateFrame("Button", "PhantomGamble_StatsTop5Btn", f, "GameMenuButtonTemplate")
	top5Btn:SetWidth(45)
	top5Btn:SetHeight(btnHeight)
	top5Btn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 5, btnY)
	top5Btn:SetText("Top 5")
	top5Btn:SetScript("OnClick", function() ReportStats(5, false) end)
	
	local top10Btn = CreateFrame("Button", "PhantomGamble_StatsTop10Btn", f, "GameMenuButtonTemplate")
	top10Btn:SetWidth(45)
	top10Btn:SetHeight(btnHeight)
	top10Btn:SetPoint("LEFT", top5Btn, "RIGHT", btnSpacing, 0)
	top10Btn:SetText("Top 10")
	top10Btn:SetScript("OnClick", function() ReportStats(10, false) end)
	
	local top15Btn = CreateFrame("Button", "PhantomGamble_StatsTop15Btn", f, "GameMenuButtonTemplate")
	top15Btn:SetWidth(45)
	top15Btn:SetHeight(btnHeight)
	top15Btn:SetPoint("LEFT", top10Btn, "RIGHT", btnSpacing, 0)
	top15Btn:SetText("Top 15")
	top15Btn:SetScript("OnClick", function() ReportStats(15, false) end)
	
	local bot5Btn = CreateFrame("Button", "PhantomGamble_StatsBot5Btn", f, "GameMenuButtonTemplate")
	bot5Btn:SetWidth(45)
	bot5Btn:SetHeight(btnHeight)
	bot5Btn:SetPoint("LEFT", top15Btn, "RIGHT", btnSpacing, 0)
	bot5Btn:SetText("Bot 5")
	bot5Btn:SetScript("OnClick", function() ReportStats(5, true) end)
	
	local lastBtn = CreateFrame("Button", "PhantomGamble_StatsLastBtn", f, "GameMenuButtonTemplate")
	lastBtn:SetWidth(45)
	lastBtn:SetHeight(btnHeight)
	lastBtn:SetPoint("LEFT", bot5Btn, "RIGHT", btnSpacing, 0)
	lastBtn:SetText("Last")
	lastBtn:SetScript("OnClick", function() ReportStats(1, true) end)
	
	-- Reset stats button
	local resetBtn = CreateFrame("Button", "PhantomGamble_StatsResetBtn", f, "GameMenuButtonTemplate")
	resetBtn:SetWidth(80)
	resetBtn:SetHeight(btnHeight)
	resetBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)
	resetBtn:SetText("Reset Stats")
	resetBtn:SetScript("OnClick", function()
		PhantomGamble["stats"] = {}
		statsNeedUpdate = true
		RefreshStatsDisplay()
		Print("", "", "Stats have been reset.")
	end)
	
	-- Resize grip
	local resizeBtn = CreateFrame("Button", "PhantomGamble_StatsResizeButton", f)
	resizeBtn:SetWidth(16)
	resizeBtn:SetHeight(16)
	resizeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
	resizeBtn:EnableMouse(true)
	local resizeTexture = resizeBtn:CreateTexture(nil, "OVERLAY")
	resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeTexture:SetAllPoints(resizeBtn)
	resizeBtn:SetScript("OnMouseDown", function() PhantomGamble_StatsFrame:StartSizing("BOTTOMRIGHT") end)
	resizeBtn:SetScript("OnMouseUp", function() 
		PhantomGamble_StatsFrame:StopMovingOrSizing()
		UpdateStatsWindowLayout()
		-- Update scroll child width
		PhantomGamble_StatsScrollChild:SetWidth(PhantomGamble_StatsScrollFrame:GetWidth())
		RefreshStatsDisplay()
	end)
	
	f:SetScript("OnSizeChanged", function() 
		UpdateStatsWindowLayout()
		PhantomGamble_StatsScrollChild:SetWidth(PhantomGamble_StatsScrollFrame:GetWidth())
	end)
	
	f:SetScript("OnShow", function()
		statsNeedUpdate = true
		RefreshStatsDisplay()
	end)
	
	f:Hide()
	return f
end

local function UpdateLayout()
	if not PhantomGamble_Frame then return end
	local width = PhantomGamble_Frame:GetWidth()
	local editWidth = math.max(60, width - 80)
	PhantomGamble_EditBox:SetWidth(editWidth)
	local btnWidth = math.max(80, width - 60)
	PhantomGamble_AcceptOnes_Button:SetWidth(btnWidth)
	PhantomGamble_LASTCALL_Button:SetWidth(btnWidth)
	PhantomGamble_ROLL_Button:SetWidth(btnWidth)
	local bottomBtnWidth = math.max(60, (width - 50) / 2)
	PhantomGamble_CHAT_Button:SetWidth(bottomBtnWidth)
	PhantomGamble_WHISPER_Button:SetWidth(bottomBtnWidth)
end

local function CreateMainFrame()
	local f = CreateFrame("Frame", "PhantomGamble_Frame", UIParent)
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
	title:SetText("|cffFFD700PhantomGamble|r")

	f:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" then this:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

	-- Stats button (top left)
	local statsBtn = CreateFrame("Button", "PhantomGamble_StatsButton", f)
	statsBtn:SetWidth(20)
	statsBtn:SetHeight(20)
	statsBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)
	
	local statsBtnBg = statsBtn:CreateTexture(nil, "BACKGROUND")
	statsBtnBg:SetTexture(0.3, 0.3, 0.5, 1)
	statsBtnBg:SetAllPoints(statsBtn)
	
	local statsBtnText = statsBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	statsBtnText:SetPoint("CENTER", statsBtn, "CENTER", 0, 0)
	statsBtnText:SetText("|cffFFD700S|r")
	
	statsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	statsBtn:SetScript("OnClick", function()
		if not PhantomGamble_StatsFrame then
			CreateStatsWindow()
		end
		if PhantomGamble_StatsFrame:IsVisible() then
			PhantomGamble_StatsFrame:Hide()
		else
			PhantomGamble_StatsFrame:Show()
		end
	end)
	statsBtn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText("Gambling Stats")
		GameTooltip:AddLine("Click to view all-time stats", 1, 1, 1)
		GameTooltip:Show()
	end)
	statsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local editbox = CreateFrame("EditBox", "PhantomGamble_EditBox", f)
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

	local acceptBtn = CreateFrame("Button", "PhantomGamble_AcceptOnes_Button", f, "GameMenuButtonTemplate")
	acceptBtn:SetWidth(150)
	acceptBtn:SetHeight(22)
	acceptBtn:SetPoint("TOP", editbox, "BOTTOM", 0, -10)
	acceptBtn:SetText("Open Entry")
	acceptBtn:SetScript("OnClick", function() PhantomGamble_OnClickACCEPTONES() end)

	local lastcallBtn = CreateFrame("Button", "PhantomGamble_LASTCALL_Button", f, "GameMenuButtonTemplate")
	lastcallBtn:SetWidth(150)
	lastcallBtn:SetHeight(22)
	lastcallBtn:SetPoint("TOP", acceptBtn, "BOTTOM", 0, -5)
	lastcallBtn:SetText("Last Call")
	lastcallBtn:SetScript("OnClick", function() PhantomGamble_OnClickLASTCALL() end)

	local rollBtn = CreateFrame("Button", "PhantomGamble_ROLL_Button", f, "GameMenuButtonTemplate")
	rollBtn:SetWidth(150)
	rollBtn:SetHeight(22)
	rollBtn:SetPoint("TOP", lastcallBtn, "BOTTOM", 0, -5)
	rollBtn:SetText("Roll")
	rollBtn:SetScript("OnClick", function() PhantomGamble_OnClickROLL() end)

	local chatBtn = CreateFrame("Button", "PhantomGamble_CHAT_Button", f, "GameMenuButtonTemplate")
	chatBtn:SetWidth(80)
	chatBtn:SetHeight(20)
	chatBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 35)
	chatBtn:SetText("RAID")
	chatBtn:SetScript("OnClick", function() PhantomGamble_OnClickCHAT() end)

	local whisperBtn = CreateFrame("Button", "PhantomGamble_WHISPER_Button", f, "GameMenuButtonTemplate")
	whisperBtn:SetWidth(100)
	whisperBtn:SetHeight(20)
	whisperBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -15, 35)
	whisperBtn:SetText("(No Whispers)")
	whisperBtn:SetScript("OnClick", function() PhantomGamble_OnClickWHISPERS() end)

	local closeBtn = CreateFrame("Button", "PhantomGamble_CloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	closeBtn:SetScript("OnClick", function() PhantomGamble_SlashCmd("hide") end)

	local resizeBtn = CreateFrame("Button", "PhantomGamble_ResizeButton", f)
	resizeBtn:SetWidth(16)
	resizeBtn:SetHeight(16)
	resizeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
	resizeBtn:EnableMouse(true)
	local resizeTexture = resizeBtn:CreateTexture(nil, "OVERLAY")
	resizeTexture:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	resizeTexture:SetAllPoints(resizeBtn)
	resizeBtn:SetScript("OnMouseDown", function() PhantomGamble_Frame:StartSizing("BOTTOMRIGHT") end)
	resizeBtn:SetScript("OnMouseUp", function() PhantomGamble_Frame:StopMovingOrSizing(); UpdateLayout() end)
	f:SetScript("OnSizeChanged", function() UpdateLayout() end)

	return f
end

local function CreateMinimapButton()
	local btn = CreateFrame("Button", "PG_MinimapButton", Minimap)
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

	btn:SetScript("OnClick", function() PG_MinimapButton_OnClick() end)
	btn:SetScript("OnDragStart", function()
		this:LockHighlight()
		this:SetScript("OnUpdate", PG_MinimapButton_DraggingFrame_OnUpdate)
	end)
	btn:SetScript("OnDragStop", function()
		this:SetScript("OnUpdate", nil)
		this:UnlockHighlight()
	end)
	btn:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:SetText("|cffFFD700PhantomGamble|r")
		GameTooltip:AddLine("Click to toggle window", 1, 1, 1)
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

	PG_MinimapButton_Reposition()
	return btn
end

function PG_MinimapButton_Reposition()
	if not PG_MinimapButton then return end
	if not PG_Settings then PG_Settings = { MinimapPos = 75 } end
	local angle = math.rad(PG_Settings.MinimapPos)
	local x = 52 - (80 * math.cos(angle))
	local y = (80 * math.sin(angle)) - 52
	PG_MinimapButton:ClearAllPoints()
	PG_MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", x, y)
end

function PG_MinimapButton_DraggingFrame_OnUpdate()
	if not PG_Settings then PG_Settings = { MinimapPos = 75 } end
	local xpos, ypos = GetCursorPosition()
	local scale = UIParent:GetEffectiveScale()
	xpos, ypos = xpos / scale, ypos / scale
	local cx, cy = Minimap:GetCenter()
	PG_Settings.MinimapPos = math.deg(math.atan2(ypos - cy, xpos - cx))
	PG_MinimapButton_Reposition()
end

function PG_MinimapButton_OnClick()
	if PhantomGamble and PhantomGamble["active"] == 1 then
		PhantomGamble_Frame:Hide()
		PhantomGamble["active"] = 0
	else
		PhantomGamble_Frame:Show()
		if PhantomGamble then PhantomGamble["active"] = 1 end
	end
end

function PhantomGamble_SlashCmd(msg)
	msg = string.lower(msg or "")
	if msg == "" then
		Print("", "", "Commands: show, hide, stats, reset, fullstats, resetstats, minimap, ban, unban, listban")
		return
	end
	if msg == "hide" then
		PhantomGamble_Frame:Hide()
		PhantomGamble["active"] = 0
	elseif msg == "show" then
		PhantomGamble_Frame:Show()
		PhantomGamble["active"] = 1
	elseif msg == "stats" then
		if not PhantomGamble_StatsFrame then CreateStatsWindow() end
		PhantomGamble_StatsFrame:Show()
	elseif msg == "reset" then
		PhantomGamble_Reset()
		Print("", "", "PhantomGamble has been reset.")
	elseif msg == "fullstats" then
		PhantomGamble_OnClickSTATS(true)
	elseif msg == "resetstats" then
		PhantomGamble["stats"] = {}
		statsNeedUpdate = true
		Print("", "", "Stats have been reset.")
	elseif msg == "minimap" then
		PhantomGamble["minimap"] = not PhantomGamble["minimap"]
		if PhantomGamble["minimap"] then PG_MinimapButton:Show() else PG_MinimapButton:Hide() end
	elseif string.sub(msg, 1, 4) == "ban " then
		local name = string.sub(msg, 5)
		if not PhantomGamble.bans then PhantomGamble.bans = {} end
		table.insert(PhantomGamble.bans, name)
		Print("", "", name .. " banned.")
	elseif string.sub(msg, 1, 6) == "unban " then
		local name = string.sub(msg, 7)
		if PhantomGamble.bans then
			for i, v in ipairs(PhantomGamble.bans) do
				if string.lower(v) == string.lower(name) then
					table.remove(PhantomGamble.bans, i)
					Print("", "", name .. " unbanned.")
					return
				end
			end
		end
	elseif msg == "listban" then
		if not PhantomGamble.bans or table.getn(PhantomGamble.bans) == 0 then
			Print("", "", "No bans.")
		else
			for i, v in ipairs(PhantomGamble.bans) do
				DEFAULT_CHAT_FRAME:AddMessage("  " .. v)
			end
		end
	else
		Print("", "", "Unknown command: " .. msg)
	end
end

SLASH_PHANTOMGAMBLE1 = "/phantomgamble"
SLASH_PHANTOMGAMBLE2 = "/pg"
SlashCmdList["PHANTOMGAMBLE"] = PhantomGamble_SlashCmd

function PhantomGamble_OnEvent()
	if event == "PLAYER_ENTERING_WORLD" then
		if not PhantomGamble_Frame then CreateMainFrame() end
		if not PG_MinimapButton then CreateMinimapButton() end

		if not PhantomGamble then
			PhantomGamble = {
				active = 1, chat = 1, channel = "gambling", whispers = false,
				strings = {}, lowtie = {}, hightie = {}, bans = {},
				minimap = true, lastroll = 100, stats = {}, joinstats = {}
			}
		end

		PhantomGamble_EditBox:SetText(tostring(PhantomGamble["lastroll"] or 100))
		chatmethod = chatmethods[PhantomGamble["chat"] or 1] or "RAID"
		PhantomGamble_CHAT_Button:SetText(chatmethod)

		if PhantomGamble["minimap"] then PG_MinimapButton:Show() else PG_MinimapButton:Hide() end
		whispermethod = PhantomGamble["whispers"] or false
		PhantomGamble_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")

		if PhantomGamble["active"] == 1 then PhantomGamble_Frame:Show() else PhantomGamble_Frame:Hide() end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PhantomGamble loaded!|r Type |cffFFD700/pg|r for commands.")
	end

	if (event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes == "true" and PhantomGamble["chat"] == 1 then
		PhantomGamble_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_GUILD" and AcceptOnes == "true" and PhantomGamble["chat"] == 2 then
		PhantomGamble_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_PARTY" and AcceptOnes == "true" and PhantomGamble["chat"] == 3 then
		PhantomGamble_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_SAY" and AcceptOnes == "true" and PhantomGamble["chat"] == 4 then
		PhantomGamble_ParseChatMsg(arg1, arg2)
	end
	if event == "CHAT_MSG_SYSTEM" and AcceptRolls == "true" then
		PhantomGamble_ParseRoll(tostring(arg1))
	end
end

function PhantomGamble_ParseChatMsg(msg, sender)
	if msg == "1" then
		if PhantomGamble_ChkBan(sender) == 0 then
			PhantomGamble_Add(sender)
			if totalrolls >= 2 then
				PhantomGamble_AcceptOnes_Button:Disable()
			end
		else
			ChatMsg("Sorry, you're banned!")
		end
	elseif msg == "-1" then
		PhantomGamble_Remove(sender)
	end
end

function PhantomGamble_OnClickCHAT()
	PhantomGamble["chat"] = (PhantomGamble["chat"] or 1) + 1
	if PhantomGamble["chat"] > 4 then PhantomGamble["chat"] = 1 end
	chatmethod = chatmethods[PhantomGamble["chat"]]
	PhantomGamble_CHAT_Button:SetText(chatmethod)
end

function PhantomGamble_OnClickWHISPERS()
	PhantomGamble["whispers"] = not PhantomGamble["whispers"]
	whispermethod = PhantomGamble["whispers"]
	PhantomGamble_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")
end

function PhantomGamble_OnClickACCEPTONES()
	local editText = PhantomGamble_EditBox:GetText()
	if editText ~= "" and editText ~= "1" and tonumber(editText) then
		PhantomGamble_Reset()
		PhantomGamble_ROLL_Button:Disable()
		PhantomGamble_LASTCALL_Button:Disable()
		AcceptOnes = "true"
		ChatMsg("Welcome to PhantomGamble! Roll Amount: " .. editText .. " gold. Type 1 to Join or -1 to withdraw.")
		PhantomGamble["lastroll"] = editText
		theMax = tonumber(editText)
		low = theMax + 1
		PhantomGamble_AcceptOnes_Button:SetText("New Game")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Please enter a valid number.|r")
	end
end

function PhantomGamble_OnClickLASTCALL()
	ChatMsg("Last Call to join!")
	PhantomGamble_LASTCALL_Button:Disable()
	PhantomGamble_ROLL_Button:Enable()
end

function PhantomGamble_OnClickROLL()
	if totalrolls > 1 then
		AcceptOnes = "false"
		AcceptRolls = "true"
		ChatMsg("Roll now! Type /random 1-" .. theMax)
		PhantomGamble_List()
	elseif AcceptOnes == "true" then
		ChatMsg("Not enough Players!")
	end
end

function PhantomGamble_OnClickSTATS(full)
	if not PhantomGamble["stats"] or not next(PhantomGamble["stats"]) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!")
		return
	end
	DEFAULT_CHAT_FRAME:AddMessage("--- PhantomGamble Stats ---")
	for name, amount in pairs(PhantomGamble["stats"]) do
		local sign = amount >= 0 and "won" or "lost"
		DEFAULT_CHAT_FRAME:AddMessage(string.format("%s %s %d gold", name, sign, math.abs(amount)))
	end
end

function PhantomGamble_Report()
	local goldowed = high - low
	if goldowed ~= 0 then
		lowname = string.upper(string.sub(lowname, 1, 1)) .. string.sub(lowname, 2)
		highname = string.upper(string.sub(highname, 1, 1)) .. string.sub(highname, 2)
		PhantomGamble["stats"][highname] = (PhantomGamble["stats"][highname] or 0) + goldowed
		PhantomGamble["stats"][lowname] = (PhantomGamble["stats"][lowname] or 0) - goldowed
		statsNeedUpdate = true
		if PhantomGamble_StatsFrame and PhantomGamble_StatsFrame:IsVisible() then
			RefreshStatsDisplay()
		end
		ChatMsg(string.format("%s owes %s %d gold.", lowname, highname, goldowed))
	else
		ChatMsg("It was a tie! No payouts!")
	end
	PhantomGamble_Reset()
	PhantomGamble_AcceptOnes_Button:SetText("Open Entry")
	PhantomGamble_CHAT_Button:Enable()
end

function PhantomGamble_Reset()
	totalrolls, low, high, lowname, highname = 0, 0, 0, "", ""
	tie, highbreak, lowbreak = 0, 0, 0
	AcceptOnes, AcceptRolls = "false", "false"
	if PhantomGamble then
		PhantomGamble.strings = {}
		PhantomGamble.lowtie = {}
		PhantomGamble.hightie = {}
	end
end

function PhantomGamble_Add(name)
	if not PhantomGamble.strings then PhantomGamble.strings = {} end
	for i, v in ipairs(PhantomGamble.strings) do
		if string.lower(v) == string.lower(name) then return end
	end
	table.insert(PhantomGamble.strings, name)
	totalrolls = table.getn(PhantomGamble.strings)
	if whispermethod then SendChatMessage("You joined!", "WHISPER", nil, name) end
	Print("", "", name .. " joined. Players: " .. totalrolls)
	if totalrolls >= 1 then PhantomGamble_LASTCALL_Button:Enable() end
end

function PhantomGamble_Remove(name)
	if not PhantomGamble.strings then return end
	for i, v in ipairs(PhantomGamble.strings) do
		if string.lower(v) == string.lower(name) then
			table.remove(PhantomGamble.strings, i)
			totalrolls = table.getn(PhantomGamble.strings)
			Print("", "", name .. " left. Players: " .. totalrolls)
			return
		end
	end
end

function PhantomGamble_ChkBan(name)
	if not PhantomGamble or not PhantomGamble.bans then return 0 end
	for i, v in ipairs(PhantomGamble.bans) do
		if string.lower(v) == string.lower(name) then return 1 end
	end
	return 0
end

function PhantomGamble_List()
	if not PhantomGamble.strings or table.getn(PhantomGamble.strings) == 0 then
		ChatMsg("No players.")
		return
	end
	local list = ""
	for i, v in ipairs(PhantomGamble.strings) do
		list = list .. (list ~= "" and ", " or "") .. v
	end
	ChatMsg("Players: " .. list)
end

function PhantomGamble_ParseRoll(msg)
	local _, _, name, roll, minroll, maxroll = string.find(msg, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
	if not name then return end
	roll, minroll, maxroll = tonumber(roll), tonumber(minroll), tonumber(maxroll)

	local found, idx = false, nil
	if PhantomGamble.strings then
		for i, v in ipairs(PhantomGamble.strings) do
			if string.lower(v) == string.lower(name) then
				found, idx = true, i
				break
			end
		end
	end
	if not found then return end
	table.remove(PhantomGamble.strings, idx)

	if maxroll ~= theMax or minroll ~= 1 then
		ChatMsg(name .. " rolled wrong range!")
		return
	end

	if roll > high then high, highname = roll, name end
	if roll < low then low, lowname = roll, name end

	totalrolls = totalrolls - 1
	Print("", "", name .. " rolled " .. roll .. ". Waiting: " .. totalrolls)
	if totalrolls == 0 then PhantomGamble_Report() end
end

local PhantomGamble_EventFrame = CreateFrame("Frame", "PhantomGamble_EventFrame", UIParent)
PhantomGamble_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_GUILD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SAY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
PhantomGamble_EventFrame:SetScript("OnEvent", PhantomGamble_OnEvent)
