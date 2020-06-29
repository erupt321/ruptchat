# ruptchat
Windower chat addon

This was originally written as just a text box replacement for tells and checking the
chatlog without using sandbox if your multiboxing.  After coding a majority of it I expanded
to a bigger chat system replacement.  Still a work in progress making style patterns
for the text.

**Changelog**

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

	//rchat length <Log Length> (Change log length size)

	//rchat width <Log Width>  (Change log width size; when wordwrap should take effect)
		
	//rchat strict_width (Toggle maintaining the max log width; avoid box shrinking and expanding)

	//rchat string_length (Toggle maintaining the log length)

	//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

	//rchat undock [tab name] (Opens a second dedicated chat window for that tab, off if empty)
	
	//rchat battle_all (Toggle Battle Chat showing in the All tab)

	//rchat battle_off (Toggle Battle Chat being process at all; totally off)
	
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

