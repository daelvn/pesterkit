local IRC
IRC = require("irc").new
local parseXML
parseXML = require("xml").load
local sleep
sleep = require("socket").sleep
local logger, sink, Logger, Sink
do
  local _obj_0 = require("debugkit.log")
  logger, sink, Logger, Sink = _obj_0.logger, _obj_0.sink, _obj_0.Logger, _obj_0.Sink
end
local chance = require("chance.chance")
local inspect = require("inspect")
local lgr = logger.minimal()
lgr.level = "none"
local log_ = lgr("none")
local compose
compose = function(...)
  return table.concat({
    ...
  }, "\t")
end
local log
log = function(...)
  return log_(compose(...))
end
local levels
levels = function(t)
  local _tbl_0 = { }
  for i, v in ipairs(t) do
    _tbl_0[v] = i
  end
  return _tbl_0
end
local Pestersink
Pestersink = function(file)
  return Sink({
    open = function(self)
      if not (self.flag.opened) then
        local fh = safeOpen(file, "a")
        if fh.error then
          error("Pestersink $ could not open file " .. tostring(file) .. "!")
        end
        self.fh, self.flag.opened = fh, true
      end
    end,
    write = function(self, L, tag, level, msg)
      if self.flag.opened then
        if (L.levels[level] >= L.levels[L.level]) and (not contains(tag, L.exclude)) then
          self.fh:write(msg)
        end
        return self.fh:flush()
      else
        return error("Pestersink $ sink is not open!")
      end
    end,
    close = function(self)
      if self.flag.opened then
        self.fh:close()
        self.flag.opened = false
      end
    end
  })
end
local Pesterlog
Pesterlog = function(channel, location)
  if location == nil then
    location = "log/" .. tostring(channel) .. ".log"
  end
  return Logger({
    color = false,
    name = channel,
    sink = sink.file(location),
    level = "none",
    levels = levels({
      "none",
      "all"
    }),
    time = function(self)
      return os.date("%X")
    end,
    date = function(self)
      return os.date("%x")
    end,
    header = function(self, t, l)
      return tostring(self:date()) .. " " .. tostring(self:time()) .. " // " .. tostring(self.name) .. " // "
    end,
    footer = function(self, t, l)
      return "\n"
    end,
    exclude = {
      "hide"
    }
  })
end
local LOGGERS = { }
local LOGFUNC = { }
chance.core.seed(os.time())
_G.irc.handlers["353"] = function(o, prefix, me, chanType, channel, names)
  if o.track_users then
    o.channels[channel] = o.channels[channel] or {
      users = { },
      type = chanType
    }
    local users = o.channels[channel].users
    for nick in names:gmatch("(%S+)") do
      local access, name = irc.parseNick(nick)
      users[name] = {
        access = access
      }
    end
    return o:invoke("NameList", channel, users)
  end
end
_G.irc.handlers["366"] = function(o, prefix, me, channel, msg)
  return o
end
local toColor
toColor = function(t)
  return "COLOR >" .. tostring(t.r) .. "," .. tostring(t.g) .. "," .. tostring(t.b)
end
local colorize
colorize = function(m, t)
  return "<c=" .. tostring(t.r) .. "," .. tostring(t.g) .. "," .. tostring(t.b) .. ">" .. tostring(m) .. "</c>"
end
local toCommand
toCommand = function(s)
  return "PESTERCHUM:" .. s
end
local splitWs
splitWs = function(s)
  local whitespace = {
    ""
  }
  local words = {
    ""
  }
  for i = 1, #s do
    local c = string.sub(s, i, i)
    if c:match("%s") then
      do
        if whitespace[#whitespace] ~= nil then
          whitespace[#whitespace] = whitespace[#whitespace] .. c
        else
          whitespace[#whitespace] = ""
        end
      end
      if words[#words] ~= "" then
        words[#words + 1] = ""
      end
    else
      if whitespace[#whitespace] ~= "" then
        whitespace[#whitespace + 1] = ""
      end
      words[#words] = words[#words] .. c
    end
  end
  if whitespace[#whitespace] == "" then
    whitespace[#whitespace] = nil
  end
  return words, whitespace
end
local zip
zip = function(t1, t2)
  local tx = { }
  local s = true
  local i = 1
  while i <= math.max(#t1, #t2) do
    if s then
      tx[#tx + 1] = t1[i]
    else
      tx[#tx + 1] = t2[i]
      i = i + 1
    end
    s = not s
  end
  return tx
end
local MOODS = {
  "chummy",
  "rancorous",
  "offline",
  "pleasant",
  "distraught",
  "pranky",
  "smooth",
  "ecstatic",
  "relaxed",
  "discontent",
  "devious",
  "sleek",
  "detestful",
  "mirthful",
  "manipulative",
  "vigorous",
  "perky",
  "acceptant",
  "protective",
  "mystified",
  "amazed",
  "insolent",
  "bemused"
}
local REVMOODS
do
  local _tbl_0 = { }
  for k, v in pairs(MOODS) do
    _tbl_0[v] = k
  end
  REVMOODS = _tbl_0
end
local moodn
moodn = function(n)
  return MOODS[n + 1]
end
local COMMANDS = {
  BEGIN = toCommand("BEGIN"),
  CEASE = toCommand("CEASE"),
  BLOCK = toCommand("BLOCK"),
  UNBLOCK = toCommand("UNBLOCK"),
  MOOD = function(n)
    return "MOOD >" .. tostring(n)
  end,
  GETMOOD = function(st)
    local _exp_0 = type(st)
    if "string" == _exp_0 then
      return "GETMOOD " .. tostring(st)
    elseif "table" == _exp_0 then
      return "GETMOOD " .. tostring(table.concat(st, ''))
    end
  end,
  TIME = function(h, m)
    if h == 0 and m == 0 then
      return toCommand(("TIME>i"))
    end
    if h > 0 or m > 0 then
      return toCommand(("TIME>F%02d:%02d"):format(h, m))
    end
    if h < 0 or m < 0 then
      return toCommand(("TIME>P%02d:%02d"):format(h, m))
    end
  end
}
local Channel
do
  local _class_0
  local _base_0 = {
    join = function(self, ucl)
      self.ucl = ucl
      if self.memo then
        return self.ucl.user:sendChat(self.target, COMMANDS.TIME(self.time.hour, self.time.minute))
      else
        return self.ucl.user:sendChat(self.target, COMMANDS.BEGIN)
      end
    end,
    part = function(self)
      return self.ucl.user:sendChat(self.target, COMMANDS.CEASE)
    end,
    send = function(self, message)
      if self.memo then
        return self.ucl.user:sendChat(self.target, colorize(message, self.ucl.color))
      else
        return self.ucl.user:sendChat(self.target, message)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function() end,
    __base = _base_0,
    __name = "Channel"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Channel = _class_0
end
local Pester
do
  local _class_0
  local _parent_0 = Channel
  local _base_0 = {
    memo = false
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, handle)
      self.target = handle
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
local Memo
do
  local _class_0
  local _parent_0 = Channel
  local _base_0 = {
    memo = true
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, memo, h, m, key)
      if h == nil then
        h = 0
      end
      if m == nil then
        m = 0
      end
      self.target = "#" .. memo
      self.time = {
        hour = h,
        minute = m
      }
      self.key = key
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
local KBLOC = {
  (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, 12 do
      _accum_0[_len_0] = ("1234567890-="):sub(i, i)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(),
  (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, 12 do
      _accum_0[_len_0] = ("qwertyuiop[]"):sub(i, i)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(),
  (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, 12 do
      _accum_0[_len_0] = ("asdfghjkl:;'"):sub(i, i)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)(),
  (function()
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, 12 do
      _accum_0[_len_0] = ("zxcvbnm,.>/?"):sub(i, i)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)()
}
local KDICT = { }
for i, l in pairs(KBLOC) do
  for j, k in pairs(l) do
    KDICT[k] = {
      i,
      j
    }
  end
end
local SDICT = {
  ["a"] = "e",
  ["b"] = "d",
  ["c"] = "k",
  ["d"] = "g",
  ["e"] = "eh",
  ["f"] = "ph",
  ["g"] = "j",
  ["h"] = "h",
  ["i"] = "ai",
  ["j"] = "ge",
  ["k"] = "c",
  ["l"] = "ll",
  ["m"] = "n",
  ["n"] = "m",
  ["o"] = "oa",
  ["p"] = "b",
  ["q"] = "kw",
  ["r"] = "ar",
  ["s"] = "ss",
  ["t"] = "d",
  ["u"] = "you",
  ["v"] = "w",
  ["w"] = "wn",
  ["x"] = "cks",
  ["y"] = "uy",
  ["z"] = "s"
}
chance.core.set("moreless", {
  -1,
  0,
  1
})
chance.core.set("more", {
  0,
  1
})
chance.core.set("less", {
  -1,
  0
})
chance.core.set("letters", (function()
  local _accum_0 = { }
  local _len_0 = 1
  for i = 1, 26 do
    _accum_0[_len_0] = ("abcdefghijklmnopqrstuvwxyz"):sub(i, i)
    _len_0 = _len_0 + 1
  end
  return _accum_0
end)())
local quirk = { }
quirk.mistype = function(word, i, rate)
  local char = word:sub(i, i)
  if not (KDICT[char]) then
    return word
  end
  local charpos = KDICT[char]
  local newpos = {
    charpos[1],
    charpos[2]
  }
  local userate = chance.misc.d100()
  if userate <= rate then
    local _exp_0 = charpos[1]
    if 1 == _exp_0 then
      newpos[1] = charpos[1] + chance.core.fromSet("more")
    elseif #KBLOC == _exp_0 then
      newpos[1] = charpos[1] + chance.core.fromSet("less")
    else
      newpos[1] = charpos[1] + chance.core.fromSet("moreless")
    end
    local _exp_1 = charpos[2]
    if 1 == _exp_1 then
      newpos[2] = charpos[2] + chance.core.fromSet("more")
    elseif #KBLOC[1] == _exp_1 then
      newpos[2] = charpos[2] + chance.core.fromSet("less")
    else
      newpos[2] = charpos[2] + chance.core.fromSet("moreless")
    end
  end
  local newword = (word:sub(1, i - 1)) .. KBLOC[newpos[1]][newpos[2]] .. (word:sub(i + 1))
  log(rate, userate, i, (inspect(charpos)), KBLOC[charpos[1]][charpos[2]], word, (inspect(newpos)), KBLOC[newpos[1]][newpos[2]], newword)
  return newword
end
quirk.transpose = function(word, i, rate)
  local userate = chance.misc.d100()
  local oldword = word
  if userate <= rate then
    local j
    local _exp_0 = i
    if 1 == _exp_0 then
      j = i + chance.core.fromSet("more")
    elseif #word == _exp_0 then
      j = i + chance.core.fromSet("less")
    else
      j = i + chance.core.fromSet("moreless")
    end
    local chars
    do
      local _accum_0 = { }
      local _len_0 = 1
      for c in oldword:gmatch(".") do
        _accum_0[_len_0] = c
        _len_0 = _len_0 + 1
      end
      chars = _accum_0
    end
    chars[i], chars[j] = chars[j], chars[i]
    word = table.concat(chars, "")
  end
  log(rate, userate, i, oldword, word)
  return word
end
quirk.randomLetter = function(word, i, rate)
  local userate = chance.misc.d100()
  local oldword = word
  if userate <= rate then
    local by = chance.core.fromSet("letters")
    word = (oldword:sub(0, i + 1)) .. by .. (oldword:sub(i + 1))
    log(rate, userate, i, tostring(word:sub(i, i)) .. " ++ " .. tostring(by) .. "?", oldword, word)
  else
    log(rate, userate, i, tostring(word:sub(i, i)) .. " == " .. tostring(word:sub(i, i)) .. ".", oldword, word)
  end
  return word
end
quirk.randomReplace = function(word, i, rate)
  local userate = chance.misc.d100()
  local oldword = word
  if userate <= rate then
    local by = chance.core.fromSet("letters")
    word = (oldword:sub(0, i - 1)) .. by .. (oldword:sub(i + 1))
    log(rate, userate, i, tostring(oldword:sub(i, i)) .. " -> " .. tostring(by) .. "?", oldword, word)
  else
    log(rate, userate, i, tostring(word:sub(i, i)) .. " == " .. tostring(word:sub(i, i)) .. ".", oldword, word)
  end
  return word
end
quirk.soundAlike = function(word, i, rate)
  if not (SDICT[word:sub(i, i)]) then
    return word
  end
  local userate = chance.misc.d100()
  local oldword = word
  if userate <= rate then
    word = (oldword:sub(0, i - 1)) .. SDICT[oldword:sub(i, i)] .. (oldword:sub(i + 1))
    log(rate, userate, i, tostring(oldword:sub(i, i)) .. " -> " .. tostring(SDICT[word:sub(i, i)]), oldword, word)
  else
    log(rate, userate, i, tostring(oldword:sub(i, i)) .. " == " .. tostring(oldword:sub(i, i)), oldword, word)
  end
  return word
end
chance.core.set("misspell", {
  quirk.mistype,
  quirk.randomLetter,
  quirk.randomReplace,
  quirk.soundAlike,
  quirk.transpose
})
local sanitize
sanitize = function(pattern)
  if pattern then
    return pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
  end
end
local Quirk
do
  local _class_0
  local _base_0 = {
    multigsub = function(replace, avec)
      return message:gsub(self.replace, function()
        return chance.core.fromSet(self.setid)
      end)
    end,
    apply = function(self, message)
      local _exp_0 = self.kind
      if "prefix" == _exp_0 then
        return self.prefix .. message
      elseif "suffix" == _exp_0 then
        return message .. self.suffix
      elseif "replace" == _exp_0 or "regex" == _exp_0 then
        return message:gsub(self.replace, self.avec)
      elseif "multi" == _exp_0 then
        return self:multigsub(self.replace, self.avec)
      elseif "function" == _exp_0 then
        return self:using(message)
      elseif "mistype" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          for i = 1, #word do
            word = quirk.mistype(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      elseif "transpose" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          for i = 1, #word do
            word = quirk.transpose(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      elseif "randomletter" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          for i = 1, #word do
            word = quirk.randomLetter(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      elseif "randomreplace" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          for i = 1, #word do
            word = quirk.randomReplace(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      elseif "soundalike" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          for i = 1, #word do
            word = quirk.soundAlike(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      elseif "misspell" == _exp_0 then
        local words, whitespace = splitWs(message)
        for i, word in ipairs(words) do
          local func = chance.core.fromSet("misspell")
          for i = 1, #word do
            word = func(word, i, self.rate)
          end
          words[i] = word
        end
        return table.concat((zip(words, whitespace)), "")
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, kind, first, second)
      self.kind = kind
      local _exp_0 = kind
      if "prefix" == _exp_0 then
        self.prefix = first
      elseif "suffix" == _exp_0 then
        self.suffix = last
      elseif "replace" == _exp_0 then
        self.replace = sanitize(first)
        self.avec = second
      elseif "regex" == _exp_0 then
        self.replace = first
        self.avec = second
      elseif "multi" == _exp_0 then
        self.replace = first
        self.setid = os.time()
        return chance.core.set(self.setid, second)
      elseif "misspell" == _exp_0 or "mistype" == _exp_0 or "transpose" == _exp_0 or "randomletter" == _exp_0 or "randomreplace" == _exp_0 or "soundalike" == _exp_0 then
        self.rate = tonumber(first)
      elseif "function" == _exp_0 then
        self.using = first
      else
        return error("unknown quirk type " .. tostring(kind))
      end
    end,
    __base = _base_0,
    __name = "Quirk"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Quirk = _class_0
end
local User
do
  local _class_0
  local _base_0 = {
    connect = function(self, t)
      if t == nil then
        t = { }
      end
      t.host = t.host or "irc.mindfang.org"
      t.port = t.port or 6667
      self.logging = t.log or false
      self.user:connect(t.host, t.port)
      if t.centralize then
        self.centralized = true
        self.user:join("#pesterchum")
        return self:sendMood()
      end
    end,
    disconnect = function(self, message)
      if message == nil then
        message = tostring(self.handle) .. " quit."
      end
      for name, chan in pairs(self.channels) do
        chan:part()
      end
      return self.user:disconnect(message)
    end,
    hook = function(self, f)
      return self.user:hook("OnChat", f)
    end,
    send = function(self, target, message)
      for name, quirk in pairs(self.quirks) do
        message = quirk:apply(message)
      end
      self.channels[target]:send(message)
      if self.logging then
        return self:log({
          nick = self.handle
        }, target, message)
      end
    end,
    log = function(self, sender, channel, message)
      if not (self.logging) then
        return 
      end
      if channel == self.handle then
        if not (LOGGERS[sender.nick]) then
          LOGGERS[sender.nick] = Pesterlog(sender.nick, "log/" .. tostring(sender.nick) .. ".log")
        end
        if not (LOGFUNC[sender.nick]) then
          LOGFUNC[sender.nick] = LOGGERS[sender.nick]("none")
        end
        local lf = LOGFUNC[sender.nick]
        return lf(tostring(sender.nick) .. ": " .. tostring(message))
      else
        if not (LOGGERS[channel]) then
          LOGGERS[channel] = Pesterlog(channel, "log/" .. tostring(channel) .. ".log")
        end
        if not (LOGFUNC[channel]) then
          LOGFUNC[channel] = LOGGERS[channel]("none")
        end
        local lf = LOGFUNC[channel]
        return lf(tostring(sender.nick) .. ": " .. tostring(message))
      end
    end,
    quirk = function(self, name, quirk)
      self.quirks[name] = quirk
    end,
    setColor = function(self, color)
      self.color = color
      for name, chan in pairs(self.channels) do
        if not (chan.memo) then
          self.user:sendChat(chan.target, toColor(color))
        end
      end
    end,
    sendMood = function(self)
      if not (self.centralized) then
        self.user:join("#pesterchum")
      end
      return self.user:sendChat("#pesterchum", COMMANDS.MOOD(REVMOODS[self.mood]))
    end,
    setMood = function(self, mood)
      if not (REVMOODS[mood]) then
        error("invalid mood")
      end
      self.mood = mood
      return self:sendMood()
    end,
    setMoodFor = function(self, handle, mood, all)
      if all then
        self.moodl_[all][handle] = false
        self.moods[handle] = mood
        local DONE = true
        for nck, v in pairs(self.moodl_[all]) do
          if v then
            DONE = false
          end
        end
        if DONE then
          return self.user:unhook("OnChat", all)
        end
      else
        self.user:unhook("OnChat", handle)
        self.moods[handle] = mood
      end
    end,
    stopGetMood = function(self, handle)
      pcall(function()
        return self.user:unhook("OnChat", handle)
      end)
      for k, v in pairs(self.moodl_) do
        if k:match(handle) then
          v[handle] = nil
        end
      end
      return log("stopGetMood " .. tostring(handle))
    end,
    getMood = function(self, handle)
      if "string" == type(handle) then
        self.user:hook("OnChat", handle, function(sender, channel, message)
          if not (channel == "#pesterchum") then
            return 
          end
          log(sender.nick, message)
          if not (sender.nick:match(handle)) then
            return 
          end
          if not (message:match("^MOOD")) then
            return 
          end
          return self:setMoodFor(handle, message)
        end)
      elseif "table" == type(handle) then
        local all = table.concat(handle, "")
        do
          local _tbl_0 = { }
          for k, v in pairs(handle) do
            _tbl_0[v] = true
          end
          self.moodl_[all] = _tbl_0
        end
        self.user:hook("OnChat", all, function(sender, channel, message)
          if not (channel == "#pesterchum") then
            return 
          end
          log(sender.nick, message)
          if not (message:match("^MOOD")) then
            return 
          end
          for _index_0 = 1, #handle do
            local _continue_0 = false
            repeat
              local nick = handle[_index_0]
              if not (sender.nick:match(nick)) then
                _continue_0 = true
                break
              end
              self:setMoodFor(nick, message, all)
              _continue_0 = true
            until true
            if not _continue_0 then
              break
            end
          end
        end)
      end
      return self.user:sendChat("#pesterchum", COMMANDS.GETMOOD(handle))
    end,
    join = function(self, channel)
      self.channels[channel.target] = channel
      self.user:join(channel.target, channel.key)
      return channel:join(self)
    end,
    part = function(self, channel)
      self.channels[channel]:part()
      self.channels[channel] = nil
    end,
    block = function(self, handle, close)
      if close == nil then
        close = true
      end
      if self.channels[handle].memo then
        error("Cannot block a memo")
      end
      self.blocked[handle] = true
      if self.channels[handle] then
        self.channels[handle]:send(COMMANDS.BLOCK)
        if close then
          self.channels[handle]:send(COMMANDS.CEASE)
        end
        if close then
          return self.channels[handle]:part()
        end
      end
    end,
    unblock = function(self, handle, interact)
      if interact == nil then
        interact = true
      end
      if self.channels[handle] then
        if self.channels[handle].memo then
          error("Cannot block a memo")
        end
      else
        self:join(Pester(handle))
      end
      self.blocked[handle] = false
      self.channels[handle]:send(COMMANDS.UNBLOCK)
      if interact then
        return self.channels[handle]:send(COMMANDS.BEGIN)
      end
    end,
    friend = function(self, handle)
      self.friends[handle] = true
    end,
    unfriend = function(self, handle)
      self.friends[handle] = true
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
      self.handle = nick
      self.color = color
      self.user = IRC({
        nick = nick,
        username = username
      })
      self.channels = { }
      self.quirks = { }
      self.blocked = { }
      self.friends = { }
      self.mood = "chummy"
      self.moods = { }
      self.moodl_ = { }
      self.logging = false
      self.user:hook("OnChat", "polling", function(sender, channel, message)
        if not (channel == "#pesterchum") then
          return 
        end
        if not (sender.nick ~= self.handle) then
          return 
        end
        if (message:match("^GETMOOD")) and (message:match(self.handle)) then
          return self:sendMood()
        end
      end)
      return self.user:hook("OnChat", "logging", function(sender, channel, message)
        log(tostring(sender.nick) .. " -> " .. tostring(channel), message)
        return self:log(sender, channel, message)
      end)
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
return {
  Channel = Channel,
  Pester = Pester,
  Memo = Memo,
  Quirk = Quirk,
  quirk = quirk,
  User = User,
  MOODS = MOODS,
  sleep = sleep,
  inspect = inspect
}
