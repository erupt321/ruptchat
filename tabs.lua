return {
	['Tabs'] = {  -- Can only have one 'All' tab and one 'Battle' tab
		{name='General',ids={},tab_type='All'},
		{name='Tell',ids= { 4, 12 },tab_type='Normal'},
		{name='Linkshell',ids= { 14, 6 },tab_type='Normal'},
		{name='Linkshell2',ids= { 214,213},tab_type='Normal'},
		{name='Party',ids= { 13, 5 },tab_type='Normal'},
		{name='Battle',ids= {},tab_type='Battle'},
	}, --  { 4, 12 } added to Exclusions would remove tell's from All Type tab.
	['All_Exclusions'] = {},
	['Battle_Exclusions'] = {},
}
