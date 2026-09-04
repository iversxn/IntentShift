local ShiftController = require('src/shift_controller')

local sim = ac.getSim()
local car = ac.getCar(0) or error('IntentShift: player car is unavailable')
local controls = ac.overrideCarControls(0)
local settings = ac.storage({ profile = 3 })

local profiles = {
  { name = 'Manual', manual = true },
  {
    name = 'Cruise', attack = 2.8, release = 0.34, demandCurve = 1.25,
    upshiftLow = 0.31, upshiftHigh = 0.78,
    downshiftLow = 0.08, downshiftHigh = 0.27,
    throttleResponse = 0.09, brakeDemand = 0.55,
    kickdownThrottle = 0.86, kickdownRPM = 0.43,
    firstGearMaxKmh = 13, firstGearMaxRPM = 0.20,
    brakingThreshold = 0.30, brakingBoost = 0.03,
    minimumThrottle = 0.06, slipLimit = 1.0,
    shiftGap = 0.45, reverseGuard = 0.85,
  },
  {
    name = 'Road', attack = 3.6, release = 0.25, demandCurve = 1.05,
    upshiftLow = 0.36, upshiftHigh = 0.91,
    downshiftLow = 0.10, downshiftHigh = 0.32,
    throttleResponse = 0.12, brakeDemand = 0.68,
    kickdownThrottle = 0.80, kickdownRPM = 0.48,
    firstGearMaxKmh = 15, firstGearMaxRPM = 0.23,
    brakingThreshold = 0.24, brakingBoost = 0.05,
    minimumThrottle = 0.05, slipLimit = 1.0,
    shiftGap = 0.35, reverseGuard = 0.75,
  },
  {
    name = 'Sport', attack = 5.0, release = 0.17, demandCurve = 0.86,
    upshiftLow = 0.48, upshiftHigh = 0.96,
    downshiftLow = 0.13, downshiftHigh = 0.39,
    throttleResponse = 0.16, brakeDemand = 0.82,
    kickdownThrottle = 0.72, kickdownRPM = 0.54,
    firstGearMaxKmh = 18, firstGearMaxRPM = 0.27,
    brakingThreshold = 0.18, brakingBoost = 0.07,
    minimumThrottle = 0.04, slipLimit = 1.0,
    shiftGap = 0.28, reverseGuard = 0.65,
  },
}

settings.profile = math.max(1, math.min(#profiles, math.floor(settings.profile)))
local controller = ShiftController.new(profiles, settings.profile)

local function maximumSlip()
  local result = 0
  for index = 0, 3 do
    result = math.max(result, car.wheels[index].ndSlip or 0)
  end
  return result
end

function script.update(dt)
  if sim.isInMainMenu or sim.isPaused or sim.isReplayActive then return end

  local action = controller:update({
    ready = car.physicsAvailable and car.isUserControlled,
    limiter = car.rpmLimiter,
    idle = car.rpmMinimum,
    rpm = car.rpm,
    gear = car.gear,
    gearCount = car.gearCount,
    speedKmh = car.speedKmh,
    gas = car.gas,
    brake = car.brake,
    slip = maximumSlip(),
  }, dt)

  if action == 'up' then
    controls.gearUp = true
  elseif action == 'down' then
    controls.gearDown = true
  end
end

function script.windowMain()
  local profile = controller:getProfile()
  ui.textAligned('DRIVE PROFILE', 0.5)
  if ui.button(profile.name, vec2(-0.1, 30)) then
    settings.profile = settings.profile % #profiles + 1
    controller:setProfile(settings.profile)
    profile = controller:getProfile()
  end

  ui.offsetCursorY(12)
  local diagnostics = controller:getDiagnostics()
  ui.text('Status: ' .. diagnostics.status)
  ui.separator()

  if profile.manual then
    ui.textWrapped('IntentShift is standing by. Select a driving profile to enable automatic shifting.')
  else
    ui.text(string.format('Demand          %3.0f%%', diagnostics.demand * 100))
    ui.text(string.format('Upshift target  %4.0f RPM', diagnostics.upshiftRPM))
    ui.text(string.format('Downshift floor %4.0f RPM', diagnostics.downshiftRPM))
    ui.offsetCursorY(8)
    ui.textWrapped('Native CSP control active. No keyboard bindings are used.')
  end

  ui.offsetCursorY(10)
  ui.pushFont(ui.Font.Small)
  ui.textColored('IntentShift 1.0.0  |  iversxn', rgbm(0.22, 0.82, 0.95, 1))
  ui.popFont()
end
