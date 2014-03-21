local page_set_title, json = page_set_title, require 'dkjson'
local url, http = require 'socket.url', require 'socket.http'
local url_escape = function (s) local v = url.escape(s); return v end
local config, tconcat = settings.migrate, table.concat
local ltn12 = require'ltn12'

local request_get_body = request_get_body

local debug = debug

module 'ophal.modules.migrate'

local function api_call(uri, request_body)
  if request_body == nil then
    request_body = {}
  end
  request_body.token = config.token

  local response_body = {}
  local request_uri = ''
  local output = {}

  request_uri = config.base_uri .. '/' .. (uri or '')
  request_body = json.encode(request_body)

  local res, code, headers = http.request{
    url = request_uri,
    method = 'POST',
    headers = {
      ['content-length'] = request_body:len(),
    },
    source = ltn12.source.string(request_body),
    sink = ltn12.sink.table(response_body),
  }

  if res == 1 then
    output.response = json.decode(tconcat(response_body) or '')
  end

  return output
end

function test()
  return '<p>Request:</p><p>' .. request_get_body() .. '</p>'
end

--[[
  Implements hook menu().
]]
function menu()
  local items = {}

  items['test'] = {
    page_callback = 'test',
  }

  items['admin/config/migrate'] = {
    page_callback = 'config_page',
  }

  items['admin/content/migrate'] = {
    page_callback = 'wizard_page',
  }

  return items
end

function config_page()
  return 'TODO'
end

function wizard_page()
  page_set_title 'Migrate wizard'
  return debug.print_r(api_call('count/node'),true)
end
