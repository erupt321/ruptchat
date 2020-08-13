_addon.author = 'Erupt'
_addon.commands = {'rchat'}
_addon.name = 'RuptChat'
_addon.version = '0.7.081220.1'
--[[

This was originally written as just a text box replacement for tells and checking the
chatlog without using sandbox if your multiboxing.  After coding a majority of it I expanded
to a bigger chat system replacement.  Still a work in progress making style patterns
for the text.


===Issues===

**If mouse input lags, enable hardware mouse in windower settings.

**Timestamps could possibly cause some false reads on filters, do recommend you turn it off.

**If you load this addon while battlemod is loaded you'll need to reload if you unload battlemod after.

============

Console Commands 

//rchat save (Force a chatlog save)

//rchat find <search terms> (Search current selected tab for search terms

//rchat mentions (Shows mention phrases you have saved for tabs)

//rchat addmention <tab> <phrase> (Add mention phrase for tab)

//rchat delmention <tab> <phrase> (Remove mention phrase for tab)

//rchat hide (Hide's text box from showing)

//rchat show (Show hidden text box)

//rchat drag (Disable Draggable boxes; requested option)

//rchat alpha <0-255> (Change background transparency)

//rchat size <font size> (Change font size, this will increase whole window size)

//rchat font <font name> (Change font, some fonts that are grossly different sizes will affect clickables)

//rchat stroke_alpha <0-255> (Change text stroke transparency)

//rchat stroke_width <0-10> (Change stroke size)

//rchat stroke_color <#r> <#g> <#b>  (Change stroke color)

//rchat size <font size> (Change font size, this will increase whole window size)

//rchat size <font size> (Change font size, this will increase whole window size)

//rchat length <Log Length> (Change log length size)

//rchat dlength <Undocked Length> (Same as Log Length, if set to 0 will use Log_Length settings)

//rchat width <Log Width>  (Change log width size; when wordwrap should take effect)

//rchat dwidth <Undocked Width> (Same as Log Width, if set to 0 will use Log_Width settings)

//rchat strict_width (Toggle maintaining the max log width; avoid box shrinking and expanding)

//rchat strict_length (Toggle maintaining the log length)

//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)
You may also hold down the Alt key and click on a tab name to open a undocked window.

//rchat snapback (When enabled the undocked window will follow your main window)

//rchat battle_all (Toggle Battle Chat showing in the All tab)

//rchat battle_off (Toggle Battle Chat being process at all; totally off)

//rchat battle_flash (Toggle Battle Messages forced pop on screen with flashing)

//rchat chatinput (Toggle a small box showing currently typed text)

//rchat inputlocation (Toggle if the chatinput box is on Top or Bottom orientation)

//rchat splitdrops (Toggle if you'd like drops to goto their own window)
				*Drops window fades after 30 seconds from last addition*

//rchat dropswindow (Toggle if pop up window for split drops shows up automatically)

//rchat showdrops (Forces drops window to open for 120 seconds)

//rchat archive (Turns on Archiving, this will make permanent monthly log files)

//rchat incoming_pause 
Will turn off vanilla windows receiving chat
this will make your chat log vanish which is more
visually appealing.  This can possibly cause issues
with certain npcs, if you have any issues with a certain
npc action just turn it off and let me know which caused it.

**Features**

*Most usability is point and click.

*Window is draggable as well as clickable.  

*All tabs are clickable, all text windows are mouse wheel scrollable.

*Clicking the [ - ] in the upper right corner will minimize the text box and 
leave just the tab menu. 

*New tells recieved while in a none "All"/"Tell" tab will provide a Notification.

*Search system for searching through current tab.  Can click to search next until finished.

*Can save as much chat log lines as you'd like but anything over 5000 can lag during save.

*Mentions can be added that alert you when a word is mentioned in a tab.

**TODO**

Click action for text box line (Click to reply to tell, etc..)

--]]


require 'logger'
require 'strings'
require 'tables'
require 'sets'
require 'chat'
require('coroutine')
files = require('files')
texts = require('texts')
config = require('config')
tab_channels = require('tabs')

save_delay = 5000
rupt_savefile = ''
rupt_db = ''
tab_styles = ''
style_templates = ''
drops_timer = os.clock()
if windower.ffxi.get_info().logged_in then
	rupt_savefile = 'chatlogs/'..windower.ffxi.get_player().name..'-current'
	rupt_db = files.new(rupt_savefile..'.lua')
end
rupt_db = files.new(rupt_savefile..'.lua')
rupt_table_length = 1000  --How many lines before we throw out lines from all_tabname table
rupt_subtable_length = 500 --How many lines before we throw out lines from sub tables (Tell,Linkshell,etc..)

chat_log_env = {
	['scrolling'] = false,
	['scroll_num'] = false,
	['finding'] = false,
	['last_seen'] = os.time(),
	['mention_found'] = false,
	['mention_count'] = 0,
	['last_mention_tab'] = false,
	['last_text_line'] = false,
}


-- 20 21 22 24 28 29 30 31 35 36 50 56 57 63 81 101 102 110 111 114 122 157 191 209
battle_ids = { [20]=true,[21]=true,[22]=true,[23]=true,[24]=true,[28]=true,[29]=true,[30]=true,[31]=true,[35]=true,[36]=true,[40]=true,[50]=true,[56]=true,[57]=true,[59]=true,[63]=true,[81]=true,[101]=true,[102]=true,[107]=true,[110]=true,[111]=true,[114]=true,[122]=true,[157]=true,[191]=true,[209]=true }
duplidoc_ids = { [190]=true }
filter_ids = { [23]=true,[24]=true,[31]=true,[151]=true,[152]=true }

-- Last adds 144 / 190
pause_ids = { [0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[38]=true,[59]=true,[64]=true,[90]=true,[91]=true,[121]=true,[123]=true,[127]=true,[131]=true,[144]=true,[146]=true,[148]=true,[160]=true,[161]=true,[190]=true,[204]=true,[207]=true,[208]=true,[210]=true,[212]=true,[213]=true,[214]=true,[245]=true }
chat_tables = {}
battle_table = {}
archive_table = {}

-- If you care to use a custom font you can play with your own settings here 
-- Format is {[Header Width Multiplier],[Word Wrap Multiplier],[Click Map Width],[Click Map Height]}
-- for some just changing your //rchat width will get you more mileage.

font_wrap_sizes = { -- Defaults to 1.9,0.8,1,1 if no font profile found
	['arial'] = { 1.75,1,1,1.4 },
	['microsoft sans serif'] = { 1.8,0.9,1,1.4 },
	['chiller'] = { 1.4,0.7,0.92,1.5 },
	['corbel'] = { 1.90 ,0.5,0.91,1.7 },
	['papyrus'] = { 2.02,0.4,0.99,1.6},
	['verdana'] = { 1.6,0.8,1.26,1.6},
	['poor richard'] = { 2.0,0.50,0.85,1.5},
	['book antiqua'] = { 1.75,0.7,1.05,1.5},
	['unispace'] = { 1.2,1.2,1.9,1.5},
}


find_table = {
	['last_find'] = false,
	['last_index'] = 1,
}


default_settings = {
	log_length = 12,
	log_width = 85,
	log_dwidth = 0, -- 0 Disables and defaults to log_width value
	log_dlength = 0, -- 0 Disable and defaults to log_length value
	battle_all = true, -- Display Battle text in All tab
	battle_off = false, -- Disable processing Battle text entirely
	strict_width = false,
	strict_length = false,
	undocked_window = false,
	undocked_tab = all_tabname,
	incoming_pause = false,
	drag_status = true,
	battle_flash = false,
	chat_input = false,
	chat_input_placement = 1,
	split_drops = false,
	drops_window = true,
	archive = false,
	flags = {
		draggable = false,
	},
	mentions = {
		All = S{},
		Tell = S{},
		Linkshell = S{},
		Linkshell2 = S{},
		Party = S{},
		Battle = S{},
	},
	text = {
		size = 10,
	},
	bg = {
		alpha = 200,
	},
}


tab_ids = {}
all_tabs = {}
for _,v in ipairs(tab_channels['Tabs']) do
	table.insert(all_tabs,v.name)
	default_settings['mentions'][v.name] = S{}
	for _,cid in pairs(v.ids) do
		tab_ids[tostring(cid)] = v.name
	end
	if v.tab_type == 'Battle' then
		battle_tabname = v.name
	end
	if v.tab_type == 'All' then
		all_tabname = v.name
	end
end



current_tab = all_tabname


--Main window
settings = config.load(default_settings)
t = texts.new(settings)
texts.bg_visible(t, true)

--Notification Window
t2 = texts.new(default_settings)
t2:visible(false)

--Undocked Tab Window
default_settings.flags.draggable = true
t3 = texts.new(default_settings)
t3:visible(false)
t3:size(settings.text.size)
texts.pad(t3,5)
--Text Input Window
t4 = texts.new(default_settings)
t4:visible(false)
t4:size(settings.text.size)
t4:bg_alpha(255)
--Drops Window
t5 = texts.new(default_settings)
t5:visible(false)
t5:size(settings.text.size)
t5:bg_alpha(settings.bg.alpha)
t5:pos(300,300)



chat_debug = false

function split(s, delimiter)
    result = {}
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    return result
end

function cht_date()
	return os.date('%y%m%d')
end

function valid_tab(tab)
	tab = tab:sub(1,1):upper()..tab:sub(2)
	for i,v in ipairs(all_tabs) do
		if tab == v then
			return true
		end
	end
	return false
end

image_map = {}

function build_maps()
	image_map = {}
	local x_base = 6.8
	local y_base = 1.5
	local font = texts.font(t):lower()
	if font_wrap_sizes[font] then
		x_base = x_base*font_wrap_sizes[font][3]
		y_base = y_base*font_wrap_sizes[font][4]
	end
	x_scale = texts.size(t) * x_base
	y_scale = texts.size(t) * y_base
	for i,v in ipairs(all_tabs) do
		if i == 1 then
			image_map[i] = { ['x_start'] = 0, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		elseif i == 2 then
			image_map[i] = { ['x_start'] = x_scale+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		elseif i > 2 then
			image_map[i] = { ['x_start'] = image_map[i-1].x_end+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		end
		image_map[i].action = function(current_menu)
			menu(current_menu,'')
		end
	end
	i = #image_map
	settings.window_visible = true
	image_map[i+1] = { ['x_start'] = image_map[i].x_end+1, ['x_end'] = x_scale*6.8, ['y_start'] = 0, ['y_end'] = y_scale}
	image_map[i+1].action = function(current_menu)
		if settings.window_visible then settings.window_visible = false else settings.window_visible = true end
		config.save(settings, windower.ffxi.get_player().name)
		reload_text()
	end
	image_map[i+2] = { ['x_start'] = 0, ['x_end'] = x_scale*1.5, ['y_start'] = y_scale+1, ['y_end'] = y_scale*2}
	image_map[i+2].action = function(current_menu)
			menu(current_menu,'')
	end
end

build_maps()

function undock(menu)
	if settings.undocked_window and settings.undocked_tab == menu then
		settings.undocked_window = false
		t3:visible(false)
		reload_text()
		config.save(settings, windower.ffxi.get_player().name)
	else
		settings.undocked_tab = menu
		settings.undocked_window = true
		texts.bg_alpha(t3, texts.bg_alpha(t))
		texts.size(t3, texts.size(t))
		reload_text()
		config.save(settings, windower.ffxi.get_player().name)
	end
end

function fillspace(spaces)
	local spacer = ''
	for i=1,spaces, 1 do
		spacer = spacer..' '
	end
	return spacer
end

start_map = #image_map
new_text_header = ''
new_text = ''
queue_reload_text = false
reload_clock = os.clock()+1

function header()
	local cur_font = texts.font(t):lower()
	
	if not font_wrap_sizes[cur_font] then
		font_wrap_sizes[cur_font] = { 1.9,0.8,1,1 }
	end
	if current_tab == 'Tell' or current_tab == all_tabname then chat_log_env['last_seen'] = os.time() end
	if chat_log_env['mention_found'] and (current_tab == chat_log_env['last_mention_tab'] or (settings.undocked_window and settings.undocked_tab == chat_log_env['last_mention_tab'])) then
		if chat_log_env['mention_count'] < os.clock() then
			chat_log_env['mention_found'] = false
			t2:bg_color(0,0,0)
			t2:visible(false)
		end
	end
	local buffer = 15
	new_text_header = ''
	for i,v in ipairs(all_tabs) do
		local length = string.len(v)
		if current_tab == v then length = length+4 end
		local space = math.floor((buffer-length)/2)
		local leftovers = buffer-(length+space)
		new_text_header = new_text_header..fillspace(space)
		if current_tab == v then
			local tmp = '[-\\cs(255,69,0)'..v..'\\cr-]'..fillspace(leftovers)..'\\cr'
			new_text_header = new_text_header..tmp
		elseif v == 'Tell' then
			--print('Tell: '..chat_tables[v][#chat_tables[v]])
			if not chat_tables[v] then chat_tables[v] = {} end
			if #chat_tables[v] > 0 then
				last_msg = string.match(chat_tables[v][#chat_tables[v]],'^[0-9]+') or false		
				if last_msg then						
					last_from = windower.regex.match(chat_tables[v][#chat_tables[v]],'^([0-9]+:[0-9]+):([^>]+)>') or false
					if chat_log_env['last_seen'] < tonumber(last_msg) and last_from then
						t2:text("New Tell From: \\cs(0,255,0)"..last_from[1][2].."\\cr")
						t2:visible(true)
						chat_log_env['mention_found'] = false
						t2:bg_color(0,0,0)
						new_text_header = new_text_header..v..'*'..fillspace(leftovers-1)
					else
						if not chat_log_env['mention_found'] then
							t2:visible(false)
						end
						new_text_header = new_text_header..v..fillspace(leftovers)
					end
				else
					new_text_header = new_text_header..v..fillspace(leftovers)
				end
			else
				new_text_header = new_text_header..v..fillspace(leftovers)
			end
		else
			new_text_header = new_text_header..v..fillspace(leftovers)
		end
	end
	if settings.window_visible then
		new_text_header = new_text_header..'[ - ]   [rChat]'
	else
		new_text_header = new_text_header..'[ + ]   [rChat]'
	end
	if settings.strict_width then
		blank_space = (settings.log_width*font_wrap_sizes[texts.font(t):lower()][1]) - string.len(new_text_header)
		new_text_header = new_text_header..fillspace(blank_space)..'\n'
	else
		new_text_header = new_text_header..'\n'
	end
	if chat_log_env['finding'] then
		new_text_header = new_text_header..'[Find Next]\n'
		t2:text("Searching for: \\cs(0,255,0)"..find_table['last_find'].."\\cr")
		t2:visible(true)
	elseif chat_log_env['scrolling'] then
		new_text_header = new_text_header..'[Jump to Bottom]\n'
		t2:visible(false)
	else
		new_text_header = new_text_header..'\n'
	end
	if not chat_log_env['scrolling'] and not chat_log_env['finding'] then
		load_chat_tab(false,'main')
	else
		load_chat_tab(chat_log_env['scroll_num'],'main')
	end
	if settings.undocked_window then
		load_chat_tab(0,'undocked')
	end
end

function wrap_text(txt,log_width)
	local slen = string.len
	local ssub = string.sub
	local sgsub = string.gsub
	if slen(txt) > log_width then
		local wrap_tmp = ""
		local wrap_cnt = 0
		for w in txt:gmatch("([^%s]+)") do
			cur_len = slen(w)
			if cur_len > log_width then
				end_len = (log_width*font_wrap_sizes[texts.font(t):lower()][2]) - wrap_cnt
				suffix = ssub(w,end_len+1)
				wrap_tmp = wrap_tmp..' '..ssub(w,1,end_len)..'\n'..suffix
				wrap_cnt = slen(suffix)
			else
				wrap_cnt = wrap_cnt+(cur_len+1)
				if wrap_cnt < log_width then
					wrap_tmp = wrap_tmp..' '..w
				else
					wrap_cnt = 10
					wrap_tmp = wrap_tmp..'\n'..w
				end
			end
		end
		if wrap_tmp ~= "" then
			txt = wrap_tmp
		end
	end
	return txt
end

function convert_text(txt,tab_style)
	local line_header = windower.regex.match(txt,'([0-9]+):([0-9]+):(.*)') or false
	if line_header then
		matches = line_header[1]
		timestamp = os.date('%X',matches[1])
		id = tonumber(matches[2])
		txt = matches[3]
	else
		line_header = windower.regex.match(txt,'([0-9]+):(.*)') or false
		matches = line_header[1]
		timestamp = os.date('%X',matches[1])
		txt = matches[2]
	end
	txt = timestamp..':'..txt
	local slen = string.len
	local ssub = string.sub
	local sgsub = string.gsub
	if tab_style == 'main' or settings.log_dwidth == 0 then 
		log_width = settings.log_width
	else
		log_width = settings.log_dwidth
	end
	txt = wrap_text(txt,log_width)
	txt = sgsub(txt,'^ ','')
	txt = sgsub(txt,'[^%z\1-\127]','')
	if tab_styles[id] then
		styles = tab_styles[id]
		for i=1,#styles,2 do
			txt = sgsub(txt,styles[i],styles[i+1])
		end
	else
		if battle_ids[id] then
			styles = tab_styles['battle']
		else
			styles = tab_styles['default']
		end
		for i=1,#styles,2 do
			txt = sgsub(txt,styles[i],styles[i+1])
		end
	end
	return txt
end

function load_chat_tab(scroll_start,window)
	if window == 'main' then
		new_text = ''
		if not chat_tables[current_tab] then
			chat_tables[current_tab] = {}
			return
		end
		if current_tab == battle_tabname then
			current_chat = battle_table
		else
			current_chat = chat_tables[current_tab]
		end
		if #current_chat == 0 then
			return
		end
		tab = current_tab
		length = settings.log_length
	else
		if window == 'undocked' then
			tab = settings.undocked_tab
			scroll_start = false
		elseif window == 'Drops' then
			tab = 'Drops'
--			scroll_start = false
		end
		if tab:lower() == battle_tabname:lower() then
			current_chat = battle_table
			if #battle_table < 1 then
				return
			end
		else
			if not chat_tables[tab] then chat_tables[tab] = {} end
			current_chat = chat_tables[tab]
		end

		if settings.log_dlength and settings.log_dlength > 0 then
			length = settings.log_dlength
		else
			length = settings.log_length
		end
	end
	if #current_chat < length then
		loop_start = 1
		loop_end = #current_chat
		loop_count = length-1
	else
		loop_start = #current_chat - length
		loop_end = #current_chat
		if scroll_start then
			loop_start = scroll_start
			loop_end = scroll_start + length
		end
		loop_count = (loop_end - loop_start)-1
	end	
	local temp_table = ''
	local prev_table = ''
	local broke_free = false
	for i=loop_end,loop_start,-1 do
		if not chat_log_env['finding'] then
			_,count = temp_table:gsub('[\r\n]','')
			if count >= loop_count and prev_table ~= '' then
				if settings.strict_length then
					broke_free = true
					if window ~= 'main' and settings.log_dwidth > 0 then
						temp_table = prev_table
						_,count2 = temp_table:gsub('[\r\n]','')
						local new_lines = loop_count - count2
						local new_line = ''
						if new_lines > 0 then
							for i=1,new_lines, 1 do
								new_line = new_line..'\n'
							end
						end
						temp_table = new_line..temp_table
					end
				end
				break
			end
		end
		if settings.strict_length then
			--Save a working copy
			prev_table = temp_table
		end
		if current_chat[i] then
			temp_table = convert_text(current_chat[i],window)..'\n'..temp_table
		end
	end
	if window == 'main' then
		if temp_table ~= '' then
			if broke_free then
				_,tmp_count = prev_table:gsub('\n','')
				local new_lines = loop_count - tmp_count
				local new_line = ''
				if new_lines > 1 then
					for i=2,new_lines, 1 do
						new_line = new_line..'\n'
					end
				end
				new_text = new_text..new_line..prev_table
			else
				new_text = new_text..temp_table
			end
		end
	else
		if temp_table ~= '' then
			if window == 'undocked' then
				t3:text('[ \\cs(255,69,0)'..tab..'\\cr ]... .. .\n'..temp_table)
				texts.size(t3, texts.size(t))
				texts.bg_alpha(t3, texts.bg_alpha(t))
				texts.font(t3, texts.font(t))
				t3:visible(true)
			elseif window == 'Drops' then
				t5:text('[ \\cs(255,69,0)'..tab..'\\cr ]... .. .\n'..temp_table)
				texts.size(t5, texts.size(t))
				texts.bg_alpha(t5, texts.bg_alpha(t))
				texts.font(t5, texts.font(t))
				t5:visible(true)
			end
		end
	end
end



dragged = nil
clicked = false
last_scroll = 0
function cap(val, min, max)
    return val > max and max or val < min and min or val
end


alt_down = false
windower.register_event('keyboard', function(dik,pressed,flags,blocked)
	if dik == 56 then
		alt_down = pressed
	end
end)

windower.register_event('mouse', function(eventtype, x, y, delta, blocked)
    hovered = texts.hover(t,x,y)
    if blocked then
        return
    end
    if eventtype == 0 then
		if clicked then
			return true
		end
        if hovered then
			if chat_debug then
				local x_extent,y_extent = texts.extents(t)
				local x_boundry = x_extent+texts.pos_x(t)
				local y_boundry = y_extent+texts.pos_y(t)
				t2:text("Mouse X: \\cs(0,255,0)"..x.."/"..texts.pos_x(t).."\\cr Y: \\cs(0,255,0)"..y.."/"..texts.pos_y(t).."\\cr Extents: "..x_boundry..' / '..y_boundry)
				t2:visible(true)
			end
			if dragged then
				dragged.text:pos(x - dragged.x, y - dragged.y)
				_,y_extent = texts.extents(t)
				t2:pos(x - dragged.x, (y - dragged.y)-20)
				if settings.chat_input_placement == 1 then
					t4:pos(x - dragged.x, (y - dragged.y)+y_extent)
				else
					t4:pos(x - dragged.x, (y - dragged.y)-40)
				end	
				if settings.snapback then
					local boundry_table = {texts.extents(t)}
					local x_boundry = boundry_table[1]+texts.pos_x(t)+2
					t3:pos(x_boundry,texts.pos_y(t))
				end
				return true
			end

			return true
        else
			if dragged then
				return true
			end
        end
    elseif eventtype == 1 then  --click
		local pos_x = texts.pos_x(t)
		local pos_y = texts.pos_y(t)
		for i,v in ipairs(image_map) do
			if (x < pos_x+v.x_end and x > pos_x+v.x_start) and (y > pos_y+v.y_start and y < pos_y+v.y_end) then
				v.action(i)
				clicked = true
				return true
			end
		end
		if hovered then
			if settings.drag_status then dragged = {text = t, x = x - pos_x, y = y - pos_y} end
			return true
		end
    elseif eventtype == 2 then --click off
		if clicked then
			clicked = false
			return true
		end
		if hovered then
			if dragged then
				config.save(settings, windower.ffxi.get_player().name)
				dragged = nil
				return true
			end
			return true
		else
			if dragged then
				dragged = nil
				return true
			end
		end
	elseif eventtype == 10 then
		if hovered or (settings.split_drops and texts.hover(t5,x,y)) then
			if current_tab == battle_tabname then
				current_chat = battle_table
			else
				current_chat = chat_tables[current_tab]
			end
			if texts.hover(t5,x,y) then
				current_chat = chat_tables['Drops']
				last_scroll_type = 'drops'
			elseif not chat_log_env['scrolling'] then
				last_scroll_type = 'main'
				chat_log_env['scroll_num'] = false
			end
			if current_chat and (last_scroll == 0 or chat_log_env['scroll_num'] == false) then
				if #current_chat > settings.log_length then
					last_scroll = #current_chat - settings.log_length
				else
					last_scroll = #current_chat
				end
			end
			if #current_chat > settings.log_length then 
				last_scroll = cap(last_scroll - delta, 1, #current_chat - (settings.log_length - 1))
				if (last_scroll >= (#current_chat - settings.log_length)) and chat_log_env['scrolling'] then
					last_scroll = #current_chat - settings.log_length
					chat_log_env['scrolling'] = false
					chat_log_env['scroll_num'] = false
				else
					if last_scroll > 0 and last_scroll <= (#current_chat - settings.log_length) then
						chat_log_env['scroll_num'] = last_scroll
						chat_log_env['scrolling'] = true
					end
				end
				if texts.hover(t5,x,y) then
					if chat_log_env['scrolling'] then
						load_chat_tab(chat_log_env['scroll_num'],'Drops')
						chat_log_env['scrolling'] = false
					else
						last_scroll = cap(last_scroll - delta, 1, #current_chat - (settings.log_length - 1))
						load_chat_tab(last_scroll,'Drops')
					end
				else
					reload_text()
				end
			end
			return true
		end
    end
end)



function reload_text()
	header()
	if settings.window_visible then t:text(new_text_header..new_text) else t:text(new_text_header) end
end

function write_db()
	local start_time = os.clock()
	local temp_table = {}
	--Prune Battle_Log
	local tinsert = table.insert
	for i,v in ipairs(chat_tables[all_tabname]) do
--		local id = windower.regex.match(v,'[0-9]+:([0-9]+):') or false
--		if (id and id[1] and id[1][1] and battle_ids[tonumber(id[1][1])] == true) or string.sub(v,1,2) == '**' then
--			table.insert(battle_table,v)
--		else
			tinsert(temp_table,v)
--		end
	end
	chat_tables[all_tabname] = nil
	chat_tables[all_tabname] = temp_table
	--Prune Length
	for i,v in pairs(chat_tables) do
		if i == all_tabname then max_length = rupt_table_length else max_length = rupt_subtable_length end
		--print('Processing table: '..i..' With Length: '..#v)
		if #v > max_length then
			--print('Pruning table: '..i..' Has '..#v..' / '..max_length)
			temp_table = {}
			for j=#v-max_length,#v,1 do
				tinsert(temp_table,v[j])
			end
			chat_tables[i] = temp_table
			--print('Table chat_tables['..i..'] = '..#chat_tables[i]..' now.')
		end
	end
	rupt_db:write('return ' ..T(chat_tables):tovstring())
	if settings.archive and #archive_table > 0 then
		local archive_clock = os.clock()
		print('Chatlog Save Finished in '..(archive_clock - start_time)..'s, Archiving New Text')
		archive_filename = files.new('chatlogs/'..windower.ffxi.get_player().name..'-'..os.date('%Y%m')..'.log')
		if not files.exists(archive_filename) then
			files.create(archive_filename)
		end
		local fappend = files.append
		fappend(archive_filename,table.concat(archive_table,'\n'))
--		for i,v in pairs(archive_table) do
--			fappend(archive_filename,v..'\n')
--		end
		archive_table = {}
--		print('Archived in '..(os.clock()-archive_clock)..'s')
	else
		print('Saved Chatlog')
	end
end



function load_db_file()
	if rupt_db ~= '' and rupt_db:exists() then
		if package.loaded[rupt_savefile] then
			package.loaded[rupt_savefile] = nil
			_G[rupt_savefile] = nil
		end
		chat_tables = require(rupt_savefile)
	end
end

load_db_file()

function addon_command(...)
    local args = T{...}
    local cmd = args[1]
	args:remove(1)
	local args_joined = table.concat(args," ")
    if cmd then
		if cmd == 'find' then
			menu('find',args_joined)
		elseif cmd == 'alpha' then
			texts.bg_alpha(t, tonumber(args[1]))
			texts.bg_alpha(t3, tonumber(args[1]))
			settings.bg_alpha = tonumber(args[1])
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'stroke_width' then
			texts.stroke_width(t, tonumber(args[1]))
			texts.stroke_width(t3, tonumber(args[1]))
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'stroke_color' then
			if #args > 3 then
				log('Missing a Color')
				return
			end
			texts.stroke_color(t, tonumber(args[1]),tonumber(args[2]),tonumber(args[3]))
			texts.stroke_color(t3, tonumber(args[1]),tonumber(args[2]),tonumber(args[3]))
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'stroke_alpha' then
			texts.stroke_alpha(t, tonumber(args[1]))
			texts.stroke_alpha(t3, tonumber(args[1]))
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'size' then
			texts.size(t, tonumber(args[1]))
			texts.size(t3, tonumber(args[1]))
			settings.text.size = tonumber(args[1])
			config.save(settings, windower.ffxi.get_player().name)
			build_maps()
		elseif cmd == 'font' then
			texts.font(t, args_joined)
			texts.font(t3, args_joined)
			settings.text.font = args_joined
			config.save(settings, windower.ffxi.get_player().name)
			build_maps()
		elseif cmd == 'length' then
			if args[1] and tonumber(args[1]) then
				settings.log_length = tonumber(args[1])
				config.save(settings, windower.ffxi.get_player().name)
				reload_text()
			else
				log('Missing or invalid argument')
			end
		elseif cmd == 'width' then
			if args[1] and tonumber(args[1]) then
				settings.log_width = tonumber(args[1])
				config.save(settings, windower.ffxi.get_player().name)
				reload_text()
			else
				log('Missing or invalid argument')
			end
		elseif cmd == 'dwidth' then
			if args[1] and tonumber(args[1]) then
				settings.log_dwidth = tonumber(args[1])
				config.save(settings, windower.ffxi.get_player().name)
				reload_text()
			else
				log('Missing or invalid argument')
			end
		elseif cmd == 'dlength' then
			if args[1] and tonumber(args[1]) then
				settings.log_dlength = tonumber(args[1])
				config.save(settings, windower.ffxi.get_player().name)
				reload_text()
			else
				log('Missing or invalid argument')
			end
		elseif cmd == 'tab' then
			if args[1] and valid_tab(args[1]) then
				for i=1,#all_tabs,1 do
					if args[1]:lower() == all_tabs[i]:lower() then
						menu(i,'')
						return
					end
				end
			elseif not args[1] then
				for i=1,#all_tabs,1 do
					if current_tab == all_tabs[i] then
						if (i+1) > #all_tabs then
							next_tab = 1
						else
							next_tab = i+1
						end
						menu(next_tab,'')
						return
					end
				end
			end
		elseif cmd == 'undock' then
			if args[1] and valid_tab(args[1]) then
				undock(args[1])
			else
				if settings.undocked_tab then
					undock(settings.undocked_tab)
				end
			end
		elseif cmd == 'battle_all' then
			if settings.battle_all then
				log('Setting battle_all to false')
				settings.battle_all = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting battle_all to true')
				settings.battle_all = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'battle_off' then
			if settings.battle_off then
				log('Setting battle_off to false')
				settings.battle_off = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting battle_off to true')
				settings.battle_off = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'battle_flash' then
			if settings.battle_flash then
				log('Setting battle_flash to false')
				settings.battle_flash = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting battle_flash to true')
				settings.battle_flash = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'strict_width' then
			if settings.strict_off then
				log('Setting strict_width to false')
				settings.strict_width = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting strict_width to true')
				settings.strict_width = true
				config.save(settings, windower.ffxi.get_player().name)
			end
			reload_text()
		elseif cmd == 'strict_length' then
			if settings.strict_length then
				log('Setting strict_length to false')
				settings.strict_length = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting strict_length to true')
				settings.strict_length = true
				config.save(settings, windower.ffxi.get_player().name)
			end
			reload_text()
		elseif cmd == 'snapback' then
			if settings.snapback then
				log('Setting snapback to false')
				settings.snapback = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting snapback to true')
				settings.snapback = true
				config.save(settings, windower.ffxi.get_player().name)
			end
			boundries = {texts.extents(t)}
			local t_pos_x = texts.pos_x(t)
			local t_pos_y = texts.pos_y(t)
			t3:pos((boundries[1]+t_pos_x+2),t_pos_y)
		elseif cmd == 'incoming_pause' then
			if settings.incoming_pause then
				log('Setting incoming_pause to false')
				settings.incoming_pause = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting incoming_pause to true')
				log('** USE THIS AT YOUR OWN RISK **')
				settings.incoming_pause = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'chatinput' then
			if settings.chat_input then
				log('Setting chat_input to false')
				settings.chat_input = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting chat_input to true')
				settings.chat_input = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'inputlocation' then
			local t_pos_x = texts.pos_x(t)
			local t_pos_y = texts.pos_y(t)
			local x_extent,y_extent = texts.extents(t)
			if settings.chat_input_placement == 1 then
				log('Setting chat_input_placement to Top')
				settings.chat_input_placement = 2
				t4:pos(t_pos_x, (t_pos_y-40))
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting chat_input_placement to Bottom')
				settings.chat_input_placement = 1
				t4:pos(t_pos_x,(t_pos_y+y_extent))
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'splitdrops' then
			if settings.split_drops then
				log('Setting split_drops to false')
				settings.split_drops = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting split_drops to true')
				settings.split_drops = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'dropswindow' then
			if settings.drops_window then
				log('Setting drops_window to false')
				settings.drops_window = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting drops_window to true')
				settings.drops_window = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'showdrops' then
			drops_timer = os.clock()+120
			if #chat_tables['Drops'] > settings.log_length then
				scroll = #chat_tables['Drops'] - settings.log_length+1
			else
				scroll = 0
			end
			load_chat_tab(scroll,'Drops')
			t5:show()
		elseif cmd == 'archive' then
			if settings.archive then
				log('Setting archive to false')
				settings.archive = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting archive to true')
				settings.archive = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'drag' then
			if settings.drag_status then
				log('Setting drag_status to false')
				settings.drag_status = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting drag_status to true')
				settings.drag_status = true
				config.save(settings, windower.ffxi.get_player().name)
			end
		elseif cmd == 'mentions' then
			for i,v in pairs(settings.mentions) do
				if #T(v) > 0 then
					values = "["..v:format('list').."]"
					log('Tab: '..i..' Values: '..values)
				end
			end
		elseif cmd == 'addmention' then
			if not args[1] then
				log('No Tab Listed //rchat addmention <tab> <value>')
				return
			elseif not valid_tab(args[1]) then
				log(args[1]..' Not a valid Tab')
				return
			end
			local tab = args[1]:sub(1,1):upper()..args[1]:sub(2):lower()
			if not args[2] then
				log('No Value Listed //rchat addmention <tab> <value>')
				return
			end
			terms = table.concat(args," ",2)
			if settings.mentions[tab]:contains(terms:lower()) then
				log(terms..' Already added to tab ['..tab..']')
				return
			end
				settings.mentions[tab]:add(terms:lower())
				config.save(settings, windower.ffxi.get_player().name)
				log(terms..' Added to tab ['..tab..']')
		elseif cmd == 'delmention' then
			if not args[1] then
				log('No Tab Listed //rchat delmention <tab> <value>')
				return
			elseif not valid_tab(args[1]) then
				log(args[1]..' Not a valid Tab')
				return
			end
			local tab = args[1]:sub(1,1):upper()..args[1]:sub(2):lower()
			if not args[2] then
				log('No Value Listed //rchat delmention <tab> <value>')
				return
			end
			terms = table.concat(args," ",2)
			if not settings.mentions[tab]:contains(terms:lower()) then
				log(terms..' not on tab ['..tab..']')
				return
			end
				settings.mentions[tab]:remove(terms:lower())
				config.save(settings, windower.ffxi.get_player().name)
				log(terms..' Removed to tab ['..tab..']')
		elseif cmd == 'show' then
			t:visible(true)
		elseif cmd == 'hide' then
			t:visible(false)
		elseif cmd == 'save' then
			write_db()
		elseif cmd == 'debug' then
			if chat_debug then chat_debug = false else chat_debug = true end
		end
	end
end

function find_next(c)
	if current_tab == battle_tabname then
		current_table = battle_table
	else
		current_table = chat_tables[current_tab]
	end
	if find_table['last_index'] == 1 then
		loop_start = #current_table
	else 
		loop_start = find_table['last_index'] - 1
	end	
	find_table['last_index'] = loop_start
	chat_log_env['finding'] = true
	local sfind = string.find
	for i=loop_start,1,-1 do
		if sfind(current_table[i]:lower(),c) then
			if find_table['last_index'] > i then
				find_table['last_index'] = i
				return i
			end
		end
	end
	return false
end

function reset_tab()
	chat_log_env['scrolling'] = false
	chat_log_env['scroll_num'] = false
	find_table['last_find'] = false
	find_table['last_index'] = 1
	chat_log_env['finding'] = false
	image_map[#image_map].action = function(current_menu)
	menu(current_menu,'')
	end
end

function mention_check()
	if chat_log_env['mention_found'] and current_tab == chat_log_env['last_mention_tab'] then
		chat_log_env['mention_found'] = false
		t2:bg_color(0,0,0)
	end
end

function menu(menunumber,c)
		local player = windower.ffxi.get_player()
		if tonumber(menunumber) ~= nil and all_tabs[menunumber] then -- generic menus
			menuname = all_tabs[menunumber]
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = menuname
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			mention_check()
			reload_text()
		elseif menunumber == #image_map then  --Bottom menu
			chat_log_env['scrolling'] = false
			chat_log_env['scroll_num'] = false
			if current_tab == battle_tabname then
				last_scroll = #battle_table - settings.log_length
			else
				last_scroll = #chat_tables[current_tab] - settings.log_length
			end
			reset_tab()
			reload_text()
		elseif menunumber == 'find' then  --Triggered from addon_command, remakes image_map fn = findnext
			local c = c:lower()
			if find_table['last_find'] == c then
				last_scroll = find_next(c)
				if not last_scroll then
					windower.ffxi.add_to_chat(200,'No more matches found')
					return
				else
					image_map[#image_map].action = function(current_menu)
						menu('findnext','')
						end
					chat_log_env['scroll_num'] = last_scroll
					reload_text()
				end
			else
				local next_item = find_next(c)
				if not next_item then
					log('No Matches for: '..c)
					find_table['last_find'] = false
					chat_log_env['finding'] = false
					image_map[#image_map].action = function(current_menu)
					menu(current_menu,'')
					end
					return
				else
					image_map[#image_map].action = function(current_menu)
						menu('findnext','')
					end
					find_table['last_find'] = c
					last_scroll = next_item
					chat_log_env['scroll_num'] = last_scroll
					reload_text()
				end
			end
		elseif menunumber == 'findnext' then
			next_item = find_next(find_table['last_find'])
			if not next_item then
				log('No more matches found')
				find_table['last_find'] = false
				chat_log_env['finding'] = false
				image_map[#image_map].action = function(current_menu)
				menu(current_menu,'')
				end
				chat_log_env['scrolling'] = true
				reload_text()
				return
			else
				last_scroll = next_item
				chat_log_env['scroll_num'] = last_scroll
				reload_text()
			end
		end

end

function check_mentions(id, chat)
	chat_type = nil
	if battle_ids[id] then
		chat_type = battle_tabname
	elseif tab_ids[tostring(id)] then
		chat_type = tab_ids[tostring(id)]
	end
	local sfind = string.find
	if not (chat_type == battle_tabname and settings.battle_all == false) then
	if #T(settings.mentions[all_tabname]) > 0 then
		local stripped = string.gsub(chat,'[^A-Za-z%s]','')
		local splitted = split(stripped,' ')
		local chat_low = chat:lower()
		local player_name = windower.ffxi.get_player().name:lower()
		for v in settings.mentions[all_tabname]:it() do
			v = v:lower()
			if sfind(chat_low,v)then
				if v == player_name then
					if splitted[1] and splitted[1]:lower() == v then
						return
					end
				end
				chat_log_env['mention_found'] = true
				chat_log_env['mention_count'] = os.clock()+30
				chat_log_env['last_mention_tab'] = all_tabname
				t2:text("New Mention @ \\cs(255,69,0)All\\cr: \\cs(0,255,0)"..v.."\\cr")
				t2:visible(true)
				t2:bg_color(0,0,0)
				return
			end
		end
	end
	end
	if chat_type and #T(settings.mentions[chat_type]) > 0 then
		if settings.battle_flash and chat_type == battle_tabname then
			--force this to process if battle_flash is true and this is a battle message
		else
			if current_tab == chat_type then
				return
			end
			if settings.undocked_window and settings.undocked_tab == chat_type then
				return
			end
		end
		local stripped = string.gsub(chat,'[^A-Za-z%s]','')
		local splitted = split(stripped,' ')
		local chat_low = chat:lower()
		local player_name = windower.ffxi.get_player().name:lower()
		for v in settings.mentions[chat_type]:it() do
			v = v:lower()
			if sfind(chat_low,v) then
				if v == player_name then
					if splitted[1] and splitted[1]:lower() == v then
						return
					end
				end
				chat_log_env['mention_found'] = true
				chat_log_env['mention_count'] = os.clock()+30
				chat_log_env['last_mention_tab'] = chat_type
				if chat_type == battle_tabname and settings.battle_flash then					
					t2:text("New Mention @ \\cs(255,69,0)"..chat_type.."\\cr: \\cs(0,255,0)"..v.."\\cr "..stripped)
				else
					t2:text("New Mention @ \\cs(255,69,0)"..chat_type.."\\cr: \\cs(0,255,0)"..v.."\\cr")
					t2:bg_color(0,0,0)
				end
				t2:visible(true)
				return
			end
		end
	end
end

battlemod_loaded = false


function chat_add(id, chat)
	chat = chat:strip_colors()
    chat = string.gsub(chat,string.char(0xEF, 0x27),'{:')
    chat = string.gsub(chat,string.char(0xEF, 0x28)..'.',':}')
	if chat_debug then print('ID: '..id..' Txt: '..chat) end

	check_mentions(id,chat)
	if not chat_tables[all_tabname] then
		chat_tables[all_tabname] = {}
	end
	chat = string.gsub(chat,'[\r\n]','')
	chat = string.gsub(chat,string.char(0x81, 0xA8),'->')
	chat = string.gsub(chat,string.char(0x81, 0xA9),'<-')
	chat = string.gsub(chat,string.char(0x07, 0x0A),'')
	chat = string.gsub(chat,'"','\"')
	if settings.archive then
		table.insert(archive_table,os.date('[%x@%X]')..':'..id..':'..chat)
	end
	if settings.split_drops then
		if id == 121 or id == 127 then
			if string.find(chat,'find') or string.find(chat,'obtains') then
				if not chat_tables['Drops'] then chat_tables['Drops'] = {} end
				table.insert(chat_tables['Drops'],os.time()..':'..id..':'..chat)
				if #chat_tables['Drops'] > settings.log_length then
					scroll = #chat_tables['Drops'] - settings.log_length
				else
					scroll = 0
				end
				if settings.drops_window then
					load_chat_tab(scroll,'Drops')
					drops_timer = os.clock()+30
				end
				return
			end
		end
	end
	if battle_ids[id] then  -- Duplicated messages that battlemod has it's own variants of
		if id == 20 and battlemod_loaded and (string.find(chat,'scores.') or string.find(chat,'uses') or string.find(chat,'hits') or string.match(chat,'.*spikes deal.*') or string.find(chat,'misses') or string.find(chat,'cures') or string.find(chat,'additional') or string.find(chat,'retaliates'))then
				return
		end
--		local battle_text = convert_text(os.time()..':'..id..':'..chat,'Battle')
--		table.insert(battle_table,battle_text)
		if not T(tab_channels['Battle_Exclusions']):contains(id) then
			table.insert(battle_table,os.time()..':'..id..':'..chat)
		end
		if settings.battle_all then
--			table.insert(chat_tables[all_tabname],'**'..battle_text)
			table.insert(chat_tables[all_tabname],os.time()..':'..id..':'..chat)
		end
		
	else
		if not T(tab_channels['All_Exclusions']):contains(id) then
			table.insert(chat_tables[all_tabname],os.time()..':'..id..':'..chat)
		end
	end
	local tab_id = tab_ids[tostring(id)] or false
	if tab_id then
		local chat_type = tab_id
		if not chat_tables[chat_type] then chat_tables[chat_type] = {} end
		table.insert(chat_tables[chat_type],os.time()..':'..id..':'..chat)
	end
	if not queue_reload_text then --Avoid having 8 messages that are received at the same time process
		queue_reload_text = true
		reload_clock = os.clock()+1
	end
end


function process_incoming_text(original,modified,orig_id,id,injected,blocked)
	if duplidoc_ids[id] then -- Handle some npc text that comes in duplicate.
		if modified == chat_log_env['last_text_line'] then
			return
		end
		chat_log_env['last_text_line'] = modified
	end
	if battle_ids[id] then
		if string.find(modified:lower(),'aoe') then
			if settings.incoming_pause then
				return true
			else
				return --Just filtering this out for now while I figure out what I want to do
			end
		end
	end
	if battle_ids[id] and injected then 
		battlemod_loaded = true
	end
	if settings.battle_off and battle_ids[id] then
		-- cancel logging battle text
	else
		if not filter_ids[id] then 
			if not battlemod_loaded then 
				modified = original 
			end
			modified = string.gsub(modified,'\\','\\\\')
			modified = string.gsub(modified,'[\r\n]','')
			modified = string.gsub(modified,'[\\]+$','')
			chat_add(id,modified)
			if not chat_log_env['scrolling'] then 
				reload_text() 
			end
		end
	end
	if settings.incoming_pause then
		if battle_ids[id] or pause_ids[id] then
			return true
		end
	end
end



windower.register_event('addon command', addon_command)


incoming_text = false
function load_events()
	if not incoming_text then 
		incoming_text = windower.register_event('incoming text',process_incoming_text)
	end
	header()
	t:visible(true)
	reload_text()
	local t_pos_x = texts.pos_x(t)
	local t_pos_y = texts.pos_y(t)
	t2:pos(t_pos_x, (t_pos_y-20))
	coroutine.sleep(1)
	x_extent,y_extent = texts.extents(t)
	t3:pos((x_extent+t_pos_x+2),t_pos_y)
	t3:stroke_width(texts.stroke_width(t))
	t3:stroke_alpha(texts.stroke_alpha(t))
	t3:stroke_color(texts.stroke_color(t))
	if settings.chat_input_placement == 1 then
		t4:pos(t_pos_x,(t_pos_y+y_extent))
	else
		t4:pos(t_pos_x,(t_pos_y-40))
	end
	build_maps()
end

function unload_events()
    windower.unregister_event(incoming_text)
	write_db()
end

last_save = os.clock()-560
function save_chat_log()
	if settings.chat_input and windower.chat.is_open() then
		chat,_ = windower.chat.get_input()
		chat = windower.convert_auto_trans(chat)
		chat = chat:strip_format()
		t4:text(chat)
		t4:show()
	else
		t4:hide()
	end
	if settings.split_drops and texts.visible(t5) then
		if os.clock() > drops_timer then
			t5:hide()
		end
	end
	if chat_log_env['mention_found'] and settings.battle_flash and chat_log_env['last_mention_tab'] == battle_tabname then
		local t = os.clock()%1 -- Flashing colors from Byrth's answering machine
		t2:bg_color(100,100+150*math.sin(t*math.pi),100+150*math.sin(t*math.pi))
		t3:bg_color(0,0,0)
	end
	if os.clock() > last_save+save_delay then
		write_db()
		last_save = os.clock()
	end
	if queue_reload_text and reload_clock < os.clock() then
		reload_text()
		queue_reload_text = false
	end
end

windower.register_event('prerender',save_chat_log)

windower.register_event('login', function()
	if windower.ffxi.get_info().logged_in then
		rupt_savefile = 'chatlogs/'..windower.ffxi.get_player().name..'-current'
		rupt_db = files.new(rupt_savefile..'.lua')
		style_templates = require('templates')
		tab_styles = require('styles')

	end
	load_db_file()
	load_events()
	style_templates = require('templates')
	tab_styles = require('styles')
end)

windower.register_event('load', function()
	if windower.ffxi.get_info().logged_in and tab_styles == '' then
		style_templates = require('templates')
		tab_styles = require('styles')
	end
	load_events()
end)

windower.register_event('logout','unload', unload_events)
