-- pesterkit
-- By daelvn
irc      = require"irc"
xml      = require"xml"
sleep    = require"socket".sleep
inspect  = require"inspect"

parseXml = (str) -> xml.load str

flatten = (t) ->
  total  = ""
  helper = (tt) ->
    for k, v in pairs tt
      if "table" == type v
        total ..= helper v
      else
        total ..= v
  helper t
  return total

flattenMemoMessage = (msg) ->
  for k, v in pairs msg
    if "string" == type k
      msg[k] = nil
    elseif "table" == type v
      msg[k] = flattenMemoMessage v
  return flatten msg

local typeof, expect, typeset
do
  typeof = (v) ->
    -- get metatable
    local meta
    if "table" == type v
      if type_mt = getmetatable v
        meta = type_mt.__type
    -- check how to obtain type
    -- __type
    if meta
      switch type meta
        when "function" then return meta v
        when "string"   then return meta
    -- io.type()
    elseif io.type v
      return "io"
    -- type()
    else
      return type v

  expect = (n, v, ts) ->
    for ty in *ts
      return true if ty == typeof v
    error "bad argument ##{n} (expected #{table.concat ts, ' or '}, got #{type v})", 2

  typeset = (v, ty) ->
    expect 1, v, {"table"}
    if mt = getmetatable v
      mt.__type = ty
    else
      setmetatable v, __type: ty
    return v

--

toColorCommand  = (clr)     -> "COLOR >#{clr.r},#{clr.g},#{clr.b}"
fromMemoMessage = (message) -> parseXml message\gsub "c=(%d+),(%d+),(%d+)", 'c r="%1" g="%2" b="%3"'

class User
  new: (nick, color={r:0,g:0,b:0}, username="pcc31") =>
    expect 1, nick,     {"string"}
    expect 2, color,    {"table"}
    expect 3, username, {"string"}
    @handle = nick
    @color  = color
    @user   = irc.new :nick, :username
  connect: (host="irc.mindfang.org", port) =>
    expect 1, host, {"string"}
    expect 2, port, {"number", "nil"}
    @user\connect host, port
  disconnect: (message="#{@handle} (webchum) disconnected.") =>
    expect 1, message, {"string"}
    @user\disconnect message
  
  -- pestering
  pester: (handle) =>
    expect 1, handle, {"string"}
    error "Target cannot be a memo!" if handle\match "^#"
    @user\join     handle
    @user\sendChat handle, "PESTERCHUM:BEGIN"
    @user\sendChat handle, toColorCommand @color
    @user\sendChat handle, "Hello. I am systemBreaker."

  -- memos
  memo: (name) =>
    expect 1, name, {"string"}
    memo = "#"..name
    @user\join memo
    @user\sendChat memo, "Hello. I am systemBreaker."

systemBreaker = User "systemBreaker"

systemBreaker.user\hook "OnChat", (sender, channel, message) ->
  --print sender.nick, channel, message
  if message\match "^P"
    print channel, sender.nick, message
  else
    t = fromMemoMessage message
    print channel, sender.nick, "#{t.r},#{t.g},#{t.b}", flattenMemoMessage t

systemBreaker\connect!
--systemBreaker\pester "angelicEternity"
systemBreaker\memo "testmemo"
while true do
  sleep 0.5
  systemBreaker.user\think!