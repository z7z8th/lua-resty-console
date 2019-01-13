#!/usr/bin/env luajit

---
--- Created by nickr.
--- DateTime: 1/7/19 5:15 PM
---

local ffi = require 'ffi'
local hiredis = require 'hiredis'
local readline = require 'resty.console.readline'
local consts = require 'resty.console.consts'
local ins = require "inspect"

local HTTP_LINE = 'GET /console\r\n'

local function parse(arg)
    local host, port
    local pos = arg[1]:find(':', 1, true)
    if pos then 
        host = arg[1]:sub(1, pos - 1)
        port = arg[1]:sub(pos + 1)
    else
        host = arg[1] 
    end

    return host or 'localhost', port or 8000
end

local HOST, PORT = parse(arg)

ffi.cdef [[
    /* lua-hiredis.c */
    typedef struct redisReader redisReader;
    typedef struct redisContext {
        int err; /* Error flags, 0 when there is no error */
        char errstr[128]; /* String representation of error when applicable */
        int fd;
        int flags;
        char *obuf; /* Write buffer */
        redisReader *reader; /* Protocol reader */
    } redisContext;

    typedef struct luahiredis_Connection {
        redisContext * pContext;
    } luahiredis_Connection;

    /* stdio.h */
    size_t write(int fd, const void *buf, size_t nbyte);
]]

local function prompt_line(rclient, line_count)
    local context = rclient:command(consts.REPL_TYPE_CONTEXT)
    -- local context = rclient:command(consts.REPL_TYPE_COMMAND)

    if context then
        return '[' .. line_count .. '] ' .. context.name  .. '> '
    else
        return nil
    end
end

local main = function()

    local rclient = hiredis.connect(HOST, PORT)
    if not rclient then
        print('Unable to connect to ' .. HOST .. ':' .. PORT)
        return
    end

    print('Connected to ' .. HOST .. ':' .. PORT .. '. Press ^C twice to exit.');

    -- allow the connection to land on an HTTP handler
    local conn_ctx = ffi.cast('luahiredis_Connection *', rclient).pContext
    ffi.C.write(conn_ctx.fd, HTTP_LINE, #HTTP_LINE)

    readline.set_completion_func(function(word)
        local matches = rclient:command(consts.REPL_TYPE_AUTOCOMP, word)
        return matches
    end)

    local line_count = 1
    while true do
        local prompt = prompt_line(rclient, line_count)
        if not prompt then
            readline.puts('disconnected')
            return
        end

        local input = readline(prompt)
        --print('input:', input)

        if input and #input > 0 then
            line_count = line_count + 1
            local output = rclient:command(consts.REPL_TYPE_COMMAND, input)
            if output then
                readline.puts('=> ' .. output.name)
            else
                readline.puts('unexpected response, disconnected')
                return 
            end

            if output and output.type then
                readline.add_to_history(input, output.type ~= consts.REDIS_REPLY_ERROR)
            end
        end
    end
end

main()




















--