-- Offline F10 handlers: preserve selection, remove stale IDs, target and command payload.
local savedGetPlayer, savedCommand = _G.getPlayer, BAO.NPCWorldClient.CommandNPC
local savedList = BAO.NPCWorldClient.GetNPCList
local ids={{id='npc_a'},{id='npc_b'}}
BAO.NPCWorldClient.GetNPCList=function() return ids end
local selector={selected=1,options={}}
function selector:clear() self.options={} end
function selector:addOption(value) self.options[#self.options+1]=value end
local w=setmetatable({npcSelector=selector}, {__index=BAOTestWindow})
w:refreshNPCList()
assert(#w.npcIds==2)
selector.selected=2
w:refreshNPCList()
assert(w.npcIds[selector.selected]=='npc_b')
ids={{id='npc_a'}}
w:refreshNPCList()
assert(selector.selected==1 and #w.npcIds==1)
_G.getPlayer=function() return {getX=function() return 10.9 end,getY=function() return 20.1 end,getZ=function() return 0 end} end
local sent
BAO.NPCWorldClient.CommandNPC=function(_,command,args) sent={command=command,args=args}; return true,'request_sent' end
w:onNPCPatrol()
assert(not sent and w.npcStatusText=='NPC: set TARGET: MY TILE first')
w:onNPCTarget()
w:onNPCPatrol()
assert(sent.command=='npc_patrol' and sent.args.id=='npc_a' and sent.args.x==10 and sent.args.y==20)
w:onNPCStop()
assert(sent.command=='npc_stop')
local previousWindow=BAOTestWindow.instance
BAOTestWindow.instance=w
BAO.DebugUI.ReceiveNPCStatus({npcId='npc_a',detail={state='FAILED',reason='navigation_stuck'}})
assert(w.npcStatusText:find('navigation_stuck',1,true))
ids={}
BAO.DebugUI.ReceiveNPCStatus({snapshot=true})
assert(#w.npcIds==0)
BAOTestWindow.instance=previousWindow
_G.getPlayer, BAO.NPCWorldClient.CommandNPC, BAO.NPCWorldClient.GetNPCList=savedGetPlayer,savedCommand,savedList
