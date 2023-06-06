# AwayScored
Parameters:
* AwayScore
* OldAwayScore
* ScoreReason

Example:
```lua
FFAPI.Events.AwayScored.Event:Connect(function(awayScore, oldAwayScore, scoreReason)
  -- Logic Here
end)
```

---

# HomeScored
Parameters:
* HomeScore
* OldHomeScore
* ScoreReason

Example:
```lua
FFAPI.Events.HomeScored.Event:Connect(function(homeScore, oldHomeScore, scoreReason)
  -- Logic Here
end)
```

---

# AwayTimeoutChange
Parameters:
* AwayTimeouts
* OldAwayTimeouts

Example:
```lua
FFAPI.Events.AwayTimeoutChange.Event:Connect(function(awayTimeouts, oldAwayTimeouts)
  -- Logic Here
end)
```

---

# HomeTimeoutChange
Parameters:
* HomeTimeouts
* OldHomeTimeouts

Example:
```lua
FFAPI.Events.HomeTimeoutChange.Event:Connect(function(homeTimeouts, oldHomeTimeouts)
  -- Logic Here
end)
```

---

# PlayClockTick
Parameters:
* pClock
* oldPClock

Example:
```lua
FFAPI.Events.PlayClockTick.Event:Connect(function(pClock, oldPClock)
  -- Logic Here
end)
```

---

# QuarterChange
Parameters:
* quarter
* oldQuarter

Example:
```lua
FFAPI.Events.QuarterChange.Event:Connect(function(quarter, oldQuarter)
  -- Logic Here
end)
```

---

# ClockTick
Parameters:
* clock
* oldClock

Example:
```lua
FFAPI.Events.ClockTick.Event:Connect(function(clock, oldClock)
  -- Logic Here
end)
```

---

# StatusChange
Parameters:
* status
* oldStatus

Example:
```lua
FFAPI.Events.StatusChange.Event:Connect(function(status, oldStatus)
  -- Logic Here
end)
```

---

# Safety
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.Safety.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# Touchdown
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.Touchdown.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# FieldGoal
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.FieldGoal.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# ExtraPoint
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.ExtraPoint.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# TwoPoint
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.TwoPoint.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# KickMissed
Parameters:
* isHomeTeam

Example:
```lua
FFAPI.Events.KickMissed.Event:Connect(function(isHomeTeam)
  -- Logic Here
end)
```

---

# BallThrown
Example:
```lua
FFAPI.Events.BallThrown.Event:Connect(function()
  -- Logic Here
end)
```

---

# BallCaught
Parameters:
* catcherId

Example:
```lua
FFAPI.Events.BallCaught.Event:Connect(function(catcherId)
  -- Logic Here
end)
```

---

# PrePlayEvent
Example:
```lua
FFAPI.Events.PrePlayEvent.Event:Connect(function()
  -- Logic Here
end)
```

---

# InPlayEvent
Example:
```lua
FFAPI.Events.InPlayEvent.Event:Connect(function()
  -- Logic Here
end)
```

---

# AfterPlayEvent
Example:
```lua
FFAPI.Events.AfterPlayEvent.Event:Connect(function()
  -- Logic Here
end)
```

---

# PlayFinishedEvent
Parameters:
* playInfo

Example:
```lua
FFAPI.Events.PlayFinishedEvent.Event:Connect(function(playInfo)
  -- Logic Here
end)
```

---

# PlayerStatsUpdated
Parameters:
* playerStats

Example:
```lua
FFAPI.Events.PlayerStatsUpdated.Event:Connect(function(playerStats)
  -- Logic Here
end)
```

---

# GameEndEvent
Parameters:
* isHomeWinner

Example:
```lua
FFAPI.Events.GameEndEvent.Event:Connect(function(isHomeWinner)
  -- Logic Here
end)
```
