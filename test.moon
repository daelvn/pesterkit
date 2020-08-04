pesterkit = require "pesterkit"

import User, Pester, Memo, sleep, inspect from pesterkit
import Quirk, quirk                       from pesterkit
import MOODS                              from pesterkit

deathGrips = User "deathGrips"
deathGrips\connect centralize: true, log: true

--deathGrips\hook (sender, channel, message) ->
--  print channel, sender.nick, message
--deathGrips\setMood "offline"
--deathGrips\send "semperParatus", "Hello. This is deathGrips."

--deathGrips\getMood "totalRando"
-- deathGrips.moods.*

deathGrips\setMood "devious"
deathGrips\join Pester "angelicEternity"
deathGrips\join Pester "oghuzOrbit"
deathGrips\join Memo   "testmemo"
deathGrips\send "angelicEternity", "YUH. YUH. YUH."
deathGrips\send "oghuzOrbit",      "YUH. YUH. YUH."
deathGrips\send "#testmemo",       "YUH. YUH. YUH."
-- deathGrips\hook (sender, channel, message) ->
--   print channel, sender.nick, message

while true
  deathGrips.user\think!
  sleep 0.5