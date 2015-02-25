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
TinyAVC.urlbuttons = {};
TinyAVC.checked = false;
TinyAVC.content = nil;

--[[
TinyAVC.dump = function(o, lvl) -- {{{ Small function to dump an object.
	if lvl == nil then lvl = 0 end
	if lvl >= 10 then return "Stack overflow" end

	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. TinyAVC.dump(v, lvl + 1) .. ','
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

TinyAVCWindow = ISCollapsableWindow:derive("TinyAVCWindow"); -- {{{
function TinyAVCWindow:initialise() -- {{{
	ISCollapsableWindow.initialise(self);
end -- }}}
function TinyAVCWindow:createChildren() -- {{{
	ISCollapsableWindow.createChildren(self);

	self.headerMod = ISButton:new(1, 20, self.width*0.6-1, 20, "Mod");
	self:addChild(self.headerMod);

	self.headerCurVer = ISButton:new(self.width*0.6, 20, self.width*0.1, 20, "Current");
	self:addChild(self.headerCurVer);

	self.headerLastVer = ISButton:new(self.width*0.7, 20, self.width*0.1, 20, "Latest");
	self:addChild(self.headerLastVer);

	self.headerNeedPZVer = ISButton:new(self.width*0.8, 20, self.width*0.1, 20, "Need PZ");
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
end -- }}}
function TinyAVCWindow:render() -- {{{
	ISCollapsableWindow.render(self);
	if not TinyAVC.checked then return end

	local i = 0;
	for mod,_ in pairs(TinyAVC.mods) do
		local r = 1;
		local g = 1;
		local b = 1;
		local a = 1;
		if TinyAVC.mods[mod].url ~= nil then
			if TinyAVC.mods[mod].latestVersion ~= TinyAVC.mods[mod].version then
				r = 0;
				g = 1;
				b = 0;
			end
			self:drawText(                  mod,                          2, 42+i*15, r, g, b, a);
			self:drawText(TinyAVC.mods[mod].version,       self.width*0.6+2, 42+i*15, r, g, b, a);
			self:drawText(TinyAVC.mods[mod].latestVersion, self.width*0.7+2, 42+i*15, r, g, b, a);
			self:drawText(TinyAVC.mods[mod].minVersion,    self.width*0.8+2, 42+i*15, r, g, b, a);

			if TinyAVC.urlbuttons[i] == nil then
				urlButton = ISButton:new(self.width*0.9+1, 42+i*15, self.width*0.1-2, 15, "URL", self, ModSelector.onOptionMouseDown);
				urlButton.internal = "URL";
				urlButton:initialise();
				urlButton:instantiate();
				urlButton.borderColor = {r=1, g=1, b=1, a=1};
				urlButton:setFont(UIFont.Small);
				self:addChild(urlButton);
				TinyAVC.urlbuttons[i] = urlButton;
			end
			TinyAVC.urlbuttons[i].url = TinyAVC.mods[mod].srcUrl;
		else
			self:drawText(mod.." does not support Tiny AVC :-(",          2, 42+i*15, 1, 0, 0, 1);
		end
		i = i + 1;
	end
end -- }}}
function TinyAVCWindow:new (x, y, width, height) -- {{{
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.title = "Tiny Automated Version Checker";
	o.minimumWidth = 200;
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

	for k,v in pairs(TinyAVC.urlbuttons) do
		v:setX(self.width*0.9+1);
		v:setWidth(self.width*0.1-2);
	end
end -- }}}
-- }}}
TinyAVC.init = function() -- {{{
	TinyAVC.win = TinyAVCWindow:new(100,100,600,400);
	TinyAVC.win:initialise();
	TinyAVC.win:addToUIManager();
	TinyAVC.win:setVisible(false);

	-- Position the button next to the MODS label
	local x = MainScreen.instance.modsOption:getX();
	x = x + MainScreen.instance.modsOption:getWidth();
	x = x + 30;
	local y = MainScreen.instance.modsOption:getY();
	local w = 64;
	local h = MainScreen.instance.bottomPanel:getHeight() - y * 2;

	TinyAVC.checkNow = ISButton:new(x, y, w, h, "Check for updates", TinyAVC.win, TinyAVCWindow.checkForUpdate);
	MainScreen.instance.bottomPanel:addChild(TinyAVC.checkNow);
end
-- }}}
Events.OnMainMenuEnter.Add(TinyAVC.init);
