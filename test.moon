import User, Pester, Memo, sleep, inspect from require "pesterkit"

systemBreaker = User "systemBreaker"
systemBreaker.user\hook "OnChat", (sender, channel, message) ->
  print channel, sender.nick, message

systemBreaker\connect!
systemBreaker\join Memo "testmemo"
systemBreaker\join Pester "angelicEternity"
systemBreaker\setColor {r: 0, g: 0, b: 0}
systemBreaker\send "#testmemo",       "Hi. I am systemBreaker."
systemBreaker\send "angelicEternity", "Hi. I am systemBreaker."
systemBreaker\setColor {r: 255, g: 0, b: 255}
systemBreaker\send "#testmemo",       "Hi. I am systemBreaker. Again"
systemBreaker\send "angelicEternity", "Hi. I am systemBreaker. Again"

while true
  systemBreaker.user\think!
  sleep 0.5