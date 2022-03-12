# vim:set ft= ts=4 sw=4 et:

use t::Test;

insert_rows();

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: gets two results
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local compare_table = require("util").compare_table
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local queries = {
                "select id, flag from hello_world order by id asc limit 2",
                "select id, flag from hello_world order by id asc limit 2 offset 2",
            }

            local results, num_queries = pg:multi_query(queries);
            if not results then
                ngx.say("failed to gets tow results: ", num_queries)
                return
            end

            ngx.say("num_queries: ", num_queries)

            local ok, err = compare_table({
                {
                  { id = 1, flag = true },
                  { id = 2, flag = true },
                },

                {
                  { id = 3, flag = true },
                  { id = 4, flag = true },
                },
            }, results)
            if not ok then
                ngx.say("failed to compare results: ", err)
                return
            end
            ngx.say("results compare: ", ok)
        }
--- response_body
num_queries: 2
results compare: true
--- no_error_log
[error]



=== TEST 2: gets three results
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local compare_table = require("util").compare_table
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local queries = {
                "select id, flag from hello_world order by id asc limit 2",
                "select id, flag from hello_world order by id asc limit 2 offset 2",
                "select id, flag from hello_world order by id asc limit 2 offset 4",
                [[insert into "hello_world" ("name", "count") values ('hi', 100) returning "id"]],
            }

            local results, num_queries = pg:multi_query(queries);
            if not results then
                ngx.say("failed to gets three results: ", num_queries)
                return
            end

            ngx.say("num_queries: ", num_queries)

            local ok, err = compare_table({
                {
                  { id = 1, flag = true },
                  { id = 2, flag = true },
                },

                {
                  { id = 3, flag = true },
                  { id = 4, flag = true },
                },

                {
                  { id = 5, flag = true },
                  { id = 6, flag = true },
                },
              }, results)
            if not ok then
                ngx.say("failed to compare results: ", err)
                return
            end
            ngx.say("results compare: ", ok)
        }
--- response_body
num_queries: 4
results compare: true
--- no_error_log
[error]



=== TEST 3: does multiple updates
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local compare_table = require("util").compare_table
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local queries = {
                "update hello_world set flag = false where id = 3",
                "update hello_world set flag = true",
            }

            local results, num_queries = pg:multi_query(queries);
            if not results then
                ngx.say("failed to does multiple updates: ", num_queries)
                return
            end

            ngx.say("num_queries: ", num_queries)

            local ok, err = compare_table({
                { affected_rows = 1 },
                { affected_rows = 10 },
              }, results)
            if not ok then
                ngx.say("failed to compare results: ", err)
                return
            end
            ngx.say("results compare: ", ok)
        }
--- response_body
num_queries: 2
results compare: true
--- no_error_log
[error]



=== TEST 4: does mix update and select
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local compare_table = require("util").compare_table
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local queries = {
                "update hello_world set flag = false where id = 3",
                "select id, flag from hello_world where id = 3",
            }

            local results, num_queries = pg:multi_query(queries);
            if not results then
                ngx.say("failed to does mix update and select: ", num_queries)
                return
            end

            ngx.say("num_queries: ", num_queries)

            local ok, err = compare_table({
                { affected_rows = 1 },
                {
                  { id = 3, flag = false },
                },
              }, results)
            if not ok then
                ngx.say("failed to compare results: ", err)
                return
            end
            ngx.say("results compare: ", ok)
        }
--- response_body
num_queries: 2
results compare: true
--- no_error_log
[error]



=== TEST 5: returns partial result on error
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local compare_table = require("util").compare_table
            local postgres = require("resty.postgres.client")
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local queries = {
                "select id, flag from hello_world order by id asc limit 1",
                "select id, flag from jello_world limit 1",
            }

            local results, err, partial, num_queries = pg:multi_query(queries);

            ngx.say("results: ", results)
            ngx.say("err: ", err)
            ngx.say("num_queries: ", num_queries)

            local ok, err = compare_table({
                { id = 1, flag = true },
              }, partial)
            if not ok then
                ngx.say("failed to compare partial: ", err)
                return
            end
            ngx.say("partial compare: ", ok)
        }
--- response_body
results: nil
err: ERROR: relation "jello_world" does not exist (79)
num_queries: 1
partial compare: true
--- no_error_log
[error]
