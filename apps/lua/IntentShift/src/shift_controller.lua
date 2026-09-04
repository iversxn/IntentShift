local Controller = {}
Controller.__index = Controller

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function mix(from, to, amount)
  return from + (to - from) * amount
end

local function approach(current, target, rate, dt)
  local step = rate * dt
  if current < target then return math.min(target, current + step) end
  return math.max(target, current - step)
end

function Controller.new(profiles, profileIndex)
  return setmetatable({
    profiles = profiles,
    profileIndex = profileIndex or 1,
    clock = 0,
    demand = 0,
    previousGas = 0,
    lastShiftAt = -100,
    lastUpshiftAt = -100,
    lastDownshiftAt = -100,
    upshiftRPM = 0,
    downshiftRPM = 0,
    status = 'Manual control',
  }, Controller)
end

function Controller:setProfile(index)
  self.profileIndex = clamp(math.floor(index), 1, #self.profiles)
  self.demand = 0
  self.status = self.profileIndex == 1 and 'Manual control' or 'Monitoring'
end

function Controller:getProfile()
  return self.profiles[self.profileIndex]
end

function Controller:getDiagnostics()
  return {
    demand = self.demand,
    upshiftRPM = self.upshiftRPM,
    downshiftRPM = self.downshiftRPM,
    status = self.status,
  }
end

function Controller:update(sample, dt)
  dt = clamp(dt or 0, 0, 0.1)
  self.clock = self.clock + dt

  local profile = self:getProfile()
  if profile.manual then
    self.previousGas = sample.gas or 0
    self.status = 'Manual control'
    return nil
  end

  local limiter = sample.limiter or 0
  local idle = sample.idle or 0
  local rpmSpan = limiter - idle
  if rpmSpan < 500 or not sample.ready then
    self.status = 'Waiting for car data'
    return nil
  end

  local gas = clamp(sample.gas or 0, 0, 1)
  local brake = clamp(sample.brake or 0, 0, 1)
  local throttleRise = math.max(0, gas - self.previousGas) / math.max(dt, 0.001)
  self.previousGas = gas

  local requested = math.max(gas, brake * profile.brakeDemand)
  requested = math.max(requested, clamp(throttleRise * profile.throttleResponse, 0, 1))
  local response = requested > self.demand and profile.attack or profile.release
  self.demand = approach(self.demand, requested, response, dt)

  local shapedDemand = self.demand ^ profile.demandCurve
  local upFraction = mix(profile.upshiftLow, profile.upshiftHigh, shapedDemand)
  local downFraction = mix(profile.downshiftLow, profile.downshiftHigh, shapedDemand)
  self.upshiftRPM = idle + rpmSpan * upFraction
  self.downshiftRPM = idle + rpmSpan * downFraction

  local gear = sample.gear or 0
  local gearCount = sample.gearCount or 0
  local rpm = sample.rpm or 0
  local speed = math.abs(sample.speedKmh or 0)
  local slip = sample.slip or 0

  if gear < 1 or gearCount < 1 then
    self.status = 'Waiting for a forward gear'
    return nil
  end
  if slip > profile.slipLimit then
    self.status = 'Holding during wheel slip'
    return nil
  end
  if self.clock - self.lastShiftAt < profile.shiftGap then
    self.status = 'Shift protection'
    return nil
  end

  local normalizedRPM = clamp((rpm - idle) / rpmSpan, 0, 1.2)
  local canUseFirst = speed <= profile.firstGearMaxKmh
    or (gas >= profile.kickdownThrottle and normalizedRPM < profile.firstGearMaxRPM)
  local kickdown = gas >= profile.kickdownThrottle
    and normalizedRPM < profile.kickdownRPM
    and gear > 1
  local brakingDownshift = brake >= profile.brakingThreshold
    and rpm < self.downshiftRPM + rpmSpan * profile.brakingBoost
    and gear > 1
  local lowRPMDownshift = rpm < self.downshiftRPM and gear > 1

  if (kickdown or brakingDownshift or lowRPMDownshift)
      and (gear > 2 or canUseFirst)
      and self.clock - self.lastUpshiftAt >= profile.reverseGuard then
    self.lastShiftAt = self.clock
    self.lastDownshiftAt = self.clock
    self.status = kickdown and 'Kickdown' or 'Downshift'
    return 'down'
  end

  if gear < gearCount
      and gas > profile.minimumThrottle
      and brake < 0.05
      and rpm >= self.upshiftRPM
      and self.clock - self.lastDownshiftAt >= profile.reverseGuard then
    self.lastShiftAt = self.clock
    self.lastUpshiftAt = self.clock
    self.status = 'Upshift'
    return 'up'
  end

  self.status = 'Monitoring'
  return nil
end

return Controller
