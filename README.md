# Name

lua-resty-postgres-client - Wrapper for [pgmoon](https://github.com/leafo/pgmoon), easy to use

# Table of Contents

- [Name](https://github.com/RunnningPig/lua-resty-postgres-client#name)
- [Description](https://github.com/RunnningPig/lua-resty-postgres-client#description)
- [Synopsis](https://github.com/RunnningPig/lua-resty-postgres-client#synopsis)
- [Methods](https://github.com/RunnningPig/lua-resty-postgres-client#methods)
  - [new](https://github.com/RunnningPig/lua-resty-postgres-client#new)
  - [query](https://github.com/RunnningPig/lua-resty-postgres-client#query)
  - [multi_query](https://github.com/RunnningPig/lua-resty-postgres-client#multi_query)
- [Installation](https://github.com/RunnningPig/lua-resty-postgres-client#installation)

# Description

This is a wrapper library for [pgmoon](https://github.com/leafo/pgmoon), simplifying the steps and hiding operations such as connect, keepalive, etc.

# Synopsis

```nginx
# you do not need the following line if you are using
# the OpenResty bundle:
lua_package_path "/path/to/lua-resty-postgres-client/lib/?.lua;;";

server {
    location /test {
        content_by_lua_block {
            local postgres = require("resty.postgres.client")

            local pg = postgres.new {
                database = "hello_world",
                user = "postgres",
                host = "127.0.0.1",
                port = 5432,
                timeout = 1000,  -- 1 sec
            }

            local query = [[
                select * from t_user where id = 1
            ]]

            local res, err = pg:query(query);
            if not res then
                ngx.say("failed to query user: ", err)
                return
            end

            if not res[1] then
                ngx.say("user not found")

            else
                -- process result: res
            end

            -- single call, multiple queries

            local queries = {
                "select id, flag from hello_world order by id asc limit 1",
                "select id, flag from jello_world limit 1",
            }

            local results, err, partial, num_queries = pg:multi_query(queries)
            if results then
                -- all ok
                for _, res in ipairs(results) do
                    -- process successful result: res
                end

            else
                -- partial ok
                for i=1, num_queries do
                    -- process successful result: partial[i]
                end

                ngx.say("failed to multi query: ", err)

                -- partial failed
                for i=num_queries+1, #queries do
                    -- process failed result: partial[i]
                end
            end
        }
    }
}
```

# Methods

## new

`syntax: pg, err = postgres.new(options_table)`

Creates a postgres object. In case of failures, returns `nil` and a string describing the error.

The `options_table` argument is a Lua table holding the following keys:

* `database`
  
  The database name to connect to **required**.
- `host`
  
  The host to connect to (default: `"127.0.0.1"`).
* `port`
  
  The port to connect to (default: `"6379"`).

* `user`
  
  The database username to authenticate (default: `"postgres"`).

* `password`
  
  Password for authentication, may be required depending on server configuration.

* `timeout`
  
  Sets the connect, send, and read timeout thresholds (in ms), for subsequent socket operations.
  
  See [pgmoon#settimeout](https://github.com/leafo/pgmoon#postgressettimeouttime) for details.

* `pool_size`
  
  Specifies the size of the connection pool.
  
  See [pgmoon#new](https://github.com/leafo/pgmoon#newoptions) for details.

* `backlog`
  
  If specified, this module will limit the total number of opened connections for this pool. 
  
  See [pgmoon#new](https://github.com/leafo/pgmoon#newoptions) for details.

* `max_idle_timeout`
  
  Specifies the max idle timeout (in ms) when the connection is in the pool.
  
  See [pgmoon#keepalive](https://github.com/leafo/pgmoon#success-err--postgreskeepalive) for details.

[Back to TOC](https://github.com/RunnningPig/lua-resty-postgres-client#table-of-contents)

## query

`syntax: result, num_queries = pg:query(query_string)`

Sends a query to the server. On failure returns `nil` and the error message.

On success returns a result depending on the kind of query sent.

See [pgmoon#query](https://github.com/leafo/pgmoon#result-num_queries--postgresqueryquery_string) for details.

[Back to TOC](https://github.com/RunnningPig/lua-resty-postgres-client#table-of-contents)

## multi_query

`syntax: results, err, partial, num_queries = pg:multi_query(queries)`

Sends multiple queries at once. 

Because Postgres executes each query at a time, earlier ones may succeed and further ones may fail. If there is a failure with multiple queries then the partial result and partial number of queries executed is returned after the error message.

See [pgmoon#query](https://github.com/leafo/pgmoon#result-num_queries--postgresqueryquery_string) for details.

[Back to TOC](https://github.com/RunnningPig/lua-resty-postgres-client#table-of-contents)

# Installation

```shell
$ luarocks install lua-resty-postgres-client
```

[Back to TOC](https://github.com/RunnningPig/lua-resty-postgres-client#table-of-contents)
