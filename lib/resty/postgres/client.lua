local postgres = require("pgmoon")

local type = type
local setmetatable = setmetatable
local concat_tab = table.concat


local _M = {
    VERSION = "0.1.0"
}

local mt = {__index = _M}


local function connect(self)
    local pg = postgres.new {
        database = self.database,
        user     = self.user,
        host     = self.host,
        port     = self.port,
        password = self.opts.password,
        pool_size   = self.opts.pool_size,
        backlog     = self.opts.backlog,
    }

    if self.opts.timeout then
        pg:settimeout(self.opts.timeout)
    end

    local ok, err = pg:connect()
    if not ok then
        return nil, err
    end

    return pg
end


local function keepalive(self, postgres)
    postgres:keepalive(self.opts.max_idle_timeout)
end


local function disconnect(self, postgres)
    postgres:disconnect()
end


local function query(self, query_string)
    local pg, err = connect(self)
    if not pg then
        return nil, err
    end

    local res, err, partial, num_queries = pg:query(query_string)
    if not res and not partial then
        return nil, err
    end

    if self.opts.pool_size or self.opts.backlog then
        keepalive(self, pg)

    else
        disconnect(self, pg)
    end

    return res, err, partial, num_queries
end
_M.query = query


function _M.multi_query(self, queries)
    local query_string = concat_tab(queries, ";")
    return query(self, query_string)
end


function _M.new(opts)
    opts = opts or {}

    if type(opts.database) ~= "string" then
        return nil, "bad argument database: string expected, got " .. type(opts.database)
    end

    return setmetatable({
        database  = opts.database,
        user      = opts.user or "postgres",
        host      = opts.host or "127.0.0.1",
        port      = opts.port or 6379,
        opts = {
            password    = opts.password,
            timeout     = opts.timeout,
            pool_size   = opts.pool_size,
            backlog     = opts.backlog,
            max_idle_timeout = opts.max_idle_timeout,
        },
    }, mt)
end


return _M