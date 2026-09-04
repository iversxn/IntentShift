import os
import unittest

from lupa import LuaRuntime


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
APP_ROOT = os.path.join(ROOT, 'apps', 'lua', 'IntentShift')


class AppIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        module_root = APP_ROOT.replace('\\', '/').replace("'", "\\'")
        app_file = os.path.join(APP_ROOT, 'IntentShift.lua').replace('\\', '/')
        self.lua.execute(
            f"""
            package.path = '{module_root}/?.lua;{module_root}/?/init.lua;' .. package.path

            sim = {{ isInMainMenu = false, isPaused = false, isReplayActive = false }}
            controls = {{ gearUp = false, gearDown = false }}
            car = {{
              physicsAvailable = true, isUserControlled = true,
              rpmLimiter = 7000, rpmMinimum = 800, rpm = 3000,
              gear = 3, gearCount = 6, speedKmh = 70,
              gas = 0.3, brake = 0,
              wheels = {{
                [0] = {{ ndSlip = 0 }}, [1] = {{ ndSlip = 0 }},
                [2] = {{ ndSlip = 0 }}, [3] = {{ ndSlip = 0 }}
              }}
            }}

            ac = {{
              getSim = function() return sim end,
              getCar = function() return car end,
              overrideCarControls = function() return controls end,
              storage = function(defaults) return defaults end,
            }}
            ui = {{
              Font = {{ Small = 1 }},
              textAligned = function() end, button = function() return false end,
              offsetCursorY = function() end, text = function() end,
              separator = function() end, textWrapped = function() end,
              pushFont = function() end, textColored = function() end,
              popFont = function() end,
            }}
            vec2 = function(x, y) return {{ x = x, y = y }} end
            rgbm = function(r, g, b, a) return {{ r = r, g = g, b = b, a = a }} end
            script = {{}}
            dofile('{app_file}')
            """
        )

    def update_until(self, control, frames=80):
        for _ in range(frames):
            self.lua.execute('controls.gearUp = false; controls.gearDown = false; script.update(0.05)')
            if self.lua.eval(f'controls.{control}'):
                return True
        return False

    def test_native_upshift_is_issued(self):
        self.lua.execute('car.rpm = 6900; car.gas = 0.45')
        self.assertTrue(self.update_until('gearUp'))

    def test_native_kickdown_is_issued(self):
        self.lua.execute('car.rpm = 1900; car.gas = 1')
        self.assertTrue(self.update_until('gearDown'))

    def test_replay_suppresses_control_output(self):
        self.lua.execute('sim.isReplayActive = true; car.rpm = 6900; car.gas = 1')
        self.assertFalse(self.update_until('gearUp'))
        self.assertFalse(self.update_until('gearDown'))

    def test_window_renders_with_live_data(self):
        self.lua.execute('script.update(0.05); script.windowMain()')


if __name__ == '__main__':
    unittest.main()
