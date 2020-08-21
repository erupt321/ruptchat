# rChat
Windower chat addon

This was originally written as just a text box replacement for tells and checking the
chatlog without using sandbox if your multiboxing.  After coding a majority of it I expanded
to a bigger chat system replacement.  Still a work in progress making style patterns
for the text.


**Templates**

	The templates.lua file is where color codes for the addon are stored.  If I happen to make abilities
	update that adds new colors to the file and you have a custom version of templates.lua then just 
	add the whatever settings lines are missing to your templates.lua, they'll always be at the end of
	the file.  I probably will allow custom named templates and have new settings automatically get added
	to user template files in the future but for now that will be the workaround.


**Changelog**

	__08.21.20__
	Added vanilla_mode option which turns off the styles portion of the addon and enables direct
	text from the vanilla client, still not 100% on all color codes for this mode.  This option can
	be accessed from //rchat vanilla_mode or from the setup menu.
	Did some rewrites on the save functions that was having issues with the recent inclusion of
	battle log to the saved file.  Old table was not being wiped and was causing a error during the
	save if currently had a large unpurged battle log.

	__08.20.20__
	Added cacheing for font data now, Should only need on font calibration to populate everything.
	Fine tuning the wrapping functions some more, namely for breaking up words instead of wrapping
	to the next line.  

	__08.18.20__
	Huge backend change to how fonts are handled and how width is handled in the addon.
	
	First big thing is there is now a Font Calibrator built into the addon.  What this does
	is load a new font and attempt to figure out if its a Monospace font or not and then
	detect how large the average letter is to more accurately map out click controls and
	word wrap functions.
	
	With this change width settings have changed from Character based to Pixel based width settings.
	So if you had a 115 width prior your new width is probably going to be more like 700.
	
	I've also tweeked some default settings for first time users, I've made both the strict* settings
	on by default as this is one of the most common questions I get about the addon.  The default font
	has been changed to 'Lucida Sans Typewriter', this was only chosen because it's a default installed
	windows monospace font.
	
	About monospace vs non.  Monospaced fonts have exact width size per character which is the ideal
	type of font for this addon.  If you notice your window moving even with strict on maybe a couple
	pixels chances are you aren't using a monospace font.  The font calibrator will tell you if your 
	font is 100% monospaced during it's test.  For non monospaced font I have put alot of work into
	trying to make the addon accomodate for your font's shortcomings.  There's a new option called
	enhancedwhitespace which is defaulted to on. If the addon detects you aren't using a monospace font
	it'll try to use this alternative whitespace character to build the menu's.  There is a chance
	some fonts don't actually have this character and will show up as blocky garbage in the menu.
	You can disable this using the rChat setup menu by right clicking [rChat] or //rchat enhancedwhitespace.
	
	Hopefully this will new addition will help some new users that are scared about switching their
	chat windows over.

	__08.15.20__
	Made a setup menu, if you right click on the [rChat] in the main menu a setup menu will open up,
	which you can then click on all the setup options to do either a quick setting change or just to 
	view all your changes.  Right clicking the [rChat] again will close the menu.

	__08.14.20__
	Rewrote the scrolling code and chat processor to be universally compatible with scrolling ability.
	Now undocked tab can be scrolled just like the Main window and Drops window, and in the future adding
	new scrollable windows will be much simplified.

	__08.13.20__
	Mostly backend cleaning up code and seperating the single file lua into seperate packages.


	__08.11.20__
	This is a big update as in I've rewritten alot of the backend on tab handling and made click maps
	fully dynamic.  This all in preparation for one of the funner features I've been able to release.
	
	Customizable Tabs.
	
	You now have a tabs.lua file which includes all the tab settings for the addon.  Within this file
	you can add and delete tabs, Rename them, change the ordering.  You can also create new custom tabs
	which you can put custom chat id's you'd like them to receive.
	
	One example: 

	You set ['All_Exclusions'] = {148,161}
	This will now filter out chat id's 148, and 161 from the 'All' type tab.  Which are instance queue
	messages and moogle/campaign messages.
	
	Now we make a Custom Tab with this in your tabs.lua.
	{name='Custom',ids={148, 161},tab_type='Normal'},
	
	Now all queue messages and moogle messages will filter into that tab solely.  The same can be
	done with battle chat types to record spell casts perhaps in their own tab.
	
	You can combine Tell/LS1/LS2 into a single tab if you'd like.
	On initial reload when you've renamed tabs your tables will be empty.  You can modify your chat log
	and rename old tables to your new ones if you want your history to resume.
	
	If you'd like to figure out what chat id's are to what, I have very brief descriptions for quite a few
	of them in the styles.lua file.  But just enable //rchat debug and you can see what id's go for what
	chat types to use in your custom settings.
	
	__08.08.20__
	Changed autotranslate phrases to show up with {}'s in the chatlog and be easier to see.
	Added some more effects to Autotranslate bracers, colored them like they are in vanilla chat!
	
	__08.07.20__
	After some testing with the archive feature I have changed the way writes are performed to
	not degrade performance under heavy logging situations like cleaving or alliance fights.
	Archive textlines will buffer until the next scheduled log write.  You can always force the log
	to write by either reloading the addon or using //rchat save.
	I also updated a style format that was causing Erase's to not display properly.
	Added //rchat dropswindow toggle.
	If splitdrops is active this will enable or disable the window from popping up unless you do abilities
	//rchat showdrops to force it.
	I also redid how the chat windows are updated to avoid the window processing 8 times a second
	when chat packet comes in with multiple entries.  Window should just process after last one to make
	things smoother.
	
	__08.06.20__
	Reworked many of the battle filters, and some of the other filters that can glitch
	out here and there with double spaces or reives Area names being misformated.  Also
	added a format for Zone in message, which means I added a color to the template for that
	as well.  I also added 2 more chat id's to the incoming_pause list,  I haven't had anything
	issues with these yet.
	
	__08.05.20__
	Added a echo color to the styles / template file.
	
	__08.04.20__
	Added Drop window in previous version, fixed some issues it caused with the find function.
	Drop window is scrollable just like the main window.
	use //rchat splitdrops to enable
	Added Archive setting, this will make permanent archive files by CharacterName-Month.log.
	Use //rchat archive to enable
	
	__07.31.20__
	Fixed some large bugs with how battle text was behaving in the 'All' tab.  I had not used battle
	text in the 'All' tab for so long I haven't tested if I had broken it, and I guess I did a long
	while ago.  Fixed some other style errors and misspells.
	
	__07.30.20__
	Fixed a bug if you tried to drag when you clicked a menu header, would trigger a movement drag
	in the client.  Thanks Akaden for pointing that one out!
	Added Split Drops option, which allows you to send drops to a pop up window that fades after 30
	seconds.   Once this is active drops will start to save to their own table as well in the save
	system which means you can store more drop history as well.

	__07.26.20__
	Fixed some chat filters in the battle log.  Added a new feature to display chat input the client
	is receiving.  Possible uses are if you were not wanting to look at the clients chat input box
	or you prefer to see the text you type more towards the center of the screen.  Does not disable
	the actual ingame chat box from displaying.

	__07.02.20__
	New setting Battle_flash.  This is a toggle for mentions that have to do with the battle log.
	If this is enable it'll flash the mention it finds along with the words on that line, this is 
	useful for abilities, when it's on it also bypasses certain mention properties like ignoring
	if your currently viewing the battle window.  All other mentions should still work like normal.
	I'm hoping this will be somewhat how people were wanting monster abilities to alert them.
	Also fixed some bugs with tabs not loading correctly on a reload, specifically empty tabs.
	Fixed a battle log style that was showing a cr on the beginning of the spell cast.

	__07.01.20__
	Fixed mentions and redid some of it's processing features, if you have a docked window up for the tab
	being mentioned it will not display it.  For 'All' mention tracking it always displays the alert and 
	will go away when you have a 'All' tab opened for at least 5 log inputs.  For mentions on other tabs
	the mention will go away as soon as you click on the tab.  Fixed some issues where mentions were 
	coming up from the wrong tabs input.

	__06.30.20__
	Added log_dwidth, which forces a different width setting on your undocked window so you can
	have mixed window sizes to suit your screen setup.
	Added snapback which will force the docked window to follow your main window whenever you drag
	the main.  You can still move around the undocked while this is enable and it will not snapback
	until the main window is dragged.

	__06.29.20__
	Added strict_length, which is the same concept as switch_width but forces logs to never
	change text box length.

	__06.28.20__
	Made some more filter changes and added some more id's to the incoming pause list.
	
	The bigger change I made was allowing font changes via //rchat font <font name>
	while this could already be achieved by editing your settings.xml I've also coded
	a table and formulas that work by the font type to adjust new strict_width / word wrap
	based on the type of font used, as well as changing the Image Map Formulas for the top bar.  
	I mapped a few fonts as examples but otherwise it will be up to you to map out fonts
	through trial and error.  If you do happen to map out some fonts be sure to submit your
	numbers to me and I'll add it to the list.

	__06.26.20__
	Made a template file now for the styles colors.  You can not modify your own color themes
	and not worry about them being overwritten by new styles being added.
	Fixed some of the save file corruption issues with line breaks via moogle/campaign messages
	Added some more styles for unadded chat id's while I was adding the template settings.
	Some more id's added to the incoming_pause, have a few people testing id's all day, to try 
	to get as many safe filtered id's as we can.

	__06.25.20__
	Add option to lock main window into place.  //rchat drag
	Fixed mention from triggering on yourself.

	__06.24.20__
	Undocked windows, allow a second window to show a specific tab.
	use //rchat undocked [tab name] to launch new tab or hold down Alt + Click Tab to launch.
	
	__06.11.20__
	First test version.


===Issues===

*If mouse input lags, enable hardware mouse in windower settings.

*Timestamps could possibly cause some false reads on filters, do recommend you turn it off.

*If you load this addon while battlemod is loaded you'll need to reload if you unload battlemod after.

============

**Console Commands**

																			 ■
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
	
	//rchat stroke_alpha <0-255> (Change text stroke transparency)

	//rchat stroke_width <0-10> (Change stroke size)

	//rchat stroke_color <#r> <#g> <#b>  (Change stroke color)

	//rchat length <Log Length> (Change log length size)

	//rchat dlength <Undocked Length> (Same as Log Length, if set to 0 will use Log_Length settings)

	//rchat width <Log Width>  (Change log width size; when wordwrap should take effect)
	
	//rchat dwidth <Undocked Width> (Same as Log Width, if set to 0 will use Log_Width settings)
		
	//rchat strict_width (Toggle maintaining the max log width; avoid box shrinking and expanding)

	//rchat strict_length (Toggle maintaining the log length)
	
	//rchat enhancedwhitespace (Toggle using Figure Spaces for menus if your on a non monospace font)

	//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

	//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)
	
	//rchat snapback (When enabled the undocked window will follow your main window
	
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

*All tabs are clickable, all text windows are mouse wheel scrollable.  Holding down ALT and clicking a tab will open a second window for that tab's chat.

*Clicking the [ - ] in the upper right corner will minimize the text box and leave just the tab menu. 

*New tells recieved while in a none "All"/"Tell" tab will provide a Notification.

*Search system for searching through current tab.  //rchat find Can click to search next until finished.

*Can save as much chat log lines as you'd like but anything over 5000 can lag during save.

*Seperate drops table to filter it out from you main log or provide focus on drops, is scrollable.

*Mentions can be added that alert you when a word is mentioned in a tab.

*Archive system to save permanent logs of your chat history in monthly files.

*Themes file to making your own custom color themes.

**Usage Examples**

	My current usage is keeping battle_all = off, this prevents battle log messages in my main log window
	then I launch a undocked 'battle' window so that I now have a split window setup.  If I want to scroll
	my battle log I'll just click into battle on my main window and scroll.  If I'm in the middle of a /tell
	conversation I will change the undocked to 'tell'.  Plenty of options to customize how you want your windows
	setup through log_length / log_width.  Hopefully in the future I will make style colors more user friendly
	to develop custom templates(This is not preventing people from already doing it as I've seen).

**Screenshots**

![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/chatwindow7.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/chatwindow9.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat7.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat8.gif)


**TODO**

	Plenty of examples of text that is not being stylized, continue building matches.
	
	Click action for text box line (Click to reply to tell, etc..)
	
	If you find chat that has no style formatting you can enable debug with //rchat debug and screenshot
	the information for that chat line and a style can be developed.

