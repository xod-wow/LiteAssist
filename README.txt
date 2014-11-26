LiteAssist
==========
  - by Xodiv (formerly) of Proudmoore


This is an addon for the computer game World of Warcraft.


About LiteAssist
----------------

LiteAssist is a very basic addon to replace the standard /assist macro.

It lets you set a unit (a player, pet or NPC) that the mod remembers.

When you push the assist key, it causes you to attack the same thing as that
unit.  It changes your target (what you are attacking) to be the same as their
target.

LiteAssist provides extra key bindings to learn who to assist and to assist
them.  You can (and must to use this addon) set them up via the WoW Keyboard
Options menu.

LiteAssist really is light. There are no /commands and no fancy GUIs, just the
3 key bindings.


Installing LiteAssist
---------------------

Unzip the archive file inside the "Interface\Addons\" folder inside your World
of Warcraft installation.  On Windows, usually this will mean the files end up
in this directory:

  C:\Program Files\World of Warcraft\Interface\Addons\LiteAssist\


Configuring LiteAssist
----------------------

After entering the World of Warcraft game, go to the Keyboard Settings menu,
scroll down to the LiteAssist section and set the key bindings.  Then just use
the keys to activate the learn and assist functions.  See below for more
details.


Key Bindings
------------

The three key bindings are:

  1. Learn unit to assist from your current target.
  2. Learn unit to assist from whatever your mouse is hovering over.
  3. Assist the previously learned unit (i.e., target its target).

You can find these under the 'LiteAssist' heading in the Keyboard Options
menu.

I use shift-F (learn target), ctrl-F (learn mouseover) and F (assist) for the
three functions.


Notification Messages
---------------------

When learning a new assist a message will pop up in the middle of the screen to
inform you.


Clearing Assist
---------------

Learn assist with no unit targeted/mouseovered to clear the assist. The assist
also starts out cleared before you first learn something.

When the assist is cleared, the assist key will assist your current target,
exactly like WoW's default assist function.  This makes it safe to override
your regular assist key ('F').


Target Frame Indicator
----------------------
When you are targeting the same unit as your assist, a small icon of a pair of
crossed swords will be shown at the left of your target frame.  This only works
with the default Blizzard interface, not other unit frame addons like XPerl.


Advanced Macro Support
----------------------

When you assist the learned target, LiteAssist is really running a macro with
'/assist PlayerName' in it.

If you create a macro of your own named LiteAssistMacro AND include in it the
text {LiteAssistUnit} (just like that, including the curly brackets),
LiteAssist will use that macro instead with the text {LiteAssistUnit} replaced
with the name of the player you learned.

You can include {LiteAssistUnit} more than once and it will replace all the
occurrences.

Non-Keyboard Use
----------------

If you want to set up buttons on your action bar to trigger LiteAssist,
you need to do so by creating macros like these and then dragging them
onto your action bar.

To learn assist from target:
  /click LiteAssistLearnTarget

To learn assist from mouseover:
  /click LiteAssistLearnHover

To assist the learned unit:
  /click LiteAssistDo

Limitations
-----------

Due to intentional limitations by Blizzard you can't change assist in combat.
If you try to learn a new assist while in combat LiteAssist will remember what
you tried to do and apply it when combat ends.

You can (obviously) still assist the learned unit while in combat.


History
-------

See ChangeLog.txt for details.

