-- PhantomGamble Addon for Turtle WoW (1.12 compatible)
-- Features: Regular Gambling + Death Roll

-- ============================================
-- VARIABLES
-- ============================================

-- Regular gambling variables
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

-- Death roll variables
local DR_Active = false
local DR_Player1 = nil
local DR_Player2 = nil
local DR_CurrentRoller = nil
local DR_CurrentMax = 0
local DR_StartNumber = 100
local DR_GoldWager = 100
local DR_AcceptingPlayers = false
local DR_WaitingForRoll = false

local chatmethods = { "RAID", "GUILD", "PARTY", "SAY" }
local chatmethod = chatmethods[1]

PG_Settings = { MinimapPos = 75 }

-- Sorted stats cache
local sortedStats = {}
local statsNeedUpdate = true

-- Stats window line pool
local statsLines = {}
local STATS_LINE_HEIGHT = 16
local MAX_STATS_LINES = 50

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

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

-- ============================================
-- STATS FUNCTIONS
-- ============================================

local function UpdateSortedStats()
	sortedStats = {}
	if not PhantomGamble or not PhantomGamble["stats"] then return end
	
	for name, amount in pairs(PhantomGamble["stats"]) do
		table.insert(sortedStats, { name = name, amount = amount })
	end
	
	table.sort(sortedStats, function(a, b) return a.amount > b.amount end)
	statsNeedUpdate = false
end

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
	
	local startIdx, endIdx, header
	
	if fromBottom then
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

local function RefreshStatsDisplay()
	if not PhantomGamble_StatsFrame or not PhantomGamble_StatsFrame:IsVisible() then return end
	if not PhantomGamble_StatsScrollChild then return end
	
	if statsNeedUpdate then UpdateSortedStats() end
	
	for i = 1, MAX_STATS_LINES do
		if statsLines[i] then statsLines[i]:Hide() end
	end
	
	local childWidth = PhantomGamble_StatsScrollChild:GetWidth()
	if not childWidth or childWidth <= 0 then childWidth = 240 end
	
	local yOffset = 0
	for i, entry in ipairs(sortedStats) do
		if i > MAX_STATS_LINES then break end
		
		local line = statsLines[i]
		if not line then
			line = PhantomGamble_StatsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			line:SetJustifyH("LEFT")
			line:SetWidth(childWidth - 10)
			statsLines[i] = line
		end
		
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", PhantomGamble_StatsScrollChild, "TOPLEFT", 5, -yOffset)
		line:SetWidth(childWidth - 10)
		
		local color
		if entry.amount > 0 then
			color = "|cff00ff00"
		elseif entry.amount < 0 then
			color = "|cffff0000"
		else
			color = "|cffffff00"
		end
		
		local sign = entry.amount >= 0 and "+" or ""
		line:SetText(string.format("%d. %s%s: %s%d gold|r", i, color, entry.name, sign, entry.amount))
		line:Show()
		
		yOffset = yOffset + STATS_LINE_HEIGHT
	end
	
	if table.getn(sortedStats) == 0 then
		local line = statsLines[1]
		if not line then
			line = PhantomGamble_StatsScrollChild:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			line:SetJustifyH("LEFT")
			statsLines[1] = line
		end
		line:ClearAllPoints()
		line:SetPoint("TOPLEFT", PhantomGamble_StatsScrollChild, "TOPLEFT", 5, 0)
		line:SetText("|cffffff00No gambling stats yet.|r")
		line:Show()
		yOffset = STATS_LINE_HEIGHT
	end
	
	local totalHeight = math.max(yOffset + 10, 50)
	PhantomGamble_StatsScrollChild:SetHeight(totalHeight)
	
	if PhantomGamble_StatsScrollBar then
		local visibleHeight = PhantomGamble_StatsScrollFrame:GetHeight()
		local maxScroll = math.max(0, totalHeight - visibleHeight)
		PhantomGamble_StatsScrollBar:SetMinMaxValues(0, maxScroll)
	end
end

local function UpdateStatsWindowLayout()
	if not PhantomGamble_StatsFrame then return end
	local width = PhantomGamble_StatsFrame:GetWidth()
	local btnWidth = math.max(40, (width - 30) / 5)
	if PhantomGamble_StatsTop5Btn then PhantomGamble_StatsTop5Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsTop10Btn then PhantomGamble_StatsTop10Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsTop15Btn then PhantomGamble_StatsTop15Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsBot5Btn then PhantomGamble_StatsBot5Btn:SetWidth(btnWidth) end
	if PhantomGamble_StatsLastBtn then PhantomGamble_StatsLastBtn:SetWidth(btnWidth) end
end

-- ============================================
-- STATS WINDOW
-- ============================================

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
	title:SetText("|cffFFD700Gambling Stats|r")
	
	f:SetScript("OnMouseDown", function()
		if arg1 == "LeftButton" then this:StartMoving() end
	end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
	
	local closeBtn = CreateFrame("Button", "PhantomGamble_StatsCloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	closeBtn:SetScript("OnClick", function() PhantomGamble_StatsFrame:Hide() end)
	
	local scrollFrame = CreateFrame("ScrollFrame", "PhantomGamble_StatsScrollFrame", f)
	scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -30)
	scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 60)
	scrollFrame:EnableMouseWheel(true)
	
	local scrollChild = CreateFrame("Frame", "PhantomGamble_StatsScrollChild", scrollFrame)
	scrollChild:SetWidth(240)
	scrollChild:SetHeight(1)
	scrollFrame:SetScrollChild(scrollChild)
	
	local scrollBar = CreateFrame("Slider", "PhantomGamble_StatsScrollBar", scrollFrame)
	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 2, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 2, 16)
	scrollBar:SetWidth(16)
	scrollBar:SetOrientation("VERTICAL")
	scrollBar:SetMinMaxValues(0, 1)
	scrollBar:SetValueStep(1)
	scrollBar:SetValue(0)
	
	local scrollBg = scrollBar:CreateTexture(nil, "BACKGROUND")
	scrollBg:SetAllPoints(scrollBar)
	scrollBg:SetTexture(0, 0, 0, 0.5)
	
	local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
	thumb:SetTexture(0.5, 0.5, 0.5, 1)
	thumb:SetWidth(14)
	thumb:SetHeight(30)
	scrollBar:SetThumbTexture(thumb)
	
	scrollBar:SetScript("OnValueChanged", function()
		scrollFrame:SetVerticalScroll(this:GetValue())
	end)
	
	scrollFrame:SetScript("OnMouseWheel", function()
		local current = scrollBar:GetValue()
		local minVal, maxVal = scrollBar:GetMinMaxValues()
		local step = STATS_LINE_HEIGHT * 3
		if arg1 > 0 then
			scrollBar:SetValue(math.max(minVal, current - step))
		else
			scrollBar:SetValue(math.min(maxVal, current + step))
		end
	end)
	
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
		local scrollWidth = PhantomGamble_StatsScrollFrame:GetWidth()
		PhantomGamble_StatsScrollChild:SetWidth(scrollWidth)
		RefreshStatsDisplay()
	end)
	
	f:SetScript("OnSizeChanged", function() 
		UpdateStatsWindowLayout()
		local scrollWidth = PhantomGamble_StatsScrollFrame:GetWidth()
		if scrollWidth and scrollWidth > 0 then
			PhantomGamble_StatsScrollChild:SetWidth(scrollWidth)
		end
	end)
	
	f:SetScript("OnShow", function()
		statsNeedUpdate = true
		this:SetScript("OnUpdate", function()
			this:SetScript("OnUpdate", nil)
			local scrollWidth = PhantomGamble_StatsScrollFrame:GetWidth()
			if scrollWidth and scrollWidth > 0 then
				PhantomGamble_StatsScrollChild:SetWidth(scrollWidth)
			end
			RefreshStatsDisplay()
		end)
	end)
	
	f:Hide()
	return f
end

-- ============================================
-- LAYOUT UPDATE
-- ============================================

local function UpdateLayout()
	if not PhantomGamble_Frame then return end
	local width = PhantomGamble_Frame:GetWidth()
	local halfWidth = (width - 15) / 2
	
	-- Left side buttons
	local leftBtnWidth = math.max(80, halfWidth - 20)
	if PhantomGamble_EditBox then PhantomGamble_EditBox:SetWidth(math.max(60, leftBtnWidth - 20)) end
	if PhantomGamble_AcceptOnes_Button then PhantomGamble_AcceptOnes_Button:SetWidth(leftBtnWidth) end
	if PhantomGamble_LASTCALL_Button then PhantomGamble_LASTCALL_Button:SetWidth(leftBtnWidth) end
	if PhantomGamble_ROLL_Button then PhantomGamble_ROLL_Button:SetWidth(leftBtnWidth) end
	
	-- Right side buttons
	local rightBtnWidth = math.max(80, halfWidth - 20)
	if PhantomGamble_DR_EditBox then PhantomGamble_DR_EditBox:SetWidth(math.max(60, rightBtnWidth - 20)) end
	if PhantomGamble_DR_StartBtn then PhantomGamble_DR_StartBtn:SetWidth(rightBtnWidth) end
	if PhantomGamble_DR_CancelBtn then PhantomGamble_DR_CancelBtn:SetWidth(rightBtnWidth) end
	
	-- Bottom buttons
	local bottomBtnWidth = math.max(50, (halfWidth - 10) / 2)
	if PhantomGamble_CHAT_Button then PhantomGamble_CHAT_Button:SetWidth(bottomBtnWidth) end
	if PhantomGamble_WHISPER_Button then PhantomGamble_WHISPER_Button:SetWidth(bottomBtnWidth) end
end

-- ============================================
-- MAIN FRAME CREATION
-- ============================================

local function CreateMainFrame()
	local f = CreateFrame("Frame", "PhantomGamble_Frame", UIParent)
	f:SetWidth(420)
	f:SetHeight(250)
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	f:SetMovable(true)
	f:SetResizable(true)
	f:EnableMouse(true)
	f:SetFrameStrata("DIALOG")
	f:SetMinResize(380, 220)
	f:SetMaxResize(600, 400)

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

	-- Center divider
	local divider = f:CreateTexture(nil, "BORDER")
	divider:SetTexture(0.5, 0.5, 0.5, 1)
	divider:SetWidth(2)
	divider:SetPoint("TOP", f, "TOP", 0, -26)
	divider:SetPoint("BOTTOM", f, "BOTTOM", 0, 55)

	-- Title bar
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
		if not PhantomGamble_StatsFrame then CreateStatsWindow() end
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

	-- Close button
	local closeBtn = CreateFrame("Button", "PhantomGamble_CloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
	closeBtn:SetScript("OnClick", function() PhantomGamble_SlashCmd("hide") end)

	-- ==========================================
	-- LEFT SIDE - Regular Gambling
	-- ==========================================
	
	local leftTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	leftTitle:SetPoint("TOP", f, "TOPLEFT", 105, -30)
	leftTitle:SetText("|cff00ff00Regular Gamble|r")

	local editbox = CreateFrame("EditBox", "PhantomGamble_EditBox", f)
	editbox:SetWidth(80)
	editbox:SetHeight(24)
	editbox:SetPoint("TOP", leftTitle, "BOTTOM", 0, -8)
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
	acceptBtn:SetWidth(120)
	acceptBtn:SetHeight(22)
	acceptBtn:SetPoint("TOP", editbox, "BOTTOM", 0, -8)
	acceptBtn:SetText("Open Entry")
	acceptBtn:SetScript("OnClick", function() PhantomGamble_OnClickACCEPTONES() end)

	local lastcallBtn = CreateFrame("Button", "PhantomGamble_LASTCALL_Button", f, "GameMenuButtonTemplate")
	lastcallBtn:SetWidth(120)
	lastcallBtn:SetHeight(22)
	lastcallBtn:SetPoint("TOP", acceptBtn, "BOTTOM", 0, -4)
	lastcallBtn:SetText("Last Call")
	lastcallBtn:SetScript("OnClick", function() PhantomGamble_OnClickLASTCALL() end)

	local rollBtn = CreateFrame("Button", "PhantomGamble_ROLL_Button", f, "GameMenuButtonTemplate")
	rollBtn:SetWidth(120)
	rollBtn:SetHeight(22)
	rollBtn:SetPoint("TOP", lastcallBtn, "BOTTOM", 0, -4)
	rollBtn:SetText("Roll")
	rollBtn:SetScript("OnClick", function() PhantomGamble_OnClickROLL() end)

	local cancelBtn = CreateFrame("Button", "PhantomGamble_Cancel_Button", f, "GameMenuButtonTemplate")
	cancelBtn:SetWidth(120)
	cancelBtn:SetHeight(22)
	cancelBtn:SetPoint("TOP", rollBtn, "BOTTOM", 0, -4)
	cancelBtn:SetText("Cancel")
	cancelBtn:SetScript("OnClick", function() PhantomGamble_OnClickCANCEL() end)
	cancelBtn:Disable()

	-- ==========================================
	-- RIGHT SIDE - Death Roll
	-- ==========================================
	
	local rightTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	rightTitle:SetPoint("TOP", f, "TOPRIGHT", -105, -30)
	rightTitle:SetText("|cffff0000Death Roll|r")

	-- Starting number label
	local drStartLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	drStartLabel:SetPoint("TOPLEFT", rightTitle, "BOTTOM", -50, -10)
	drStartLabel:SetWidth(35)
	drStartLabel:SetJustifyH("RIGHT")
	drStartLabel:SetText("|cffffffffStart:|r")

	-- Starting number button (click to show dropdown)
	local drStartBtn_Select = CreateFrame("Button", "PhantomGamble_DR_StartSelect", f)
	drStartBtn_Select:SetWidth(60)
	drStartBtn_Select:SetHeight(20)
	drStartBtn_Select:SetPoint("LEFT", drStartLabel, "RIGHT", 5, 0)
	
	local drStartBtnBg = drStartBtn_Select:CreateTexture(nil, "BACKGROUND")
	drStartBtnBg:SetTexture(0.1, 0.1, 0.1, 0.8)
	drStartBtnBg:SetAllPoints(drStartBtn_Select)
	
	local drStartBtnText = drStartBtn_Select:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	drStartBtnText:SetPoint("CENTER", drStartBtn_Select, "CENTER", 0, 0)
	drStartBtnText:SetText("100")
	
	local drStartBtnArrow = drStartBtn_Select:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	drStartBtnArrow:SetPoint("RIGHT", drStartBtn_Select, "RIGHT", -3, 0)
	drStartBtnArrow:SetText("v")
	
	drStartBtn_Select:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
	
	-- Dropdown menu for start values
	local drStartDropdown = CreateFrame("Frame", "PhantomGamble_DR_StartDropdown", f)
	drStartDropdown:SetWidth(60)
	drStartDropdown:SetHeight(110)
	drStartDropdown:SetPoint("TOP", drStartBtn_Select, "BOTTOM", 0, 0)
	drStartDropdown:SetFrameStrata("TOOLTIP")
	drStartDropdown:Hide()
	
	local drDropdownBg = drStartDropdown:CreateTexture(nil, "BACKGROUND")
	drDropdownBg:SetTexture(0, 0, 0, 0.9)
	drDropdownBg:SetAllPoints(drStartDropdown)
	
	local drDropdownBorder = drStartDropdown:CreateTexture(nil, "BORDER")
	drDropdownBorder:SetTexture(0.5, 0.5, 0.5, 1)
	drDropdownBorder:SetPoint("TOPLEFT", drStartDropdown, "TOPLEFT", -1, 1)
	drDropdownBorder:SetPoint("BOTTOMRIGHT", drStartDropdown, "BOTTOMRIGHT", 1, -1)
	
	local startOptions = {10, 50, 100, 1000, 10000}
	local startOptionButtons = {}
	
	for i, val in ipairs(startOptions) do
		local optBtn = CreateFrame("Button", "PhantomGamble_DR_StartOpt"..i, drStartDropdown)
		optBtn:SetWidth(58)
		optBtn:SetHeight(20)
		optBtn:SetPoint("TOP", drStartDropdown, "TOP", 0, -2 - ((i-1) * 21))
		
		local optText = optBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		optText:SetPoint("CENTER", optBtn, "CENTER", 0, 0)
		if val >= 10000 then
			optText:SetText(string.format("%d,000", val/1000))
		elseif val >= 1000 then
			optText:SetText(string.format("%d,000", val/1000))
		else
			optText:SetText(tostring(val))
		end
		
		optBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
		optBtn:SetScript("OnClick", function()
			DR_StartNumber = val
			if val >= 10000 then
				drStartBtnText:SetText("10,000")
			elseif val >= 1000 then
				drStartBtnText:SetText("1,000")
			else
				drStartBtnText:SetText(tostring(val))
			end
			PhantomGamble["lastDRStart"] = val
			drStartDropdown:Hide()
		end)
		
		startOptionButtons[i] = optBtn
	end
	
	drStartBtn_Select:SetScript("OnClick", function()
		if drStartDropdown:IsVisible() then
			drStartDropdown:Hide()
		else
			drStartDropdown:Show()
		end
	end)
	
	-- Hide dropdown when clicking elsewhere
	drStartDropdown:SetScript("OnShow", function()
		this:SetScript("OnUpdate", function()
			if not MouseIsOver(drStartDropdown) and not MouseIsOver(drStartBtn_Select) then
				if IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton") then
					drStartDropdown:Hide()
				end
			end
		end)
	end)
	drStartDropdown:SetScript("OnHide", function()
		this:SetScript("OnUpdate", nil)
	end)

	-- Gold wager label
	local drGoldLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	drGoldLabel:SetPoint("TOPLEFT", drStartLabel, "BOTTOMLEFT", 0, -10)
	drGoldLabel:SetWidth(35)
	drGoldLabel:SetJustifyH("RIGHT")
	drGoldLabel:SetText("|cffffd700Gold:|r")

	-- Gold wager editbox
	local drGoldEditbox = CreateFrame("EditBox", "PhantomGamble_DR_GoldEditBox", f)
	drGoldEditbox:SetWidth(60)
	drGoldEditbox:SetHeight(20)
	drGoldEditbox:SetPoint("LEFT", drGoldLabel, "RIGHT", 5, 0)
	drGoldEditbox:SetFontObject(ChatFontNormal)
	drGoldEditbox:SetAutoFocus(false)
	drGoldEditbox:SetNumeric(true)
	drGoldEditbox:SetMaxLetters(6)
	drGoldEditbox:SetJustifyH("CENTER")
	drGoldEditbox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
	drGoldEditbox:SetScript("OnEnterPressed", function() this:ClearFocus() end)

	local drGoldEditBg = drGoldEditbox:CreateTexture(nil, "BACKGROUND")
	drGoldEditBg:SetTexture(0.1, 0.1, 0.1, 0.8)
	drGoldEditBg:SetAllPoints(drGoldEditbox)

	local drStartBtn = CreateFrame("Button", "PhantomGamble_DR_StartBtn", f, "GameMenuButtonTemplate")
	drStartBtn:SetWidth(120)
	drStartBtn:SetHeight(22)
	drStartBtn:SetPoint("TOP", drGoldLabel, "BOTTOM", 60, -10)
	drStartBtn:SetText("Start Death Roll")
	drStartBtn:SetScript("OnClick", function() PhantomGamble_DR_Start() end)

	local drCancelBtn = CreateFrame("Button", "PhantomGamble_DR_CancelBtn", f, "GameMenuButtonTemplate")
	drCancelBtn:SetWidth(120)
	drCancelBtn:SetHeight(22)
	drCancelBtn:SetPoint("TOP", drStartBtn, "BOTTOM", 0, -4)
	drCancelBtn:SetText("Cancel")
	drCancelBtn:SetScript("OnClick", function() PhantomGamble_DR_Cancel() end)
	drCancelBtn:Disable()

	-- Death Roll Status
	local drStatus = f:CreateFontString("PhantomGamble_DR_Status", "OVERLAY", "GameFontNormalSmall")
	drStatus:SetPoint("TOP", drCancelBtn, "BOTTOM", 0, -8)
	drStatus:SetWidth(140)
	drStatus:SetText("|cffffff00Waiting...|r")

	-- ==========================================
	-- BOTTOM - Shared Controls
	-- ==========================================

	local chatBtn = CreateFrame("Button", "PhantomGamble_CHAT_Button", f, "GameMenuButtonTemplate")
	chatBtn:SetWidth(70)
	chatBtn:SetHeight(20)
	chatBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 15, 30)
	chatBtn:SetText("RAID")
	chatBtn:SetScript("OnClick", function() PhantomGamble_OnClickCHAT() end)

	local whisperBtn = CreateFrame("Button", "PhantomGamble_WHISPER_Button", f, "GameMenuButtonTemplate")
	whisperBtn:SetWidth(90)
	whisperBtn:SetHeight(20)
	whisperBtn:SetPoint("LEFT", chatBtn, "RIGHT", 5, 0)
	whisperBtn:SetText("(No Whispers)")
	whisperBtn:SetScript("OnClick", function() PhantomGamble_OnClickWHISPERS() end)

	-- Resize grip
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

-- ============================================
-- MINIMAP BUTTON
-- ============================================

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

-- ============================================
-- DEATH ROLL FUNCTIONS
-- ============================================

function PhantomGamble_DR_Start()
	local goldText = PhantomGamble_DR_GoldEditBox:GetText()
	
	if not DR_StartNumber or DR_StartNumber < 2 then
		DR_StartNumber = 100
	end
	
	if goldText == "" or not tonumber(goldText) or tonumber(goldText) < 1 then
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Please enter a valid gold wager (1 or higher).|r")
		return
	end
	
	DR_GoldWager = tonumber(goldText)
	DR_CurrentMax = DR_StartNumber
	DR_Active = false
	DR_AcceptingPlayers = true
	DR_Player1 = nil
	DR_Player2 = nil
	DR_WaitingForRoll = false
	
	-- Save last used values
	PhantomGamble["lastDRStart"] = DR_StartNumber
	PhantomGamble["lastDRGold"] = DR_GoldWager
	
	ChatMsg("Death Roll! Starting at " .. DR_StartNumber .. " for " .. DR_GoldWager .. " gold! Type 1 to join (need 2 players).")
	
	PhantomGamble_DR_StartBtn:SetText("Waiting...")
	PhantomGamble_DR_StartBtn:Disable()
	PhantomGamble_DR_CancelBtn:Enable()
	PhantomGamble_DR_Status:SetText("|cffffff00Waiting for players...|r")
end

function PhantomGamble_DR_Cancel()
	DR_Active = false
	DR_AcceptingPlayers = false
	DR_Player1 = nil
	DR_Player2 = nil
	DR_WaitingForRoll = false
	DR_CurrentMax = 0
	
	PhantomGamble_DR_StartBtn:SetText("Start Death Roll")
	PhantomGamble_DR_StartBtn:Enable()
	PhantomGamble_DR_CancelBtn:Disable()
	PhantomGamble_DR_Status:SetText("|cffffff00Cancelled|r")
	
	ChatMsg("Death Roll has been cancelled.")
end

function PhantomGamble_DR_AddPlayer(name)
	if not DR_AcceptingPlayers then return end
	
	-- Check if already joined
	if DR_Player1 and string.lower(DR_Player1) == string.lower(name) then return end
	if DR_Player2 and string.lower(DR_Player2) == string.lower(name) then return end
	
	if not DR_Player1 then
		DR_Player1 = name
		Print("", "", name .. " joined Death Roll as Player 1")
		PhantomGamble_DR_Status:SetText("|cff00ff00P1: " .. name .. "|r\n|cffffff00Waiting for P2...|r")
		if whispermethod then
			SendChatMessage("You joined Death Roll as Player 1!", "WHISPER", nil, name)
		end
	elseif not DR_Player2 then
		DR_Player2 = name
		Print("", "", name .. " joined Death Roll as Player 2")
		DR_AcceptingPlayers = false
		
		-- Start the game
		DR_Active = true
		DR_CurrentRoller = DR_Player1
		DR_WaitingForRoll = true
		
		PhantomGamble_DR_Status:SetText("|cff00ff00P1: " .. DR_Player1 .. "|r\n|cff00ff00P2: " .. DR_Player2 .. "|r")
		
		ChatMsg("Death Roll started! " .. DR_Player1 .. " vs " .. DR_Player2 .. " - Start: " .. DR_StartNumber .. ", Wager: " .. DR_GoldWager .. " gold!")
		ChatMsg(DR_Player1 .. " rolls first! /random 1-" .. DR_CurrentMax)
		
		if whispermethod then
			SendChatMessage("You joined Death Roll as Player 2!", "WHISPER", nil, name)
		end
	end
end

function PhantomGamble_DR_ParseRoll(msg)
	if not DR_Active or not DR_WaitingForRoll then return end
	
	local _, _, name, roll, minroll, maxroll = string.find(msg, "(.+) rolls (%d+) %((%d+)%-(%d+)%)")
	if not name then return end
	
	roll = tonumber(roll)
	minroll = tonumber(minroll)
	maxroll = tonumber(maxroll)
	
	-- Check if it's the current roller
	if string.lower(name) ~= string.lower(DR_CurrentRoller) then return end
	
	-- Check roll range
	if minroll ~= 1 or maxroll ~= DR_CurrentMax then
		ChatMsg(name .. " rolled wrong range! Should be 1-" .. DR_CurrentMax)
		return
	end
	
	-- Check for death (rolled 1)
	if roll == 1 then
		-- Game over - current roller loses
		local winner, loser
		if string.lower(DR_CurrentRoller) == string.lower(DR_Player1) then
			loser = DR_Player1
			winner = DR_Player2
		else
			loser = DR_Player2
			winner = DR_Player1
		end
		
		winner = string.upper(string.sub(winner, 1, 1)) .. string.sub(winner, 2)
		loser = string.upper(string.sub(loser, 1, 1)) .. string.sub(loser, 2)
		
		ChatMsg("DEATH! " .. loser .. " rolled a 1!")
		ChatMsg(loser .. " owes " .. winner .. " " .. DR_GoldWager .. " gold!")
		
		-- Update stats
		PhantomGamble["stats"][winner] = (PhantomGamble["stats"][winner] or 0) + DR_GoldWager
		PhantomGamble["stats"][loser] = (PhantomGamble["stats"][loser] or 0) - DR_GoldWager
		statsNeedUpdate = true
		
		if PhantomGamble_StatsFrame and PhantomGamble_StatsFrame:IsVisible() then
			RefreshStatsDisplay()
		end
		
		-- Reset
		DR_Active = false
		DR_WaitingForRoll = false
		DR_Player1 = nil
		DR_Player2 = nil
		
		PhantomGamble_DR_StartBtn:SetText("Start Death Roll")
		PhantomGamble_DR_StartBtn:Enable()
		PhantomGamble_DR_CancelBtn:Disable()
		PhantomGamble_DR_Status:SetText("|cff00ff00" .. winner .. " wins!|r")
		return
	end
	
	-- Continue game - update max and switch roller
	DR_CurrentMax = roll
	
	if string.lower(DR_CurrentRoller) == string.lower(DR_Player1) then
		DR_CurrentRoller = DR_Player2
	else
		DR_CurrentRoller = DR_Player1
	end
	
	ChatMsg(name .. " rolled " .. roll .. ". " .. DR_CurrentRoller .. "'s turn! /random 1-" .. DR_CurrentMax)
	PhantomGamble_DR_Status:SetText("|cffffff00" .. DR_CurrentRoller .. "'s turn|r\n|cffffff00Roll 1-" .. DR_CurrentMax .. "|r")
end

-- ============================================
-- REGULAR GAMBLING FUNCTIONS
-- ============================================

function PhantomGamble_OnClickACCEPTONES()
	if PhantomGamble_AcceptOnes_Button:GetText() == "New Game" then
		PhantomGamble_Reset()
		PhantomGamble_AcceptOnes_Button:SetText("Open Entry")
		PhantomGamble_AcceptOnes_Button:Enable()
		PhantomGamble_ROLL_Button:Disable()
		PhantomGamble_LASTCALL_Button:Disable()
		PhantomGamble_Cancel_Button:Disable()
		return
	end
	
	local editText = PhantomGamble_EditBox:GetText()
	if editText ~= "" and editText ~= "1" and tonumber(editText) then
		PhantomGamble_Reset()
		PhantomGamble_ROLL_Button:Disable()
		PhantomGamble_LASTCALL_Button:Disable()
		PhantomGamble_Cancel_Button:Enable()
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

function PhantomGamble_OnClickCANCEL()
	if AcceptOnes == "true" or AcceptRolls == "true" then
		ChatMsg("Gambling session has been cancelled.")
	end
	
	PhantomGamble_Reset()
	PhantomGamble_AcceptOnes_Button:SetText("Open Entry")
	PhantomGamble_AcceptOnes_Button:Enable()
	PhantomGamble_ROLL_Button:Disable()
	PhantomGamble_LASTCALL_Button:Disable()
	PhantomGamble_Cancel_Button:Disable()
	PhantomGamble_CHAT_Button:Enable()
	
	Print("", "", "Gambling cancelled.")
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
	PhantomGamble_AcceptOnes_Button:Enable()
	PhantomGamble_ROLL_Button:Disable()
	PhantomGamble_LASTCALL_Button:Disable()
	PhantomGamble_Cancel_Button:Disable()
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

-- ============================================
-- CHAT MESSAGE PARSING
-- ============================================

function PhantomGamble_ParseChatMsg(msg, sender)
	-- Check for Death Roll join
	if msg == "1" and DR_AcceptingPlayers then
		PhantomGamble_DR_AddPlayer(sender)
		return
	end
	
	-- Regular gambling
	if msg == "1" and AcceptOnes == "true" then
		if PhantomGamble_ChkBan(sender) == 0 then
			PhantomGamble_Add(sender)
			if totalrolls >= 2 then
				PhantomGamble_AcceptOnes_Button:Disable()
			end
		else
			ChatMsg("Sorry, you're banned!")
		end
	elseif msg == "-1" and AcceptOnes == "true" then
		PhantomGamble_Remove(sender)
	end
end

-- ============================================
-- SLASH COMMANDS
-- ============================================

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
		PhantomGamble_DR_Cancel()
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

-- ============================================
-- EVENT HANDLING
-- ============================================

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
		DR_StartNumber = PhantomGamble["lastDRStart"] or 100
		-- Update the dropdown button text
		if PhantomGamble_DR_StartSelect then
			local startText = tostring(DR_StartNumber)
			if DR_StartNumber >= 10000 then
				startText = "10,000"
			elseif DR_StartNumber >= 1000 then
				startText = "1,000"
			end
			local btnText = PhantomGamble_DR_StartSelect:GetRegions()
			for i = 1, PhantomGamble_DR_StartSelect:GetNumRegions() do
				local region = select(i, PhantomGamble_DR_StartSelect:GetRegions())
				if region and region:GetObjectType() == "FontString" and region:GetText() ~= "v" then
					region:SetText(startText)
					break
				end
			end
		end
		PhantomGamble_DR_GoldEditBox:SetText(tostring(PhantomGamble["lastDRGold"] or 100))
		chatmethod = chatmethods[PhantomGamble["chat"] or 1] or "RAID"
		PhantomGamble_CHAT_Button:SetText(chatmethod)

		if PhantomGamble["minimap"] then PG_MinimapButton:Show() else PG_MinimapButton:Hide() end
		whispermethod = PhantomGamble["whispers"] or false
		PhantomGamble_WHISPER_Button:SetText(whispermethod and "(Whispers)" or "(No Whispers)")

		if PhantomGamble["active"] == 1 then PhantomGamble_Frame:Show() else PhantomGamble_Frame:Hide() end
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00PhantomGamble loaded!|r Type |cffFFD700/pg|r for commands.")
	end

	-- Chat message handling for both game modes
	local chatEvent = false
	if (event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and PhantomGamble["chat"] == 1 then
		chatEvent = true
	elseif event == "CHAT_MSG_GUILD" and PhantomGamble["chat"] == 2 then
		chatEvent = true
	elseif event == "CHAT_MSG_PARTY" and PhantomGamble["chat"] == 3 then
		chatEvent = true
	elseif event == "CHAT_MSG_SAY" and PhantomGamble["chat"] == 4 then
		chatEvent = true
	end
	
	if chatEvent then
		PhantomGamble_ParseChatMsg(arg1, arg2)
	end
	
	-- System message (roll) handling
	if event == "CHAT_MSG_SYSTEM" then
		-- Check for death roll first
		if DR_Active then
			PhantomGamble_DR_ParseRoll(tostring(arg1))
		end
		-- Then check regular gambling
		if AcceptRolls == "true" then
			PhantomGamble_ParseRoll(tostring(arg1))
		end
	end
end

-- ============================================
-- EVENT FRAME REGISTRATION
-- ============================================

local PhantomGamble_EventFrame = CreateFrame("Frame", "PhantomGamble_EventFrame", UIParent)
PhantomGamble_EventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_GUILD")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SAY")
PhantomGamble_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
PhantomGamble_EventFrame:SetScript("OnEvent", PhantomGamble_OnEvent)
