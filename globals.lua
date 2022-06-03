save_delay = 5000
rupt_savefile = ''
rupt_db = ''
tab_styles = ''
style_templates = ''
battlemod_loaded = false
chat_debug = false
drops_timer = os.clock()
undocked_timer = os.clock()+30
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
	['monospace'] = false,
}


-- 20 21 22 24 28 29 30 31 35 36 50 56 57 63 81 101 102 110 111 114 122 157 191 209
battle_ids = { [20]=true,[21]=true,[22]=true,[23]=true,[24]=true,[25]=true,[28]=true,[29]=true,[30]=true,[31]=true,[35]=true,[36]=true,[40]=true,[50]=true,[56]=true,[57]=true,[59]=true,[63]=true,[81]=true,[101]=true,[102]=true,[107]=true,[110]=true,[111]=true,[112]=true,[114]=true,[122]=true,[157]=true,[191]=true,[209]=true }
duplidoc_ids = { [190]=true }
filter_ids = { [23]=true,[24]=true,[31]=true,[151]=true,[152]=true }

-- Last adds 144 / 190
pause_ids = { [0]=true,[1]=true,[4]=true,[5]=true,[6]=true,[7]=true,[8]=true,[9]=true,[10]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[38]=true,[59]=true,[64]=true,[90]=true,[91]=true,[121]=true,[123]=true,[127]=true,[131]=true,[144]=true,[146]=true,[148]=true,[160]=true,[161]=true,[190]=true,[204]=true,[207]=true,[208]=true,[210]=true,[212]=true,[213]=true,[214]=true,[221]=true,[245]=true }
chat_tables = {}
battle_table = {}
archive_table = {}

-- Thanks Kenshi for building these.
assist_flags = { 
	labels = {'bronze','silver','gold' },
	bronze = {
	[1] = string.char(0x2F),
	[2] = string.char(0x30),
	[3] = string.char(0x31),
	[4] = string.char(0x32),
	[5] = string.char(0x33),
	[6] = string.char(0x34),
	[7] = string.char(0x35),
--	[8] = string.char(0x36),
--	[9] = string.char(0x37),
--	[10] = string.char(0x38),
	},
	silver = {
	[1] = string.char(0x39),
	[2] = string.char(0x3A),
	[3] = string.char(0x3B),
	[4] = string.char(0x3C),
	[5] = string.char(0x3D),
	[6] = string.char(0x3E),
	[7] = string.char(0x3F),
--	[8] = string.char(0x40),
--	[9] = string.char(0x41),
--	[10] = string.char(0x42)
	},
	gold = {
	[1] = string.char(0x43),
	[2] = string.char(0x44),
	[3] = string.char(0x45),
	[4] = string.char(0x46),
	[5] = string.char(0x47),
	[6] = string.char(0x48),
	[7] = string.char(0x49),
--	[8] = string.char(0x4A),
--	[9] = string.char(0x4B),
--	[10] = string.char(0x4C),
	},
}
find_table = {
	['last_find'] = false,
	['last_index'] = 1,
}


default_settings = {
	log_length = 12,
	log_width = 500,
	log_dwidth = 0, -- 0 Disables and defaults to log_width value
	log_dlength = 0, -- 0 Disable and defaults to log_length value
	battle_all = true, -- Display Battle text in All tab
	battle_off = false, -- Disable processing Battle text entirely
	strict_width = true,
	strict_length = true,
	undocked_window = false,
	undocked_tab = all_tabname,
	undocked_hide = false,
	incoming_pause = false,
	drag_status = true,
	battle_flash = false,
	snapback = true,
	chat_input = false,
	chat_input_placement = 1,
	split_drops = false,
	drops_window = true,
	enh_whitespace = true,
	archive = false,
	vanilla_mode = false,
	flags = {
		draggable = false,
		bold = false,
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
		font = 'Courier New',
		fonts = {'Arial','Lucida Sans Typewriter'},
		size = 10,
		alpha = 255,
		red = 255,
		green = 255,
		blue = 255,
		stroke = {
			width = 1,
			alpha = 185,
			red = 20,
			green = 20,
			blue = 20,
		},
	},
	bg = {
		alpha = 255,
		red = 0,
		green = 0,
		blue = 0,
	},
}


tab_ids = {}
all_tabs = {}

calibrate_text = ""
calibrate_width  = "WIBIWIBIWIBIWIBIWIBI\nWIBIWIBIWIBIWIBIWIBI"
calibrate_width2 = "WIIIWIIIWIIIWIIIWIII\nWIIIWIIIWIIIWIIIWIiI"
calibrate_count = 0


setup_window_toggles = { 'battle_all','battle_off','strict_width','strict_length',
'incoming_pause','drag_status','battle_flash','chat_input','snapback','split_drops','drops_window','enh_whitespace','archive','vanilla_mode'}
setup_window_commands = { 'battle_all','battle_off','strict_width','strict_length',
'incoming_pause','drag','battle_flash','chatinput','snapback','splitdrops','dropswindow','enhancedwhitespace','archive','vanilla_mode'}
