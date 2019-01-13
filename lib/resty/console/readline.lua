#!/usr/bin/env lua

local ins = require 'inspect'
local history_file = os.getenv('HOME') ..'/.repl-history'
local ffi = require 'ffi'

-- from signal.h:
local SIGINT = 2
local SIG_ERR = -1

ffi.cdef [[
    /* signal.h */
    typedef void (*sig_t) (int);
    sig_t signal(int sig, sig_t func);

    /* stdlib.h */
    void exit(int status);

    /* libc definitions */
    void* malloc(size_t bytes);
    void free(void *);

    /* stdio.h */
    size_t fwrite(const void *, size_t, size_t, void*);

    /* readline.h */
    typedef void rl_vcpfunc_t (char *);

    void rl_initialize();
    char *readline (const char *prompt);

    /* basic history handling */
    void add_history(const char *line);
    int write_history (const char *filename);
    int append_history (int nelements, const char *filename);
    int read_history (const char *filename);

    /* completion */
    typedef char **rl_completion_func_t (const char *, int, int);
    typedef char *rl_compentry_func_t (const char *, int);
    typedef char **rl_hook_func_t (const char *, int);
    typedef char *rl_hook_func_t (const char *, int);

    char **rl_completion_matches (const char *, rl_compentry_func_t *);

    const char *rl_basic_word_break_characters;
    rl_completion_func_t *rl_attempted_completion_function;
    char *rl_line_buffer;
    int rl_completion_append_character;
    int rl_completion_suppress_append;
    int rl_attempted_completion_over;

    void rl_callback_handler_install (const char *prompt, rl_vcpfunc_t *lhandler);
    void rl_callback_read_char (void);
    void rl_callback_handler_remove (void);

    void rl_refresh_line(int, int);
    struct timeval { long tv_sec; long tv_nsec; };
    int select(int nfds, int *readfds, struct fd_set * writefds, struct fd_set * errorfds, struct timeval * timeout);

    int rl_on_new_line (void);
    void rl_replace_line (const char *text, int clear_undo);

    void* rl_outstream;

    int rl_set_prompt (const char *prompt);
    int rl_clear_message (void);
    int rl_message (const char *);
    int rl_delete_text (int start, int end);
    int rl_insert_text (const char *);
    int rl_forced_update_display (void);
    void rl_redisplay (void);
    int rl_point;
    int rl_end;
    int rl_catch_signals;

    rl_hook_func_t *rl_startup_hook;
    int rl_readline_state;
]]

local clib

-- for linux with readline 6.x, 7.x, and macos
for _, suffix in ipairs({'.so.6', '.so.7', ''}) do
    local ok
    pcall(ffi.load, 'libhistory' .. suffix)
    ok, clib = pcall(ffi.load, 'libreadline' .. suffix)
    if ok then break end
end

if type(clib) == 'string' then
    print(clib)     -- this is actually error string
    return ffi.C.exit(2)
end

clib.rl_initialize()
-- read history from file
clib.read_history(history_file)

local puts = function(text)
    text = tostring(text or '') .. '\n'
    
    if clib.rl_outstream then
        return clib.fwrite(text, #text, 1, clib.rl_outstream)
    else
        return print(text)
    end
end

local add_to_history = function(text, save)
    clib.add_history(text)
    if save then
        clib.write_history(history_file)
    end
end

local function set_completion_func(func)
    function clib.rl_attempted_completion_function(word)
        local prefix = ffi.string(word)

        local ok, matches = pcall(func, prefix)
        if not ok then return nil end

        -- if matches is an rl_completion_entry_function empty array,
        -- tell readline to not call default completion (file)
        clib.rl_attempted_completion_over = 1
        pcall(function() clib.rl_completion_suppress_append = 1 end)

        -- translate matches table to C strings
        -- (there is probably more efficient ways to do it)
        local ret = clib.rl_completion_matches(word, function(_, i)
            local match = matches[i + 1]
            --print(i, match)

            if match then
                -- readline will free the C string by itself, so create copies of them
                local buf = ffi.C.malloc(#match + 1)
                ffi.copy(buf, match, #match + 1)
                return buf
            else
                return ffi.new('void*', nil)
            end
        end)
        return ret
    end
end

local sigint_count = 0
local function sigint_handler(status)
    puts()

    if clib.rl_end == 0 then
        sigint_count = sigint_count + 1
        if sigint_count == 1 then
            puts('press ^C once again to exit')
        else
            return ffi.C.exit(1)
        end
    else
        sigint_count = 0
        clib.rl_replace_line("", 0)
    end

    clib.rl_on_new_line()
    clib.rl_redisplay();
end

assert(SIG_ERR ~= ffi.C.signal(SIGINT, sigint_handler))

local readline = function(...)
    local input = clib.readline(...)
    sigint_count = 0

    local line
    if input ~= nil then
        line = ffi.string(input)
        ffi.C.free(input)
    end

    return line
end

local _M = setmetatable({
    puts = puts,
    set_completion_func = set_completion_func,
    add_to_history = add_to_history,
}, { __call = function(_, ...) return readline(...) end })

return _M
