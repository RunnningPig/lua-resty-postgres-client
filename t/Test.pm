package t::Test;

use strict;
use warnings;

use Test::Nginx::Socket::Lua::Stream -Base;
use Cwd qw(cwd);

my $pwd = cwd();
my $HtmlDir = html_dir;

our @EXPORT = qw($GlobalConfig create_database create_table insert_rows);
our $GlobalConfig = qq{
    lua_package_path "$pwd/lib/?.lua;$pwd/t/?.lua;;";
    lua_package_cpath "/usr/local/openresty-debug/lualib/?.so;/usr/local/openresty/lualib/?.so;;";
};

$ENV{TEST_NGINX_POSTGRES_DATABASE} ||= "lua_resty_postgres_client_test";
$ENV{TEST_NGINX_POSTGRES_PASSWORD} ||= "lua_resty_postgres_client";
$ENV{TEST_NGINX_POSTGRES_USER} ||= "postgres";
$ENV{TEST_NGINX_POSTGRES_HOST} ||= "127.0.0.1";
$ENV{TEST_NGINX_POSTGRES_PORT} ||= 5432;

no_long_string();

add_block_preprocessor(sub {
    my $block = shift;

    if (!defined $block->http_only) {
        if (defined($ENV{TEST_SUBSYSTEM}) && $ENV{TEST_SUBSYSTEM} eq "stream") {
            if (!defined $block->stream_config) {
                $block->set_value("stream_config", $block->global_config);
            }
            if (!defined $block->stream_server_config) {
                $block->set_value("stream_server_config", $block->server_config);
            }
            if (defined $block->internal_server_error) {
                $block->set_value("stream_respons", "");
            }
        } else {
            if (!defined $block->http_config) {
                $block->set_value("http_config", $block->global_config);
            }
            if (!defined $block->request) {
                $block->set_value("request", <<\_END_);
GET /t
_END_
            }
            if (!defined $block->config) {
                $block->set_value("config", "location /t {\n" . $block->server_config . "\n}");
            }
            if (defined $block->internal_server_error) {
                $block->set_value("error_code", 500);
                $block->set_value("ignore_response_body", "");
            }
        }
    }
});


my $psql = "PGHOST='$ENV{TEST_NGINX_POSTGRES_HOST}' PGPORT='$ENV{TEST_NGINX_POSTGRES_PORT}' PGUSER='$ENV{TEST_NGINX_POSTGRES_USER}' PGPASSWORD='$ENV{TEST_NGINX_POSTGRES_PASSWORD}' psql -c ";

my $create_database_snippet = <<"EOF";
    local psql = require("util").psql

    local query = [[
        drop database if exists $ENV{TEST_NGINX_POSTGRES_DATABASE}
    ]]

    local ok, stdout, stderr, reason, status = psql(query)
    if not ok then
        ngx.log(ngx.ERR, "failed to drop database with status: " .. status .. ", reason: " .. reason .. ", stderr: " .. stderr)
        return
    end

    ngx.log(ngx.INFO, "drop database ok")

    query = [[
        create database $ENV{TEST_NGINX_POSTGRES_DATABASE}
    ]]

    ok, stdout, stderr, reason, status = psql(query)
    if not ok then
        ngx.log(ngx.ERR, "failed to create database with status: " .. status .. ", reason: " .. reason .. ", stderr: " .. stderr)
        return
    end

    ngx.log(ngx.INFO, "create database ok")
EOF

my $create_table_snippet = <<"EOF";
    local psql = require("util").psql

    local query = [[
        create table hello_world (
            id serial not null,
            name text,
            count integer not null default 0,
            flag boolean default TRUE,
            primary key (id)
        )
    ]]

    local ok, stdout, stderr, reason, status = psql(query, "$ENV{TEST_NGINX_POSTGRES_DATABASE}")
    if not ok then
        ngx.log(ngx.ERR, "failed to create table with status: " .. status .. ", reason: " .. reason .. ", stderr: " .. stderr)
        return
    end

    ngx.log(ngx.INFO, "create table ok")
EOF

my $insert_rows_snippet = <<"EOF";
    local psql = require("util").psql

    for i=1,10 do
        local query = ([[
            insert into "hello_world" ("name", "count")
                values ('thing_#%s', %s)
        ]]):format(i, i)

        local ok, stdout, stderr, reason, status = psql(query, "$ENV{TEST_NGINX_POSTGRES_DATABASE}")
        if not ok then
            ngx.log(ngx.ERR, "failed to insert row #" .. i .. " with status: " .. status .. ", reason: " .. reason .. ", stderr: " .. stderr)
            return
        end
    end

    ngx.log(ngx.INFO, "insert rows ok")
EOF

sub create_database {
    add_block_preprocessor(sub {
        my $block = shift;

        my $server_config = "access_by_lua_block {"
                                . $create_database_snippet
                                . "}";
        if (defined $block->server_config) {
            $server_config = $server_config . "\n" . $block->server_config;
        }

        $block->set_value("server_config", $server_config);
    });
}

sub create_table {
    add_block_preprocessor(sub {
        my $block = shift;

        my $server_config = "access_by_lua_block {"
                                . $create_database_snippet
                                . "\n"
                                . $create_table_snippet
                                . "}";
        if (defined $block->server_config) {
            $server_config = $server_config . "\n" . $block->server_config;
        }

        $block->set_value("server_config", $server_config);
    });
}

sub insert_rows {
    add_block_preprocessor(sub {
        my $block = shift;

        my $server_config = "access_by_lua_block {"
                                . $create_database_snippet
                                . "\n"
                                . $create_table_snippet
                                . "\n"
                                . $insert_rows_snippet
                                . "}";
        if (defined $block->server_config) {
            $server_config = $server_config . "\n" . $block->server_config;
        }

        $block->set_value("server_config", $server_config);
    });
}

1;
