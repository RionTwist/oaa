-- Taken from bb template
if FinalDuel == nil then
  DebugPrint ( 'Creating new FinalDuel object.' )
  FinalDuel = class({})
  Debug.EnabledModules['duels:final-duel'] = true
end

-- Duels.onStart = DuelStartEvent.listen
-- Duels.onPreparing = DuelPreparingEvent.listen
-- Duels.onEnd = DuelEndEvent.listen

local limitIncreaseAmounts = {
  short = 7,
  normal = 10,
  long = 13,
}

function FinalDuel:Init ()
  Duels.onEnd(partial(FinalDuel.EndDuelHandler, FinalDuel))
  Duels.onPreparing(partial(FinalDuel.PreparingDuelHandler, FinalDuel))
  Duels.onStart(partial(FinalDuel.StartDuelHandler, FinalDuel))
  PointsManager.onWinner(partial(FinalDuel.Trigger, FinalDuel))
end

function FinalDuel:Trigger (team)
  self.needsFinalDuel = true

  if Duels.currentDuel then
    -- let end of duel handler sort it out
    return
  end

  self.isCurrentlyFinalDuel = true
  Duels:StartDuel(5)
end

function FinalDuel:PreparingDuelHandler (keys)
  DebugPrint('self: ' .. tostring(self))
  DebugPrint('keys: ' .. tostring(keys))
  if self.needsFinalDuel then
  end
end

function FinalDuel:StartDuelHandler (keys)
  if self.needsFinalDuel then
    local limit = PointsManager:GetLimit()
    local goodPoints = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS)
    local badPoints = PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
    local goodCanWin = goodPoints >= limit
    local badCanWin = badPoints >= limit
    local extraMessage = ""
    if goodCanWin then
      if badCanWin then
        extraMessage = "The winner of this duel wins the game"
      else
        extraMessage = "The game will end if Radiant wins"
      end
    else
      extraMessage = "The game will end if Radiant wins"
    end

    Notifications:TopToAll({text="Final duel! " .. extraMessage, duration=4.0})
    self.needsFinalDuel = false
  end
end

function FinalDuel:EndDuelHandler (currentDuel)
  if not self.isCurrentlyFinalDuel then
    if self.needsFinalDuel then
      -- a duel just ended and we need to trigger the final duel
      Timers:CreateTimer(10, function ()
        self:Trigger()
      end)
    end
    return
  end
  self.isCurrentlyFinalDuel = false

  -- currentDuel.duelEnd1
  -- currentDuel.duelEnd2
  local loser = currentDuel.duelEnd1
  if loser == true then
    loser = currentDuel.duelEnd2
  end

  local limit = PointsManager:GetLimit()
  local goodPoints = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS)
  local badPoints = PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
  local goodCanWin = goodPoints >= limit
  local badCanWin = badPoints >= limit

  if loser == "bad" and goodCanWin then
    PointsManager:SetWinner(DOTA_TEAM_GOODGUYS)
    return
  end
  if loser == "good" and badCanWin then
    PointsManager:SetWinner(DOTA_TEAM_BADGUYS)
    return
  end
  local addToLimit = limitIncreaseAmounts[PointsManager:GetGameLength()]
  Notifications:TopToAll({text="The objective has been extended by " .. tostring(addToLimit), duration=5.0})

  PointsManager:SetLimit(PointsManager:GetLimit() + addToLimit)
end
