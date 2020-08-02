local irc = require("irc")
local xml = require("xml")
local sleep = require("socket").sleep
local inspect = require("inspect")
local parseXml
parseXml = function(str)
  return xml.load(str)
end
local flatten
flatten = function(t)
  local total = ""
  local helper
  helper = function(tt)
    for k, v in pairs(tt) do
      if "table" == type(v) then
        total = total .. helper(v)
      else
        total = total .. v
      end
    end
  end
  helper(t)
  return total
end
local flattenMemoMessage
flattenMemoMessage = function(msg)
  for k, v in pairs(msg) do
    if "string" == type(k) then
      msg[k] = nil
    elseif "table" == type(v) then
      msg[k] = flattenMemoMessage(v)
    end
  end
  return flatten(msg)
end
local typeof, expect, typeset
do
  typeof = function(v)
    local meta
    if "table" == type(v) then
      do
        local type_mt = getmetatable(v)
        if type_mt then
          meta = type_mt.__type
        end
      end
    end
    if meta then
      local _exp_0 = type(meta)
      if "function" == _exp_0 then
        return meta(v)
      elseif "string" == _exp_0 then
        return meta
      end
    elseif io.type(v) then
      return "io"
    else
      return type(v)
    end
  end
  expect = function(n, v, ts)
    for _index_0 = 1, #ts do
      local ty = ts[_index_0]
      if ty == typeof(v) then
        return true
      end
    end
    return error("bad argument #" .. tostring(n) .. " (expected " .. tostring(table.concat(ts, ' or ')) .. ", got " .. tostring(type(v)) .. ")", 2)
  end
  typeset = function(v, ty)
    expect(1, v, {
      "table"
    })
    do
      local mt = getmetatable(v)
      if mt then
        mt.__type = ty
      else
        setmetatable(v, {
          __type = ty
        })
      end
    end
    return v
  end
end
local toColorCommand
toColorCommand = function(clr)
  return "COLOR >" .. tostring(clr.r) .. "," .. tostring(clr.g) .. "," .. tostring(clr.b)
end
local fromMemoMessage
fromMemoMessage = function(message)
  return parseXml(message:gsub("c=(%d+),(%d+),(%d+)", 'c r="%1" g="%2" b="%3"'))
end
local PesterCommandTypes = {
  Begin = "BEGIN",
  Close = "CEASE",
  Block = "BLOCK",
  UnBlock = "UNBLOCK"
}
local PesterCommand
PesterCommand = function(command)
  return "PESTERCHUM:" .. tostring(command)
end
local HandleSpace
do
  local _class_0
  local _base_0 = {
    join = function(self, u)
      return u:join(self.name)
    end,
    is_memo = function(self)
      return false
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name)
      self.name = name
    end,
    __base = _base_0,
    __name = "HandleSpace"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  HandleSpace = _class_0
end
local Memo
do
  local _class_0
  local _parent_0 = HandleSpace
  local _base_0 = {
    is_memo = function(self)
      return true
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Memo",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Memo = _class_0
end
local Pester
do
  local _class_0
  local _parent_0 = HandleSpace
  local _base_0 = { }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, ...)
      return _class_0.__parent.__init(self, ...)
    end,
    __base = _base_0,
    __name = "Pester",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  Pester = _class_0
end
local User
do
  local _class_0
  local _base_0 = {
    send_command = function(self, handle, cmd)
      return self.user:sendChat(handle.name, PesterCommand(cmd))
    end,
    connect = function(self, host, port)
      if host == nil then
        host = "irc.mindfang.org"
      end
      expect(1, host, {
        "string"
      })
      expect(2, port, {
        "number",
        "nil"
      })
      return self.user:connect(host, port)
    end,
    disconnect = function(self, handle)
      self:send_command(handle, PesterCommandTypes.Close)
      return self.user:disconnect(message)
    end,
    pester = function(self, handle)
      handle:join(self.user)
      self:send_command(handle, PesterCommandTypes.Begin)
      return self:set_color(handle, self.color)
    end,
    memo = function(self, handle)
      handle:join(self.user)
      return self:message(handle, "Hello. I am systemBreaker.")
    end,
    message = function(self, handle, text)
      local handle_name = handle.name
      if handle:is_memo() then
        return self.user:sendChat(handle_name, "<c=" .. tostring(self.color.r) .. "," .. tostring(self.color.g) .. "," .. tostring(self.color.b) .. ">" .. tostring(text))
      else
        return self.user:sendChat(handle_name, text)
      end
    end,
    set_color = function(self, handle, color)
      self.color = color
      if not (handle:is_memo()) then
        return self.user:sendChat(handle.name, toColorCommand(self.color))
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, nick, color, username)
      if color == nil then
        color = {
          r = 0,
          g = 0,
          b = 0
        }
      end
      if username == nil then
        username = "pcc31"
      end
      expect(1, nick, {
        "string"
      })
      expect(2, color, {
        "table"
      })
      expect(3, username, {
        "string"
      })
      self.handle = nick
      self.color = color
      self.user = irc.new({
        nick = nick,
        username = username
      })
    end,
    __base = _base_0,
    __name = "User"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  User = _class_0
end
local systemBreaker = User("webchumClient", {
  r = 255,
  g = 0,
  b = 0
})
local testmemo = Pester("oghuzOrbit")
systemBreaker.user:hook("OnChat", function(sender, channel, message)
  if message:match("^P") then
    return print(channel, sender.nick, message)
  else
    local t = fromMemoMessage(message)
    return print(channel, sender.nick, tostring(t.r) .. "," .. tostring(t.g) .. "," .. tostring(t.b), flattenMemoMessage(t))
  end
end)
systemBreaker:connect()
systemBreaker:pester(testmemo)
systemBreaker:message(testmemo, "yo")
return systemBreaker:disconnect(testmemo)
