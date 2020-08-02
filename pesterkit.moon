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

COMMANDS = {
  BEGIN: "BEGIN"
  CLOSE: "CEASE"
  BLOCK: "BLOCK"
  UNBLOCK: "UNBLOCK"
}

PesterCommand = (command) ->
  "PESTERCHUM:#{command}"

class HandleSpace
  new: (@name) =>

  join: (u) => 
    u.user\join @name

  disconnect: (u) =>
    u\sendCommand @, COMMANDS.Close
    u.user\disconnect ""

  isMemo: => false

  connect: =>

class Memo extends HandleSpace
  isMemo: => true

  disconnect: (u) =>
    u.user\disconnect ""

  connect: (u) =>
    @join u
    u\setColor @, u.color

class Pester extends HandleSpace
  connect: (u) =>
    @join u
    u\sendCommand @, COMMANDS.BEGIN
    u\setColor @, u.color

class User
  new: (nick, color={r:0,g:0,b:0}, username="pcc31") =>
    expect 1, nick,     {"string"}
    expect 2, color,    {"table"}
    expect 3, username, {"string"}
    @handle = nick
    @color  = color
    @user   = irc.new :nick, :username

  -- formats and sends pesterchum command
  sendCommand: (handle, cmd) =>
    @user\sendChat handle.name, PesterCommand cmd

  -- connects
  connect: (host="irc.mindfang.org", port) =>
    expect 1, host, {"string"}
    expect 2, port, {"number", "nil"}
    @user\connect host, port

  -- disconnects
  disconnect: (handle) =>
    handle\disconnect @

  -- send message to memo/1on1
  message: (handle, text) =>
    handle_name = handle.name
    if handle\isMemo!
      @user\sendChat handle_name, "<c=#{@color.r},#{@color.g},#{@color.b}>#{text}"
    else
      @user\sendChat handle_name, text

  -- dynamically sets color
  setColor: (handle, @color) =>
    unless handle\isMemo!
      @user\sendChat handle.name, toColorCommand @color

{
  :User, :Pester, :Memo, :HandleSpace
}