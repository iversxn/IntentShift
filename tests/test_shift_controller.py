import os
import unittest

from lupa import LuaRuntime


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MODULE_ROOT = os.path.join(ROOT, 'apps', 'lua', 'IntentShift')


class ShiftControllerTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        module_path = MODULE_ROOT.replace('\\', '/').replace("'", "\\'")
        self.lua.execute(
            f"package.path = '{module_path}/?.lua;{module_path}/?/init.lua;' .. package.path"
        )
        self.controller_type = self.lua.eval("require('src/shift_controller')")[0]
        self.profiles = self.lua.table_from([
            self.lua.table_from({'name': 'Manual', 'manual': True}),
            self.lua.table_from({
                'name': 'Road', 'attack': 4, 'release': 1, 'demandCurve': 1,
                'upshiftLow': 0.35, 'upshiftHigh': 0.90,
                'downshiftLow': 0.10, 'downshiftHigh': 0.32,
                'throttleResponse': 0, 'brakeDemand': 0.6,
                'kickdownThrottle': 0.8, 'kickdownRPM': 0.48,
                'firstGearMaxKmh': 15, 'firstGearMaxRPM': 0.23,
                'brakingThreshold': 0.25, 'brakingBoost': 0.05,
                'minimumThrottle': 0.05, 'slipLimit': 1,
                'shiftGap': 0.35, 'reverseGuard': 0.75,
            }),
        ])

    def sample(self, **changes):
        values = {
            'ready': True, 'limiter': 7000, 'idle': 800, 'rpm': 3000,
            'gear': 3, 'gearCount': 6, 'speedKmh': 70,
            'gas': 0.3, 'brake': 0, 'slip': 0,
        }
        values.update(changes)
        return self.lua.table_from(values)

    def settle(self, controller, sample=None, seconds=1.0):
        sample = sample or self.sample()
        first_action = None
        for _ in range(int(seconds / 0.05)):
            action = controller.update(controller, sample, 0.05)
            if first_action is None and action is not None:
                first_action = action
        return first_action

    def test_manual_profile_never_shifts(self):
        controller = self.controller_type.new(self.profiles, 1)
        for _ in range(40):
            action = controller.update(controller, self.sample(rpm=6900, gas=1), 0.05)
            self.assertIsNone(action)

    def test_high_rpm_requests_upshift(self):
        controller = self.controller_type.new(self.profiles, 2)
        action = self.settle(controller, self.sample(rpm=6900, gas=0.4))
        self.assertEqual(action, 'up')

    def test_kickdown_requests_downshift(self):
        controller = self.controller_type.new(self.profiles, 2)
        self.settle(controller, self.sample(rpm=3500, gas=0.2), seconds=0.8)
        action = controller.update(controller, self.sample(rpm=2100, gas=1), 0.1)
        self.assertEqual(action, 'down')

    def test_braking_requests_downshift(self):
        controller = self.controller_type.new(self.profiles, 2)
        action = self.settle(
            controller, self.sample(rpm=1800, gas=0, brake=0.7), seconds=0.5
        )
        self.assertEqual(action, 'down')

    def test_second_gear_does_not_select_first_at_high_speed(self):
        controller = self.controller_type.new(self.profiles, 2)
        for _ in range(20):
            action = controller.update(
                controller,
                self.sample(rpm=1200, gas=0.2, gear=2, speedKmh=80),
                0.05,
            )
            self.assertIsNone(action)

    def test_reverse_guard_prevents_immediate_direction_change(self):
        controller = self.controller_type.new(self.profiles, 2)
        upshift = None
        for _ in range(20):
            upshift = controller.update(controller, self.sample(rpm=6900, gas=0.4), 0.05)
            if upshift is not None:
                break
        self.assertEqual(upshift, 'up')
        for _ in range(10):
            action = controller.update(
                controller, self.sample(rpm=1200, gas=1, gear=4), 0.05
            )
            self.assertIsNone(action)

    def test_wheel_slip_blocks_shift(self):
        controller = self.controller_type.new(self.profiles, 2)
        for _ in range(30):
            action = controller.update(
                controller, self.sample(rpm=6900, gas=1, slip=1.2), 0.05
            )
            self.assertIsNone(action)

    def test_top_gear_blocks_upshift(self):
        controller = self.controller_type.new(self.profiles, 2)
        for _ in range(30):
            action = controller.update(
                controller, self.sample(rpm=6900, gas=1, gear=6, gearCount=6), 0.05
            )
            self.assertIsNone(action)

    def test_invalid_physics_data_blocks_shift(self):
        controller = self.controller_type.new(self.profiles, 2)
        self.assertIsNone(controller.update(controller, self.sample(ready=False), 0.1))
        self.assertIsNone(controller.update(controller, self.sample(limiter=0), 0.1))

if __name__ == '__main__':
    unittest.main()
