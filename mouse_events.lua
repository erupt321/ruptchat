
local dragged = nil
last_scroll = 0

function cap(val, min, max)
    return val > max and max or val < min and min or val
end

windower.register_event('keyboard', function(dik,pressed,flags,blocked)
	if dik == 56 then
		alt_down = pressed
	end
end)

windower.register_event('mouse', function(eventtype, x, y, delta, blocked)
    hovered = texts.hover(TextWindow.main,x,y)
    if blocked then
        return
    end
    if eventtype == 0 then
		if left_clicked then
			return true
		end
		if texts.hover(TextWindow.setup,x,y) then
			if chat_debug then
				local x_extent,y_extent = texts.extents(TextWindow.setup)
				local x_boundry = x_extent+texts.pos_x(TextWindow.setup)
				local y_boundry = y_extent+texts.pos_y(TextWindow.setup)
				TextWindow.notification:text("Mouse X: \\cs(0,255,0)"..x.."/"..texts.pos_x(TextWindow.setup).."\\cr Y: \\cs(0,255,0)"..y.."/"..texts.pos_y(TextWindow.setup).."\\cr Extents: "..x_boundry..' / '..y_boundry)
				TextWindow.notification:visible(true)
			end
		end
        if hovered then
			if chat_debug then
				local x_extent,y_extent = texts.extents(TextWindow.main)
				local x_boundry = x_extent+texts.pos_x(TextWindow.main)
				local y_boundry = y_extent+texts.pos_y(TextWindow.main)
				TextWindow.notification:text("Mouse X: \\cs(0,255,0)"..x.."/"..texts.pos_x(TextWindow.main).."\\cr Y: \\cs(0,255,0)"..y.."/"..texts.pos_y(TextWindow.main).."\\cr Extents: "..x_boundry..' / '..y_boundry)
				TextWindow.notification:visible(true)
			end
			if dragged then
				dragged.text:pos(x - dragged.x, y - dragged.y)
				x_extent,y_extent = texts.extents(TextWindow.main)
				TextWindow.notification:pos(x - dragged.x, (y - dragged.y)-20)
				if settings.chat_input_placement == 1 then
					TextWindow.input:pos(x - dragged.x, (y - dragged.y)+y_extent)
				else
					TextWindow.input:pos(x - dragged.x, (y - dragged.y)-40)
				end	
				if settings.snapback then
					local x_boundry = x_extent+texts.pos_x(TextWindow.main)+2
					TextWindow.undocked:pos(x_boundry,texts.pos_y(TextWindow.main))
				end
				if TextWindow.setup:visible() then
					setup_menu()
				end
				return true
			end

			return true
        else
			if dragged then
				return true
			end
        end
    elseif eventtype == 1 then  --left click
		local pos_x,pos_y = texts.pos(TextWindow.main)
		if hovered then
			for i,v in ipairs(main_map_left) do
				if (x < pos_x+v.x_end and x > pos_x+v.x_start) and (y > pos_y+v.y_start and y < pos_y+v.y_end) then
					v.action(i)
					left_clicked = true
					return true
				end
			end
		end
		if TextWindow.setup:visible() and texts.hover(TextWindow.setup,x,y) then
			local setup_pos_x,setup_pos_y = windower.text.get_location(TextWindow.setup._name)
			for i,v in ipairs(setup_map_left) do
				if (x < setup_pos_x+v.x_end and x > setup_pos_x+v.x_start) and (y > setup_pos_y+v.y_start and y < setup_pos_y+v.y_end) then
					v.action(i)
					left_clicked = true
					return true
				end
			end
		end
		if hovered then
			if settings.drag_status then dragged = {text = TextWindow.main, x = x - pos_x, y = y - pos_y} end
			return true
		end
    elseif eventtype == 2 then --left click off
		if left_clicked then
			left_clicked = false
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
	elseif eventtype == 4 then --right click on
		if hovered then
			local pos_x = texts.pos_x(TextWindow.main)
			local pos_y = texts.pos_y(TextWindow.main)
			for i,v in ipairs(main_map_right) do
				if (x < pos_x+v.x_end and x > pos_x+v.x_start) and (y > pos_y+v.y_start and y < pos_y+v.y_end) then
					v.action()
					right_clicked = true
					return true
				end
			end
		else
			for i,window in pairs(Scrolling_Windows) do
				if window ~= 'main' and window ~= 'undocked' then
					if TextWindow[window]:hover(x,y) then
						if texts.visible(TextWindow[window]) then
							texts.hide(TextWindow[window])
							right_clicked = true
							return true
						end
					end
				end
			end
		end
	elseif eventtype == 5 then --right click off
		if right_clicked then
			right_clicked = false
			return true
		end
	elseif eventtype == 10 then
			hovered = false
			for _,windowObj in pairs(Scrolling_Windows) do
				if texts.hover(TextWindow[windowObj],x,y) then
					if windowObj == 'main' then
						current_chat = chat_tables[current_tab]
					elseif windowObj == 'undocked' then
						current_chat = chat_tables[settings.undocked_tab]
						if settings.undocked_tab == battle_tabname then
							current_chat = battle_table
						end
					else
						if chat_tables[windowObj] then
							current_chat = chat_tables[windowObj]
						end
					end
					if last_scroll_type and last_scroll_type ~= windowObj then
						if last_scroll_type == 'main' and chat_log_env['scrolling'] then
							chat_log_env['scrolling'] = false
							reload_text()
						end
 						chat_log_env['scroll_num'][last_scroll_type] = false
						last_scroll = 0
					end
					last_scroll_type = windowObj
					hovered = true
				end
			end
			if not hovered then return end
			if current_tab == battle_tabname then
				current_chat = battle_table
			end
	
			if current_chat and (last_scroll == 0 or chat_log_env['scroll_num'][last_scroll_type] == false) then
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
					chat_log_env['scroll_num'][last_scroll_type] = false
					last_scroll = 0
					load_chat_tab(false,last_scroll_type)
					reload_text()
				else
					if last_scroll > 0 and last_scroll <= (#current_chat - settings.log_length) then
						chat_log_env['scrolling'] = true
						chat_log_env['scroll_num'][last_scroll_type] = last_scroll
					end
				end
				if chat_log_env['scrolling'] then
					if last_scroll_type ~= 'main' then
						load_chat_tab(chat_log_env['scroll_num'][last_scroll_type],last_scroll_type)
					else
						reload_text()
					end
				end
			end
			return true
    end
end)

function calibrate_font()
	if calibrate_go then
		local size = calibrate_queue['size']
		local extents_x,extents_y = texts.extents(TextWindow.calibrate)
		local font = settings.text.font:lower()
		if not font_wrap_sizes[font] then
			font_wrap_sizes[font] = {}
		end
		if calibrate_queue['type'] == 'char' then
			check_monospace = true
			chat_log_env['monospace'] = false
			font_wrap_sizes[font][size] = {
				x_menu_scale = (extents_x-11) / #all_tabs,
				y_scale = (extents_y+10) / 2,
				y_scale_raw = extents_y / 2,
				x_char_len = (extents_x+10) / calibrate_count,
			}
			font_wrap_sizes[font][size]['minimize_scale'] = font_wrap_sizes[font][size].x_menu_scale * 0.27
			font_wrap_sizes[font][size]['rchat_scale'] = font_wrap_sizes[font][size].x_menu_scale * 0.75
		else
			font_wrap_sizes[font][size]['x_char_scale'] = (extents_x+10)/20
			if check_monospace then
				texts.text(TextWindow.calibrate,calibrate_width2)
				coroutine.sleep(1)
				local second_extents_x,_ = texts.extents(TextWindow.calibrate)
				if extents_x == second_extents_x then
					log("Using a Monospace font! Good for you!")
					chat_log_env['monospace'] = true
					font_wrap_sizes[font]['monospace_flag'] = true
				else
					font_wrap_sizes[font]['monospace_flag'] = false
				end
				check_monospace = false
			end
--			log("Xchar Len: "..font_wrap_sizes[font][size]['x_char_len'].." Xchar Scale: "..font_wrap_sizes[font][size].x_char_scale)
		end
		if size > 6 then
			calibrate_queue['size'] = size-1
			calibrate_go = false
			TextWindow.calibrate:hide()
			coroutine.schedule(calibrate_font,0.5)
		else
			TextWindow.calibrate:hide()
			calibrate_go = false
			if calibrate_queue['type'] == 'char' then
				calibrate_queue['size'] = 12
				calibrate_queue['type'] = 'space'
				calibrate_queue['type_text'] = calibrate_width
				coroutine.schedule(calibrate_font,0.5)
			else
				log('Completed calibration for font: '..font)
				fonts_db:write('return ' ..T(font_wrap_sizes):tovstring())
				coroutine.schedule(build_maps,1)
			end
		end
	else
		if calibrate_queue['size'] == 12  and  calibrate_queue['type'] == 'char' then
			log('Calibrating font: '..settings.text.font)
		end
		texts.font(TextWindow.calibrate,settings.text.font)
		texts.size(TextWindow.calibrate,calibrate_queue.size)
		texts.pad(TextWindow.calibrate,5)
		texts.text(TextWindow.calibrate,calibrate_queue['type_text'])
		texts.show(TextWindow.calibrate)
		calibrate_go = true
		coroutine.schedule(calibrate_font,0.5)
	end
end

function build_maps()
	main_map_left = {}
	main_map_right = {}
	local font = texts.font(TextWindow.main):lower()
	local size = texts.size(TextWindow.main)
	if not font_wrap_sizes then
		font_wrap_sizes = {}
	end
	if not font_wrap_sizes[font] or not font_wrap_sizes[font][size] then
		calibrate_go = false
		calibrate_queue = {}
		calibrate_queue['type'] = 'char'
		calibrate_queue['type_text'] = calibrate_text
		calibrate_queue['size'] = 12
		calibrate_font()
		return
	end
	chat_log_env['monospace'] = font_wrap_sizes[font]['monospace_flag']
	log('Building Click Maps..')
	local x_scale = font_wrap_sizes[font][size].x_menu_scale
	local y_scale = font_wrap_sizes[font][size].y_scale
	local minimize_scale = font_wrap_sizes[font][size].minimize_scale
	local rchat_scale = font_wrap_sizes[font][size].rchat_scale
	local x_extent,_ = texts.extents(TextWindow.main)
	for i,v in ipairs(all_tabs) do
		if i == 1 then
			main_map_left[i] = { ['x_start'] = 0, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		elseif i == 2 then
			main_map_left[i] = { ['x_start'] = x_scale+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale+5}
		elseif i < #all_tabs then
			main_map_left[i] = { ['x_start'] = main_map_left[i-1].x_end+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale+5}
		else
			main_map_left[i] = { ['x_start'] = main_map_left[i-1].x_end+1, ['x_end'] = x_scale*(i*0.99), ['y_start'] = 0, ['y_end'] = y_scale+5}
		end
		main_map_left[i].action = function(current_menu)
			menu(current_menu,'')
		end
	end
	i = #main_map_left
	settings.window_visible = true
	main_map_left[i+1] = { ['x_start'] = main_map_left[i].x_end+1, ['x_end'] = main_map_left[i].x_end+minimize_scale, ['y_start'] = 0, ['y_end'] = y_scale}
	main_map_left[i+1].action = function(current_menu)
		if settings.window_visible then settings.window_visible = false else settings.window_visible = true end
		config.save(settings, windower.ffxi.get_player().name)
		reload_text()
	end
	main_map_left[i+2] = { ['x_start'] = 0, ['x_end'] = x_scale*1.5, ['y_start'] = y_scale+6, ['y_end'] = (y_scale*2)+5}
	main_map_left[i+2].action = function(current_menu)
			menu(current_menu,'')
	end
	local rchat_end = main_map_left[i+1].x_end+rchat_scale
	if rchat_end > x_extent then
		rchat_end = x_extent
	end
	main_map_right[1] = { ['x_start'] = main_map_left[i+1].x_end+1, ['x_end'] = main_map_left[i+1].x_end+rchat_scale, ['y_start'] = 0, ['y_end'] = y_scale}
	main_map_right[1].action = function()
			menu('setup_menu','')
	end
	if settings.snapback then
		local x_extent,_ = texts.extents(TextWindow.main)
		local x_boundry = x_extent+texts.pos_x(TextWindow.main)+2
		TextWindow.undocked:pos(x_boundry,texts.pos_y(TextWindow.main))
	end
	mirror_textboxes()
end

function setup_window_map()
	local font = texts.font(TextWindow.main):lower()
	local size = texts.size(TextWindow.main)
	local x_scale = font_wrap_sizes[font][size].x_menu_scale
	setup_map_left = {}
	local _,y_setup_extent = TextWindow.setup:extents()
	local setup_y_scale = y_setup_extent / (#setup_window_toggles+1)
	for i,v in ipairs(setup_window_toggles) do
		if i == 1 then
			setup_map_left[i] = { ['x_start'] = 5, ['x_end'] = x_scale*1, ['y_start'] = setup_y_scale, ['y_end'] = setup_y_scale*2}
		else
			setup_map_left[i] = { ['x_start'] = 5, ['x_end'] = x_scale*1, ['y_start'] = setup_map_left[i-1]['y_end'], ['y_end'] = setup_y_scale*(i+1)}
		end
		setup_map_left[i].action = function(current_option)
			menu('setup_option',current_option)
		end
	end
end




function mirror_textboxes()
	for _,window in pairs({'undocked','Drops','setup','search','calibrate'}) do
		texts.bg_alpha(TextWindow[window],texts.bg_alpha(TextWindow.main))
		texts.bg_color(TextWindow[window],texts.bg_color(TextWindow.main))
		texts.bold(TextWindow[window],texts.bold(TextWindow.main))
		texts.size(TextWindow[window],texts.size(TextWindow.main))
		texts.alpha(TextWindow[window],texts.alpha(TextWindow.main))
		texts.stroke_width(TextWindow[window],texts.stroke_width(TextWindow.main))
		texts.stroke_alpha(TextWindow[window],texts.stroke_alpha(TextWindow.main))
		texts.stroke_color(TextWindow[window],texts.stroke_color(TextWindow.main))
	end
end
