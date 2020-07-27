# ruptchat
Windower chat addon

This was originally written as just a text box replacement for tells and checking the
chatlog without using sandbox if your multiboxing.  After coding a majority of it I expanded
to a bigger chat system replacement.  Still a work in progress making style patterns
for the text.

**Changelog**

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
	Fixed a battle log style that was showing a [cr on the beginning of the spell cast.

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

	//rchat string_length (Toggle maintaining the log length)

	//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

	//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)
	
	//rchat snapback (When enabled the undocked window will follow your main window
	
	//rchat battle_all (Toggle Battle Chat showing in the All tab)

	//rchat battle_off (Toggle Battle Chat being process at all; totally off)

	//rchat battle_flash (Toggle Battle Messages forced pop on screen with flashing)
	
	//rchat chatinput (Toggle a small box showing currently typed text)

	//rchat inputlocation (Toggle if the chatinput box is on Top or Bottom orientation)
	
	//rchat incoming_pause **EXPERIMENTAL** 
	
	Will turn off vanilla windows receiving chat
	this will make your chat log vanish which is more
	visually appealing, but you'll be solely relying
	on this addon for all ingame text, which not even 
	I trust fully yet.  If in doubt just unpause it again.
	

  

**Features**

*Most usability is point and click.

*Window is draggable as well as clickable.  

*All tabs are clickable, all text windows are mouse wheel scrollable.  Holding down ALT and clicking a tab will open a second window for that tab's chat.

*Clicking the [ - ] in the upper right corner will minimize the text box and leave just the tab menu. 

*New tells recieved while in a none "All"/"Tell" tab will provide a Notification.

*Search system for searching through current tab.  Can click to search next until finished.

*Can save as much chat log lines as you'd like but anything over 5000 can lag during save.

*Mentions can be added that alert you when a word is mentioned in a tab.

**Usage Examples**

	My current usage is keeping battle_all = off, this prevents battle log messages in my main log window
	then I launch a undocked 'battle' window so that I now have a split window setup.  If I want to scroll
	my battle log I'll just click into battle on my main window and scroll.  If I'm in the middle of a /tell
	conversation I will change the undocked to 'tell'.  Plenty of options to customize how you want your windows
	setup through log_length / log_width.  Hopefully in the future I will make style colors more user friendly
	to develop custom templates(This is not preventing people from already doing it as I've seen).

**Screenshots**

![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat10.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat11.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat7.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat8.gif)


**TODO**

	Plenty of examples of text that is not being stylized, continue building matches.
	
	Click action for text box line (Click to reply to tell, etc..)
	
	If you find chat that has no style formatting you can enable debug with //rchat debug and screenshot
	the information for that chat line and a style can be developed.

