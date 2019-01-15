# Welcome to Resty Console

Aliaksandr's [Resty Repl](https://github.com/saks/lua-resty-repl) is a powerful tool with a bunch of nice [features](https://github.com/saks/lua-resty-repl#features). I personally am a big fan of it. But still it has a few drawbacks:

* Has to modify source code for each nginx handler in question to use Resty Repl
* Nginx needs to run in non-daemon mode to leverage the TTY/readline facilities

These limitations make it less useful for development workflow and production live debugging. So here comes the [Resty Console](https://github.com/nicoster/lua-resty-console).

`Resty Console` inherits the code of `resty-repl` so it inherits the nice features like:
* readline full integration
* auto completion
* pretty print objects (powered by inspect.lua)
* and more ..
## Status
Experimental.

## Installation
```
luarocks install lua-resty-console
```

## Synopsis


`Resty Console` consists of 2 parts - server side and client. This separation allows us to both enjoy all the goodies of readline and keep footprints on the server minimium.

### Server Side
Add the following snippet into your nignx configuration
```
lua_shared_dict mycache 128M;   # for demo only 
server {
  listen 127.0.0.1:8001;
  location /console {
    content_by_lua_block {
      require('resty.console').start()
    }
  }
```
As this exposes Openresty Lua VM for inspection, and `Resty Console` doesn't have builtin authentication yet, it's crucial to listen only on `localhost` ports. 
The location is hardcoded to `/console` in the client, and it's not configurable for now.

### Client

Issue the following command to launch client and connect to the server
```
$ luajit <LUAROCKS-DIR>/lib/resty/console/client.lua localhost:8001
Connected to localhost:8001. Press ^C twice to exit.
[1] ngx(content)>
```

#### Auto Completion
```
[1] ngx(content)> ngx.E →→      #press tab twice
ngx.EMERG  ngx.ERR    ngx.ERROR        
[1] ngx(content)> _G. →→
_G._.                _G.debug.            _G.loadfile()        _G.pairs()           _G.setmetatable()
_G._G.               _G.dofile()          _G.loadstring()      _G.pcall()           _G.string.
_G._VERSION          _G.error()           _G.math.             _G.print()           _G.table.
_G.__ngx_cycle       _G.gcinfo()          _G.module()          _G.rawequal()        _G.tonumber()
_G.__ngx_req         _G.getfenv()         _G.ndk.              _G.rawget()          _G.tostring()
_G.assert()          _G.getmetatable()    _G.newproxy()        _G.rawlen()          _G.type()
_G.bit.              _G.io.               _G.next()            _G.rawset()          _G.unpack()
_G.c.                _G.ipairs()          _G.ngx.              _G.require()         _G.xpcall()
_G.collectgarbage()  _G.jit.              _G.os.               _G.select()          
_G.coroutine.        _G.load()            _G.package.          _G.setfenv()         
[1] ngx(content)> _G.
```

#### Invoke Functions
```
[1] ngx(content)> f = function() return 'a', 'b' end
=> nil
[2] ngx(content)> f()
=> "a", "b"

[3] ngx(content)> ngx.md5('abc')
=> 900150983cd24fb0d6963f7d28e17f72
[4] ngx(content)> ngx.time()
=> 1547534019
```

#### Check VM Internals

Below is an example of replicating the functionalities of [lua-resty-shdict-server](https://github.com/fffonion/lua-resty-shdict-server), manipulating shared-dict with canonical APIs directly, in the most natrual way.
```
[9] ngx(content)> ngx.config.prefix()
=> /workspace/lua-resty-console/
[10] ngx(content)> ngx.config.ngx_lua_version
=> 10011
[11] ngx(content)> ngx.config.nginx_configure()
=>  --prefix=/usr/local/Cellar/openresty/1.13.6.1/nginx --with-cc-opt='-O2 -I/usr/local/include -I/usr/local/opt/pcre/include -I/usr/local/opt/openresty-openssl/include' --add-module=../ngx_devel_kit-0.3.0 --add-module=../echo-nginx-module-0.61 ...


[12] ngx(content)> ngx.sha →→
ngx.sha1_bin()  ngx.shared.     
[12] ngx(content)> ngx.shared. →→
ngx.shared.cache.    ngx.shared.metrics.  
[12] ngx(content)> c = ngx.shared.mycache
=> nil
[13] ngx(content)> c
=> { <userdata 1>,
  <metatable> = <1>{
    __index = <table 1>,
    add = <function 1>,
    delete = <function 2>,
    flush_all = <function 3>,
    flush_expired = <function 4>,
    get = <function 5>,
    get_keys = <function 6>,
    get_stale = <function 7>,
    incr = <function 8>,
    llen = <function 9>,
    lpop = <function 10>,
    lpush = <function 11>,
    replace = <function 12>,
    rpop = <function 13>,
    rpush = <function 14>,
    safe_add = <function 15>,
    safe_set = <function 16>,
    set = <function 17>
  }
}
[14] ngx(content)> c:set('a', 1)
=> true
[15] ngx(content)> c:get('a')
=> 1
[16] ngx(content)> c:get_keys()
=> { "a" }

```


## Compatibility
Right now it's only compatible with:
- Openresty/luajit

## OS Support
- GNU/Linux
- Mac OS


## Code Status

[![Build Status](https://api.travis-ci.com/nicoster/lua-resty-console.svg?branch=master)](https://api.travis-ci.com/nicoster/lua-resty-console)

## License

resty-console is released under the [MIT License](http://www.opensource.org/licenses/MIT).
