# vim:set ft= ts=4 sw=4 et:

use t::Test;

insert_rows();

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: select some rows
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
                select * from hello_world
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to select some rows: ", err)
                return
            end

            ngx.say("type(res): ", type(res))
            ngx.say("#res: ", #res)
        }
--- response_body
type(res): table
#res: 10
--- no_error_log
[error]



=== TEST 2: update rows
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
                ngx.say("failed to update rows: ", err)
                return
            end

            ngx.say("update rows: ", json.encode(res))

            query = [[
                select name from hello_world limit 1
            ]]

            res, err = pg:query(query)
            if not res then
                ngx.say("failed to select: ", err)
                return
            end

            ngx.say("select name: ", res[1].name)
        }
--- response_body
update rows: {"affected_rows":10}
select name: blahblah
--- no_error_log
[error]



=== TEST 3: delete a row
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
                delete from "hello_world" where id = 1
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to delete a row: ", err)
                return
            end

            ngx.say("delete a row: ", json.encode(res))

            query = [[
                select * from hello_world where id = 1
            ]]

            res, err = pg:query(query)
            if not res then
                ngx.say("failed to select: ", err)
                return
            end

            ngx.say("select *: ", res[1])
        }
--- response_body
delete a row: {"affected_rows":1}
select *: nil
--- no_error_log
[error]



=== TEST 4: truncate table
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
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
                truncate hello_world
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to truncate table: ", err)
                return
            end

            ngx.say("truncate table: ", res)
        }
--- response_body
truncate table: true
--- no_error_log
[error]



=== TEST 5: make many select queries
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

            for i=1,20 do
                local query = [[
                    update "hello_world" SET "name" = 'blahblah' where id = 
                ]] .. i

                local res, err = pg:query(query)
                if not res then
                    ngx.say("failed to update #", i, " :", err)
                    return
                end

                ngx.say("update #", i, ": ", json.encode(res))

                query = [[
                    select * from hello_world
                ]]

                res, err = pg:query(query)
                if not res then
                    ngx.say("failed to select *: ", err)
                    return
                end

                ngx.say("select *: ", not not res)
            end
        }
--- response_body
update #1: {"affected_rows":1}
select *: true
update #2: {"affected_rows":1}
select *: true
update #3: {"affected_rows":1}
select *: true
update #4: {"affected_rows":1}
select *: true
update #5: {"affected_rows":1}
select *: true
update #6: {"affected_rows":1}
select *: true
update #7: {"affected_rows":1}
select *: true
update #8: {"affected_rows":1}
select *: true
update #9: {"affected_rows":1}
select *: true
update #10: {"affected_rows":1}
select *: true
update #11: {"affected_rows":0}
select *: true
update #12: {"affected_rows":0}
select *: true
update #13: {"affected_rows":0}
select *: true
update #14: {"affected_rows":0}
select *: true
update #15: {"affected_rows":0}
select *: true
update #16: {"affected_rows":0}
select *: true
update #17: {"affected_rows":0}
select *: true
update #18: {"affected_rows":0}
select *: true
update #19: {"affected_rows":0}
select *: true
update #20: {"affected_rows":0}
select *: true
--- no_error_log
[error]
--- timeout: 5s
