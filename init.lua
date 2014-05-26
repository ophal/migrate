local page_set_title, add_js, theme, type = page_set_title, add_js, theme, type
local url, pairs, json = require 'socket.url', pairs, require 'dkjson'
local url_escape, l = function (s) local v = url.escape(s); return v end, l
local config, tconcat, modules = settings.migrate, table.concat, ophal.modules
local ltn12, arg, setmetatable = require'ltn12', arg, setmetatable
local require = require

local request_get_body = request_get_body

local debug = debug

module 'ophal.modules.migrate'

local user

--[[
  Implements hook_user().
]]
function init()
  user = modules.user
end

local migration = {
  __index = function (t, k)
    if k == 'load' then
      return function (t, config)
        local library = require(t.library_path)
        library.info = t
        library.config = config
        return library
      end
    end
  end
}

function test()
  return '<p>Request:</p><p>' .. request_get_body() .. '</p>'
end

--[[
  Implements hook menu().
]]
function route()
  local items = {}

  items['test'] = {
    page_callback = 'test',
  }

  items['admin/config/migrate'] = {
    page_callback = 'config_page',
    access_callback = {module = 'user', 'access', 'administer migrations'},
  }

  items['admin/content/migrate'] = {
    page_callback = 'wizard_page',
    access_callback = {module = 'user', 'access', 'run migrations'},
  }

  items.migrate = {
    page_callback = 'migrate_service',
    access_callback = {module = 'user', 'access', 'run migrations'},
    format = 'json',
  }

  return items
end

function config_page()
  return 'TODO'
end

function get_migrations()
  local err
  local migrations, item = {}

  for name, m in pairs(modules) do
    if m.migration then
      item, err = m.migration() -- call hook implementation
      if err then
        return nil, err
      end
      for k, v in pairs(item) do
        setmetatable(v, migration)
        migrations[k] = v:load(config[k])
      end
    end
  end

  return migrations
end

function wizard_page()
  local id, task, migrations, source, response
  local output = {}

  add_js 'modules/migrate/migrate.js'

  page_set_title 'Migrate wizard'

  migrations = get_migrations()

  id = arg(3)
  source = arg(4)
  if id ~= nil then
    if source ~= nil then
      task = migrations[id].tasks[source]
      page_set_title(('Migrate wizard: %s > %s'):format(config[id].description, task.description))
      add_js{
        {[id] = {source = source}},
        namespace = 'migrate', type = 'settings'
      }
      add_js{("Ophal.migrate.start('%s')"):format(id), type = 'inline'}
      output[1 + #output] = ('<div id="migrate_%s">'):format(id)
      output[1 + #output] = '<p>'
      output[1 + #output] = 'Number of objects: <span class="total"></span><br />'
      output[1 + #output] = 'Current object: <span class="current"></span><br />'
      output[1 + #output] = '</p>'
      output[1 + #output] = theme{'progress'}
      output[1 + #output] = '</div>'
    else
      page_set_title(('Migrate wizard: %s'):format(config[id].description))
      output[1 + #output] = '<ul>'
      for j, task in pairs(migrations[id].tasks) do
        output[1 + #output] = '<li>'
        output[1 + #output] = l(task.description, ('admin/content/migrate/%s/%s'):format(id, j) or j)
        output[1 + #output] = '</li>'
      end
      output[1 + #output] = '</ul>'
    end
  else
    output[1 + #output] = '<p>Available migrations:</p>'
    output[1 + #output] = '<ul>'
    for k, id in pairs(config) do
      output[1 + #output] = '<li>'
      output[1 + #output] = l(('%s (%s)'):format(id.description or k, migrations[k].info.type), ('admin/content/migrate/%s'):format(k))
      output[1 + #output] = '</li>'
    end
    output[1 + #output] = '</ul>'
  end

  return tconcat(output)
end

function migrate_service()
  local input, parsed, pos, err, task, migrations
  local output = {}

  input = request_get_body()
  parsed, pos, err = json.decode(input, 1, nil)
  migrations = get_migrations()

  if err then
    output.error = err
  elseif 'table' == type(parsed) then
    task = migrations[parsed.id].tasks[parsed.source]
    if parsed.action == 'count' then
      output.count = (task.count() or {}).total
    elseif parsed.action == 'list' then
      output.list = task.list(parsed.last_id)
    elseif parsed.action == 'import' then
      output.imported = task:import(parsed.object_id)
    end
  end

  return output
end
