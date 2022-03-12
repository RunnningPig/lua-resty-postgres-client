# vim:set ft= ts=4 sw=4 et:

use t::Test;

create_database();

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

run_tests();

__DATA__

=== TEST 1: create and drop table
--- global_config eval: $::GlobalConfig
--- server_config
        content_by_lua_block {
            local postgres = require "resty.postgres.client"
            local pg = postgres.new {
                database = "$TEST_NGINX_POSTGRES_DATABASE",
                user     = "$TEST_NGINX_POSTGRES_USER",
                password = "$TEST_NGINX_POSTGRES_PASSWORD",
                host     = "$TEST_NGINX_POSTGRES_HOST",
                port     = $TEST_NGINX_POSTGRES_PORT,
                timeout  = 1000,  -- 1 second 
            }

            local query = [[
                create table hello_world (
                    id serial not null,
                    name text,
                    count integer not null default 0,
                    primary key (id)
                )
            ]]

            local res, err = pg:query(query)
            if not res then
                ngx.say("failed to create table: ", err)
                return
            end

            ngx.say("create table: ", res)

            query = "drop table if exists $TEST_NGINX_POSTGRES_DATABASE"

            res, err = pg:query(query)
            if not res then
                ngx.say("failed to drop table: ", err)
                return
            end

            ngx.say("drop table: ", res)
        }
--- response_body
create table: true
drop table: true
--- no_error_log
[error]
