-- pesterkit
-- By daelvn, Pancakeddd
{new: IRC}       = require "irc"
{load: parseXML} = require "xml"
{:sleep}         = require "socket"
{:logger}        = require "debugkit.log"
chance           = require "chance.chance"
inspect          = require "inspect"

-- logging
lgr       = logger.minimal!
lgr.level = "none" -- change to all for no debug info, none for all (i know, fuck old kankri)
log_      = lgr "none"
compose   = (...) -> return table.concat {...}, "\t"
log       = (...) -> log_ compose ...

-- random things
chance.core.seed os.time!

-- irc fix
_G.irc.handlers["353"] = (o, prefix, me, chanType, channel, names) ->
  if o.track_users
    o.channels[channel] or= {users: {}, type: chanType}
    users = o.channels[channel].users
    for nick in names\gmatch "(%S+)"
      access, name = irc.parseNick nick
      users[name] = :access
    o\invoke "NameList", channel, users
_G.irc.handlers["366"] = (o, prefix, me, channel, msg) -> o

-- functions
-- gets a color object and turns it into a color command
toColor = (t) -> "COLOR >#{t.r},#{t.g},#{t.b}"
-- colorize a message
colorize = (m, t) -> "<c=#{t.r},#{t.g},#{t.b}>#{m}</c>"
-- formats a command
toCommand = (s) -> "PESTERCHUM:"..s
-- separates into words and whitespace
splitWs = (s) ->
  whitespace = {""}
  words = {""}
  for i = 1, #s
    c = string.sub(s, i, i)
    if c\match "%s"
      whitespace[#whitespace] = do
        if whitespace[#whitespace] != nil
          whitespace[#whitespace] .. c
        else
          ""
      if words[#words] != ""
        words[#words+1] = ""
    else
      --print c
      if whitespace[#whitespace] != ""
        whitespace[#whitespace+1] = ""
      words[#words] ..= c
  whitespace[#whitespace] = nil if whitespace[#whitespace] == ""
  return words, whitespace
-- zips together two tables
zip = (t1, t2) ->
  tx = {}
  s = true
  i = 1
  while i <= math.max(#t1, #t2)
    if s
      tx[#tx+1] = t1[i]
    else
      tx[#tx+1] = t2[i]
      i += 1
    s = not s
  tx

-- constants
-- moods
MOODS = {
  "chummy",   "rancorous", "offline",   "pleasant",   "distraught"
  "pranky",   "smooth",    "ecstatic",  "relaxed",    "discontent"
  "devious",  "sleek",     "detestful", "mirthful",   "manipulative"
  "vigorous", "perky",     "acceptant", "protective", "mystified"
  "amazed",   "insolent",  "bemused"
}
REVMOODS = {v, k for k, v in pairs MOODS}
moodn = (n) -> MOODS[n+1]
-- commands
COMMANDS =
  -- begin (pester)
  BEGIN: toCommand "BEGIN"
  -- cease (pester)
  CEASE: toCommand "CEASE"
  -- block (pester)
  BLOCK: toCommand "BLOCK"
  -- unblock (pester)
  UNBLOCK: toCommand "UNBLOCK"
  -- mood (meta)
  MOOD: (n) -> "MOOD >#{n}"
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
    @ucl.user\sendChat @target, COMMANDS.CEASE
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

-- Quirking constants
-- As defined in the official Pesterchum client, for similarity.
KBLOC = {[("1234567890-=")\sub i, i for i=1,12]
         [("qwertyuiop[]")\sub i, i for i=1,12]
         [("asdfghjkl:;'")\sub i, i for i=1,12]
         [("zxcvbnm,.>/?")\sub i, i for i=1,12]}
KDICT = {}
for i, l in pairs KBLOC
  for j, k in pairs l
    KDICT[k] = {i, j}
SDICT = {"a": "e",   "b": "d",  "c": "k",  "d": "g",   "e": "eh",
         "f": "ph",  "g": "j",  "h": "h",  "i": "ai",  "j": "ge",
         "k": "c",   "l": "ll", "m": "n",  "n": "m",   "o": "oa",
         "p": "b",   "q": "kw", "r": "ar", "s": "ss",  "t": "d",
         "u": "you", "v": "w",  "w": "wn", "x": "cks", "y": "uy", "z": "s"}
chance.core.set "moreless", {-1, 0, 1}
chance.core.set "more",     {0, 1}
chance.core.set "less",     {-1, 0}
chance.core.set "letters",  [("abcdefghijklmnopqrstuvwxyz")\sub i, i for i=1,26]

-- Quirking functions
quirk = {}
-- simulates pressing a key that was near the one meant to be pressed
quirk.mistype = (word, i, rate) ->
  char = word\sub i, i
  return word unless KDICT[char]
  charpos = KDICT[char]
  newpos  = {charpos[1], charpos[2]}
  --
  userate = chance.misc.d100!
  if userate <= rate
    newpos[1] = switch charpos[1]
      when 1      then charpos[1] + chance.core.fromSet "more"
      when #KBLOC then charpos[1] + chance.core.fromSet "less"
      else             charpos[1] + chance.core.fromSet "moreless"
    newpos[2] = switch charpos[2]
      when 1         then charpos[2] + chance.core.fromSet "more"
      when #KBLOC[1] then charpos[2] + chance.core.fromSet "less"
      else                charpos[2] + chance.core.fromSet "moreless"
  newword = (word\sub 1, i-1) .. KBLOC[newpos[1]][newpos[2]] .. (word\sub i+1)
  log rate, userate, i, (inspect charpos), KBLOC[charpos[1]][charpos[2]], word, (inspect newpos), KBLOC[newpos[1]][newpos[2]], newword
  return newword
-- simulates pressing the keys in a different order
quirk.transpose = (word, i, rate) ->
  userate = chance.misc.d100!
  oldword = word
  if userate <= rate
    j                  = switch i
      when 1 then     i + chance.core.fromSet "more"
      when #word then i + chance.core.fromSet "less"
      else            i + chance.core.fromSet "moreless"
    chars              = [c for c in oldword\gmatch "."]
    chars[i], chars[j] = chars[j], chars[i]
    word               = table.concat chars, ""
  log rate, userate, i, oldword, word
  return word
-- simulates adding a random letter
quirk.randomLetter = (word, i, rate) ->
  userate = chance.misc.d100!
  oldword = word
  if userate <= rate
    by   = chance.core.fromSet "letters"
    word = (oldword\sub 0, i+1) .. by .. (oldword\sub i+1)
    log rate, userate, i, "#{word\sub i, i} ++ #{by}?", oldword, word
  else
    log rate, userate, i, "#{word\sub i, i} == #{word\sub i, i}.", oldword, word
  return word
-- simulates replacing a random letter
quirk.randomReplace = (word, i, rate) ->
  userate = chance.misc.d100!
  oldword = word
  if userate <= rate
    by   = chance.core.fromSet "letters"
    word = (oldword\sub 0, i-1) .. by .. (oldword\sub i+1)
    log rate, userate, i, "#{oldword\sub i, i} -> #{by}?", oldword, word
  else
    log rate, userate, i, "#{word\sub i, i} == #{word\sub i, i}.", oldword, word
  return word
-- simulates not knowing how to spell a word
quirk.soundAlike = (word, i, rate) ->
  return word unless SDICT[word\sub i, i]
  userate = chance.misc.d100!
  oldword = word
  if userate <= rate
    word = (oldword\sub 0, i-1) .. SDICT[oldword\sub i, i] .. (oldword\sub i+1)
    log rate, userate, i, "#{oldword\sub i, i} -> #{SDICT[word\sub i, i]}", oldword, word
  else
    log rate, userate, i, "#{oldword\sub i, i} == #{oldword\sub i, i}", oldword, word
  return word
-- misspellings
chance.core.set "misspell", {quirk.mistype, quirk.randomLetter, quirk.randomReplace, quirk.soundAlike, quirk.transpose}

-- Quirking support
sanitize  = (pattern) -> pattern\gsub "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0" if pattern
class Quirk
  -- new quirk
  -- kinds: prefix, suffix, replace, regex, multi, mistype, transpose, randomletter, randomreplace, soundalike, misspell, function
  new: (kind, first, second) =>
    @kind = kind
    switch kind
      when "prefix"
        @prefix = first
      when "suffix"
        @suffix = last
      when "replace"
        @replace = sanitize first
        @avec    = second
      when "regex"
        @replace = first
        @avec    = second
      when "multi"
        @replace = first
        @setid   = os.time!
        chance.core.set @setid, second
      when "misspell", "mistype", "transpose", "randomletter", "randomreplace", "soundalike"
        @rate = tonumber first
      when "function"
        @using = first
      else
        error "unknown quirk type #{kind}"
  -- multigsub
  multigsub: (replace, avec) -> message\gsub @replace, -> chance.core.fromSet @setid
  -- apply quirk
  apply: (message) =>
    switch @kind
      when "prefix"           then return @prefix .. message
      when "suffix"           then return message .. @suffix
      when "replace", "regex" then return message\gsub @replace, @avec
      when "multi"            then return @multigsub @replace, @avec
      when "function"         then return @using message
      when "mistype"
        words, whitespace = splitWs message
        for i, word in ipairs words
          for i=1, #word
            word = quirk.mistype word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""
      when "transpose"
        words, whitespace = splitWs message
        for i, word in ipairs words
          for i=1, #word
            word = quirk.transpose word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""
      when "randomletter"
        words, whitespace = splitWs message
        for i, word in ipairs words
          for i=1, #word
            word = quirk.randomLetter word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""
      when "randomreplace"
        words, whitespace = splitWs message
        for i, word in ipairs words
          for i=1, #word
            word = quirk.randomReplace word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""
      when "soundalike"
        words, whitespace = splitWs message
        for i, word in ipairs words
          for i=1, #word
            word = quirk.soundAlike word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""
      when "misspell"
        words, whitespace = splitWs message
        for i, word in ipairs words
          func = chance.core.fromSet "misspell"
          for i=1, #word
            word = func word, i, @rate
          words[i] = word
        return table.concat (zip words, whitespace), ""      

-- User class
class User
  -- TODO moods
  -- TODO getmoods
  -- TODO logs
  -- new user
  new: (nick, color={r:0,g:0,b:0}, username="pcc31") =>
    @handle   = nick
    @color    = color
    @user     = IRC :nick, :username
    @channels = {}
    @quirks   = {}
    @blocked  = {}
    @friends  = {}

  -- connect
  connect: (t={}) =>
    t.host or= "irc.mindfang.org"
    t.port or= 6667
    @user\connect t.host, t.port
    @user\join "#pesterchum" if t.centralize
  -- disconnect
  disconnect: (message="#{@handle} quit.") =>
    for name, chan in pairs @channels
      chan\part!
    @user\disconnect message
  
  -- hook a function to the chat
  hook: (f) => @user\hook "OnChat", f

  -- send as chat
  send: (target, message) =>
    for name, quirk in pairs @quirks
      message = quirk\apply message
    @channels[target]\send message

  -- add a quirk
  quirk: (name, quirk) => @quirks[name] = quirk

  -- set the color
  setColor: (color) =>
    @color = color
    for name, chan in pairs @channels
      --@user\join chan.target
      @user\sendChat chan.target, toColor color unless chan.memo

  -- set the mood
  setMood: (mood) =>
    error "invalid mood" unless REVMOODS[mood]
    @mood = moods
    @join Memo "pesterchum" unless @channels["#pesterchum"]
    @user\sendChat "#pesterchum", COMMANDS.MOOD REVMOODS[mood]

  -- join a memo or pester someone
  join: (channel) =>
    @channels[channel.target] = channel
    @user\join channel.target, channel.key
    channel\join @ -- so that the channel can access our functions
  -- leave a channel
  part: (channel) =>
    @channels[channel]\part!
    @channels[channel] = nil

  -- blocks someone
  block: (handle, close=true) =>
    error "Cannot block a memo" if @channels[handle].memo
    @blocked[handle] = true
    if @channels[handle]
      @channels[handle]\send COMMANDS.BLOCK
      @channels[handle]\send COMMANDS.CEASE if close
      @channels[handle]\part!               if close
  -- unblocks someone
  unblock: (handle, interact=true) =>
    if @channels[handle]
      error "Cannot block a memo" if @channels[handle].memo
    else
      @join Pester handle
    @blocked[handle] = false
    @channels[handle]\send COMMANDS.UNBLOCK
    @channels[handle]\send COMMANDS.BEGIN if interact

  -- befriend someone
  friend: (handle) => @friends[handle] = true
  -- unfriend someone
  unfriend: (handle) => @friends[handle] = true
    

{
  :Channel, :Pester, :Memo
  :Quirk, :quirk
  :User
  :MOODS
  :sleep, :inspect
}