local ffi = require "ffi"

-- ===================================================================

ffi.cdef [[
typedef uint32_t glui32;
typedef int32_t glsi32;

typedef struct glk_window_struct *winid_t;
typedef struct glk_stream_struct *strid_t;
typedef struct glk_fileref_struct *frefid_t;
typedef struct glk_schannel_struct *schanid_t;

static const int evtype_None = 0;
static const int evtype_Timer = 1;
static const int evtype_CharInput = 2;
static const int evtype_LineInput = 3;
static const int evtype_MouseInput = 4;
static const int evtype_Arrange = 5;
static const int evtype_Redraw = 6;
static const int evtype_SoundNotify = 7;
static const int evtype_Hyperlink = 8;
static const int evtype_VolumeNotify = 9;

typedef struct event_struct {
    glui32 type;
    winid_t win;
    glui32 val1, val2;
} event_t;

static const int style_Normal = 0;
static const int style_Emphasized = 1;
static const int style_Preformatted = 2;
static const int style_Header = 3;
static const int style_Subheader = 4;
static const int style_Alert = 5;
static const int style_Note = 6;
static const int style_BlockQuote = 7;
static const int style_Input = 8;
static const int style_User1 = 9;
static const int style_User2 = 10;

typedef struct stream_result_struct {
    glui32 readcount;
    glui32 writecount;
} stream_result_t;

static const int wintype_AllTypes = 0;
static const int wintype_Pair = 1;
static const int wintype_Blank = 2;
static const int wintype_TextBuffer = 3;
static const int wintype_TextGrid = 4;
static const int wintype_Graphics = 5;

static const int winmethod_Left  = 0x00;
static const int winmethod_Right = 0x01;
static const int winmethod_Above = 0x02;
static const int winmethod_Below = 0x03;
static const int winmethod_DirMask = 0x0f;

static const int winmethod_Fixed = 0x10;
static const int winmethod_Proportional = 0x20;
static const int winmethod_DivisionMask = 0xf0;

static const int winmethod_Border   = 0x000;
static const int winmethod_NoBorder = 0x100;
static const int winmethod_BorderMask = 0x100;

static const int fileusage_Data = 0x00;
static const int fileusage_SavedGame = 0x01;
static const int fileusage_Transcript = 0x02;
static const int fileusage_InputRecord = 0x03;
static const int fileusage_TypeMask = 0x0f;

static const int fileusage_TextMode   = 0x100;
static const int fileusage_BinaryMode = 0x000;

static const int filemode_Write = 0x01;
static const int filemode_Read = 0x02;
static const int filemode_ReadWrite = 0x03;
static const int filemode_WriteAppend = 0x05;

extern void glk_exit(void);

extern winid_t glk_window_open(winid_t split, glui32 method, glui32 size, glui32 wintype, glui32 rock);
extern void glk_window_close(winid_t win, stream_result_t *result);
extern void glk_window_get_size(winid_t win, glui32 *widthptr, glui32 *heightptr);
extern void glk_window_clear(winid_t win);
extern void glk_window_move_cursor(winid_t win, glui32 xpos, glui32 ypos);

extern void glk_window_set_echo_stream(winid_t win, strid_t str);
extern void glk_set_window(winid_t win);

extern strid_t glk_stream_open_file(frefid_t fileref, glui32 fmode, glui32 rock);
extern void glk_stream_close(strid_t str, stream_result_t *result);

extern void glk_put_char(unsigned char ch);
extern void glk_put_char_stream(strid_t str, unsigned char ch);
extern void glk_put_string(char *s);
extern void glk_put_string_stream(strid_t str, char *s);
extern void glk_set_style(glui32 styl);

extern glsi32 glk_get_char_stream(strid_t str);

extern frefid_t glk_fileref_create_by_prompt(glui32 usage, glui32 fmode, glui32 rock);
extern void glk_fileref_destroy(frefid_t fref);

extern void glk_select(event_t *event);

extern void glk_request_line_event(winid_t win, char *buf, glui32 maxlen, glui32 initlen);
]]

-- ===================================================================

return function (lib)
   local M = {}

   function M.new_bytestr (len)
      return ffi.new ('char['..len..']')
   end

   function M.new_event_ptr ()
      return ffi.new "event_t[1]"
   end

   function M.string (bytestr)
      return ffi.string (bytestr)
   end

   function M.new_stream_result_ptr ()
      return ffi.new 'stream_result_t[1]'
   end
   
   function M.exit ()
      lib.glk_exit ()
   end

   function M.window_open (split, method, size, wintype, rock)
      return lib.glk_window_open (split, method, size, wintype, rock)
   end

   function M.window_close (win)
      local result = ffi.new "stream_result_t[1]"
      lib.glk_window_close (win, result)
      return result[0]
   end

   function M.window_get_size (win)
      local widthptr, heightptr = ffi.new "glui32[1]", ffi.new "glui32[1]"
      lib.glk_window_get_size (win, widthptr, heightptr)
      return widthptr[0], heightptr[0]
   end

   function M.window_clear (win)
      lib.glk_window_clear (win)
   end

   function M.window_move_cursor (win, xpos, ypos)
      lib.glk_window_move_cursor (win, xpos, ypos)
   end

   function M.window_set_echo_stream (win, str)
      lib.glk_window_set_echo_stream (win, str)
   end

   function M.set_window (win)
      lib.glk_set_window (win)
   end

   function M.stream_open_file (fileref, fmode, rock)
      return lib.glk_stream_open_file (fileref, fmode, rock)
   end

   function M.stream_close (str, result)
      lib.glk_stream_close (str, result)
   end

   function M.put_char (ch)
      lib.glk_put_char (string.byte (ch))
   end

   function M.put_char_stream (str, ch)
      lib.glk_put_char_stream (str, ch)
   end

   function M.put_string (s)
      lib.glk_put_string (ffi.new ("char[?]", #s + 1, s))
   end

   function M.put_string_stream (str, s)
      lib.glk_put_string_stream (str, ffi.new ("char[?]", #s + 1, s))
   end

   function M.set_style (styl)
      lib.glk_set_style (styl)
   end

   function M.get_char_stream (str)
      return lib.glk_get_char_stream (str)
   end

   function M.fileref_create_by_prompt (usage, fmode, rock)
      return lib.glk_fileref_create_by_prompt (usage, fmode, rock)
   end

   function M.fileref_destroy (fref)
      lib.glk_fileref_destroy (fref)
   end

   function M.select (ev)
      lib.glk_select (ev)
   end

   function M.request_line_event (win, buf, maxlen, initlen)
      lib.glk_request_line_event (win, buf, maxlen, initlen)
   end

   return M
end
