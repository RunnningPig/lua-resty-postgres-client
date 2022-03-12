local shell = require("resty.shell")

local type = type
local pairs = pairs
local table = table
local tostring = tostring
local ngx_re = ngx.re


local _M = {}


local pg_user     = os.getenv("TEST_NGINX_POSTGRES_USER") or "postgres"
local pg_password = os.getenv("TEST_NGINX_POSTGRES_PASSWORD") or "lua_resty_postgres_client"
local pg_host     = os.getenv("TEST_NGINX_POSTGRES_HOST") or "127.0.0.1"
local pg_port     = os.getenv("TEST_NGINX_POSTGRES_PORT") or 5432


local function shell_escape(str)
    local newstr = ngx_re.gsub(str, "'", "'\\''")
    return newstr
end


local function oneline(str)
    local newstr = ngx_re.gsub(str, "\n", " ")
    newstr = ngx_re.gsub(newstr, " +", " ")
    newstr = ngx_re.gsub(newstr, "^ +", "")
    newstr = ngx_re.gsub(newstr, " +$", "")
    return newstr
end


function _M.psql(query, database)
    query = oneline(query)

    local cmd = (
        [[PGHOST='%s' PGPORT='%s' PGUSER='%s' PGPASSWORD='%s' psql -c '%s' '%s']]
    ):format(
        shell_escape(pg_host),
        shell_escape(pg_port),
        shell_escape(pg_user),
        shell_escape(pg_password),
        shell_escape(query),
        database and shell_escape(database) or ""
    )
    return shell.run(cmd)
end


local compare_table
do
    local dir_names = {}

function compare_table(pattern, data, deep)
    deep = deep or 1

    for k, v in pairs(pattern) do
        dir_names[deep] = k

        if v == ngx.null then
            v = nil
        end

        if type(v) == "table" and data[k] then
            local ok, err = compare_table(v, data[k], deep + 1)
            if not ok then
                return false, err
            end

        elseif v ~= data[k] then
            return false, "path: " .. table.concat(dir_names, "->", 1, deep)
                          .. " expect: " .. tostring(v) .. " got: "
                          .. tostring(data[k])
        end
    end

    return true
end

end -- do
_M.compare_table = compare_table


return _M