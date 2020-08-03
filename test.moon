pesterkit = require "pesterkit"

import User, Pester, Memo, sleep, inspect from pesterkit
import Quirk, quirk                       from pesterkit

systemBreaker = User "deathGrips"
systemBreaker\connect centralize: false
systemBreaker\join Memo "testmemo"

systemBreaker\hook (sender, channel, message) ->
  print channel, sender.nick, message
systemBreaker\setMood "offline"
systemBreaker\send "#testmemo", "Hello. This is systemBreaker."

while true
  systemBreaker.user\think!
  sleep 0.5