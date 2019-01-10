package = "lua-resty-console"
version = "0.1.0"
source = {
   url = "https://github.com/nicoster/lua-resty-console",
   tag = "v0.1.0"
}
description = {
   summary = "Interactive console (REPL) for Openresty to inspect Lua VM internal state, to run lua code, to invoke functions and more",
   homepage = "https://github.com/nicoster/lua-resty-console",
   license = "MIT/X11"
}
dependencies = 
   "lua-hiredis >= 0.2.1",
}
build = {
   type = "builtin",
   modules = {
      ["lib.resty.console"] = "lib/resty/console.lua",
      ["lib.resty.console.binding"] = "lib/resty/console/binding.lua",
      ["lib.resty.console.client"] = "lib/resty/console/client.lua",
      ["lib.resty.console.completer"] = "lib/resty/console/completer.lua",
      ["lib.resty.console.consts"] = "lib/resty/console/consts.lua",
      ["lib.resty.console.readline"] = "lib/resty/console/readline.lua",
      ["lib.resty.console.resp"] = "lib/resty/console/resp.lua",
      ["lib.resty.console.utils"] = "lib/resty/console/utils.lua",
   }
}
