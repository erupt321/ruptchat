_addon.author = 'Erupt'
_addon.commands = {'rchat'}
_addon.name = 'RuptChat'
_addon.version = '1.2.06072022.1'
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

//rchat bold (Toggle Bold for current font, if font doesn't have a bold variant may error out)

//rchat italic (Toggle Italic for current font, if font doesn't have a italic variant may error out)

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

//rchat enhancedwhitespace (Toggle using Figure Spaces for menus if your on a non monospace font)

//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)
You may also hold down the Alt key and click on a tab name to open a undocked window.

//rchat undocked_hide (Hides the undocked window after 30 seconds of inactivity)

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

//rchat resetpos (Resets the chat window to 200x200 location on your screen)

//rchat vanilla_mode (Turns on vanilla log mode which turns off styles and uses unchanged
client text with color conversion.

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


require('logger')
require('strings')
require('tables')
require('sets')
require('chat')
require('coroutine')
files = require('files')
texts = require('texts')
config = require('config')
tab_channels = require('tabs')
require('mouse_events')
require('text_processing')
require('globals')

function fillspace(spaces)
	local spacer = ''
	if not settings then
		settings = {
			enh_whitespace = true
		}
	end
	for i=1,spaces, 1 do
		if not chat_log_env['monospace'] and (settings and settings.enh_whitespace) then
			spacer = spacer..' '
		else
			spacer = spacer..' '
		end
	end
	return spacer
end

function setup_tabs()
	all_tabs = {}
	calibrate_count = 0
	calibrate_text = ''
	for _,v in ipairs(tab_channels['Tabs']) do
		table.insert(all_tabs,v.name)
		local buffer = 14
		local length = string.len(v.name)
		local space = math.floor((buffer-length)/2)
		local leftovers = buffer-(length+space)
		calibrate_count = calibrate_count+length+space+leftovers
		calibrate_text = calibrate_text..fillspace(space)..v.name..fillspace(leftovers)
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
end

setup_tabs()

current_tab = all_tabname

TextWindow = {}

--main window
settings = config.load(default_settings)
TextWindow.main = texts.new(settings)
texts.bg_visible(TextWindow.main, true)

--Notification Window
TextWindow.notification = texts.new(default_settings)
TextWindow.notification:visible(false)

--Undocked Tab Window
default_settings.flags.draggable = true
TextWindow.undocked = texts.new(default_settings)
TextWindow.undocked:visible(false)
texts.pad(TextWindow.undocked,5)

--Text Input Window
TextWindow.input = texts.new(default_settings)
TextWindow.input:visible(false)
TextWindow.input:bg_alpha(255)

--Drops Window
TextWindow.Drops = texts.new(default_settings)
TextWindow.Drops:visible(false)
TextWindow.Drops:pos(300,300)

--Setup Window
TextWindow.setup = texts.new({flags = {draggable=false}})
TextWindow.setup:visible(false)
texts.pad(TextWindow.setup,5)

--Calibration Window
TextWindow.calibrate = texts.new(default_settings)
TextWindow.calibrate:visible(false)
TextWindow.calibrate:pos(300,300)

--Search Window
TextWindow.search = texts.new(default_settings)
TextWindow.search:visible(false)

Scrolling_Windows = {'main','undocked','Drops','search'}


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

function undock(menu)
	if settings.undocked_window and settings.undocked_tab == menu then
		settings.undocked_window = false
		TextWindow.undocked:visible(false)
		reload_text()
		config.save(settings, windower.ffxi.get_player().name)
	else
		settings.undocked_tab = menu
		settings.undocked_window = true
		texts.bg_alpha(TextWindow.undocked, texts.bg_alpha(TextWindow.main))
		texts.size(TextWindow.undocked, texts.size(TextWindow.main))
		reload_text()
		config.save(settings, windower.ffxi.get_player().name)
	end
end

queue_reload_text = false
reload_clock = os.clock()+1

function write_db()
	local start_time = os.clock()
	local temp_table = {}
	local tinsert = table.insert
	for i,v in pairs(chat_tables) do --Prune renamed / dead tab data
		if not valid_tab(i) and i ~= 'Drops' then
			chat_tables[i] = nil
		end
	end
	--Prune Length
	chat_tables[battle_tabname] = battle_table
	for i,v in pairs(chat_tables) do
		if i == all_tabname then max_length = rupt_table_length else max_length = rupt_subtable_length end
		if #v > max_length then
			temp_table = {}
			for j=#v-max_length,#v,1 do
				tinsert(temp_table,v[j])
			end
			chat_tables[i] = temp_table
		end
	end
	rupt_db:write('return ' ..T(chat_tables):tovstring())
	battle_table = chat_tables[battle_tabname]
	chat_tables[battle_tabname] = nil
	if settings.archive and archive_table and #archive_table > 0 then
		local archive_clock = os.clock()
		print('Chatlog Save Finished in '..(archive_clock - start_time)..'s, Archiving New Text')
		archive_filename = files.new('chatlogs/'..windower.ffxi.get_player().name..'-'..os.date('%Y%m')..'.log')
		if not files.exists(archive_filename) then
			files.create(archive_filename)
		end
		local fappend = files.append
		if #archive_table > 200 then
			i = 1
			while i < #archive_table do
				local end_range
				if (i + 200) > #archive_table then
					end_range = #archive_table
				else
					end_range = i+200
				end
				fappend(archive_filename,table.concat(archive_table,'\n',i,end_range))
				i = end_range
			end
		else
			fappend(archive_filename,table.concat(archive_table,'\n'))		
		end
		archive_table = nil
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
		print('Loading Chat Tables '..rupt_savefile)
		chat_tables = require(rupt_savefile)
		if chat_tables[battle_tabname] then
			battle_table = chat_tables[battle_tabname]
			chat_tables[battle_tabname] = nil
		end
		if windower.ffxi.get_info().logged_in then
		fontfile = 'data/'..windower.ffxi.get_player().name..'-fontsizes.lua'
		fonts_db = files.new(fontfile)
		if fonts_db:exists() then
			font_wrap_sizes = dofile(windower.addon_path..fontfile)
		end
		end
	end
end


load_db_file()

function find_all(s)
	local s_pat = s:gsub(' ','.'):lower()
	local found = false
	chat_tables[battle_tabname] = battle_table
	for i,tab in pairs(chat_tables) do
		if i ~= 'search' then
			for line,txt in ipairs(tab) do
				if string.lower(txt):find(s_pat) then
					found = true
					if not txt:find('RuptChat') then
						table.insert(chat_tables['search'],txt)
					end
				end
			end
		end
	end
	chat_tables[battle_tabname] = nil
	if found then
		table.insert(chat_tables['search'],os.time()..':207:RuptChat: Search for ['..s..'] completed with '..#chat_tables['search']..' results')
	end
	return found
end

function addon_command(...)
    local args = T{...}
    local cmd = args[1]
	args:remove(1)
	local args_joined = table.concat(args," ")
    if cmd then
		if cmd == 'find' then
			menu('find',args_joined)
		elseif cmd == 'findall' then
			chat_tables['search'] = {}
			if find_all(args_joined) then
				load_chat_tab(0,'search')
				TextWindow.search:show()
			else
				log('No Results for: '..args_joined)
			end
		elseif cmd == 'alpha' then
			texts.bg_alpha(TextWindow.main, tonumber(args[1]))
			settings.bg_alpha = tonumber(args[1])
			config.save(settings, windower.ffxi.get_player().name)
			mirror_textboxes()			
		elseif cmd == 'bold' then
			if settings.flags and settings.flags.bold then
				settings.flags.bold = false
			else
				settings.flags.bold = true
			end
			texts.bold(TextWindow.main, settings.flags.bold)
			mirror_textboxes()
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'italic' then
			if settings.flags and settings.flags.italic then
				settings.flags.italic = false
			else
				settings.flags.italic = true
			end
			texts.italic(TextWindow.main, settings.flags.italic)
			mirror_textboxes()
			config.save(settings, windower.ffxi.get_player().name)
		elseif cmd == 'stroke_width' then
			texts.stroke_width(TextWindow.main, tonumber(args[1]))
			config.save(settings, windower.ffxi.get_player().name)
			mirror_textboxes()
		elseif cmd == 'stroke_color' then
			if #args > 3 then
				log('Missing a Color')
				return
			end
			texts.stroke_color(TextWindow.main, tonumber(args[1]),tonumber(args[2]),tonumber(args[3]))
			config.save(settings, windower.ffxi.get_player().name)
			mirror_textboxes()
		elseif cmd == 'stroke_alpha' then
			texts.stroke_alpha(TextWindow.main, tonumber(args[1]))
			config.save(settings, windower.ffxi.get_player().name)
			mirror_textboxes()
		elseif cmd == 'size' then
			texts.size(TextWindow.main, tonumber(args[1]))
			texts.size(TextWindow.undocked, tonumber(args[1]))
			settings.text.size = tonumber(args[1])
			config.save(settings, windower.ffxi.get_player().name)
			build_maps()
		elseif cmd == 'font' then
			texts.font(TextWindow.main, args_joined)
			texts.font(TextWindow.undocked, args_joined)
			settings.text.font = args_joined
			config.save(settings, windower.ffxi.get_player().name)
			calibrate_go = false
			calibrate_queue = {}
			calibrate_queue['type'] = 'char'
			calibrate_queue['type_text'] = calibrate_text
			calibrate_queue['size'] = 12
			calibrate_font()
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
		elseif cmd == 'undocked_hide' then
			if settings.undocked_hide then
				log('Setting undocked_hide to false')
				settings.undocked_hide = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting undocked_hide to true')
				settings.undocked_hide = true
				config.save(settings, windower.ffxi.get_player().name)
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
			if settings.strict_width then
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
			boundries = {texts.extents(TextWindow.main)}
			local t_pos_x = texts.pos_x(TextWindow.main)
			local t_pos_y = texts.pos_y(TextWindow.main)
			TextWindow.undocked:pos((boundries[1]+t_pos_x+2),t_pos_y)
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
			local t_pos_x = texts.pos_x(TextWindow.main)
			local t_pos_y = texts.pos_y(TextWindow.main)
			local x_extent,y_extent = texts.extents(TextWindow.main)
			if settings.chat_input_placement == 1 then
				log('Setting chat_input_placement to Top')
				settings.chat_input_placement = 2
				TextWindow.input:pos(t_pos_x, (t_pos_y-40))
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting chat_input_placement to Bottom')
				settings.chat_input_placement = 1
				TextWindow.input:pos(t_pos_x,(t_pos_y+y_extent))
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
			TextWindow.Drops:show()
		elseif cmd == 'enhancedwhitespace' then
			if settings.enh_whitespace then
				log('Setting enh_whitespace to false')
				settings.enh_whitespace = false
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting enh_whitespace to true')
				settings.enh_whitespace = true
				config.save(settings, windower.ffxi.get_player().name)
			end
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
		elseif cmd == 'vanilla_mode' then
			if settings.vanilla_mode then
				log('Setting vanilla_mode to false')
				settings.vanilla_mode = false
				TextWindow.main:bg_color(0,0,0)
				TextWindow.undocked:bg_color(0,0,0)
				config.save(settings, windower.ffxi.get_player().name)
			else
				log('Setting vanilla_mode to true')
				settings.vanilla_mode = true
				TextWindow.main:bg_color(30,30,74)
				TextWindow.undocked:bg_color(30,30,74)
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
		elseif cmd == 'calibrate' then
			setup_tabs()
			calibrate_go = false
			calibrate_queue = {}
			calibrate_queue['type'] = 'char'
			calibrate_queue['type_text'] = calibrate_text
			calibrate_queue['size'] = 12
			calibrate_font()
		elseif cmd == 'resetpos' then
			TextWindow.main:pos(200,200)
		elseif cmd == 'show' then
			TextWindow.main:visible(true)
		elseif cmd == 'hide' then
			TextWindow.main:visible(false)
			TextWindow.undocked:visible(false)
		elseif cmd == 'save' then
			write_db()
		elseif cmd == 'testline' then
			chat_add(222,"ï4üAlamihgoû(E) : Feel free to use this chat channel if you have any questions about FFXI, monk-related or otherwise.")
		elseif cmd == 'debug' then
			if chat_debug then chat_debug = false else chat_debug = true end
		end
	end
	if TextWindow.setup:visible() then
		setup_menu()
	end
end
windower.register_event('addon command', addon_command)

function setup_menu()
	local setup_text = '[ \\cs(255,69,0)Setup\\cr ]... .. .\n'
	for _,v in ipairs(setup_window_toggles) do
		setup_text = setup_text..'['..v..'] = '
		if settings[v] then
			setup_text = setup_text..'\\cs(0,255,0)On\\cr Off\n'
		else
			setup_text = setup_text..'On \\cs(255,0,0)Off\\cr\n'
		end
	end
	texts.size(TextWindow.setup, texts.size(TextWindow.main))
	texts.bg_alpha(TextWindow.setup, texts.bg_alpha(TextWindow.main))
	texts.font(TextWindow.setup, texts.font(TextWindow.main))
	TextWindow.setup:text(setup_text)
	if ext_x and ext_x > 10 then
		local main_ext_x,main_ext_y = TextWindow.main:extents()
		local main_pos_x,main_pos_y = TextWindow.main:pos()
		TextWindow.setup:pos((main_pos_x+main_ext_x)-ext_x,(main_pos_y-ext_y))
		TextWindow.setup:visible(true)
		coroutine.schedule(setup_window_map,0.2)
	else
		ext_x,ext_y = TextWindow.setup:extents()
		local main_ext_x,main_ext_y = TextWindow.main:extents()
		local main_pos_x,main_pos_y = TextWindow.main:pos()
		TextWindow.setup:pos((main_pos_x+main_ext_x)-ext_x,(main_pos_y-ext_y))
		TextWindow.setup:visible(true)
		coroutine.schedule(setup_menu,0.2)
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
--	chat_log_env['scroll_num'] = {}
	find_table['last_find'] = false
	find_table['last_index'] = 1
	chat_log_env['finding'] = false
	main_map_left[#main_map_left].action = function(current_menu)
	menu(current_menu,'')
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
		elseif menunumber == #main_map_left then  --Bottom menu
			chat_log_env['scrolling'] = false
			--chat_log_env['scroll_num'] = false
			if current_tab == battle_tabname then
				last_scroll = #battle_table - settings.log_length
			else
				last_scroll = #chat_tables[current_tab] - settings.log_length
			end
			reset_tab()
			reload_text()
		elseif menunumber == 'find' then  --Triggered from addon_command, remakes main_map_left fn = findnext
			local c = c:lower()
			if find_table['last_find'] == c then
				last_scroll = find_next(c)
				if not last_scroll then
					windower.ffxi.add_to_chat(200,'No more matches found')
					return
				else
					main_map_left[#main_map_left].action = function(current_menu)
						menu('findnext','')
						end
					chat_log_env['scroll_num']['main'] = last_scroll
					reload_text()
				end
			else
				local next_item = find_next(c)
				if not next_item then
					log('No Matches for: '..c)
					find_table['last_find'] = false
					chat_log_env['finding'] = false
					main_map_left[#main_map_left].action = function(current_menu)
					menu(current_menu,'')
					end
					return
				else
					main_map_left[#main_map_left].action = function(current_menu)
						menu('findnext','')
					end
					find_table['last_find'] = c
					last_scroll = next_item
					chat_log_env['scroll_num']['main'] = last_scroll
					reload_text()
				end
			end
		elseif menunumber == 'findnext' then
			next_item = find_next(find_table['last_find'])
			if not next_item then
				log('No more matches found')
				find_table['last_find'] = false
				chat_log_env['finding'] = false
				main_map_left[#main_map_left].action = function(current_menu)
				menu(current_menu,'')
				end
				chat_log_env['scrolling'] = true
				reload_text()
				return
			else
				last_scroll = next_item
				chat_log_env['scroll_num']['main'] = last_scroll
				reload_text()
			end
		elseif menunumber == 'setup_menu' then
			if TextWindow.setup:visible() then
				texts.visible(TextWindow.setup,false)
			--	ext_x = nil
			else
				setup_menu()
			end
		elseif menunumber == 'setup_option' then
			addon_command(setup_window_commands[tonumber(c)])
		end

end

function mention_check()
	if chat_log_env['mention_found'] and current_tab == chat_log_env['last_mention_tab'] then
		chat_log_env['mention_found'] = false
		TextWindow.notification:bg_color(0,0,0)
		mirror_textboxes()
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
				TextWindow.notification:text("New Mention @ \\cs(255,69,0)All\\cr: \\cs(0,255,0)"..v.."\\cr")
				TextWindow.notification:visible(true)
				TextWindow.notification:bg_color(0,0,0)
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
					TextWindow.notification:text("New Mention @ \\cs(255,69,0)"..chat_type.."\\cr: \\cs(0,255,0)"..v.."\\cr "..stripped)
				else
					TextWindow.notification:text("New Mention @ \\cs(255,69,0)"..chat_type.."\\cr: \\cs(0,255,0)"..v.."\\cr")
					TextWindow.notification:bg_color(0,0,0)
				end
				TextWindow.notification:visible(true)
				return
			end
		end
	end
end


incoming_text = false

function load_events()
	if not incoming_text then 
		incoming_text = windower.register_event('incoming text',process_incoming_text)
	end
	header()
	TextWindow.main:visible(true)
	reload_text()
	local t_pos_x = texts.pos_x(TextWindow.main)
	local t_pos_y = texts.pos_y(TextWindow.main)
	TextWindow.notification:pos(t_pos_x, (t_pos_y-20))
	coroutine.sleep(1)
	x_extent,y_extent = texts.extents(TextWindow.main)
	TextWindow.undocked:pos((x_extent+t_pos_x+2),t_pos_y)
	if settings.chat_input_placement == 1 then
		TextWindow.input:pos(t_pos_x,(t_pos_y+y_extent))
	else
		TextWindow.input:pos(t_pos_x,(t_pos_y-40))
	end
	mirror_textboxes()
end

function unload_events()
    windower.unregister_event(incoming_text)
	write_db()
end
windower.register_event('logout','unload', unload_events)

last_save = os.clock()-560

function save_chat_log()
	if settings.chat_input and windower.chat.is_open() then
		local chat,_ = windower.chat.get_input()
		chat = windower.convert_auto_trans(chat)
		chat = chat:strip_format()
		TextWindow.input:text(chat)
		TextWindow.input:show()
	else
		TextWindow.input:hide()
	end
	if settings.split_drops and texts.visible(TextWindow.Drops) then
		if os.clock() > drops_timer then
			TextWindow.Drops:hide()
		end
	end
	if settings.undocked_hide and texts.visible(TextWindow.undocked) then
		if os.clock() > undocked_timer then
			TextWindow.undocked:hide()
		end
	end
	if chat_log_env['mention_found'] and settings.battle_flash and chat_log_env['last_mention_tab'] == battle_tabname then
		local t = os.clock()%1 -- Flashing colors from Byrth's answering machine
		windower.text.set_bg_color(TextWindow.notification._name,255,100,100+150*math.sin(t*math.pi),100+150*math.sin(t*math.pi))
	end
	if os.clock() > last_save+save_delay then
		coroutine.schedule(write_db,0)
		last_save = os.clock()
	end
	if queue_reload_text and reload_clock < os.clock() then
		coroutine.schedule(reload_text,0)
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
		fontfile = 'data/'..windower.ffxi.get_player().name..'-fontsizes.lua'
		fonts_db = files.new(fontfile)
		coroutine.sleep(0.1)
	end
	load_db_file()
	load_events()
	coroutine.schedule(build_maps,2.5)
end)

windower.register_event('load', function()
	if windower.ffxi.get_info().logged_in then
		rupt_savefile = 'chatlogs/'..windower.ffxi.get_player().name..'-current'
		rupt_db = files.new(rupt_savefile..'.lua')
		style_templates = require('templates')
		tab_styles = require('styles')
		fontfile = 'data/'..windower.ffxi.get_player().name..'-fontsizes.lua'
		fonts_db = files.new(fontfile)
		coroutine.sleep(0.1)
		load_db_file()
	end
	load_events()
	coroutine.schedule(build_maps,2.5)
end)
