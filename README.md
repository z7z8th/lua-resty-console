# Welcome to Resty Console

[![Build Status](https://api.travis-ci.com/nicoster/lua-resty-console.svg?branch=master)](https://api.travis-ci.com/nicoster/lua-resty-console)

Aliaksandr's [Resty Repl](https://github.com/saks/lua-resty-repl) is a powerful tool with a bunch of nice [features](https://github.com/saks/lua-resty-repl#features). I personally am a big fan of it. But still it has a few drawbacks:

* Has to modify source code for each nginx handler in question to use Resty Repl
* Nginx needs to run in non-daemon mode to leverage the TTY/readline facilities
These limitations make it less useful for development workflow and production live debugging. So here comes the [resty-console](https://github.com/nicoster/lua-resty-console).

`resty-console` inherits the code of `resty-repl` so it inherits the features like:
* [readline](https://tiswww.case.edu/php/chet/readline/rltop.html) full integration - all the shortcuts like `^A`, `^R`, `ESC+DEL`, .. are supported
* auto completion / command history
* pretty print objects (with inspect.lua)
* and more ..

## Status
Experimental.

## Installation
Install `resty-console` with LuaRocks

```
luarocks install lua-resty-console
```
or get a feel of it with Docker
```
$ git clone https://github.com/nicoster/lua-resty-console.git
$ cd lua-resty-console
$ make demo   # invoking docker-compose
...
Connected to localhost:80
[1] ngx(content)> 
```


## Synopsis


`resty-console` consists of 2 parts - backend and client. This separation allows you to enjoy all the goodies of readline without messing with the TTY thing in nginx process. 

The client talks to the backend using [REdis Serialization Protocol](https://redis.io/topics/protocol) which is simple and efficient. Actually this design makes the client a universal REPL client with all the beloved readline features, as long as the implementation of a backend conforms to the protocol.

### Backend
Add the following snippet into your nignx configuration
```
lua_shared_dict mycache 128M;   # for demo only 
lua_shared_dict metrics 128M;   # for demo only

server {
  listen 127.0.0.1:8001;
  location /console {
    content_by_lua_block {
      require('resty.console').start()
    }
  }
```
As this exposes Openresty Lua VM for inspection, and `resty-console` doesn't have builtin authentication yet, it's crucial to listen only on `localhost` ports. 
The location is hardcoded to `/console` in the client, and it's not configurable for now.

### Client

Issue the following command to launch client and connect to the backend
```
$ luajit <LUAROCKS-DIR>/lib/resty/console/client.lua localhost:8001
Connected to localhost:8001. Press ^C twice to exit.
[1] ngx(content)>
```
You may run the following command to install a shortcut to the client.

```
sudo ln -s $(luarocks show lua-resty-console|grep -o '/.*client.lua') /usr/local/bin/resty-cli
```

#### Auto Completion
```
[1] ngx(content)> ngx.E →→      #press tab twice
ngx.EMERG  ngx.ERR    ngx.ERROR        
[1] ngx(content)> _G. →→
_G._.                _G.ipairs()          _G.rawequal()
_G._G.               _G.jit.              _G.rawget()
_G._VERSION          _G.load()            _G.rawlen()
_G.__ngx_cycle       _G.loadfile()        _G.rawset()
_G.__ngx_req         _G.loadstring()      _G.require()
_G.assert()          _G.math.             _G.select()
_G.bit.              _G.module()          _G.setfenv()
_G.collectgarbage()  _G.ndk.              _G.setmetatable()
_G.coroutine.        _G.newproxy()        _G.string.
_G.debug.            _G.next()            _G.table.
_G.dofile()          _G.ngx.              _G.tonumber()
_G.error()           _G.os.               _G.tostring()
_G.gcinfo()          _G.package.          _G.type()
_G.getfenv()         _G.pairs()           _G.unpack()
_G.getmetatable()    _G.pcall()           _G.xpcall()
_G.io.               _G.print()         
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

Below is an example of replicating the functionalities of [lua-resty-shdict-server](https://github.com/fffonion/lua-resty-shdict-server), manipulating shared-dict with canonical APIs directly.
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
ngx.shared.mycache.    ngx.shared.metrics.  
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

## Known Issues
If nginx runs with multiple workers (which is the normal case), each worker has an isolated Lua VM to handle requests. When a resty-console client connects to the backend, there's a good chance that connections are established with different workers, thus each time the client is dealing with a different Lua VM.

There is a nginx patch [listen per worker](https://rarut.wordpress.com/2013/06/18/multi-worker-statistics-and-control-with-nginx-per-worker-listener-patch/) which might address this issue. It allows each worker to listen on a unique port, so client could connect to different workers at will.

## OS Support
- GNU/Linux
- Mac OS

## Credits
- the client part uses [lua-hiredis](https://github.com/agladysh/lua-hiredis) for redis protocol parsing
- the backend uses the code from [lua-resty-shdict-server](https://github.com/fffonion/lua-resty-shdict-server) for redis protocol parsing
- the binding, completer, readline modules are inherited from [lua-resty-repl](https://github.com/saks/lua-resty-repl)

## License

resty-console is released under the [MIT License](http://www.opensource.org/licenses/MIT).
