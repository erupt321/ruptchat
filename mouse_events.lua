
local dragged = nil
local clicked = false
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
				_,y_extent = texts.extents(TextWindow.main)
				TextWindow.notification:pos(x - dragged.x, (y - dragged.y)-20)
				if settings.chat_input_placement == 1 then
					TextWindow.input:pos(x - dragged.x, (y - dragged.y)+y_extent)
				else
					TextWindow.input:pos(x - dragged.x, (y - dragged.y)-40)
				end	
				if settings.snapback then
					local boundry_table = {texts.extents(TextWindow.main)}
					local x_boundry = boundry_table[1]+texts.pos_x(TextWindow.main)+2
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
			ext_x,ext_y = TextWindow.setup:extents()
			local main_ext_x,main_ext_y = TextWindow.main:extents()
			local main_pos_x,main_pos_y = TextWindow.main:pos()
			setup_pos_y = main_pos_y-ext_y
			local setup_pos_x,_ = texts.pos(TextWindow.setup)
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
		local pos_x = texts.pos_x(TextWindow.main)
		local pos_y = texts.pos_y(TextWindow.main)
		for i,v in ipairs(main_map_right) do
			if (x < pos_x+v.x_end and x > pos_x+v.x_start) and (y > pos_y+v.y_start and y < pos_y+v.y_end) then
				v.action()
				right_clicked = true
				return true
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
					if windowObj == 'Drops' then
						current_chat = chat_tables['Drops']
					end
					if windowObj == 'main' then
						current_chat = chat_tables[current_tab]
					elseif windowObj == 'undocked' then
						current_chat = chat_tables[settings.undocked_tab]
						if settings.undocked_tab == battle_tabname then
							current_chat = battle_table
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

function build_maps()
	main_map_left = {}
	main_map_right = {}
	local x_base = 6.8
	local y_base = 1.5
	local font = texts.font(TextWindow.main):lower()
	if font_wrap_sizes[font] then
		x_base = x_base*font_wrap_sizes[font][3]
		y_base = y_base*font_wrap_sizes[font][4]
	end
	x_scale = texts.size(TextWindow.main) * x_base
	y_scale = texts.size(TextWindow.main) * y_base
	for i,v in ipairs(all_tabs) do
		if i == 1 then
			main_map_left[i] = { ['x_start'] = 0, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		elseif i == 2 then
			main_map_left[i] = { ['x_start'] = x_scale+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		elseif i > 2 then
			main_map_left[i] = { ['x_start'] = main_map_left[i-1].x_end+1, ['x_end'] = x_scale*i, ['y_start'] = 0, ['y_end'] = y_scale}
		end
		main_map_left[i].action = function(current_menu)
			menu(current_menu,'')
		end
	end
	i = #main_map_left
	settings.window_visible = true
	main_map_left[i+1] = { ['x_start'] = main_map_left[i].x_end+1, ['x_end'] = x_scale*6.8, ['y_start'] = 0, ['y_end'] = y_scale}
	main_map_left[i+1].action = function(current_menu)
		if settings.window_visible then settings.window_visible = false else settings.window_visible = true end
		config.save(settings, windower.ffxi.get_player().name)
		reload_text()
	end
	main_map_left[i+2] = { ['x_start'] = 0, ['x_end'] = x_scale*1.5, ['y_start'] = y_scale+1, ['y_end'] = y_scale*2}
	main_map_left[i+2].action = function(current_menu)
			menu(current_menu,'')
	end
	main_map_right[1] = { ['x_start'] = main_map_left[i].x_end+1, ['x_end'] = x_scale*6.8, ['y_start'] = 0, ['y_end'] = y_scale}
	main_map_right[1].action = function()
			menu('setup_menu','')
	end
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
