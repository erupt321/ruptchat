_addon.author = 'Erupt'
_addon.commands = {'rchat'}
_addon.name = 'RuptChat'
_addon.version = '0.3.062720.1'
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

//rchat length <Log Length> (Change log length size)

//rchat width <Log Width>  (Change log width size; when wordwrap should take effect)

//rchat strict_width (Toggle maintaining the max log width; avoid box shrinking and expanding)

//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)

//rchat battle_all (Toggle Battle Chat showing in the All tab)

//rchat battle_off (Toggle Battle Chat being process at all; totally off)

//rchat incoming_pause **EXPERIMENTAL** Will turn off vanilla windows receiving chat
										this will make your chat log vanish which is more
										visually appealing, but you'll be solely relying
										on this addon for all ingame text, which not even 
										I trust fully yet.  If in doubt just unpause it again.

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
res = require('resources')
files = require('files')
texts = require('texts')
config = require('config')

save_delay = 5000
rupt_savefile = ''
rupt_db = ''
tab_styles = ''
style_templates = ''
if windower.ffxi.get_info().logged_in then
	rupt_savefile = 'chatlogs/'..windower.ffxi.get_player().name..'-current'
	rupt_db = files.new(rupt_savefile..'.lua')
end
rupt_db = files.new(rupt_savefile..'.lua')
rupt_table_length = 1000  --How many lines before we throw out lines from 'All' table
rupt_subtable_length = 500 --How many lines before we throw out lines from sub tables (Tell,Linkshell,etc..)

current_tab = 'All'
all_tabs = {'All','Tell','Linkshell','Linkshell2','Party','Battle'}

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

tab_ids = {
	['4']  = 'Tell',
	['12'] = 'Tell',
	['14'] = 'Linkshell',
	['6'] = 'Linkshell',
	['214'] = 'Linkshell2',
	['213'] = 'Linkshell2',
	['13'] = 'Party',
	['5'] = 'Party',
}


-- 20 21 22 24 28 29 30 31 35 36 50 56 57 63 81 101 102 110 111 114 122 157 191 209
battle_ids = { [20]=true,[21]=true,[22]=true,[23]=true,[24]=true,[28]=true,[29]=true,[30]=true,[31]=true,[35]=true,[36]=true,[40]=true,[50]=true,[56]=true,[57]=true,[63]=true,[81]=true,[101]=true,[102]=true,[107]=true,[110]=true,[111]=true,[114]=true,[122]=true,[157]=true,[191]=true,[209]=true }
duplidoc_ids = { [190]=true }
filter_ids = { [23]=true,[24]=true,[31]=true,[151]=true,[152]=true }
pause_ids = { [0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[38]=true,[59]=true,[64]=true,[90]=true,[91]=true,[121]=true,[123]=true,[127]=true,[131]=true,[148]=true,[160]=true,[161]=true,[204]=true,[207]=true,[208]=true,[210]=true,[212]=true,[213]=true,[214]=true,[245]=true }
chat_tables = {}
battle_table = {}

find_table = {
	['last_find'] = false,
	['last_index'] = 1,
}


default_settings = {
	log_length = 12,
	log_width = 85,
	battle_all = true, -- Display Battle text in All tab
	battle_off = false, -- Disable processing Battle text entirely
	strict_width = false,
	undocked_window = false,
	undocked_tab = 'All',
	incoming_pause = false,
	drag_status = true,
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
texts.size(t3,settings.text.size)
texts.pad(t3,5)



chat_debug = false

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
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
-- size 12 = x = 78 y = 18 size 10 = x = 65 y = 15  size 8 = x = 51 y = 12 size 6 = x = 38 y = 9
cur_map = 1
image_map = {}

function build_maps()
	x_scale = texts.size(t) * 6.8
	y_scale = texts.size(t) * 1.5
	image_map[0] = { ['x_start'] = 0, ['x_end'] = x_scale, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[0].action = function()
		menu('All','')
	end
	image_map[1] = { ['x_start'] = x_scale+1, ['x_end'] = x_scale*2, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[1].action = function()
		menu('Tell','')
	end
	image_map[2] = { ['x_start'] = image_map[1].x_end+1, ['x_end'] = x_scale*3, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[2].action = function()
		menu('Linkshell','')
	end
	image_map[3] = { ['x_start'] = image_map[2].x_end+1, ['x_end'] = x_scale*4, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[3].action = function()
		menu('Linkshell2','')
	end
	image_map[4] = { ['x_start'] = image_map[3].x_end+1, ['x_end'] = x_scale*5, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[4].action = function()
		menu('Party','')
	end
	image_map[5] = { ['x_start'] = image_map[4].x_end+1, ['x_end'] = x_scale*6, ['y_start'] = -10, ['y_end'] = y_scale}
	image_map[5].action = function()
		menu('Battle','')
	end
	settings.window_visible = true
	image_map[6] = { ['x_start'] = image_map[5].x_end+1, ['x_end'] = x_scale*6.8, ['y_start'] = 0, ['y_end'] = y_scale}
	image_map[6].action = function()
		if settings.window_visible then settings.window_visible = false else settings.window_visible = true end
		config.save(settings, windower.ffxi.get_player().name)
		reload_text()
	end
	image_map[7] = { ['x_start'] = 0, ['x_end'] = x_scale*1.5, ['y_start'] = y_scale+1, ['y_end'] = y_scale*2}
	image_map[7].action = function()
		menu('Bottom','')
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
function header()
	if current_tab == 'Tell' or current_tab == 'All' then chat_log_env['last_seen'] = os.time() end
	if chat_log_env['mention_found'] and current_tab == chat_log_env['last_mention_tab'] then
		if chat_log_env['mention_count'] > 4 then
			chat_log_env['mention_found'] = false
		else
			chat_log_env['mention_count'] = chat_log_env['mention_count'] + 1
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
		blank_space = (settings.log_width*1.6) - string.len(new_text_header)
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
	load_chat_tab(chat_log_env['scroll_num'],'main')
	if settings.undocked_window then load_chat_tab(0,'undocked') end
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
	txt = txt:strip_format()
	txt = timestamp..':'..txt
	if string.len(txt) > settings.log_width then
		local wrap_tmp = ""
		local wrap_cnt = 0
		for w in txt:gmatch("([^%s]+)") do
			cur_len = string.len(w)
			if cur_len > settings.log_width then
				end_len = (settings.log_width*0.94) - wrap_cnt
				suffix = string.sub(w,end_len+1)
				wrap_tmp = wrap_tmp..' '..string.sub(w,1,end_len)..'\n'..suffix
				wrap_cnt = string.len(suffix)
			else
				wrap_cnt = wrap_cnt+(cur_len+1)
				if wrap_cnt < settings.log_width then
					wrap_tmp = wrap_tmp..' '..w
				else
					wrap_cnt = 0
					wrap_tmp = wrap_tmp..'\n'..w
				end
			end
		end
		if wrap_tmp ~= "" then
			txt = wrap_tmp
		end
	end
	txt = string.gsub(txt,'^ ','')
	txt = string.gsub(txt,'[^%z\1-\127]','')
--		print(T(tab_styles[id]):tovstring()..' Table Size: '..#tab_styles[id])
	if tab_styles[id] then
		styles = tab_styles[id]
		--print('ID: '..id..' Msg: '..txt)
		for i=1,#styles,2 do

			txt = string.gsub(txt,styles[i],styles[i+1])
		end
	else
		if battle_ids[id] then
			--print('ID: '..id..' Msg: '..txt)
			styles = tab_styles['battle']
		else
			styles = tab_styles['default']
		end
		for i=1,#styles,2 do
			txt = string.gsub(txt,styles[i],styles[i+1])
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
		if current_tab == 'Battle' then
			current_chat = battle_table
		else
			current_chat = chat_tables[current_tab]
		end
		if #current_chat == 0 then
			return
		end
		tab = current_tab
	else
		tab = settings.undocked_tab
		if tab:lower() == 'battle' then
			current_chat = battle_table
		else
			current_chat = chat_tables[tab]
		end
		scroll_start = false
	end
	if #current_chat < settings.log_length then
		loop_start = 1
		loop_end = #current_chat
	else
		if window == 'main' then
			loop_start = #current_chat - settings.log_length
		else
			loop_start = #current_chat - (settings.log_length+1)
		end
		loop_end = #current_chat
		if scroll_start then
			loop_start = scroll_start
			loop_end = scroll_start + settings.log_length
		end
	end	
	local temp_table = ''
	loop_count = (loop_end - loop_start)
	for i=loop_end,loop_start,-1 do
		if not chat_log_env['finding'] then
			_,count = temp_table:gsub('[\r\n]','')
			if count > loop_count then
				break
			end
		end
		if current_chat[i] then
			if tab == 'Battle' then --everything in battle_table is preformatted
				temp_table = current_chat[i]..'\n'..temp_table
			else
				if string.sub(current_chat[i],1,2) == '**' then --preformatted on addition to 'All'
					temp_table = string.sub(current_chat[i],3)..'\n'..temp_table
				else
					temp_table = convert_text(current_chat[i],tab)..'\n'..temp_table
				end
			end
		end
	end
	if window == 'main' then
		if temp_table ~= '' then
			new_text = new_text..temp_table
		end
	else
		if temp_table ~= '' then
			t3:text('[ \\cs(255,69,0)'..tab..'\\cr ]... .. .\n'..temp_table)
			texts.size(t3, texts.size(t))
			texts.bg_alpha(t3, texts.bg_alpha(t))
			texts.font(t3, texts.font(t))
			t3:visible(true)
		end
	end
end



dragged = nil
last_scroll = 0
function cap(val, min, max)
    return val > max and max or val < min and min or val
end


alt_down = false
windower.register_event('keyboard', function(dik,pressed,flags,blocked)
	if dik == 56 then
		if pressed then
			alt_down = true
		else
			alt_down = false
		end
	end
end)
windower.register_event('mouse', function(eventtype, x, y, delta, blocked)
    hovered = texts.hover(t,x,y)
    if blocked then
        return
    end
    if eventtype == 0 then
        if hovered then
			if chat_debug then
				local boundry_table = {texts.extents(t)}
				local x_boundry = boundry_table[1]+texts.pos_x(t)
				local y_boundry = boundry_table[1]+texts.pos_y(t)
				t2:text("Mouse X: \\cs(0,255,0)"..x.."/"..texts.pos_x(t).."\\cr Y: \\cs(0,255,0)"..y.."/"..texts.pos_y(t).."\\cr Extents: "..x_boundry..' / '..y_boundry)
				t2:visible(true)
			end
			if dragged then
				dragged.text:pos(x - dragged.x, y - dragged.y)
				t2:pos(x - dragged.x, (y - dragged.y)-20)
				return true
			end

			return true
        else
			if dragged then
				return true
			end
        end
    elseif eventtype == 1 then
		v = image_map[0]
		if (x < texts.pos_x(t)+v.x_end and x > texts.pos_x(t)+v.x_start) and (y > texts.pos_y(t)+v.y_start and y < texts.pos_y(t)+v.y_end) then
			cur_map = 0
			v[1] = cur_map
			v.action()
			return true
		else
		for i,v in ipairs(image_map) do
			if (x < texts.pos_x(t)+v.x_end and x > texts.pos_x(t)+v.x_start) and (y > texts.pos_y(t)+v.y_start and y < texts.pos_y(t)+v.y_end) then
				cur_map = i-start_map
				v[1] = cur_map
				v.action()
				return true
			end
		end
		if hovered then
			local pos_x = texts.pos_x(t)
			local pos_y = texts.pos_y(t)
			if settings.drag_status then dragged = {text = t, x = x - pos_x, y = y - pos_y} end
			return true
		end
		end
    elseif eventtype == 2 then
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
		if hovered then
			if current_tab == 'Battle' then
				current_chat = battle_table
			else
				current_chat = chat_tables[current_tab]
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
--				print('Last Scroll: '..last_scroll..' Table Length: '..#current_chat..' / '..(#current_chat - settings.log_length))
				reload_text()
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
	print('Saving Chatlog')
	local temp_table = {}
	--Prune Battle_Log
	for i,v in ipairs(chat_tables['All']) do
		local id = windower.regex.match(v,'[0-9]+:([0-9]+):') or false
		if (id and id[1] and id[1][1] and battle_ids[tonumber(id[1][1])] == true) or string.sub(v,1,2) == '**' then
--			table.insert(battle_table,v)
		else
			table.insert(temp_table,v)
		end
	end
	chat_tables['All'] = nil
	chat_tables['All'] = temp_table
	--Prune Length
	for i,v in pairs(chat_tables) do
		if i == 'All' then max_length = rupt_table_length else max_length = rupt_subtable_length end
		--print('Processing table: '..i..' With Length: '..#v)
		if #v > max_length then
			--print('Pruning table: '..i..' Has '..#v..' / '..max_length)
			temp_table = {}
			for j=#v-max_length,#v,1 do
				table.insert(temp_table,v[j])
			end
			chat_tables[i] = temp_table
			--print('Table chat_tables['..i..'] = '..#chat_tables[i]..' now.')
		end
	end
	rupt_db:write('return ' ..T(chat_tables):tovstring())
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
	local zone = res.zones[windower.ffxi.get_info().zone].en
    if cmd then
		if cmd == 'find' then
			menu('find',args_joined)
		elseif cmd == 'alpha' then
			texts.bg_alpha(t, tonumber(args[1]))
			texts.bg_alpha(t3, tonumber(args[1]))
			settings.bg_alpha = tonumber(args[1])
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
			--reload_text()
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
		elseif cmd == 'tab' then
			if args[1] and valid_tab(args[1]) then
				menu(args[1]:sub(1,1):upper()..args[1]:sub(2):lower(),'')
			elseif not args[1] then
				for i=1,#all_tabs,1 do
					if current_tab == all_tabs[i] then
						if (i+1) > #all_tabs then
							next_tab = 1
						else
							next_tab = i+1
						end
						menu(all_tabs[next_tab],'')
						return
					end
				end
			end
		elseif cmd == 'undock' then
			if args[1] and valid_tab(args[1]) then
				undock(args[1])
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
				settings.mentions[tab]:add(terms)
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
				settings.mentions[tab]:remove(terms)
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
	if current_tab == 'Battle' then
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
	for i=loop_start,1,-1 do
		if string.find(current_table[i]:lower(),c) then
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
	image_map[7].action = function()
	menu('Bottom','')
	end
end

function menu(menuname,c)
		local player = windower.ffxi.get_player()
		local pos = windower.ffxi.get_mob_by_target('me')
		if menuname == 'All' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'All'
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			reload_text()
		elseif menuname == 'Tell' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'Tell'
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			reload_text()
		elseif menuname == 'Linkshell' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'Linkshell'
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			reload_text()
		elseif menuname == 'Linkshell2' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'Linkshell2'
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			reload_text()
		elseif menuname == 'Party' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'Party'
			reset_tab()
			if not chat_tables[current_tab] then chat_tables[current_tab] = {} end
			last_scroll = #chat_tables[current_tab] - settings.log_length
			reload_text()
		elseif menuname == 'Battle' then
			if alt_down then
				undock(menuname)
				return
			end
			current_tab = 'Battle'
			reset_tab()
			last_scroll = #battle_table - settings.log_length
			reload_text()
		elseif menuname == 'Bottom' then
			chat_log_env['scrolling'] = false
			chat_log_env['scroll_num'] = false
			if current_tab == 'Battle' then
				last_scroll = #battle_table - settings.log_length
			else
				last_scroll = #chat_tables[current_tab] - settings.log_length
			end
			reset_tab()
			reload_text()
		elseif menuname == 'find' then
			local c = c:lower()
			if find_table['last_find'] == c then
				last_scroll = find_next(c)
				if not last_scroll then
					windower.ffxi.add_to_chat(200,'No more matches found')
					return
				else
					image_map[7].action = function()
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
					image_map[7].action = function()
					menu('Bottom','')
					end
					return
				else
					image_map[7].action = function()
						menu('findnext','')
					end
					find_table['last_find'] = c
					last_scroll = next_item
					chat_log_env['scroll_num'] = last_scroll
					reload_text()
				end
			end
		elseif menuname == 'findnext' then
			next_item = find_next(find_table['last_find'])
			if not next_item then
				log('No more matches found')
				find_table['last_find'] = false
				chat_log_env['finding'] = false
				image_map[7].action = function()
				menu('Bottom','')
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
	if battle_ids[id] then
		chat_type = 'Battle'
	elseif tab_ids[tostring(id)] then
		chat_type = tab_ids[tostring(id)]
	end
	if #T(settings.mentions['All']) > 0 then
		local stripped = string.gsub(chat,'[^A-Za-z%s]','')
		local splitted = split(stripped,' ')
		for v in settings.mentions['All']:it() do
			if  string.find(chat:lower(),v:lower())then
				if v:lower() == windower.ffxi.get_player().name:lower() then
					if splitted[1] and splitted[1]:lower() == v:lower() then
						return
					end
				end
				chat_log_env['mention_found'] = true
				chat_log_env['mention_count'] = 1
				chat_log_env['last_mention_tab'] = 'All'
				t2:text("New Mention @ \\cs(255,69,0)All\\cr: \\cs(0,255,0)"..v.."\\cr")
				t2:visible(true)
				return
			end
		end
	end
	if chat_type and #T(settings.mentions[chat_type]) > 0 then
		for v in settings.mentions[chat_type]:it() do
			if string.find(chat:lower(),v:lower()) then
				chat_log_env['mention_found'] = true
				chat_log_env['mention_count'] = 1
				chat_log_env['last_mention_tab'] = chat_type
				t2:text("New Mention @ \\cs(255,69,0)"..chat_type.."\\cr: \\cs(0,255,0)"..v.."\\cr")
				t2:visible(true)
				return
			end
		end
	end
end

battlemod_loaded = false


function chat_add(id, chat)
	chat = windower.convert_auto_trans(chat)
	chat = chat:strip_format()
	check_mentions(id,chat)
	if not chat_tables['All'] then
		chat_tables['All'] = {}
	end
	if chat_debug then print('ID: '..id..' Txt: '..chat) end
	chat = string.gsub(chat,'[\r\n]','')
	chat = string.gsub(chat,'',' ')
	chat = string.gsub(chat,string.char(0x07, 0x0A),'')
	chat = string.gsub(chat,'"','\"')
	if battle_ids[id] then
		if battlemod_loaded and (string.match(chat,'.*scores.*') or string.match(chat,'.*uses.*') or string.match(chat,'.*hits.*') or string.match(chat,'.*spikes deal.*') or string.find(chat,'misses') or string.find(chat,'cures')) then
				return
		end
		local battle_text = convert_text(os.time()..':'..id..':'..chat,'Battle')
		table.insert(battle_table,battle_text)
		if settings.battle_all then
			table.insert(chat_tables['All'],'**'..battle_text)
		end
		
	else
		table.insert(chat_tables['All'],os.time()..':'..id..':'..chat)
	end
	if tab_ids[tostring(id)] then
		local chat_type = tab_ids[tostring(id)]
		if not chat_tables[chat_type] then chat_tables[chat_type] = {} end
		table.insert(chat_tables[chat_type],os.time()..':'..id..':'..chat)
	end
	reload_text()
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
			if not battlemod_loaded then modified = original end
			modified = string.gsub(modified,'[\r\n]','')
			modified = string.gsub(modified,'[\\]+$','')
			chat_add(id,modified)
			if not chat_log_env['scrolling'] then reload_text() end
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
	if not incoming_text then incoming_text = windower.register_event('incoming text',process_incoming_text) end
	header()
	t:visible(true)
	reload_text()
	t2:pos(texts.pos_x(t), (texts.pos_y(t)-20))
	coroutine.sleep(1)
	boundries = {texts.extents(t)}
	t3:pos((boundries[1]+texts.pos_x(t)+2),texts.pos_y(t))
end

function unload_events()
    windower.unregister_event(incoming_text)
	write_db()
end

last_save = os.clock()-560
function save_chat_log()
	if os.clock() > last_save+save_delay then
		write_db()
		last_save = os.clock()
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
