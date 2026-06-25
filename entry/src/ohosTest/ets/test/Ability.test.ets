import { describe, it, expect } from '@ohos/hypium'

export default function AbilityTest() {
  describe('Sanity_Test', () => {
    it('test_runner_initialized', () => {
      expect(1 + 1).assertEqual(2)
    })
  })
}
