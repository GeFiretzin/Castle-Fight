function GameMode:OnGameRulesStateChange()
  local nNewState = GameRules:State_Get()
  if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
    print( "[PRE_GAME] in Progress" )
  elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    GameMode:OnGameInProgress()
  end
end

function GameMode:OnGameInProgress()
  GameMode:CountdownToNextRound(TIME_BEFORE_FIRST_ROUND)
end

function GameMode:OnNPCSpawned(keys)
  local npc = EntIndexToHScript(keys.entindex)

  -- Ignore specific units
  local unitName = npc:GetUnitName()
  if unitName == "npc_dota_hero_treant" then return end
  if unitName == "npc_dota_thinker" then return end
  if unitName == "npc_dota_units_base" then return end
  if unitName == "" then return end

  -- Level all of the unit's abilities to max
  if npc:IsHero() then
    npc:SetAbilityPoints(0)
  end

  for i=0,16 do
    local ability = npc:GetAbilityByIndex(i)
    if ability then ability:SetLevel(ability:GetMaxLevel()) end
  end

  if npc:IsRealHero() and npc.bFirstSpawned == nil then
      npc.bFirstSpawned = true
      GameMode:OnHeroInGame(npc)
  end

  Units:Init(npc)
end

function GameMode:OnHeroInGame(hero)
  print("Hero Spawned")

  -- Add bots to the playerids list
  local playerID = hero:GetPlayerOwnerID()
  if not TableContainsValue(GameRules.playerIDs, playerID) then
    print("Didn't find playerID, inserting")
    table.insert(GameRules.playerIDs, playerID)
  end

  -- Get rid of the tp scroll
  Timers:CreateTimer(.03, function()
    for i=0,15 do
      local item = hero:GetItemInSlot(i)
      if item ~= nil and item:GetAbilityName() == "item_tpscroll" then
        item:RemoveSelf()
      end
    end

    hero:AddItem(CreateItem("item_build_gjallarhorn", hero, hero))
    hero:AddItem(CreateItem("item_build_artillery", hero, hero))
    hero:AddItem(CreateItem("item_build_watch_tower", hero, hero))
    hero:AddItem(CreateItem("item_build_heroic_shrine", hero, hero))
    hero:AddItem(CreateItem("item_build_treasure_box", hero, hero))

  end)  
end

function GameMode:OnEntityKilled(keys)
  local killed = EntIndexToHScript(keys.entindex_killed)
  local killer = nil

  if keys.entindex_attacker ~= nil then
    killer = EntIndexToHScript( keys.entindex_attacker )
  end

  if killed:GetUnitName() == "castle" then
    if GameRules.roundInProgress then
      GameMode:EndRound(killed:GetTeam())
    end
    return
  end

  local bounty = killed:GetGoldBounty()
  if killer and bounty and not killer:IsRealHero() and not DeepTableCompare(killer == killed, true) then
    -- when you use forcekill, it's the same as the unit killing itself
    local player = killer:GetPlayerOwner()
    local killerPlayerID = killer:GetPlayerOwnerID()
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, killed, bounty, player)
    PlayerResource:ModifyGold(killerPlayerID, bounty, false, DOTA_ModifyGold_CreepKill)
  end

  if IsCustomBuilding(killed) and not killed:IsUnderConstruction() then
    local killedPlayerID = killed:GetPlayerOwnerID()

    -- Lose the income value that this building was generating
    local lostIncome = killed.incomeValue
    GameRules.income[killedPlayerID] = GameRules.income[killedPlayerID] - lostIncome

    if killed:GetUnitName() == "item_build_treasure_box" then
      GameRules.numBoxes[killedPlayerID] = GameRules.numBoxes[killedPlayerID] - 1
    end
  end
end

function GameMode:OnConnectFull(keys)
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local ply = EntIndexToHScript(entIndex)

  -- The Player ID of the joining player
  local playerID = ply:GetPlayerID()

  table.insert(GameRules.playerIDs, playerID)
end

function GameMode:OnPlayerReconnect(keys)
  print("OnPlayerReconnect")
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local playerHero = player:GetAssignedHero()
  
  -- Do necessary UI rebuilding here
end

function GameMode:OnConstructionCompleted(building, ability, isUpgrade, previousIncomeValue)
  local buildingType = building:GetBuildingType()
  local hero = building:GetOwner()
  local playerID = building:GetPlayerOwnerID()
  local goldCost = ability:GetGoldCost(ability:GetLevel())

  -- If this building produced units, give the player lumber
  if buildingType == "UnitTrainer" or buildingType == "SiegeTrainer" then
    SendOverheadEventMessage(hero, OVERHEAD_ALERT_HEAL, building, goldCost, nil)
    hero:GiveLumber(goldCost)
  end

  -- If the unit is a treasure box, increase the income for the team
  if building:GetUnitName() == "treasure_box" then
    GameRules.numBoxes[playerID] = GameRules.numBoxes[playerID] + 1
  end

  -- Give the player a reward for being the nth player to build a building
  -- reward is 20, 15, 10, 5
  if TableCount(GameRules.buildingsBuilt[playerID]) == 0 then
    local numBuilt = GameRules.numPlayersBuilt
    local reward = 20 - numBuilt * 5

    if reward > 0 then
      local rewardMessage = "You received <font color='FFBF00'>" .. reward .. "</font> gold for being the <font color='#00C400'>" .. 
        numBuilt + 1 .. getNumberSuffix(numBuilt + 1) .. "</font> player to build a building."
      Notifications:Top(playerID, {text=rewardMessage, duration=5.0})
    end

    GameRules.numPlayersBuilt = numBuilt + 1
  end
  table.insert(GameRules.buildingsBuilt[playerID], building)

  local increase = GameMode:GetIncomeIncreaseForBuilding(building, goldCost)

  -- Track how much income this building is generating
  if isUpgrade then
    building.incomeValue = previousIncomeValue + increase
  else
    building.incomeValue = increase
  end

  GameRules.income[playerID] = GameRules.income[playerID] + building.incomeValue
end