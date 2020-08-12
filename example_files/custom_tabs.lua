return {
	['Tabs'] = {  -- Can only have one 'All' tab and one 'Battle' tab
		{name='General',ids={},tab_type='All'},
		{name='Tell',ids= { 4, 12 },tab_type='Normal'},
		{name='Custom',ids= {148, 161},tab_type='Normal'},
		{name='LS',ids= { 14, 6, 214, 213 },tab_type='Normal'},
--		{name='Linkshell2',ids= { 214,213},tab_type='Normal'},
		{name='Party',ids= { 13, 5 },tab_type='Normal'},
		{name='Battle',ids= {},tab_type='Battle'},
	},
	['All_Exclusions'] = {148, 161},
	['Battle_Exclusions'] = { },
}
