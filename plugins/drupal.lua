local json, http = require 'dkjson', require 'socket.http'
local tconcat, modules = table.concat, ophal.modules

local m = {}

m.tasks = {
  content = {
    description = 'Import Drupal nodes',
    count = function()
      local rs = m:api_call('count/node') or {}
      return rs.response
    end,
    list = function(last_id)
      last_id = last_id or 0
      local rs = m:api_call('list/node/' .. last_id) or {}
      return rs.response
    end,
    fetch = function(id)
      local rs = m:api_call('fetch/node/' .. id) or {}
      debug.log(rs)
      return rs.response
    end,
  },
  user = {
    description = 'Import Drupal users',
    count = function()
      local rs = m:api_call('count/user') or {}
      return rs.response
    end,
    list = function(last_id)
      last_id = last_id or 0
      local rs = m:api_call('list/user/' .. last_id) or {}
      return rs.response
    end,
    fetch = function(id)
      local rs = m:api_call('fetch/user/' .. id) or {}
      debug.log(rs)
      return rs.response
    end,
  },
  comment = {
    description = 'Import Drupal comments',
    count = function()
      local rs = m:api_call('count/comment') or {}
      return rs.response
    end,
    list = function(last_id)
      last_id = last_id or 0
      local rs = m:api_call('list/comment/' .. last_id) or {}
      return rs.response
    end,
    fetch = function(id)
      local rs = m:api_call('fetch/comment/' .. id) or {}
      return rs.response
    end,
    import = function(t, id)
      local data = t.fetch(id)
      if data then
        return modules.comment.create {
          id = data.cid,
          entity_id = data.nid,
          parent_id = data.pid,
          user_id = data.uid,
          body = data.comment,
          created = data.timestamp,
          status = data.status,
          subject = data.subject,
          hostname = data.hostname,
          format = data.format,
          name = data.name,
          mail = data.mail,
          homepage = data.homepage,
        }
      end
    end,
  },
  alias = {
    description = 'Import Drupal path aliases',
    count = function()
      local rs = m:api_call('count/alias') or {}
      return rs.response
    end,
    list = function(last_id)
      last_id = last_id or 0
      local rs = m:api_call('list/alias/' .. last_id) or {}
      return rs.response
    end,
    fetch = function(id)
      local rs = m:api_call('fetch/alias/' .. id) or {}
      return rs.response
    end,
    import = function (t, id)
      local data = t.fetch(id)
      if data then
        return route_create_alias {
          source = data.src,
          alias = data.dst,
          language = data.language,
        }
      end
    end,
  },
}

m.api_call = function(t, uri, request_body)
  if request_body == nil then
    request_body = {}
  end
  request_body.token = t.config.token

  local response_body = {}
  local request_uri = ''
  local output = {}

  request_uri = t.config.base_uri .. '/' .. (uri or '')
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

return m
