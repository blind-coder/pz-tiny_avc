require "OptionScreens/MainScreen"
require "OptionScreens/ModSelector"
require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISPanel"
require "luautils";

TinyAVC = {};
TinyAVC.mods = {};
TinyAVC.lineHeight = getTextManager():MeasureStringY(UIFont.Small, "Mg");
TinyAVC.TAG_VERSION     = "modversion=";
TinyAVC.TAG_PZ_VERSION  = "pzversion=";
TinyAVC.TAG_VERSION_URL = "versionurl=";
TinyAVC.TAG_MOD_URL     = "modurl=";
TinyAVC.TAG_DELIMITER   = "=";

TinyAVC.getUrl = function(url) -- {{{
	local isr = getUrlInputStream(url);
	if not isr then return "" end;

	local content = "";
	local line = isr:readLine();
	while line ~= nil do
		content = content.."\n"..line;
		line = isr:readLine();
	end
	isr:close();

	return content;
end
-- }}}
TinyAVC.versionHistory = {};
TinyAVC.sanitizeTISVersion = {};
TinyAVC.sanitizeVersion = function(ver) -- {{{
	if TinyAVC.sanitizeTISVersion[ver] ~= nil then
		ver = TinyAVC.sanitizeTISVersion[ver];
	end
	return ver;
end -- }}}
TinyAVC.isNewerVersion = function(old, new) -- {{{
	old = TinyAVC.sanitizeVersion(old);
	new = TinyAVC.sanitizeVersion(new);
	local oldV = TinyAVC.versionHistory[old];
	local newV = TinyAVC.versionHistory[new];

	if oldV == nil or newV == nil then
		return true; -- if we don't know the version, it's probably newer than this mod.
	end
	return oldV.order < newV.order;
end -- }}}
TinyAVC.isOlderVersion = function(old, new) -- {{{
	old = TinyAVC.sanitizeVersion(old);
	new = TinyAVC.sanitizeVersion(new);
	local oldV = TinyAVC.versionHistory[old];
	local newV = TinyAVC.versionHistory[new];

	if oldV == nil or newV == nil then
		return false; -- if we don't know the version, it's probably not older than this mod.
	end
	return oldV.order > newV.order;
end -- }}}
TinyAVC.versionIsCompatible = function(old, new) -- {{{
	old = TinyAVC.sanitizeVersion(old);
	new = TinyAVC.sanitizeVersion(new);
	local inBetween = false;
	local foundOld = false;
	local foundNew = false;
	for k,v in pairs(TinyAVC.versionHistory) do
		if inBetween then
			if not v.backwardsCompatible then
				return false;
			end
		end
		if k == old then
			inBetween = true;
			foundOld = true;
		end
		if k == new then
			inBetween = false;
			foundNew = true;
		end
	end
	if not (foundOld and foundNew) then
		return false; -- at least one version was not found, err on the side of caution.
	end
	return true;
end -- }}}

-- @deprecated Will be removed in future versions.
local function assureBackwardsCompatibility(mod) -- {{{
	TinyAVC.mods[mod] = {};
	local f = getFileInput("..".."/".."mods".."/"..mod.."/".."tiny_avc.txt");
	if f ~= nil then
		local line = f:readLine();
		while line ~= nil do
			if luautils.stringStarts(line, "version:") then
				local r = luautils.split(line, ":");
				TinyAVC.mods[mod].version = r[2];
			end
			if luautils.stringStarts(line, "url:") then
				local r = luautils.split(line, ":")
				TinyAVC.mods[mod].url = r[2]..":"..r[3];
			end
			line = f:readLine();
		end
		f:close();
	end

	if TinyAVC.mods[mod].url ~= nil then
		TinyAVC.mods[mod].latestVersion = "ERR";
		TinyAVC.mods[mod].minVersion = "ERR";
		TinyAVC.mods[mod].srcUrl = "ERR";
		local content = TinyAVC.getUrl(TinyAVC.mods[mod].url);
		--[[ Format is:
		--version:0.9.5
		--minVersion:30.16
		--url:http://theindiestone.com/forums/index.php/topic/10952-dirty-water-and-saltwater-get-sick-by-drinking-from-the-toilet-rain-barrel-collect-water-from-rivers/
		--]]
		for _,line in pairs(luautils.split(content, "\n")) do
			if luautils.stringStarts(line, "version:") then
				local r = luautils.split(line, ":");
				TinyAVC.mods[mod].latestVersion = r[2];
			end
			if luautils.stringStarts(line, "minVersion:") then
				local r = luautils.split(line, ":");
				TinyAVC.mods[mod].minVersion = r[2];
			end
			if luautils.stringStarts(line, "url:") then
				local r = luautils.split(line, ":");
				TinyAVC.mods[mod].srcUrl = r[2]..":"..r[3];
			end
		end
	end
end
-- }}}

function TinyAVC.downloadUpdates() -- {{{
	local content = TinyAVC.getUrl("https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/versionHistory.txt");
	for _,line in pairs(luautils.split(content, "\n")) do
		if not luautils.stringStarts(line, "#") then
			local t = luautils.split(line, ";");
			TinyAVC.versionHistory[t[1]] = { order = t[2], backwardsCompatible = (t[3] == "true") };
		end
	end

	content = TinyAVC.getUrl("https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/sanitizeVersion.txt");
	for _,line in pairs(luautils.split(content, "\n")) do
		local t = luautils.split(line, ";");
		TinyAVC.sanitizeTISVersion[t[1]] = t[2];
	end

	local list = getModDirectoryTable();
	for _, mod in pairs(list) do
		local modInfo = getModInfo(mod);
		mod = modInfo:getId();
		TinyAVC.mods[mod] = {};
		local file = getModFileReader(mod, "mod.info", false);
		if file then
			while true do
				local line = file:readLine();
				if not line then
					file:close();
					break;
				end
				if luautils.stringStarts(line, TinyAVC.TAG_VERSION) then
					local snippet = luautils.split(line, TinyAVC.TAG_DELIMITER);
					TinyAVC.mods[mod].version = snippet[2];
				elseif luautils.stringStarts(line, TinyAVC.TAG_VERSION_URL) then
					local snippet = luautils.split(line, TinyAVC.TAG_DELIMITER)
					TinyAVC.mods[mod].url = snippet[2];
				end
			end
		end

		if TinyAVC.mods[mod].url then
			TinyAVC.mods[mod].latestVersion = "ERR";
			TinyAVC.mods[mod].minVersion = "ERR";
			TinyAVC.mods[mod].srcUrl = "ERR";

			local content = TinyAVC.getUrl(TinyAVC.mods[mod].url);
			for _, line in pairs(luautils.split(content, "\n")) do
				if luautils.stringStarts(line, TinyAVC.TAG_VERSION) then
					local snippet = luautils.split(line, TinyAVC.TAG_DELIMITER);
					TinyAVC.mods[mod].latestVersion = snippet[2];
				elseif luautils.stringStarts(line, TinyAVC.TAG_PZ_VERSION) then
					local snippet = luautils.split(line, TinyAVC.TAG_DELIMITER);
					TinyAVC.mods[mod].minVersion = snippet[2];
				elseif luautils.stringStarts(line, TinyAVC.TAG_MOD_URL) then
					local snippet = luautils.split(line, TinyAVC.TAG_DELIMITER);
					TinyAVC.mods[mod].srcUrl = snippet[2];
				end
			end

		else
			-- @deprecated Will be removed in future versions.
			assureBackwardsCompatibility(mod);
		end
	end
end
-- }}}
function TinyAVC.checkForUpdate() -- {{{
	TinyAVC.downloadUpdates();

	for i,k in ipairs(ModSelector.instance.listbox.items) do
		local mod = luautils.split(k.text, "/");
		mod = mod[#mod];
		local modInfo = TinyAVC.mods[mod];
		local addText = " <LINE> <LINE> ";
		if modInfo.url == nil then
			addText = addText .. getText('UI_TinyAVC_Not_Supported');
		else
			addText = addText .. string.format(getText('UI_TinyAVC_Current_Version'), modInfo.version);
			if modInfo.latestVersion == modInfo.version then
				addText = addText .. getText('UI_TinyAVC_Up_To_Date');
			else
				addText = addText .. string.format(getText('UI_TinyAVC_Update_Available'), modInfo.latestVersion);
				if modInfo.minVersion ~= nil then
					if TinyAVC.isNewerVersion(getCore():getVersionNumber(), modInfo.minVersion) then
						addText = addText .. string.format(getText('UI_TinyAVC_PZ_Newer'), modInfo.minVersion);
					elseif TinyAVC.isOlderVersion(getCore():getVersionNumber(), modInfo.minVersion) then
						addText = addText .. string.format(getText('UI_TinyAVC_PZ_Older'), modInfo.minVersion);
					end
					if not TinyAVC.versionIsCompatible(modInfo.minVersion, getCore():getVersionNumber()) then
						addText = addText .. string.format(getText('UI_TinyAVC_Not_Compatible'), getCore():getVersionNumber(), modInfo.minVersion);
					end
				end
			end
		end

		local text = k.item.modInfo:getDescription();
		k.item.richText:setText(text .. addText);
		k.item.richText:paginate();
	end
end -- }}}

TinyAVC.init = function() -- {{{
	-- Position the button next to the Get Mods button
	local x = MainScreen.instance.modSelect.getModButton:getX();
	local y = MainScreen.instance.modSelect.getModButton:getY();
	local w = MainScreen.instance.modSelect.getModButton:getWidth();
	local h = MainScreen.instance.modSelect.getModButton:getHeight();
	x       = x - w;
	x       = x - 10;

	TinyAVC.checkNow = ISButton:new(x, y, w, h, getText('UI_TinyAVC_Button_Text'), nil, TinyAVC.checkForUpdate);
	TinyAVC.checkNow.borderColor = {r=1, g=1, b=1, a=0.1};
	TinyAVC.checkNow:ignoreWidthChange();
	TinyAVC.checkNow:ignoreHeightChange();
	TinyAVC.checkNow:setAnchorLeft(true);
	TinyAVC.checkNow:setAnchorRight(false);
	TinyAVC.checkNow:setAnchorTop(false);
	TinyAVC.checkNow:setAnchorBottom(true);

	MainScreen.instance.modSelect:addChild(TinyAVC.checkNow);
end
-- }}}
Events.OnMainMenuEnter.Add(TinyAVC.init);
