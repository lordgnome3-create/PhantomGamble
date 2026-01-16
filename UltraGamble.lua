local AcceptOnes = "false";
local AcceptRolls = "false";
local totalrolls = 0
local tierolls = 0;
local theMax
local lowname = ""
local highname = ""
local low = 0
local high = 0
local tie = 0
local highbreak = 0;
local lowbreak = 0;
local tiehigh = 0;
local tielow = 0;
local chatmethod = "RAID";
local whispermethod = false;
local totalentries = 0;
local highplayername = "";
local lowplayername = "";
local rollCmd = "/random";
local debugLevel = 0;
local virag_debug = false
local chatmethods = {
	"RAID",
	"GUILD",
	"PARTY"
}
local chatmethod = chatmethods[1];


-- Create Main Frame in Lua
local function CreateMainFrame()
	-- Create main frame
	local f = CreateFrame("Frame", "UltraGambling_Frame", UIParent)
	f:SetWidth(300)
	f:SetHeight(200)
	f:SetPoint("CENTER")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 }
	})
	f:SetScript("OnMouseDown", function() this:StartMoving() end)
	f:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)
	
	-- Title
	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOP", 0, -15)
	title:SetText("UltraGamble")
	
	-- Edit Box
	local editbox = CreateFrame("EditBox", "UltraGambling_EditBox", f)
	editbox:SetWidth(100)
	editbox:SetHeight(32)
	editbox:SetPoint("TOP", 0, -40)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetAutoFocus(false)
	editbox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
	
	-- Edit box backdrop
	editbox:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Common\\Common-Input-Border",
		tile = true, edgeSize = 8, tileSize = 32,
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	})
	editbox:SetBackdropColor(0, 0, 0, 0.5)
	
	-- Open Entry Button
	local acceptBtn = CreateFrame("Button", "UltraGambling_AcceptOnes_Button", f, "GameMenuButtonTemplate")
	acceptBtn:SetWidth(120)
	acceptBtn:SetHeight(25)
	acceptBtn:SetPoint("TOP", 0, -80)
	acceptBtn:SetText("Open Entry")
	acceptBtn:SetScript("OnClick", UltraGambling_OnClickACCEPTONES)
	
	-- Last Call Button
	local lastcallBtn = CreateFrame("Button", "UltraGambling_LASTCALL_Button", f, "GameMenuButtonTemplate")
	lastcallBtn:SetWidth(120)
	lastcallBtn:SetHeight(25)
	lastcallBtn:SetPoint("TOP", acceptBtn, "BOTTOM", 0, -5)
	lastcallBtn:SetText("Last Call")
	lastcallBtn:SetScript("OnClick", UltraGambling_OnClickLASTCALL)
	
	-- Roll Button
	local rollBtn = CreateFrame("Button", "UltraGambling_ROLL_Button", f, "GameMenuButtonTemplate")
	rollBtn:SetWidth(120)
	rollBtn:SetHeight(25)
	rollBtn:SetPoint("TOP", lastcallBtn, "BOTTOM", 0, -5)
	rollBtn:SetText("Roll")
	rollBtn:SetScript("OnClick", UltraGambling_OnClickROLL)
	
	-- Chat Method Button
	local chatBtn = CreateFrame("Button", "UltraGambling_CHAT_Button", f, "GameMenuButtonTemplate")
	chatBtn:SetWidth(80)
	chatBtn:SetHeight(20)
	chatBtn:SetPoint("BOTTOMLEFT", 20, 15)
	chatBtn:SetText("RAID")
	chatBtn:SetScript("OnClick", UltraGambling_OnClickCHAT)
	
	-- Whisper Button
	local whisperBtn = CreateFrame("Button", "UltraGambling_WHISPER_Button", f, "GameMenuButtonTemplate")
	whisperBtn:SetWidth(100)
	whisperBtn:SetHeight(20)
	whisperBtn:SetPoint("BOTTOMRIGHT", -20, 15)
	whisperBtn:SetText("(No Whispers)")
	whisperBtn:SetScript("OnClick", UltraGambling_OnClickWHISPERS)
	
	-- Close Button
	local closeBtn = CreateFrame("Button", "UltraGambling_CloseButton", f, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", -5, -5)
	closeBtn:SetScript("OnClick", hide_from_xml)
	
	return f
end

-- LOAD FUNCTION --
function UltraGambling_OnLoad()
	DEFAULT_CHAT_FRAME:AddMessage("|cffffff00<UltraGamble for Turtle WoW> loaded /ug to use");

	this:RegisterEvent("CHAT_MSG_RAID");
	this:RegisterEvent("CHAT_MSG_PARTY");
	this:RegisterEvent("CHAT_MSG_RAID_LEADER");
	this:RegisterEvent("CHAT_MSG_GUILD");
	this:RegisterEvent("CHAT_MSG_SYSTEM");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("CHAT_MSG_WHISPER");

	-- Create the main frame if it doesn't exist
	if not UltraGambling_Frame then
		CreateMainFrame()
	end
	
	UltraGambling_ROLL_Button:Disable();
	UltraGambling_AcceptOnes_Button:Enable();
	UltraGambling_LASTCALL_Button:Disable();
	UltraGambling_CHAT_Button:Enable();
end

local function Print(pre, red, text)
	if red == "" then red = "/UG" end
	DEFAULT_CHAT_FRAME:AddMessage(pre..GREEN_FONT_COLOR_CODE..red..FONT_COLOR_CODE_CLOSE..": "..text)
end

local function DebugMsg(level, text)
	if debugLevel < level then return end

	if level == 1 then
		level = " INFO: "
	elseif level == 2 then
		level = " DEBUG: "
	elseif level == 3 then
		level = " ERROR: "
	end
	Print("","",GRAY_FONT_COLOR_CODE..date("%H:%M:%S")..RED_FONT_COLOR_CODE..level..FONT_COLOR_CODE_CLOSE..text)
end

local function ChatMsg(msg, chatType, language, channel)
	chatType = chatType or chatmethod
	if chatType == "PARTY" and UltraGambling["channel"] then
		channel = UltraGambling["channel"]
		chatType = "CHANNEL"
	end
	SendChatMessage(msg, chatType, language, channel)
end

function hide_from_xml()
	UltraGambling_SlashCmd("hide")
	UltraGambling["active"] = 0;
end

function UltraGambling_SlashCmd(msg)
	local msg = string.lower(msg);
	local msgPrint = 0;
	if (msg == "" or msg == nil) then
		Print("", "", "~Following commands for UltraGamble~");
		Print("", "", "show - Shows the frame");
		Print("", "", "hide - Hides the frame");
		Print("", "", "channel - Change the custom channel for gambling");
		Print("", "", "reset - Resets the AddOn");
		Print("", "", "fullstats - list full stats");
		Print("", "", "resetstats - Resets the stats");
		Print("", "", "joinstats [main] [alt] - Apply [alt]'s win/losses to [main]");
		Print("", "", "minimap - Toggle minimap show/hide");
		Print("", "", "unjoinstats [alt] - Unjoin [alt]'s win/losses from whomever it was joined to");
		Print("", "", "ban - Ban's the user from being able to roll");
		Print("", "", "unban - Unban's the user");
		Print("", "", "listban - Shows ban list");
		msgPrint = 1;
	end
	if (msg == "hide") then
		UltraGambling_Frame:Hide();
		UltraGambling["active"] = 0;
		msgPrint = 1;
	end
	if (msg == "show") then
		UltraGambling_Frame:Show();
		UltraGambling["active"] = 1;
		msgPrint = 1;
	end
	if (msg == "reset") then
		UltraGambling_Reset();
		UltraGambling_ResetCmd()
		msgPrint = 1;
	end
	if (msg == "fullstats") then
		UltraGambling_OnClickSTATS(true)
		msgPrint = 1;
	end
	if (msg == "resetstats") then
		Print("", "", "|cffffff00UltraGamble stats have now been reset");
		UltraGambling_ResetStats();
		msgPrint = 1;
	end
	if (msg == "minimap") then
		Minimap_Toggle()
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 7) == "channel") then
		UltraGambling_ChangeChannel(strsub(msg, 9));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 9) == "joinstats") then
		UltraGambling_JoinStats(strsub(msg, 11));
		msgPrint = 1;
	end
	if (string.sub(msg, 1, 11) == "unjoinstats") then
		UltraGambling_UnjoinStats(strsub(msg, 13));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 3) == "ban") then
		UltraGambling_AddBan(strsub(msg, 5));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 5) == "unban") then
		UltraGambling_RemoveBan(strsub(msg, 7));
		msgPrint = 1;
	end

	if (string.sub(msg, 1, 7) == "listban") then
		UltraGambling_ListBan();
		msgPrint = 1;
	end

	if (msgPrint == 0) then
		Print("", "", "|cffffff00Invalid argument for command /ug");
	end
end

SlashCmdList["ULTRAGAMBLING"] = UltraGambling_SlashCmd;
SLASH_ULTRAGAMBLING1 = "/UltraGambler";
SLASH_ULTRAGAMBLING2 = "/ug";

function UltraGambling_ParseChatMsg(arg1, arg2)
	if (arg1 == "1") then
		if(UltraGambling_ChkBan(tostring(arg2)) == 0) then
			UltraGambling_Add(tostring(arg2));
			if (not UltraGambling_LASTCALL_Button:IsEnabled() and totalrolls == 1) then
				UltraGambling_LASTCALL_Button:Enable();
			end
			if totalrolls == 2 then
				UltraGambling_AcceptOnes_Button:Disable();
				UltraGambling_AcceptOnes_Button:SetText("Open Entry");
			end
		else
			ChatMsg("Sorry, but you're banned from the game!");
		end

	elseif(arg1 == "-1") then
		UltraGambling_Remove(tostring(arg2));
		if (UltraGambling_LASTCALL_Button:IsEnabled() and totalrolls == 0) then
			UltraGambling_LASTCALL_Button:Disable();
		end
		if totalrolls == 1 then
			UltraGambling_AcceptOnes_Button:Enable();
			UltraGambling_AcceptOnes_Button:SetText("Open Entry");
		end
	end
end

local function OptionsFormatter(text, prefix)
	if prefix == "" or prefix == nil then prefix = "/UG" end
	DEFAULT_CHAT_FRAME:AddMessage(string.format("%s%s%s: %s", GREEN_FONT_COLOR_CODE, prefix, FONT_COLOR_CODE_CLOSE, text))
end

function UltraGambling_OnEvent(event)

	-- LOADS ALL DATA FOR INITIALIZATION OF ADDON --
	if (event == "PLAYER_ENTERING_WORLD") then
		UltraGambling_EditBox:SetJustifyH("CENTER");

		if(not UltraGambling) then
			UltraGambling = {
				["active"] = 1,
				["chat"] = 1,
				["channel"] = "gambling",
				["whispers"] = false,
				["strings"] = { },
				["lowtie"] = { },
				["hightie"] = { },
				["bans"] = { },
				["minimap"] = true
			}
		elseif UltraGambling["minimap"] == nil then
			UltraGambling["minimap"] = true
		end
		if(not UltraGambling["lastroll"]) then UltraGambling["lastroll"] = 100; end
		if(not UltraGambling["stats"]) then UltraGambling["stats"] = { }; end
		if(not UltraGambling["joinstats"]) then UltraGambling["joinstats"] = { }; end
		if(not UltraGambling["chat"]) then UltraGambling["chat"] = 1; end
		if(not UltraGambling["channel"]) then UltraGambling["channel"] = "gambling"; end
		if(not UltraGambling["whispers"]) then UltraGambling["whispers"] = false; end
		if(not UltraGambling["bans"]) then UltraGambling["bans"] = { }; end

		UltraGambling_EditBox:SetText(""..UltraGambling["lastroll"]);

		chatmethod = chatmethods[UltraGambling["chat"]];
		UltraGambling_CHAT_Button:SetText(chatmethod);

		if UltraGambling["minimap"] then
			UG_MinimapButton:Show()
		else
			UG_MinimapButton:Hide()
		end

		if(UltraGambling["whispers"] == false) then
			whispermethod = false;
		else
			UltraGambling_WHISPER_Button:SetText("(Whispers)");
			whispermethod = true;
		end
		if(UltraGambling["active"] == 1) then
			UltraGambling_Frame:Show();
		else
			UltraGambling_Frame:Hide();
		end
	end

	-- Handle whisper commands
	if (event == "CHAT_MSG_WHISPER") then
		local msg, sender = arg1, arg2
		if msg and string.lower(msg):find("!stats") then
			ChatMsg("Work in Progress","WHISPER",nil,sender);
		end
	end

	-- IF IT'S A RAID MESSAGE... --
	if ((event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID") and AcceptOnes=="true" and UltraGambling["chat"] == 1) then
		local msg, sender = arg1, arg2
		UltraGambling_ParseChatMsg(msg, sender)
	end

	if (event == "CHAT_MSG_GUILD" and AcceptOnes=="true" and UltraGambling["chat"] == 2) then
		local msg, sender = arg1, arg2
		UltraGambling_ParseChatMsg(msg, sender)
	end

	if event == "CHAT_MSG_PARTY" and AcceptOnes=="true" and UltraGambling["chat"] == 3 then
		local msg, sender = arg1, arg2
		UltraGambling_ParseChatMsg(msg, sender)
	end

	if (event == "CHAT_MSG_SYSTEM" and AcceptRolls=="true") then
		local msg = arg1
		UltraGambling_ParseRoll(tostring(msg));
	end
end


function UltraGambling_ResetStats()
	UltraGambling["stats"] = { };
end

function Minimap_Toggle()
	if UltraGambling["minimap"] then
		UltraGambling["minimap"] = false
		UG_MinimapButton:Hide()
	else
		UltraGambling["minimap"] = true
		UG_MinimapButton:Show()
	end
end

function UltraGambling_OnClickCHAT()
	if(UltraGambling["chat"] == nil) then UltraGambling["chat"] = 1; end

	UltraGambling["chat"] = (UltraGambling["chat"] % getn(chatmethods)) + 1;

	chatmethod = chatmethods[UltraGambling["chat"]];
	UltraGambling_CHAT_Button:SetText(chatmethod);
end

function UltraGambling_OnClickWHISPERS()
	if(UltraGambling["whispers"] == nil) then UltraGambling["whispers"] = false; end

	UltraGambling["whispers"] = not UltraGambling["whispers"];

	if(UltraGambling["whispers"] == false) then
		UltraGambling_WHISPER_Button:SetText("(No Whispers)");
		whispermethod = false;
	else
		UltraGambling_WHISPER_Button:SetText("(Whispers)");
		whispermethod = true;
	end
end

function UltraGambling_ChangeChannel(channel)
	UltraGambling["channel"] = channel
	Print("", "", "Channel set to: "..channel)
end

function UltraGambling_JoinStats(msg)
	local i = string.find(msg, " ");
	if((not i) or i == -1 or string.find(msg, "[", 1, true) or string.find(msg, "]", 1, true)) then
		ChatFrame1:AddMessage("");
		return;
	end
	local mainname = string.sub(msg, 1, i-1);
	local altname = string.sub(msg, i+1);
	ChatFrame1:AddMessage(string.format("Joined alt '%s' -> main '%s'", altname, mainname));
	UltraGambling["joinstats"][altname] = mainname;
end

function UltraGambling_UnjoinStats(altname)
	if(altname ~= nil and altname ~= "") then
		ChatFrame1:AddMessage(string.format("Unjoined alt '%s' from any other characters", altname));
		UltraGambling["joinstats"][altname] = nil;
	else
		local i, e;
		for i, e in UltraGambling["joinstats"] do
			ChatFrame1:AddMessage(string.format("currently joined: alt '%s' -> main '%s'", i, e));
		end
	end
end

function UltraGambling_OnClickSTATS(full)
	local sortlistname = {};
	local sortlistamount = {};
	local n = 0;
	local i, j, k;

	for i, j in UltraGambling["stats"] do
		local name = i;
		if(UltraGambling["joinstats"][strlower(i)] ~= nil) then
			name = UltraGambling["joinstats"][strlower(i)];
			name = strupper(strsub(name,1,1))..strsub(name,2);
		end
		for k=0,n do
			if(k == n) then
				sortlistname[n] = name;
				sortlistamount[n] = j;
				n = n + 1;
				break;
			elseif(strlower(name) == strlower(sortlistname[k])) then
				sortlistamount[k] = (sortlistamount[k] or 0) + j;
				break;
			end
		end
	end

	if(n == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("No stats yet!");
		return;
	end

	for i = 0, n-1 do
		for j = i+1, n-1 do
			if(sortlistamount[j] > sortlistamount[i]) then
				sortlistamount[i], sortlistamount[j] = sortlistamount[j], sortlistamount[i];
				sortlistname[i], sortlistname[j] = sortlistname[j], sortlistname[i];
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("--- UltraGamble Stats ---", chatmethod);

	if full then
		for k = 0, getn(sortlistamount) do
			local sortsign = "won";
			if(sortlistamount[k] < 0) then sortsign = "lost"; end
			ChatMsg(string.format("%d.  %s %s %d total", k+1, sortlistname[k], sortsign, math.abs(sortlistamount[k])), chatmethod);
		end
		return
	end

	local x1 = 3-1;
	local x2 = n-3;
	if(x1 >= n) then x1 = n-1; end
	if(x2 <= x1) then x2 = x1+1; end

	for i = 0, x1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
	end

	if(x1+1 < x2) then
		ChatMsg("...", chatmethod);
	end

	for i = x2, n-1 do
		sortsign = "won";
		if(sortlistamount[i] < 0) then sortsign = "lost"; end
		ChatMsg(string.format("%d.  %s %s %d total", i+1, sortlistname[i], sortsign, math.abs(sortlistamount[i])), chatmethod);
	end
end


function UltraGambling_OnClickROLL()
	if (totalrolls > 0 and AcceptRolls == "true") then
		if getn(UltraGambling.strings) ~= 0 then
			UltraGambling_List();
		end
		return;
	end
	if (totalrolls >1) then
		AcceptOnes = "false";
		AcceptRolls = "true";
		if (tie == 0) then
			ChatMsg("Roll now!");
		end

		if (lowbreak == 1) then
			ChatMsg(format("%s%d%s", "Low end tiebreaker! Roll 1-", theMax, " now!"));
			UltraGambling_List();
		end

		if (highbreak == 1) then
			ChatMsg(format("%s%d%s", "High end tiebreaker! Roll 1-", theMax, " now!"));
			UltraGambling_List();
		end

		UltraGambling_EditBox:ClearFocus();

	end

	if (AcceptOnes == "true" and totalrolls <2) then
		ChatMsg("Not enough Players!");
	end
end

function UltraGambling_OnClickLASTCALL()
	ChatMsg("Last Call to join!");
	UltraGambling_EditBox:ClearFocus();
	UltraGambling_LASTCALL_Button:Disable();
	UltraGambling_ROLL_Button:Enable();
end

function UltraGambling_OnClickACCEPTONES()
	if UltraGambling_EditBox:GetText() ~= "" and UltraGambling_EditBox:GetText() ~= "1" then
		UltraGambling_Reset();
		UltraGambling_ROLL_Button:Disable();
		UltraGambling_LASTCALL_Button:Disable();
		AcceptOnes = "true";
		local fakeroll = "";
		ChatMsg(format("%s%s%s%s", ".:Welcome to UltraGamble:. User's Roll - (", UltraGambling_EditBox:GetText(), ") - Type 1 to Join  (-1 to withdraw)", fakeroll));
		UltraGambling["lastroll"] = UltraGambling_EditBox:GetText();
		theMax = tonumber(UltraGambling_EditBox:GetText());
		low = theMax+1;
		tielow = theMax+1;
		UltraGambling_EditBox:ClearFocus();
		UltraGambling_AcceptOnes_Button:SetText("New Game");
		UltraGambling_LASTCALL_Button:Disable();
		UltraGambling_EditBox:ClearFocus();
	else
		DEFAULT_CHAT_FRAME:AddMessage("Please enter a number to roll from.");
	end
end

function UltraGambling_OnClickRoll()
	RandomRoll(1, tonumber(UltraGambling_EditBox:GetText()) or 100)
end

function UltraGambling_OnClickRoll1()
	ChatMsg("1");
end

UG_Settings = {
	MinimapPos = 75
}

-- ** do not call from the mod's OnLoad, VARIABLES_LOADED or later is fine. **
function UG_MinimapButton_Reposition()
	UG_MinimapButton:SetPoint("TOPLEFT","Minimap","TOPLEFT",52-(80*cos(UG_Settings.MinimapPos)),(80*sin(UG_Settings.MinimapPos))-52)
end

function UG_MinimapButton_DraggingFrame_OnUpdate()
	local xpos,ypos = GetCursorPosition()
	local xmin,ymin = Minimap:GetLeft(), Minimap:GetBottom()

	xpos = xmin-xpos/UIParent:GetScale()+70
	ypos = ypos/UIParent:GetScale()-ymin-70

	UG_Settings.MinimapPos = math.deg(math.atan2(ypos,xpos))
	UG_MinimapButton_Reposition()
end

function UG_MinimapButton_OnClick()
	if UltraGambling["active"] == 1 then
		UltraGambling_Frame:Hide()
		UltraGambling["active"] = 0
	else
		UltraGambling_Frame:Show()
		UltraGambling["active"] = 1
	end
end

function UltraGambling_Report()
	local goldowed = high - low
	if (goldowed ~= 0) then
		lowname = strupper(strsub(lowname,1,1))..strsub(lowname,2);
		highname = strupper(strsub(highname,1,1))..strsub(highname,2);
		local string3 = strjoin(" ", "", lowname, "owes", highname, goldowed,"gold.")

		UltraGambling["stats"][highname] = (UltraGambling["stats"][highname] or 0) + goldowed;
		UltraGambling["stats"][lowname] = (UltraGambling["stats"][lowname] or 0) - goldowed;

		ChatMsg(string3);
	else
		ChatMsg("It was a tie! No payouts on this roll!");
	end
	UltraGambling_Reset();
	UltraGambling_AcceptOnes_Button:SetText("Open Entry");
	UltraGambling_CHAT_Button:Enable();
end

function UltraGambling_Tiebreaker()
	tierolls = 0;
	totalrolls = 0;
	tie = 1;
	if getn(UltraGambling.lowtie) == 1 then
		UltraGambling.lowtie = {};
	end
	if getn(UltraGambling.hightie) == 1 then
		UltraGambling.hightie = {};
	end
	totalrolls = getn(UltraGambling.lowtie) + getn(UltraGambling.hightie);
	tierolls = totalrolls;
	if (getn(UltraGambling.hightie) == 0 and getn(UltraGambling.lowtie) == 0) then
		UltraGambling_Report();
	else
		AcceptRolls = "false";
		if getn(UltraGambling.lowtie) > 0 then
			lowbreak = 1;
			highbreak = 0;
			tielow = theMax+1;
			tiehigh = 0;
			UltraGambling.strings = UltraGambling.lowtie;
			UltraGambling.lowtie = {};
			UltraGambling_OnClickROLL();
		end
		if getn(UltraGambling.hightie) > 0 and getn(UltraGambling.strings) == 0 then
			lowbreak = 0;
			highbreak = 1;
			tielow = theMax+1;
			tiehigh = 0;
			UltraGambling.strings = UltraGambling.hightie;
			UltraGambling.hightie = {};
			UltraGambling_OnClickROLL();
		end
	end
end

function UltraGambling_ParseRoll(temp2)
	local temp1 = strlower(temp2);

	local player, junk, roll, range = strsplit(" ", temp1);

	if junk == "rolls" and UltraGambling_Check(player)==1 then
		local minRoll, maxRoll = strsplit("-",range);
		minRoll = tonumber(strsub(minRoll,2));
		maxRoll = tonumber(strsub(maxRoll,1,-2));
		roll = tonumber(roll);
		if (maxRoll == theMax and minRoll == 1) then
			if (tie == 0) then
				if (roll == high) then
					if getn(UltraGambling.hightie) == 0 then
						UltraGambling_AddTie(highname, UltraGambling.hightie);
					end
					UltraGambling_AddTie(player, UltraGambling.hightie);
				end
				if (roll>high) then
					highname = player
					highplayername = player
					if (high == 0) then
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win a max of %sg", roll, (high - 1)),"WHISPER",nil,player);
						end
					else
						high = roll
						if (whispermethod) then
							ChatMsg(string.format("You have the HIGHEST roll so far: %s and you might win %sg from %s", roll, (high - low), lowplayername),"WHISPER",nil,player);
							ChatMsg(string.format("%s now has the HIGHEST roller so far: %s and you might owe him/her %sg", player, roll, (high - low)),"WHISPER",nil,lowplayername);
						end
					end
					UltraGambling.hightie = {};
				end
				if (roll == low) then
					if getn(UltraGambling.lowtie) == 0 then
						UltraGambling_AddTie(lowname, UltraGambling.lowtie);
					end
					UltraGambling_AddTie(player, UltraGambling.lowtie);
				end
				if (roll<low) then
					lowname = player
					lowplayername = player
					low = roll
					if (high ~= low) then
						if (whispermethod) then
							ChatMsg(string.format("You have the LOWEST roll so far: %s and you might owe %s %sg ", roll, highplayername, (high - low)),"WHISPER",nil,player);
						end
					end
					UltraGambling.lowtie = {};
				end
			else
				if (lowbreak == 1) then
					if (roll == tielow) then
						if getn(UltraGambling.lowtie) == 0 then
							UltraGambling_AddTie(lowname, UltraGambling.lowtie);
						end
						UltraGambling_AddTie(player, UltraGambling.lowtie);
					end
					if (roll<tielow) then
						lowname = player
						tielow = roll;
						UltraGambling.lowtie = {};
					end
				end
				if (highbreak == 1) then
					if (roll == tiehigh) then
						if getn(UltraGambling.hightie) == 0 then
							UltraGambling_AddTie(highname, UltraGambling.hightie);
						end
						UltraGambling_AddTie(player, UltraGambling.hightie);
					end
					if (roll>tiehigh) then
						highname = player
						tiehigh = roll;
						UltraGambling.hightie = {};
					end
				end
			end
			UltraGambling_Remove(tostring(player));
			totalentries = totalentries + 1;

			if getn(UltraGambling.strings) == 0 then
				if tierolls == 0 then
					UltraGambling_Report();
				else
					if totalentries == 2 then
						UltraGambling_Report();
					else
						UltraGambling_Tiebreaker();
					end
				end
			end
		end
	end
end

function UltraGambling_Check(player)
	for i=1, getn(UltraGambling.strings) do
		if strlower(UltraGambling.strings[i]) == tostring(player) then
			return 1
		end
	end
	return 0
end

function UltraGambling_List()
	for i=1, getn(UltraGambling.strings) do
		local string3 = strjoin(" ", "", strupper(strsub(tostring(UltraGambling.strings[i]),1,1))..strsub(tostring(UltraGambling.strings[i]),2),"still needs to roll.")
		ChatMsg(string3);
	end
end

function UltraGambling_ListBan()
	local bancnt = 0;
	Print("", "", "|cffffff00To ban do /ug ban (Name) or to unban /ug unban (Name) - The Current Bans:");
	for i=1, getn(UltraGambling.bans) do
		bancnt = 1;
		DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", "...", tostring(UltraGambling.bans[i])));
	end
	if (bancnt == 0) then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffff00To ban do /ug ban (Name) or to unban /ug unban (Name).");
	end
end

function UltraGambling_Add(name)
	local insname = strlower(name);
	if (insname ~= nil and insname ~= "") then
		local found = 0;
		for i=1, getn(UltraGambling.strings) do
			if UltraGambling.strings[i] == insname then
				found = 1;
			end
		end
		if found == 0 then
			table.insert(UltraGambling.strings, insname)
			totalrolls = totalrolls+1
		end
	end
end

function UltraGambling_ChkBan(name)
	local insname = strlower(name);
	if (insname ~= nil and insname ~= "") then
		for i=1, getn(UltraGambling.bans) do
			if strlower(UltraGambling.bans[i]) == strlower(insname) then
				return 1
			end
		end
	end
	return 0
end

function UltraGambling_AddBan(name)
	local insname = strlower(name);
	if (insname ~= nil and insname ~= "") then
		local banexist = 0;
		for i=1, getn(UltraGambling.bans) do
			if UltraGambling.bans[i] == insname then
				Print("", "", "|cffffff00Unable to add to ban list - user already banned.");
				banexist = 1;
			end
		end
		if (banexist == 0) then
			table.insert(UltraGambling.bans, insname)
			Print("", "", "|cffffff00User is now banned!");
			local string3 = strjoin(" ", "", "User Banned from rolling! -> ",insname, "!")
			DEFAULT_CHAT_FRAME:AddMessage(strjoin("|cffffff00", string3));
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function UltraGambling_RemoveBan(name)
	local insname = strlower(name);
	if (insname ~= nil and insname ~= "") then
		for i=1, getn(UltraGambling.bans) do
			if strlower(UltraGambling.bans[i]) == strlower(insname) then
				table.remove(UltraGambling.bans, i)
				Print("", "", "|cffffff00User removed from ban successfully.");
				return;
			end
		end
	else
		Print("", "", "|cffffff00Error: No name provided.");
	end
end

function UltraGambling_AddTie(name, tietable)
	local insname = strlower(name);
	if (insname ~= nil and insname ~= "") then
		local found = 0;
		for i=1, getn(tietable) do
			if tietable[i] == insname then
				found = 1;
			end
		end
		if found == 0 then
			table.insert(tietable, insname)
			tierolls = tierolls+1
			totalrolls = totalrolls+1
		end
	end
end

function UltraGambling_Remove(name)
	local insname = strlower(name);
	for i=1, getn(UltraGambling.strings) do
		if UltraGambling.strings[i] ~= nil then
			if strlower(UltraGambling.strings[i]) == strlower(insname) then
				table.remove(UltraGambling.strings, i)
				totalrolls = totalrolls - 1;
			end
		end
	end
end

function UltraGambling_RemoveTie(name, tietable)
	local insname = strlower(name);
	for i=1, getn(tietable) do
		if tietable[i] ~= nil then
			if strlower(tietable[i]) == insname then
				table.remove(tietable, i)
			end
		end
	end
end

function UltraGambling_Reset()
	UltraGambling["strings"] = { };
	UltraGambling["lowtie"] = { };
	UltraGambling["hightie"] = { };
	AcceptOnes = "false"
	AcceptRolls = "false"
	totalrolls = 0
	theMax = 0
	tierolls = 0;
	lowname = ""
	highname = ""
	low = theMax
	high = 0
	tie = 0
	highbreak = 0;
	lowbreak = 0;
	tiehigh = 0;
	tielow = 0;
	totalentries = 0;
	highplayername = "";
	lowplayername = "";
	UltraGambling_ROLL_Button:Disable();
	UltraGambling_AcceptOnes_Button:Enable();
	UltraGambling_LASTCALL_Button:Disable();
	UltraGambling_CHAT_Button:Enable();
	UltraGambling_AcceptOnes_Button:SetText("Open Entry");
	Print("", "", "|cffffff00UltraGamble has now been reset");
end

function UltraGambling_ResetCmd()
	ChatMsg(".:UltraGamble:. Game has been reset", chatmethod)
end

function UltraGambling_EditBox_OnLoad()
	UltraGambling_EditBox:SetAutoFocus(false);
end
