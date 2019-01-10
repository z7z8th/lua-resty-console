
local consts = require 'resty.console.consts'
local resp_module = require 'resty.console.resp'
require 'resty.console.utils'

local function new_sock(data)

    return {
        inbuf = '',
        outbuf = (data or ''):split('\r\n'),
        send = function(self, data)
            -- print('send:', data)
            self.inbuf = self.inbuf .. data
        end,
        feed = function(self, data) 
            self.outbuf = (data or ''):split('\r\n')
        end,
        receive = coroutine.wrap(function(self, param)
            local prev_param
            for _, line in ipairs(self.outbuf) do
                local _, size = coroutine.yield(line)
                if prev_param and size == 2 then
                    _, size = coroutine.yield('\r\n') 
                end

                prev_param = size
            end
        end)
    }
end

describe('sock-mock', function()
    it('should send data', function()
        local sock = new_sock()
        sock:send('a\r\n')
        assert.equals('a\r\n', sock.inbuf)
    end)

    it('should recv data', function()
        local sock = new_sock('a\r\nb')
        assert.equals('a', sock:receive())
        assert.equals('b', sock:receive())
    end)
end)

describe('resp protocol parser', function() 
    it('should parse command', function()
        local sock = new_sock(
            '*1\r\n$1\r\n3\r\n' ..
            '*2\r\n$1\r\n2\r\n$5\r\nngx.a\r\n' ..
            '*2\r\n$1\r\n1\r\n$4\r\n.quit\r\n'
        )
        local handler = function(typ, arg)
            -- print('type:', typ, ' arg:', arg)
            arg = arg[1]
            if typ == consts.REPL_TYPE_CONTEXT then
                assert.is_nil(arg)
                return {msg = 'ngx(content)'}
            elseif typ == consts.REPL_TYPE_AUTOCOMP then
                if arg == 'ngx.a' then
                    return {msg = 'ngx.arg.'}
                end
            else
                assert.equals(consts.REPL_TYPE_COMMAND, typ)
                assert.equals('.quit', arg)
                return 
            end
        end

        local s = spy.new(handler)
        local resp = resp_module.new(s)
        resp:serve(sock)

        assert.spy(s).was.called(3)
        assert.equals('+ngx(content)\r\n+ngx.arg.\r\n', sock.inbuf)
    end)
end)
