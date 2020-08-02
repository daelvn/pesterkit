import User, Pester, Memo from require "pesterkit"

systemBreaker = User "webchumClient", {r: 255, g: 0, b: 0}
testUser = User "heyMan", {r:0, g:0, b:255}

systemBreaker.user\hook "OnChat", (sender, channel, message) ->
  --print sender.nick, channel, message
  if message\match "^P"
    print channel, sender.nick, message
  else
    t = fromMemoMessage message
    print channel, sender.nick, "#{t.r},#{t.g},#{t.b}", flattenMemoMessage t

systemBreaker\connect!
testUser\connect!
--systemBreaker\pester "angelicEternity"
--systemBreaker\memo testmemo

--systemBreaker\set_color testmemo, {r: c, g: c, b: c}
--systemBreaker\message testmemo, "test"

pester_handler = Memo "#testmemo"

users = {}

for i = 1, 10
  u = User "userDude#{i}", {r:math.random(0, 200), g:math.random(0, 200), b:math.random(0, 200)}
  u\connect!
  pester_handler\connect u
  users[#users+1] = u

for user in *users
  sleep 0.5
  user\message pester_handler, "My name is #{user.handle} and my index is #{i}"

for user in *users
  pester_handler\disconnect user