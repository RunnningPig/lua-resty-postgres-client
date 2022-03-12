# vim:set ft= ts=4 sw=4 et:

use t::Test;

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: create and drop database
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local postgres = require "resty.postgres.client"
            local pg = postgres.new {
                --database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = "drop database if exists $TEST_NGINX_POSTGRES_DATABASE"

            local res, err = pg:query(query);
            if not res then
                ngx.say("failed to drop database: ", err)
                return
            end

            ngx.say("drop database: ", res)

            query = "create database $TEST_NGINX_POSTGRES_DATABASE"

            res, err = pg:query(query);
            if not res then
                ngx.say("failed to create database: ", err)
                return
            end

            ngx.say("create database: ", res)
        }
--- response_body
drop database: true
create database: true
--- no_error_log
[error]
--- SKIP



=== TEST 2: timeout
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local postgres = require "resty.postgres.client"
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "10.0.0.1",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second
            }

            local query = "select 1"

            local res, err = pg:query(query);
            if not res then
                ngx.say("failed to select: ", err)
                return
            end

            ngx.say("select: ", res)
        }
--- response_body
failed to select: timeout
--- error_log
lua tcp socket connect timed out
