local irc = require("irc")
local sleep = require("socket").sleep
local systemBreaker = irc.new({
  username = "pcc31",
  nick = "systemBreaker"
})
systemBreaker:connect("irc.mindfang.org")
return systemBreaker:sendChat("#testmemo", "Hello. I am systemBreaker. On a memo. Twice.")
