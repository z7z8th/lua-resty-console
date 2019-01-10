local repl = require 'resty.console'

insulate('context', function()
  it('is lua(main) if context is nil', function()
    local _ngx = _G.ngx   -- insulate() not working. store 'ngx' manually
    _G.ngx = nil
    assert.are_equal('lua(main)', repl.context())
    _G.ngx = _ngx
  end)

  it('has ngx_timer context', function()
    assert.are_equal('ngx(timer)', repl.context())
  end)

end)


describe('resty console', function()
  it('should work', function()
    assert.are_equal('function', type(repl.start))
  end)

end)
