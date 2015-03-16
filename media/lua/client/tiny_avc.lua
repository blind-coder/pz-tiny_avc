require "OptionScreens/MainScreen"
require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"

function string.split(inputstr, sep) -- {{{
	if sep == nil then
		sep = "%s"
	end
	local t={} ; i=1
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end
-- }}}
function string.starts(String,Start) -- {{{
	return string.sub(String,1,string.len(Start))==Start
end
-- }}}

TinyAVC = {};
TinyAVC.mods = {};
TinyAVC.checked = false;
TinyAVC.content = nil;
TinyAVC.modPanels = {};
TinyAVC.lineHeight = getTextManager():MeasureStringY(UIFont.Small, "Mg");
--[[
TinyAVC.dump = function(o, lvl) -- {{{ Small function to dump an object.
	if lvl == nil then lvl = 0 end
	if lvl >= 10 then return "Stack overflow ("..tostring(o)..")" end

	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if k == "prev" or k == "next" then
				s = s .. '['..k..'] = '..tostring(v);
			else
				if type(k) ~= 'number' then k = '"'..k..'"' end
				s = s .. '['..k..'] = ' .. TinyAVC.dump(v, lvl + 1) .. ','
			end
		end
		return s .. '} '
	else
		return tostring(o)
	end
end
-- }}}
TinyAVC.pline = function (text) -- {{{ Print text to logfile
	print(tostring(text));
end
-- }}}
--]]

TinyAVC.getUrl = function(url) -- {{{
	local url = URL.new(url);
	local conn = url:openStream();
	local isr = DataInputStream.new(conn);
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
TinyAVC.versionHistory = { -- {{{
	["1"] = {
		order = 1,
		backwardsCompatible = false
	},
	["8"] = {
		order = 2,
		backwardsCompatible = false
	},
	["14"] = {
		order = 3,
		backwardsCompatible = false
	},
	["19"] = {
		order = 4,
		backwardsCompatible = false
	},
	["20"] = {
		order = 5,
		backwardsCompatible = false
	},
	["21"] = {
		order = 6,
		backwardsCompatible = false
	},
	["22"] = {
		order = 7,
		backwardsCompatible = false
	},
	["23"] = {
		order = 8,
		backwardsCompatible = false
	},
	["24"] = {
		order = 9,
		backwardsCompatible = false
	},
	["28"] = {
		order = 10,
		backwardsCompatible = false
	},
	["29.3"] = {
		order = 11,
		backwardsCompatible = false
	},
	["30.16"] = {
		order = 12,
		backwardsCompatible = false
	},
	["31"] = {
		order = 13,
		backwardsCompatible = true
	},
	["31.1"] = {
		order = 14,
		backwardsCompatible = true
	},
	["31.2"] = {
		order = 15,
		backwardsCompatible = true
	},
	["31.3"] = {
		order = 16,
		backwardsCompatible = true
	},
	["31.4"] = {
		order = 17,
		backwardsCompatible = true
	},
	["31.5"] = {
		order = 18,
		backwardsCompatible = true
	},
	["31.6"] = {
		order = 19,
		backwardsCompatible = true
	}
};
-- }}}
TinyAVC.sanitizeTISVersion = { -- {{{
	-- Somewhere up here is 2.9.9.6
	["2.9.9.17"]  =  "1", -- Build from around 2013-09-09, no idea where else to put this. Might also be 17d, idk.
	["17 (0008)"] =  "8", -- actually 2.9.9.17 Build 8
	["17 (0014)"] = "14", -- actually 2.9.9.17 Build 14
	["Build: 19"] = "19", -- actually 2.9.9.17 Build 19
	["17 (0020)"] = "20", -- actually 2.9.9.17 Build 20
	["2.9.9.17b"] = "21", -- just counting up from here on
	-- ["2.9.9.17"] -- this is actually 17d, but it didn't get the suffix. This means a collision with the first line in here.
	["2.9.9.17e"] = "22",
	["2.9.9.17e"] = "23",
	["2.9.9.17g (0007)"] = "24", -- 2.9.9.17 Build g Subbuild 0007 and ohlordpleasekillmenow.
	["Build 28"]  = "28",
	["Early Access v. 29.3"] = "29.3",
	["Early Access v. 30.16"] = "30.16",
	["Early Access v. 31"] = "31",
	["Early Access v. 31.1"] = "31.1",
	["Early Access v. 31.2"] = "31.2",
	["Early Access v. 31.3"] = "31.3",
	["Early Access v. 31.4"] = "31.4",
	["Early Access v. 31.5"] = "31.5",
	["Early Access v. 31.6"] = "31.6"
};
-- }}}
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

TinyAVCModPanel = ISPanel:derive("TinyAVCModPanel");
function TinyAVCModPanel:createChildren() -- {{{
	ISPanel.createChildren(self);
	self.urlButton = ISButton:new(self.width*0.9+1, 0, self.width*0.1-2, self:getHeight(), "URL", self, ModSelector.onOptionMouseDown);
	self.urlButton.internal = "URL";
	self.urlButton:initialise();
	self.urlButton:instantiate();
	self.urlButton:setFont(UIFont.Small);
	self:addChild(self.urlButton);
end
-- }}}
function TinyAVCModPanel:setWidth(newX) -- {{{
	if self:getWidth() == newX then return end;
	ISPanel.setWidth(self, newX);

	self.urlButton:setX(newX*0.9+1);
	self.urlButton:setWidth(newX*0.1-2);
end
-- }}}
function TinyAVCModPanel:setHeight(newY) -- {{{
	if self:getHeight() == newY then return end;

	local diff = newY - self:getHeight();
	ISPanel.setHeight(self, newY);
	self.urlButton:setHeight(newY);
	local ptr = self.next;
	while ptr do
		ptr:setY(ptr:getY()+diff);
		ptr = ptr.next;
	end
end
-- }}}
function TinyAVCModPanel:render() -- {{{
	self.background = self:isMouseOver();
	ISPanel.render(self);

	if self.modInfo.url ~= nil then
		local r = 1;
		local g = 1;
		local b = 1;
		local a = 1;
		if self.modInfo.latestVersion ~= self.modInfo.version then
			r = 0;
			g = 1;
			b = 0;
		end

		self:drawText(self.modInfo.name,                         2, 2, r, g, b, a);
		self:drawText(self.modInfo.version,       self.width*0.6+2, 2, r, g, b, a);
		self:drawText(self.modInfo.latestVersion, self.width*0.7+2, 2, r, g, b, a);
		self:drawText(self.modInfo.minVersion,    self.width*0.8+2, 2, r, g, b, a);

		self.urlButton.url = self.modInfo.srcUrl;

		local line2 = nil;
		local line3 = nil;
		if TinyAVC.isNewerVersion(getCore():getVersionNumber(), self.modInfo.minVersion) then
			line2 = "You must update PZ to at least version "..self.modInfo.minVersion.." to use this mod!";
			if not TinyAVC.versionIsCompatible(getCore():getVersionNumber(), self.modInfo.minVersion) then
				line3 = "Version "..getCore():getVersionNumber().." is not compatible to "..self.modInfo.minVersion.."! Expect breakage!";
			end
		elseif TinyAVC.isOlderVersion(getCore():getVersionNumber(), self.modInfo.minVersion) then
			line2 = "This mod was built for PZ version "..self.modInfo.minVersion.."!";
			if not TinyAVC.versionIsCompatible(self.modInfo.minVersion, getCore():getVersionNumber()) then
				line3 = "Version "..getCore():getVersionNumber().." is not compatible to "..self.modInfo.minVersion.."! Expect breakage!";
			end
		end
		if line2 ~= nil then
			self:drawText(line2, 22, 2 + TinyAVC.lineHeight + 2, r, g, b, a);
		end
		if line3 ~= nil then
			self:setHeight(2 + TinyAVC.lineHeight + 2 + TinyAVC.lineHeight + 2 + TinyAVC.lineHeight + 2);
			self:drawText(line3, 22, 2 + TinyAVC.lineHeight + 2 + TinyAVC.lineHeight + 2, r, g, b, a);
		end
	else
		self:drawText(self.modInfo.name.." does not support Tiny AVC :-(", 2, 2, 1, 0, 0, 1);
	end
end
-- }}}
function TinyAVCModPanel:new(x, y, w, h, modInfo) -- {{{
	local o = {};
	o = ISPanel:new(x, y, w, h);
	setmetatable(o, self)
	self.__index = self
	o.modInfo = modInfo;
	o.background = true;
	o.backgroundColor = {r=0.5, g=0.5, b=0.5, a=1};
	o.borderColor = {r=0.4, g=0.4, b=0.4, a=1};
	return o;
end
-- }}}

TinyAVCWindow = ISCollapsableWindow:derive("TinyAVCWindow");
function TinyAVCWindow:initialise() -- {{{
	ISCollapsableWindow.initialise(self);
end -- }}}
function TinyAVCWindow:createChildren() -- {{{
	ISCollapsableWindow.createChildren(self);

	self.headerMod = ISButton:new(1, 17, self.width*0.6-1, 20, "Mod");
	self:addChild(self.headerMod);

	self.headerCurVer = ISButton:new(self.width*0.6, 17, self.width*0.1, 20, "Current");
	self:addChild(self.headerCurVer);

	self.headerLastVer = ISButton:new(self.width*0.7, 17, self.width*0.1, 20, "Latest");
	self:addChild(self.headerLastVer);

	self.headerNeedPZVer = ISButton:new(self.width*0.8, 17, self.width*0.1, 20, "Need PZ");
	self:addChild(self.headerNeedPZVer);
end -- }}}
function TinyAVCWindow:downloadUpdates() -- {{{
	if TinyAVC.checked then return end;
	TinyAVC.checked = true;
	TinyAVC.content = "";
	local list = getModDirectoryTable();
	for _,mod in pairs(list) do
		TinyAVC.mods[mod] = {};
		local f = getFileInput(".."..File.separator.."mods"..File.separator..mod..File.separator.."tiny_avc.txt");
		if f ~= nil then
			local line = f:readLine();
			while line ~= nil do
				if string.starts(line, "version:") then
					local r = string.split(line, ":");
					TinyAVC.mods[mod].version = r[2];
				end
				if string.starts(line, "url:") then
					local r = string.split(line, ":")
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
			for _,line in pairs(string.split(content, "\n")) do
				if string.starts(line, "version:") then
					local r = string.split(line, ":");
					TinyAVC.mods[mod].latestVersion = r[2];
				end
				if string.starts(line, "minVersion:") then
					local r = string.split(line, ":");
					TinyAVC.mods[mod].minVersion = r[2];
				end
				if string.starts(line, "url:") then
					local r = string.split(line, ":");
					TinyAVC.mods[mod].srcUrl = r[2]..":"..r[3];
				end
			end
		end
	end
end
-- }}}
function TinyAVCWindow:checkForUpdate() -- {{{
	self:setVisible(true);
	self:downloadUpdates();
	local y = self.headerMod:getY()+self.headerMod:getHeight();
	local lastPanel = nil;

	for modName,mod in pairs(TinyAVC.mods) do
		mod.name = modName;
		modPanel = TinyAVCModPanel:new(0, y, self:getWidth(), 2 + TinyAVC.lineHeight + 2 + TinyAVC.lineHeight + 2, mod);
		self:addChild(modPanel);
		TinyAVC.modPanels[modPanel.ID] = modPanel;
		modPanel.prev = lastPanel;
		if lastPanel ~= nil then
			lastPanel.next = modPanel;
		end
		lastPanel = modPanel;
		y = y + modPanel:getHeight();
	end

	self.minimumHeight = y+15;
end -- }}}
function TinyAVCWindow:new (x, y, width, height) -- {{{
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.title = "Tiny Automated Version Checker";
	o.minimumWidth = 500;
	o.minimumHeight = 100;
	return o
end -- }}}
function TinyAVCWindow:onResize() -- {{{
	ISCollapsableWindow.onResize(self);
	self.headerMod:setWidth(self.width*0.6-1);
	self.headerCurVer:setX(self.width*0.6);
	self.headerCurVer:setWidth(self.width*0.1);
	self.headerLastVer:setX(self.width*0.7);
	self.headerLastVer:setWidth(self.width*0.1);
	self.headerNeedPZVer:setX(self.width*0.8);
	self.headerNeedPZVer:setWidth(self.width*0.1);

	for _,child in pairs(TinyAVC.modPanels) do
		child:setWidth(self.width);
	end
end
-- }}}

TinyAVC.init = function() -- {{{
	TinyAVC.win = TinyAVCWindow:new(100,100,600,400);
	TinyAVC.win:initialise();
	TinyAVC.win:setVisible(false);
	MainScreen.instance:addChild(TinyAVC.win);

	-- Position the button next to the Get Mods button
	local x = MainScreen.instance.modSelect.getModButton:getX();
	x       = x + MainScreen.instance.modSelect.getModButton:getWidth();
	x       = x + 10;
	local y = MainScreen.instance.modSelect.getModButton:getY();
	local w = MainScreen.instance.modSelect.getModButton:getWidth();
	local h = MainScreen.instance.modSelect.getModButton:getHeight();

	TinyAVC.checkNow = ISButton:new(x, y, w, h, "Check for updates", TinyAVC.win, TinyAVCWindow.checkForUpdate);
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
