# ruptchat
Windower chat addon

This was originally written as just a text box replacement for tells and checking the
chatlog without using sandbox if your multiboxing.  After coding a majority of it I expanded
to a bigger chat system replacement.  Still a work in progress making style patterns
for the text.


===Issues===

*If mouse input lags, enable hardware mouse in windower settings.

*Timestamps could possibly cause some false reads on filters, do recommend you turn it off.

*If you load this addon while battlemod is loaded you'll need to reload if you unload battlemod after.

============

**Console Commands** 

	//rchat save (Force a chatlog save)

	//rchat find <search terms> (Search current selected tab for search terms

	//rchat mentions (Shows mention phrases you have saved for tabs)

	//rchat addmention <tab> <phrase> (Add mention phrase for tab)

	//rchat delmention <tab> <phrase> (Remove mention phrase for tab)

	//rchat hide (Hide's text box from showing)

	//rchat show (Show hidden text box)

	//rchat alpha <0-255> (Change background transparency)

	//rchat size <font size> (Change font size, this will increase whole window size)

	//rchat length <Log Length> (Change log length size)

	//rchat width <Log Width>  (Change log width size; when wordwrap should take effect)
		
	//rchat strict_width (Toggle maintaining the max log width; avoid box shrinking and expanding)

	//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)

	//rchat undock <tab name> (Opens a second dedicated chat window for that tab)
	
	//rchat battle_all (Toggle Battle Chat showing in the All tab)

	//rchat battle_off (Toggle Battle Chat being process at all; totally off)
  

**Features**

*Most usability is point and click.

*Window is draggable as well as clickable.  

*All tabs are clickable, all text windows are mouse wheel scrollable.

*Clicking the [ - ] in the upper right corner will minimize the text box and 
leave just the tab menu. 

*New tells recieved while in a none "All"/"Tell" tab will provide a Notification.

*Search system for searching through current tab.  Can click to search next until finished.

*Can save as much chat log lines as you'd like but anything over 5000 can lag during save.

*Mentions can be added that alert you when a word is mentioned in a tab.

**Screenshots**

![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat10.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat7.gif)


![Image of Rchat](https://github.com/erupt321/ruptchat/blob/master/images/rchat8.gif)


**TODO**

	Click action for text box line (Click to reply to tell, etc..)

