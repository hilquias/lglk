-- ===================================================================

local ffi = require "ffi"
local bit = require "bit"

local glk = ffi.load "glkterm"
local lglk = require "lglk" (glk)

-- ===================================================================

local mainwin = lglk.window_open (nil, 0, 0, glk.wintype_TextBuffer, 1)

if not mainwin then
   return
end

lglk.set_window (mainwin)

local statuswin = lglk.window_open (mainwin, bit.bor (glk.winmethod_Above, glk.winmethod_Fixed), 3, glk.wintype_TextGrid, 0)

local quotewin = nil

local scriptref = nil

local scriptstr = nil

lglk.put_string [[
Model Glk Program
An Interactive Model Glk Program
Port of "model.c", by Andrew Plotkin
Release 7.

Type "help" for a list of commands.

]]

local current_room = 0

local need_look = true

local function draw_statuswin ()
   if not statuswin then
      return
   end

   local roomname

   if current_room == 0 then
      roomname = "The Room"
   else
      roomname = "A Different Room"
   end

   lglk.set_window (statuswin)

   lglk.window_clear (statuswin)

   local width, height = lglk.window_get_size (statuswin)

   lglk.window_move_cursor (statuswin, (width - #roomname) / 2, 1)
   lglk.put_string (roomname)

   lglk.window_move_cursor (statuswin, width - 3, 0)
   lglk.put_string [[\|/]]
   lglk.window_move_cursor (statuswin, width - 3, 1)
   lglk.put_string [[-*-]]
   lglk.window_move_cursor (statuswin, width - 3, 2)
   lglk.put_string [[/|\]]

   lglk.set_window (mainwin)
end

local function yes_or_no ()
   draw_statuswin ()

   while true do
      local commandbuf = lglk.new_bytestr (256)

      lglk.request_line_event (mainwin, commandbuf, 255, 0)

      local gotline = false

      local ev = lglk.new_event_ptr ()

      while not gotline do
	 lglk.select (ev)

	 if ev[0].type == glk.evtype_LineInput then
	    if ev[0].win == mainwin then
	       gotline = true
	    end
	 elseif ev[0].type == glk.evtype_Arrange then
	    draw_statuswin ()
	 end
      end

      local cmd = lglk.string (commandbuf)

      local len = ev[0].val1

      cmd = string.sub (cmd, 1, len)

      cmd = string.gsub (cmd, "^%s*(.-)%s*$", "%1")

      cmd = string.lower (cmd)

      if cmd == "yes" then
	 return true
      elseif cmd == "no" then
	 return false
      end

      lglk.put_string 'Please enter "yes" or "no": '
   end
end

local function verb_help ()
   lglk.put_string "This model only understands the following commands:\n"
   lglk.put_string "HELP: Display this list.\n"
   lglk.put_string "JUMP: A verb which just prints some text.\n"
   lglk.put_string "YADA: A verb which prints a very long stream of text.\n"
   lglk.put_string "MOVE: A verb which prints some text, and also changes the status line display.\n"
   lglk.put_string "QUOTE: A verb which displays a block quote in a temporary third window.\n"
   lglk.put_string "SCRIPT: Turn on transcripting, so that output will be echoed to a text file.\n"
   lglk.put_string "UNSCRIPT: Turn off transcripting.\n"
   lglk.put_string "SAVE: Write fake data to a save file.\n"
   lglk.put_string "RESTORE: Read it back in.\n"
   lglk.put_string "QUIT: Quit and exit.\n"
end

local function verb_jump ()
   lglk.put_string "You jump on the fruit, spotlessly.\n"
end

local function verb_yada ()
   for i = 1, 100 do
      if i ~= 1 then
	 lglk.put_char ' '
      end
      if i % 15 == 0 then
	 lglk.put_string "FizzBuzz"
      elseif i % 3 == 0 then
	 lglk.put_string "Fizz"
      elseif i % 5 == 0 then
	 lglk.put_string "Buzz"
      else
	 lglk.put_string (tostring (i))
      end
   end
   lglk.put_string ".\n"
end

local function verb_quote ()
   lglk.put_string "Someone quotes some poetry.\n"

   if not quotewin then
      quotewin = lglk.window_open (mainwin, bit.bor (glk.winmethod_Above, glk.winmethod_Fixed), 5, glk.wintype_TextBuffer, 0)
      if not quotewin then
	 return
      end
   else
      lglk.window_clear (quotewin)
   end

   lglk.set_window (quotewin)
   lglk.set_style (glk.style_BlockQuote)
   lglk.put_string "Tomorrow probably never rose or set\n"
   lglk.put_string "Or went out and bought cheese, or anything like that\n"
   lglk.put_string "And anyway, what light through yonder quote box breaks\n"
   lglk.put_string "Handle to my hand?\n"
   lglk.put_string "              -- Fred\n"
   lglk.set_window (mainwin)
end

local function verb_move ()
   current_room = (current_room + 1) % 2
   need_look = true
   lglk.put_string "You walk for a while.\n"
end

local function verb_quit ()
   lglk.put_string "Are you sure you want to quit? "
   if yes_or_no () then
      lglk.put_string "Thanks for playing.\n"
      lglk.exit ()
   end
end

local function verb_save ()
   local saveref = lglk.fileref_create_by_prompt (bit.bor (glk.fileusage_SavedGame, glk.fileusage_BinaryMode), glk.filemode_Write, 0)

   if not saveref then
      lglk.put_string "Unable to place save file.\n"
      return
   end

   local savestr = lglk.stream_open_file (saveref, glk.filemode_Write, 0)

   if not savestr then
      lglk.put_string "Unable to write to save file.\n"
      lglk.fileref_destroy (saveref)
      return
   end

   lglk.fileref_destroy (saveref)

   for i = 1, 255 do
      lglk.put_char_stream (savestr, i)
   end

   local result = lglk.new_stream_result_ptr ()

   lglk.stream_close (savestr, result)

   lglk.put_string "Game saved.\n"
end

local function verb_restore ()
   local saveref = lglk.fileref_create_by_prompt (bit.bor (glk.fileusage_SavedGame, glk.fileusage_BinaryMode), glk.filemode_Read, 0)

   if not saveref then
      lglk.put_string "Unable to find save file.\n"
      return
   end

   local savestr = lglk.stream_open_file (saveref, glk.filemode_Read, 0)

   if not savestr then
      lglk.put_string "Unable to read from save file.\n"
      lglk.fileref_destroy (saveref)
      return
   end

   lglk.fileref_destroy (saveref)

   local err = false

   for i = 1, 255 do
      local ch = lglk.get_char_stream (savestr)
      if ch == -1 then
	 lglk.put_string "Unexpected end of file.\n"
	 err = true
	 break
      end
      if ch ~= i then
	 lglk.put_string "This does not appear to be a valid saved game.\n"
	 err = true
	 break
      end
   end

   local result = lglk.new_stream_result_ptr ()

   lglk.stream_close (savestr, result)

   if err then
      lglk.put_string "Failed.\n"
      return
   end

   lglk.put_string "Game restored.\n"
end

local function verb_script ()
   if scriptstr then
      lglk.put_string "Scripting is already on.\n"
      return
   end

   if not scriptref then
      scriptref = lglk.fileref_create_by_prompt (bit.bor (glk.fileusage_Transcript, glk.fileusage_TextMode), glk.filemode_WriteAppend, 0)
      if not scriptref then
	 lglk.put_string "Unable to place script file.\n"
	 return
      end
   end

   scriptstr = lglk.stream_open_file (scriptref, glk.filemode_WriteAppend, 0)

   if not scriptstr then
      lglk.put_string "Unable to write to script file.\n"
      return
   end

   lglk.put_string "Scripting on.\n"
   lglk.window_set_echo_stream (mainwin, scriptstr)

   lglk.put_string_stream (scriptstr, "This is the beginning of a transcript.\n")
end

local function verb_unscript ()
   if not scriptstr then
      lglk.put_string "Scripting is already off.\n"
      return
   end

   lglk.put_string_stream (scriptstr, "This is the end of a transcript.\n\n")

   local result = lglk.new_stream_result_ptr ()

   lglk.stream_close (scriptstr, result)

   lglk.put_string "Scripting off.\n"

   scriptstr = nil
end

while true do
   draw_statuswin ()

   if need_look then
      need_look = false

      lglk.put_string "\n"

      lglk.set_style (glk.style_Subheader)

      if current_room == 0 then
	 lglk.put_string "The Room\n"
      else
	 lglk.put_string "A Different Room\n"
      end

      lglk.set_style (glk.style_Normal)
      lglk.put_string "You're in a room of some sort.\n"
   end

   lglk.put_string "\n>"

   local commandbuf = lglk.new_bytestr (256)

   lglk.request_line_event (mainwin, commandbuf, 255, 0)

   local gotline = false

   local ev = lglk.new_event_ptr ()

   while not gotline do
      lglk.select (ev)

      if ev[0].type == glk.evtype_LineInput then
	 if ev[0].win == mainwin then
	    gotline = true
	 end
      elseif ev[0].type == glk.evtype_Arrange then
	 draw_statuswin ()
      end
   end

   if quotewin then
      lglk.window_close (quotewin)
      quotewin = nil
   end

   local cmd = lglk.string(commandbuf)

   local len = ev[0].val1

   cmd = string.sub (cmd, 1, len)

   cmd = string.gsub (cmd, "^%s*(.-)%s*$", "%1")

   cmd = string.lower (cmd)

   if cmd == "" then
      lglk.put_string "Excuse me?\n"

   elseif cmd == "help" then
      verb_help ()

   elseif cmd == "move" then
      verb_move ()

   elseif cmd == "jump" then
      verb_jump ()

   elseif cmd == "yada" then
      verb_yada ()

   elseif cmd == "quote" then
      verb_quote ()

   elseif cmd == "quit" then
      verb_quit ()

   elseif cmd == "save" then
      verb_save ()

   elseif cmd == "restore" then
      verb_restore ()

   elseif cmd == "script" then
      verb_script ()

   elseif cmd == "unscript" then
      verb_unscript ()

   else
      lglk.put_string [[I don't understand the command "]]
      lglk.put_string (cmd)
      lglk.put_string '".\n'
   end
end
