function string.flen(txt,pixel)
	_,n = string.gsub(txt,"[^%s]","")
	_,m = string.gsub(txt,"%s","")
	return (n+m)*pixel
end

function wrap_text(txt,log_width)
	local slen = string.len
	local ssub = string.sub
	local sgsub = string.gsub
	if not font_wrap_sizes or not font_wrap_sizes[texts.font(TextWindow.main):lower()] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_scale'] then
		font_pixel = 9
	else
		font_pixel = font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_len'] or 9
	end
	if chat_log_env['monospace'] then
		local log_width = log_width
		if slen(txt) > log_width/font_pixel then
			local wrap_tmp = ""
			local wrap_cnt = 0
			for w in txt:gmatch("([^%s]+)") do
				local cnt_deflate_pre = 0
				local cnt_deflate_suf = 0
				if string.find(w,'{:') then
					cnt_deflate_pre = 1
				end
				if string.find(w,':}') then
					cnt_deflate_suf = 1
				end
				if settings.vanilla_mode then
					if string.find(w,'['..string.char(0x1E, 0x1F)..'].') then
						cnt_deflate_pre = cnt_deflate_pre + 1
					end
				end
				cur_len = slen(w)-cnt_deflate_pre-cnt_deflate_suf
				if cur_len+wrap_cnt > (log_width/font_pixel) then
					end_len = ((log_width/font_pixel) - wrap_cnt)-1
					local new_word = ssub(w,1,end_len)
					
					if slen(wrap_tmp)+slen(new_word)-cnt_deflate_pre > (log_width/font_pixel) then
						wrap_tmp = wrap_tmp..'\n'..w
						wrap_cnt = 0-cnt_deflate_suf
					else
						suffix = ssub(w,end_len+1)
						if string.find(new_word,'{:') then
							wrap_tmp = wrap_tmp..'\n'..new_word..suffix
							wrap_cnt = slen(new_word..suffix)-1
						else
							if slen(new_word) < 7 then
								wrap_tmp = wrap_tmp..'\n'..new_word..suffix
								wrap_cnt = 10-cnt_deflate_pre-cnt_deflate_suf
							else
								wrap_tmp = wrap_tmp..' '..new_word..'\n'..suffix
								wrap_cnt = slen(suffix)-cnt_deflate_suf
							end
						end
					end
				else
					wrap_cnt = wrap_cnt+(cur_len+1)
					if wrap_cnt < (log_width/font_pixel) then
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
	else
		local log_width = log_width+(log_width*.038)
		local txt_len = string.flen(txt,font_pixel)
		if txt_len > log_width+10 then
			local wrap_tmp = ""
			local wrap_cnt = 0
			local log_char = math.ceil(((log_width+3) / font_pixel))-1
			for w in txt:gmatch("[^%s]+") do
				local cnt_deflate_pre = 0
				local cnt_deflate_suf = 0
				if string.find(w,'{:') then
					cnt_deflate_pre = 1
				end
				if string.find(w,':}') then
					cnt_deflate_suf = 1
				end
				if settings.vanilla_mode then
					if string.find(w,'['..string.char(0x1E, 0x1F)..'].') then
						cnt_deflate_pre = cnt_deflate_pre + 1
					end
				end
				cur_len = (slen(w)-cnt_deflate_pre-cnt_deflate_suf)*font_pixel
				if wrap_cnt+cur_len > log_width+6 then
					local end_len = log_char - ((wrap_cnt+cur_len)/font_pixel)
					local new_word = ssub(w,1,end_len)
					local suffix = ssub(w,end_len+1)
					if string.flen(wrap_tmp,font_pixel)+string.flen(new_word,font_pixel) > log_width+6 then
						wrap_tmp = wrap_tmp..'\n'..w
						wrap_cnt = 0
					else
						if string.find(new_word,'{:') then
							wrap_tmp = wrap_tmp..'\n'..new_word..suffix
							wrap_cnt = string.flen(new_word..suffix,font_pixel)
						else
							if slen(new_word) < 7 then
								wrap_tmp = wrap_tmp..'\n'..new_word..suffix
								wrap_cnt = 0
							else
								wrap_tmp = wrap_tmp..' '..ssub(w,1,end_len)..'\n'..suffix
								wrap_cnt = string.flen(suffix,font_pixel)
							end
						end
					end
				else
					wrap_cnt = (wrap_cnt+cur_len+font_pixel)
					wrap_tmp = wrap_tmp..' '..w
				end
			end
			if wrap_tmp ~= "" then
				txt = wrap_tmp
			end
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
	if not settings.vanilla_mode then txt = timestamp..':'..txt end
	local slen = string.len
	local ssub = string.sub
	local sgsub = string.gsub
	if tab_style == 'main' or settings.log_dwidth == 0 then 
		log_width = settings.log_width
	else
		log_width = settings.log_dwidth
	end
	if not settings.vanilla_mode then
		txt = txt:gsub('['..string.char(0x1E, 0x1F, 0x7F)..'].', '')
		txt = sgsub(txt,'[^%z\1-\127]','')
	else
		--txt = string.gsub(txt,string.char(0x1E, 0x01),'')
	end
	txt = wrap_text(txt,log_width)
	txt = sgsub(txt,'^ ','')
	if not settings.vanilla_mode then
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
	else
		if string.find(txt,'['..string.char(0x1E, 0x1F)..']') then
			txt = string.gsub(txt,'['..string.char(0x1F)..'](.)',function(w)
			local col = tonumber(string.byte(w))
			--print('Code: '..col..txt)
			if col == 1 then
				col = id
			end
			if vanilla_color_codes[col] and vanilla_color_codes[col] ~= '' then
				return '\\cs('..vanilla_color_codes[col]..')'
			else 
				return
			end
			end)
		
			if string.find(txt,string.char(0x1E)) then
				txt = string.gsub(txt,'['..string.char(0x1E)..'](.)',function(w)
				local col = tonumber(string.byte(w))
				--print('Code2: '..col..txt)
				if col == 1 then
					col = id
				end
			if vanilla_color_codes[col] and vanilla_color_codes[col] ~= '' then
				return '\\cs('..vanilla_color_codes[col]..')'
			else return  end
			end)
		end

		end
		if vanilla_color_codes[id] == '' or vanilla_color_codes[id] == nil then
			vanilla_color_codes[id] = "225, 222, 247"
		end
		txt = sgsub(txt,"{(\n?):",'%1\\cs(0,255,0){\\cr\\cs('..vanilla_color_codes[id]..')')
		txt = sgsub(txt,":(\n?)}",'\\cr\\cs(255,0,0)}\\cr%1\\cs('..vanilla_color_codes[id]..')')
		txt = sgsub(txt,'[^%z\1-\127]','')
		txt = txt:gsub('.$', '')
		txt = string.gsub(txt,string.char(0x1E, 0x01),'\\cr')
		txt = txt:gsub('['..string.char(0x7F)..']', '')
		txt = '\\cs('..vanilla_color_codes[id]..')'..txt..'\\cr'

	end
	return txt
end

function header()
	local cur_font = texts.font(TextWindow.main):lower()
	if not font_wrap_sizes or not font_wrap_sizes[texts.font(TextWindow.main):lower()] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_scale'] then
		font_pixel = 9
		space_pixel = 9
	else
		font_pixel = font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_len']
	end
	if current_tab == 'Tell' or current_tab == all_tabname then chat_log_env['last_seen'] = os.time() end
	if chat_log_env['mention_found'] and (current_tab == chat_log_env['last_mention_tab'] or (settings.undocked_window and settings.undocked_tab == chat_log_env['last_mention_tab'])) then
		if chat_log_env['mention_count'] < os.clock() then
			chat_log_env['mention_found'] = false
			TextWindow.notification:bg_color(0,0,0)
			TextWindow.notification:visible(false)
		end
	end
	local buffer = 14
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
		if not chat_log_env['monospace'] and settings.enh_whitespace then
			new_text_header = new_text_header..'[ - ]   [rChat]'
		else
			new_text_header = new_text_header..'[ - ]   [rChat]'
		end
	else
		if not chat_log_env['monospace'] and settings.enh_whitespace then
			new_text_header = new_text_header..'[ + ]   [rChat]'
		else
			new_text_header = new_text_header..'[ + ]   [rChat]'
		end
	end
	if settings.strict_width then
		blank_space = ((settings.log_width+(settings.log_width*0.038)) - ((calibrate_count+15)*font_pixel)) / font_pixel
		new_text_header = new_text_header..fillspace(math.ceil(blank_space))..'\n'
	else
		new_text_header = new_text_header..'\n'
	end
	if chat_log_env['finding'] then
		new_text_header = new_text_header..'[Find Next]\n'
		TextWindow.notification:text("Searching for: \\cs(0,255,0)"..find_table['last_find'].."\\cr")
		TextWindow.notification:visible(true)
	elseif chat_log_env['scrolling'] and last_scroll_type == 'main' then
		new_text_header = new_text_header..'[Jump to Bottom]\n'
		TextWindow.notification:visible(false)
	else
		new_text_header = new_text_header..'\n'
	end
	if not chat_log_env['scrolling'] and not chat_log_env['finding'] then
		load_chat_tab(false,'main')
	else
		if chat_log_env['scrolling'] and last_scroll_type == 'main' then
			load_chat_tab(chat_log_env['scroll_num']['main'],'main')
		else
			load_chat_tab(false,'main')
		end
	end
	if settings.undocked_window then
		if not chat_log_env['scrolling'] or last_scroll_type ~= 'undocked' then
			load_chat_tab(false,'undocked')
		end
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
		if not scroll_start or scroll_start == 0 then
			scroll_start = false
		end
		if window == 'undocked' then
			tab = settings.undocked_tab
		elseif chat_tables[window] then
			tab = window
		else
			return
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
			if chat_log_env['scrolling'] and last_scroll_type == window then
				scroll_head = '[Scrolling]'
			else
				scroll_head = ''
			end
			if not font_wrap_sizes or not font_wrap_sizes[texts.font(TextWindow.main):lower()] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)] or not font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_scale'] then
				font_pixel = 9
			else
				font_pixel = font_wrap_sizes[texts.font(TextWindow.main):lower()][texts.size(TextWindow.main)]['x_char_len']
			end
			local header = '[ \\cs(255,69,0)'..tab..'\\cr ]... .. .'
			if settings.log_dwidth == 0 then
				log_width = settings.log_width
			else
				log_width = settings.log_dwidth
			end
			local log_char = math.ceil(log_width / font_pixel)
			blank_space = log_char+6 - (string.len(header)-18)
			texts.text(TextWindow[window],header..fillspace(blank_space)..'\n'..scroll_head..temp_table)
			texts.size(TextWindow[window], texts.size(TextWindow.main))
			texts.bg_alpha(TextWindow[window], texts.bg_alpha(TextWindow.main))
			texts.font(TextWindow[window], texts.font(TextWindow.main))
			texts.visible(TextWindow[window],true)
		end
	end
end

function reload_text()
	header()
	if settings.window_visible then TextWindow.main:text(new_text_header..new_text) else TextWindow.main:text(new_text_header) end
end

function chat_add(id, chat)
	if id == 221 or id == 222 then
		local player_name = string.match(chat,"[^a-zA-Z]+([a-zA-Z]+)")
		local chat_head = string.match(chat,"([^a-zA-Z]+)")
		local rank = 0
		local mentor_flag = 'B'
		local rank_match = false
		if player_name then
			for _,flag in pairs(assist_flags.labels) do
				local cur_flag = assist_flags[flag]
				for cur_rank,rank_hex in pairs(cur_flag) do
					rank_match = string.find(chat_head,rank_hex) or false
					if rank_match then
						rank = cur_rank
						mentor_flag = string.upper(string.sub(flag,1,1))
						break
					end
				end
				if rank_match then
					break
				end
			end
		end
		table.insert(archive_table,os.date('[%x@%X]')..':'..id..':'..chat)
		if rank == 0 then 
			chat = "[R"..rank..']'..chat
		else
			chat = "["..mentor_flag.."-R"..rank..']'..string.sub(chat,4)
		end
		chat = string.gsub(chat,"ü","")
		if chat_debug then print('ID: '..id..' Txt: '..chat) end
	end
	if not settings.vanilla_mode then
		chat = chat:strip_colors()
	end
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
		if not archive_table then
			archive_table = {}
		end
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
			if settings.undocked_hide and settings.undocked_tab == battle_tabname then
				TextWindow.undocked:show()
				undocked_timer = os.clock()+30
			end
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
		if settings.undocked_hide and settings.undocked_tab == chat_type then	
			TextWindow.undocked:show()
			undocked_timer = os.clock()+30
		end
	end
	if not queue_reload_text then --Avoid having 8 messages that are received at the same time process
		queue_reload_text = true
		reload_clock = os.clock()+1
	end
end

vanilla_color_codes = dofile(windower.addon_path..'data/colors.lua')

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

