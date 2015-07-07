require "OptionScreens/MainScreen"
require "ISUI/ISButton"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
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
---[[
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
	print("TINY_AVC: Downloading "..url);
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
TinyAVC.versionHistory = { -- {{{
--[[
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
	},
	["31.7"] = {
		order = 20,
		backwardsCompatible = true
	},
	["31.8"] = {
		order = 21,
		backwardsCompatible = true
	},
	["31.9"] = {
		order = 22,
		backwardsCompatible = true
	},
	["31.10"] = {
		order = 23,
		backwardsCompatible = true
	},
	["31.11"] = {
		order = 24,
		backwardsCompatible = true
	},
	["31.12"] = {
		order = 25,
		backwardsCompatible = true
	},
	["31.13"] = {
		order = 26,
		backwardsCompatible = true
	},
	["32.1"] = {
		order = 27,
		backwardsCompatible = false
	},
	["32.2"] = {
		order = 28,
		backwardsCompatible = true
	},
	["32.3"] = {
		order = 29,
		backwardsCompatible = true
	},
	["32.4"] = {
		order = 30,
		backwardsCompatible = true
	},
	["32.5"] = {
		order = 31,
		backwardsCompatible = true
	},
	["32.6"] = {
		order = 32,
		backwardsCompatible = true
	},
	["32.7"] = {
		order = 33,
		backwardsCompatible = true
	}
--]]
};
-- }}}
TinyAVC.sanitizeTISVersion = { -- {{{
--[[
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
	["Early Access v. 31.6"] = "31.6",
	["Early Access v. 31.7"] = "31.7",
	["Early Access v. 31.8"] = "31.8",
	["Early Access v. 31.9"] = "31.9",
	["Early Access v. 31.10"] = "31.10",
	["Early Access v. 31.11"] = "31.11",
	["Early Access v. 31.12"] = "31.12",
	["Early Access v. 31.13"] = "31.13",
	["Early Access v. 32.1"] = "32.1",
	["Early Access v. 32.2"] = "32.2",
	["Early Access v. 32.3"] = "32.3",
	["Early Access v. 32.4"] = "32.4",
	["Early Access v. 32.5"] = "32.5",
	["Early Access v. 32.6"] = "32.6",
	["Early Access v. 32.7"] = "32.7"
--]]
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

TinyAVCWindow = ISCollapsableWindow:derive("TinyAVCWindow");
function TinyAVC.ScrollingListBoxPreRender(self) -- {{{
	self:drawRect(0, -self:getYScroll(), self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	if self.drawBorder then
		self:drawRectBorder(0, -self:getYScroll(), self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
	end

	local y = 0;
	local alt = false;
	if self.items == nil then
		return;
	end

	if self.selected ~= -1 and self.selected < 1 then
		self.selected = 1
	elseif self.selected ~= -1 and self.selected > #self.items then
		self.selected = #self.items
	end

	local altBg = self.altBgColor

	local i = 1;
	for k, v in ipairs(self.items) do
		if not v.height then v.height = self.itemheight end -- compatibililty

		if alt and altBg then
			self:drawRect(0, y, self:getWidth(), v.height-1, altBg.r, altBg.g, altBg.b, altBg.a);
		else

		end
		v.index = i;
		local y2 = self:doDrawItem(y, v, alt);
		v.height = y2 - y
		y = y2

		alt = not alt;
		i = i + 1;
	end

	self:setScrollHeight((y));

	self:updateSmoothScrolling()
	self:updateTooltip()
end
-- }}}
function TinyAVCWindow:doDrawItem(y, item, alt) -- {{{
	item = item.item;

	y = y + 4;

	self:drawRectBorder(4, y, self:getWidth() - (4 + self.vscroll:getWidth()), 64, 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b);

	local x = 8;
	if item.url ~= nil then
		local r, g, b, a = 1, 1, 1, 1;
		if item.latestVersion ~= item.version then
			self:drawText(item.name,                         x, 2 + y,   r, 0.6, 0.0, a);
			self:drawText(item.version,       self.width*0.6+x, 2 + y,   r, 0.6, 0.0, a);
			self:drawText(item.latestVersion, self.width*0.7+x, 2 + y, 0.0,   g, 0.0, a);
		else
			self:drawText(item.name,                         x, 2 + y, r, g, b, a);
			self:drawText(item.version,       self.width*0.6+x, 2 + y, r, g, b, a);
			self:drawText(item.latestVersion, self.width*0.7+x, 2 + y, r, g, b, a);
		end
		self:drawText(item.minVersion,    self.width*0.8+x, 2+y, r, g, b, a);

		local line2 = nil;
		local line3 = nil;
		if TinyAVC.isNewerVersion(getCore():getVersionNumber(), item.minVersion) then
			line2 = "You must update PZ to at least version "..item.minVersion.." to use this mod!";
			if not TinyAVC.versionIsCompatible(getCore():getVersionNumber(), item.minVersion) then
				line3 = "Version "..getCore():getVersionNumber().." is not compatible to "..item.minVersion.."! Expect breakage!";
			end
		elseif TinyAVC.isOlderVersion(getCore():getVersionNumber(), item.minVersion) then
			line2 = "This mod was built for PZ version "..item.minVersion.."!";
			if not TinyAVC.versionIsCompatible(item.minVersion, getCore():getVersionNumber()) then
				line3 = "Version "..getCore():getVersionNumber().." is not compatible to "..item.minVersion.."! Expect breakage!";
			end
		end
		if line2 ~= nil then
			self:drawText(line2, 20+x, 2 + TinyAVC.lineHeight + 2 + y, r, g, b, a);
		end
		if line3 ~= nil then
			self:drawText(line3, 20+x, 2 + TinyAVC.lineHeight + 2 + TinyAVC.lineHeight + 2 + y, r, g, b, a);
		end

		if item.urlButton ~= nil then
			item.urlButton:setY(self:getYScroll()+y);
		else
			local x = self:getWidth() - (self.vscroll:getWidth());
			x = x - 62;
			item.urlButton = ISButton:new(x, self:getYScroll()+y, 62, 62, "URL", item, ModSelector.onOptionMouseDown);
			item.urlButton.internal = "URL";
			item.urlButton.url = item.srcUrl;
			item.urlButton:initialise();
			item.urlButton:instantiate();
			item.urlButton:setFont(UIFont.Small);
			self.parent:addChild(item.urlButton);
		end
		-- item.urlButton:prerender();
		-- item.urlButton:render();
	else
		self:drawText(item.name.." does not support Tiny AVC :-(", x, 2 + y, 1, 0, 0, 1);
	end

	return y + 64;
end
-- }}}
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

	self.bounds = ISPanel:new(1, 37, self.width-2, self.height-37);
	self.bounds.prerender = function(self)
		self:setStencilRect(0,0,self.width+1, self.height);
		ISPanel.prerender(self);
	end
	self.bounds.render = function(self)
		ISPanel.render(self);
		self:clearStencilRect();
	end
	self:addChild(self.bounds);

	self.contentBox = ISScrollingListBox:new(0, 0, self.bounds.width, self.bounds.height);
	self.contentBox.itemheight = 64;
	self.contentBox.drawBorder = true;
	self.contentBox.doDrawItem = TinyAVCWindow.doDrawItem;
	self.contentBox.parent = self;
	self.contentBox:initialise();
	self.contentBox:instantiate();
	self.contentBox:setAnchorLeft(true);
	self.contentBox:setAnchorRight(true);
	self.contentBox:setAnchorTop(true);
	self.contentBox:setAnchorBottom(true);
	self.contentBox.parent = self.bounds;
	self.contentBox.prerender = TinyAVC.ScrollingListBoxPreRender;
	self.bounds:addChild(self.contentBox);
end -- }}}

local TAG_VERSION     = "modversion=";
local TAG_PZ_VERSION  = "pzversion=";
local TAG_VERSION_URL = "versionurl=";
local TAG_MOD_URL     = "modurl=";
local TAG_DELIMITER   = "=";

-- @deprecated Will be removed in future versions.
local function assureBackwardsCompatibility(mod)
	TinyAVC.checked = true;
	TinyAVC.content = "";
	local list = getModDirectoryTable();
	for _,mod in pairs(list) do
		TinyAVC.mods[mod] = {};
		local f = getFileInput("..".."/".."mods".."/"..mod.."/".."tiny_avc.txt");
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

function TinyAVCWindow:downloadUpdates() -- {{{
	if TinyAVC.checked then return end;

	local content = TinyAVC.getUrl("https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/versionHistory.txt");
	for _,line in pairs(string.split(content, "\n")) do
		if not luautils.stringStarts(line, "#") then
			local t = string.split(line, ";");
			TinyAVC.versionHistory[t[1]] = { order = t[2], backwardsCompatible = (t[3] == "true") };
		end
	end

	content = TinyAVC.getUrl("https://raw.githubusercontent.com/blind-coder/pz-tiny_avc/master/sanitizeVersion.txt");
	for _,line in pairs(string.split(content, "\n")) do
		local t = string.split(line, ";");
		TinyAVC.sanitizeTISVersion[t[1]] = t[2];
	end

	TinyAVC.checked = true;
	TinyAVC.content = "";
	local list = getModDirectoryTable();
	for _, mod in pairs(list) do
		TinyAVC.mods[mod] = {};
		local file = getFileInput("..".."/".."mods".."/"..mod.."/".."mod.info");
		if file then
			while true do
				local line = file:readLine();
				if not line then
					file:close();
					break;
				end
				if string.starts(line, TAG_VERSION) then
					local snippet = string.split(line, TAG_DELIMITER);
					TinyAVC.mods[mod].version = snippet[2];
				elseif string.starts(line, TAG_VERSION_URL) then
					local snippet = string.split(line, TAG_DELIMITER)
					TinyAVC.mods[mod].url = snippet[2];
				end
			end
		end

		if TinyAVC.mods[mod].url then
			TinyAVC.mods[mod].latestVersion = "ERR";
			TinyAVC.mods[mod].minVersion = "ERR";
			TinyAVC.mods[mod].srcUrl = "ERR";

			local content = TinyAVC.getUrl(TinyAVC.mods[mod].url);
			for _, line in pairs(string.split(content, "\n")) do
				if string.starts(line, TAG_VERSION) then
					local snippet = string.split(line, TAG_DELIMITER);
					TinyAVC.mods[mod].latestVersion = snippet[2];
				elseif string.starts(line, TAG_PZ_VERSION) then
					local snippet = string.split(line, TAG_DELIMITER);
					TinyAVC.mods[mod].minVersion = snippet[2];
				elseif string.starts(line, TAG_MOD_URL) then
					local snippet = string.split(line, TAG_DELIMITER);
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
function TinyAVCWindow:checkForUpdate() -- {{{
	self:setVisible(true);
	self:downloadUpdates();
	ModSelector.instance.listbox:setVisible(false);

	for modName,mod in pairs(TinyAVC.mods) do
		mod.name = modName;
		self.contentBox:addItem(modName, mod);
	end
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
function TinyAVCWindow:onMouseDown(x, y) -- {{{
	self:bringToTop();
end
-- }}}
function TinyAVCWindow:close() -- {{{
	ISCollapsableWindow.close(self);
	ModSelector.instance.listbox:setVisible(true);
end
-- }}}

TinyAVC.init = function() -- {{{
	TinyAVC.win = TinyAVCWindow:new(ModSelector.instance.listbox:getX(), ModSelector.instance.listbox:getY(), ModSelector.instance.listbox:getWidth(), ModSelector.instance.listbox:getHeight());
	TinyAVC.win:initialise();
	TinyAVC.win:setVisible(false);
	ModSelector.instance:addChild(TinyAVC.win);

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
