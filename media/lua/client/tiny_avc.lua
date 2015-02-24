require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"

TinyAVC = {};
TinyAVC.mods = {};
TinyAVC.mods.tiny_avc = {};
TinyAVC.mods.tiny_avc.url = "http://pzmap.crash-override.net/tiny_avc.txt";
TinyAVC.mods.tiny_avc.version = "0.0.1";

function split(inputstr, sep) -- {{{
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
dump = function(o) -- {{{ Small function to dump an object.
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end
-- }}}
pline = function (text) -- {{{ Print text to logfile
	print(tostring(text));
end
-- }}}
getUrl = function(url) -- {{{
	pline("Loading "..url);
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
	self.versionPanel = TinyAVCInfo:new(0, 16, self.width, self.height-16);
	self.versionPanel:initialise();
	self:addChild(self.versionPanel);
end -- }}}
function TinyAVCWindow:new (x, y, width, height) -- {{{
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	self.versionPanel = {};
	return o 
end -- }}} 
-- }}}

TinyAVCInfo = ISPanel:derive("TinyAVCInfo"); -- {{{
function TinyAVCInfo:initialise() -- {{{
  ISPanel.initialise(self);
end -- }}}
function TinyAVCInfo:createChildren()
	pline("createChildren");
	panel = ISRichTextPanel:new(5, 5, 580, 395);
	panel:instantiate();
	self:addChild(panel);
	self.descriptionPanel = panel;
end
function TinyAVCInfo:prerender() -- {{{
	if self.content ~= nil then return end;
	local list = getModDirectoryTable();
	local red = " <RGB:1,0,0> ";
	local green = " <RGB:0,1,0> ";
	local white = " <RGB:1,1,1> ";
	local line = " <LINE> ";
	-- pline("Mydocfolder: "..Core.getMyDocumentFolder());
	-- pline("Sep: "..File.separator);
	-- pline("List: "..dump(list));
	self.content = "";
	for _,mod in pairs(list) do
		local url = nil;
		local version = nil;
		local srcUrl = nil;
		local latestVersion = nil;
		local minVersion = nil;
		--[[{{{
		local f = getFileInput(".."..File.separator.."mods"..File.separator..mod..File.separator.."tiny_avc.txt");
		if f ~= nil then
			local line = f:readLine();
			while line ~= nil do
				pline(line);
				pline(dump(split(line, ":")));
				pline(dump(string.starts(line, "url:")));
				if string.starts(line, "version:") then
					local r = split(line, ":");
					version = r[2];
				end
				if string.starts(line, "url:") then
					local r = split(line, ":")
					url = r[2]..":"..r[3];
				end
				line = f:readLine();
			end
			f:close();
		else
			pline(Core.getMyDocumentFolder()..File.separator.."mods"..File.separator..mod..File.separator.."tiny_avc.txt doesn't exist!");
		end
		--}}}]]
		if TinyAVC.mods[mod] == nil then
			self.content = self.content..red.."Mod "..mod.." has no TinyAVC support!"..white..line;
		else
			url = TinyAVC.mods[mod].url;
			version = TinyAVC.mods[mod].version;
			pline("Version: "..dump(version).." URL: "..dump(url));
			if url ~= nil then
				local content = getUrl(url);
				--[[ Format is:
				--version:0.9.5
				--minVersion:30.16
				--url:http://theindiestone.com/forums/index.php/topic/10952-dirty-water-and-saltwater-get-sick-by-drinking-from-the-toilet-rain-barrel-collect-water-from-rivers/ 
				--]]
				for _,line in pairs(split(content, "\n")) do
					if string.starts(line, "version:") then
						local r = split(line, ":");
						latestVersion = r[2];
					end
					if string.starts(line, "minVersion") then
						local r = split(line, ":");
						minVersion = r[2];
					end
					if string.starts(line, "url:") then
						local r = split(line, ":");
						srcUrl = r[2]..":"..r[3];
					end
				end
			end
			if latestVersion ~= nil then
				if latestVersion ~= version then
					self.content = self.content..red.."Mod "..mod.." has a new version: "..latestVersion..line;
					self.content = self.content..red.."URL: "..url..line;
				else
					self.content = self.content..green.."Mod "..mod.." is the latest version: "..version..line;
				end
			else
				self.content = self.content..red.."Can't check Mod "..mod.." for new version :-("..line;
			end
		end
	end
end
-- }}}
function TinyAVCInfo:render() -- {{{
	self.descriptionPanel.text = self.content;
	self.descriptionPanel:paginate();
end -- }}}
function TinyAVCInfo:new (x, y, width, height) -- {{{
  local o = {}
  o = ISPanel:new(x, y, width, height);
  setmetatable(o, self)
	self.__index = self
	o.width = width;
	o.height = height;
  o.barrel = barrel;
	o.content = nil;
	return o
end -- }}}
-- }}}

TinyAVC.doCheck = function() -- {{{
	local win = TinyAVCWindow:new(100,200,600,400);
	win:initialise();
	win:addToUIManager();
end
-- }}}
Events.OnMainMenuEnter.Add(TinyAVC.doCheck);
