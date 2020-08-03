pesterkit = require "pesterkit"

import User, Pester, Memo, sleep, inspect from pesterkit
import Quirk, quirk                       from pesterkit

systemBreaker = User "systemBreaker"
systemBreaker\connect centralize: false

systemBreaker.user\hook "OnChat", (sender, channel, message) ->
  print channel, sender.nick, message

systemBreaker\join Memo "testmemo"
systemBreaker\quirk Quirk "misspell", 10
systemBreaker\send "#testmemo", "Hello. This is systemBreaker."

while true
  systemBreaker.user\think!
  sleep 0.5