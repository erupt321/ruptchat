# ruptchat
Windower chat addon


This was originally written as just a text box replacement for tells and checking the
chatlog without sandbox is your multiboxing.  After coding a majority of it I expanded
to a almost full chat system replacement.  Still a work in progress making style patterns
for the text.

If mouse input lags, enable hardware mouse in windower settings.

Timestamps could possible cause some false reads on filters, do recommend you turn it off.

Console Commands 

//rchat save (Force a chatlog save)
//rchat find <search terms> (Search current selected tab for search terms
//rchat mentions (Shows mention phrases you have saved for tabs)
//rchat addmention <tab> <phrase> (Add mention phrase for tab)
//rchat delmention <tab> <phrase> (Remove mention phrase for tab)
//rchat hide (Hide's text box from showing)
//rchat show (Show hidden text box)
//rchat alpha <0-255> (Change background transparency)
//rchat tab [tab name] (Change tab's without mouse input, goes to next tab if empty)


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

**TODO**
Click action for text box line (Click to reply to tell, etc..)