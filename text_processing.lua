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
				end_len = (log_width*font_wrap_sizes[texts.font(TextWindow.main):lower()][2]) - wrap_cnt
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

function header()
	local cur_font = texts.font(TextWindow.main):lower()
	if not font_wrap_sizes[cur_font] then
		font_wrap_sizes[cur_font] = { 1.9,0.8,1,1 }
	end
	if current_tab == 'Tell' or current_tab == all_tabname then chat_log_env['last_seen'] = os.time() end
	if chat_log_env['mention_found'] and (current_tab == chat_log_env['last_mention_tab'] or (settings.undocked_window and settings.undocked_tab == chat_log_env['last_mention_tab'])) then
		if chat_log_env['mention_count'] < os.clock() then
			chat_log_env['mention_found'] = false
			TextWindow.notification:bg_color(0,0,0)
			TextWindow.notification:visible(false)
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
						TextWindow.notification:text("New Tell From: \\cs(0,255,0)"..last_from[1][2].."\\cr")
						TextWindow.notification:visible(true)
						chat_log_env['mention_found'] = false
						TextWindow.notification:bg_color(0,0,0)
						new_text_header = new_text_header..v..'*'..fillspace(leftovers-1)
					else
						if not chat_log_env['mention_found'] then
							TextWindow.notification:visible(false)
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
		blank_space = (settings.log_width*font_wrap_sizes[texts.font(TextWindow.main):lower()][1]) - string.len(new_text_header)
		new_text_header = new_text_header..fillspace(blank_space)..'\n'
	else
		new_text_header = new_text_header..'\n'
	end
	if chat_log_env['finding'] then
		new_text_header = new_text_header..'[Find Next]\n'
		TextWindow.notification:text("Searching for: \\cs(0,255,0)"..find_table['last_find'].."\\cr")
		TextWindow.notification:visible(true)
	elseif chat_log_env['scrolling'] then
		new_text_header = new_text_header..'[Jump to Bottom]\n'
		TextWindow.notification:visible(false)
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

local new_text = ''

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
				TextWindow.undocked:text('[ \\cs(255,69,0)'..tab..'\\cr ]... .. .\n'..temp_table)
				texts.size(TextWindow.undocked, texts.size(TextWindow.main))
				texts.bg_alpha(TextWindow.undocked, texts.bg_alpha(TextWindow.main))
				texts.font(TextWindow.undocked, texts.font(TextWindow.main))
				TextWindow.undocked:visible(true)
			elseif window == 'Drops' then
				TextWindow.drops:text('[ \\cs(255,69,0)'..tab..'\\cr ]... .. .\n'..temp_table)
				texts.size(TextWindow.drops, texts.size(TextWindow.main))
				texts.bg_alpha(TextWindow.drops, texts.bg_alpha(TextWindow.main))
				texts.font(TextWindow.drops, texts.font(TextWindow.main))
				TextWindow.drops:visible(true)
			end
		end
	end
end

function reload_text()
	header()
	if settings.window_visible then TextWindow.main:text(new_text_header..new_text) else TextWindow.main:text(new_text_header) end
end

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

