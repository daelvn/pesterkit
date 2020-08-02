irc = require "irc"
sleep = require"socket".sleep

systemBreaker = irc.new username: "pcc31", nick: "systemBreaker"

systemBreaker\connect "irc.mindfang.org"
--systemBreaker\sendChat "#testmemo", "PESTERCHUM:BEGIN"
systemBreaker\sendChat "#testmemo", "Hello. I am systemBreaker. On a memo. Twice."