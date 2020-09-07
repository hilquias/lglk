#include "lua.h"
#include "luajit.h"
#include "lauxlib.h"
#include "lualib.h"

#include "glk.h"
#include "glkstart.h"

void glk_main() {
  lua_State *L;

  L = luaL_newstate();

  luaL_openlibs(L);

  if (luaL_dofile(L, "model.lua")) {
    printf("Could not load file: %sn", lua_tostring(L, -1));
    lua_close(L);
  }

  lua_close(L);
}

glkunix_argumentlist_t glkunix_arguments[] =
  {
   { NULL, glkunix_arg_End, NULL }
  };

int glkunix_startup_code(glkunix_startup_t *data) {
  return 1;
}
