# vim:set ft= ts=4 sw=4 et:

use t::Test;

create_table();

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: inserts a row
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                insert into "hello_world" ("name", "count") values ('hi', 100)
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to inserts a row: ", err)
                return
            end

            ngx.say("inserts a row: ", json.encode(res))
        }
--- response_body
inserts a row: {"affected_rows":1}
--- no_error_log
[error]



=== TEST 2: inserts a row with return value
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                insert into "hello_world" ("name", "count") values ('hi', 100) returning "id"
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to inserts a row: ", err)
                return
            end

            ngx.say("inserts a row: ", json.encode(res))
        }
--- response_body
inserts a row: {"1":{"id":1},"affected_rows":1}
--- no_error_log
[error]



=== TEST 3: selects from empty table
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                select * from hello_world limit 2
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to selects from empty table: ", err)
                return
            end

            ngx.say("selects from empty table: ", json.encode(res))
        }
--- response_body
selects from empty table: {}
--- no_error_log
[error]



=== TEST 4: selects count as a number
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                select count(*) from hello_world
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to selects count: ", err)
                return
            end

            ngx.say("selects count: ", json.encode(res))
        }
--- response_body
selects count: [{"count":0}]
--- no_error_log
[error]



=== TEST 5: deletes nothing
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                delete from hello_world
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to deletes nothing: ", err)
                return
            end

            ngx.say("deletes nothing: ", json.encode(res))
        }
--- response_body
deletes nothing: {"affected_rows":0}
--- no_error_log
[error]



=== TEST 6: update no rows
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local json = require("cjson.safe")
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                update "hello_world" SET "name" = 'blahblah'
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to update no rows: ", err)
                return
            end

            ngx.say("update no rows: ", json.encode(res))
        }
--- response_body
update no rows: {"affected_rows":0}
--- no_error_log
[error]
