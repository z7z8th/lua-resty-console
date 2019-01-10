---
--- Created by nickr.
--- DateTime: 1/7/19 5:15 PM
---

require 'resty.console.utils'     -- for string:split()
local ffi = require 'ffi'
local hiredis = require 'hiredis'
local readline = require 'resty.console.readline'
local consts = require 'resty.console.consts'
local ins = require "inspect"

local HTTP_LINE = 'GET /console\r\n'
local HOST, PORT = unpack((arg[1] or ''):split())
HOST = HOST or 'localhost'
PORT = PORT or '8000'

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
    --print(ins(context))
    return '[' .. line_count .. '] ' .. context.name .. '> '
end

local main = function()

    local rclient = hiredis.connect(HOST, PORT)
    if not rclient then
        print('Unable to connect to ' .. HOST .. ':' .. PORT)
        return
    end

    print('Connected to ' .. HOST .. ':' .. PORT .. '. Press ^C twice to exit.\n');

    -- allow the connection to land on an HTTP handler
    local conn_ctx = ffi.cast('luahiredis_Connection *', rclient).pContext
    ffi.C.write(conn_ctx.fd, HTTP_LINE, #HTTP_LINE)

    readline.set_completion_func(function(word)
        local matches = rclient:command(consts.REPL_TYPE_AUTOCOMP, word)
        --print(ins(matches))
        return matches
    end)

    local line_count = 1
    while true do
        local input = readline(prompt_line(rclient, line_count))
        --print('input:', input)

        if input and #input > 0 then
            line_count = line_count + 1
            local output = rclient:command(consts.REPL_TYPE_COMMAND, input)
            if output then
                readline.puts('=> ' .. output.name)
            else
                return
            end

            if output and output.type and output.type ~= consts.REDIS_REPLY_ERROR then
                readline.add_to_history(input)
            end
        end
    end
end

main()




















--