-- pesterkit
-- By daelvn, Pancakeddd
{new: IRC}       = require "irc"
{load: parseXML} = require "xml"
{:sleep}         = require "socket"
inspect          = require "inspect"

-- functions
-- gets a color object and turns it into a color command
toColor = (t) -> "COLOR >#{t.r},#{t.g},#{t.b}"
-- colorize a message
colorize = (m, t) -> "<c=#{t.r},#{t.g},#{t.b}>#{m}</c>"
-- formats a command
toCommand = (s) -> "PESTERCHUM:"..s

COMMANDS =
  -- begin (pester)
  BEGIN: toCommand "BEGIN"
  -- cease (pester)
  CEASE: toCommand "CEASE"
  -- time (memo)
  -- h is hours, m is minutes
  -- 0, 0 is present
  -- negative hour accepted
  TIME: (h, m) ->
    return toCommand ("TIME>i")                      if h == 0 and m == 0
    return toCommand ("TIME>F%02d:%02d")\format h, m if h > 0  or  m > 0
    return toCommand ("TIME>P%02d:%02d")\format h, m if h < 0  or  m < 0

-- Base channel
-- ucl is for User CLass
class Channel
  -- enter
  join: (ucl) =>
    @ucl = ucl
    if @memo
      @ucl.user\sendChat @target, COMMANDS.TIME @time.hour, @time.minute
    else
      @ucl.user\sendChat @target, COMMANDS.BEGIN
  -- leave
  part: =>
    @ucl\send @target, COMMANDS.CEASE
  -- send a message
  send: (message) =>
    if @memo
      @ucl.user\sendChat @target, colorize message, @ucl.color
    else
      @ucl.user\sendChat @target, message


-- Pester
class Pester extends Channel
  memo: false
  new: (handle) =>
    @target = handle

-- Memo
class Memo extends Channel
  memo: true
  new: (memo, h=0, m=0, key) =>
    @target = "#"..memo
    @time   = {hour: h, minute: m}
    @key    = key

-- User class
class User
  -- new user
  new: (nick, color={r:0,g:0,b:0}, username="pcc31") =>
    @handle   = nick
    @color    = color
    @user     = IRC :nick, :username
    @channels = {}

  -- connect
  connect: (host="irc.mindfang.org", port) =>
    @user\connect host, port
  -- disconnect
  disconnect: (message="#{@handle} quit.") =>
    for name, chan in pairs @channels
      chan\part!
    @user\disconnect message

  -- send as chat
  send: (target, message) => @channels[target]\send message

  -- set the color
  setColor: (color) =>
    @color = color
    for name, chan in pairs @channels
      @user\sendChat chan.target, toColor color unless chan.memo

  -- join a memo or pester someone
  join: (channel) =>
    @channels[channel.target] = channel
    @user\join channel.target, channel.key
    channel\join @ -- so that the channel can access our functions

{
  :Channel, :Pester, :Memo
  :User
  :sleep, :inspect
}