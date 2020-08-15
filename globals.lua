save_delay = 5000
rupt_savefile = ''
rupt_db = ''
tab_styles = ''
style_templates = ''
battlemod_loaded = false
chat_debug = false
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
	['scroll_num'] = {},
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

setup_window_toggles = { 'battle_all','battle_off','strict_width','strict_length',
'incoming_pause','drag_status','battle_flash','chat_input','snapback','split_drops','drops_window','archive'}
setup_window_commands = { 'battle_all','battle_off','strict_width','strict_length',
'incoming_pause','drag','battle_flash','chatinput','snapback','splitdrops','dropswindow','archive'}