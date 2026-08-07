import { describe, it, expect } from '@ohos/hypium'
import { getDailyHourLuck, getCurrentHourLuck } from '../../../../main/ets/model/hour-luck'
import { JIAN_CHU_NAMES, getJianChuIndex } from '../../../../main/ets/model/almanac'

export default function HourLuckTest() {
  describe('HourLuck_Test', () => {

    // 传统口诀：子午日起申（8）、丑未起戌（10）、寅申起子（0）、卯酉起寅（2）、辰戌起辰（4）、巳亥起午（6）
    it('qinglong_starts_at_shen_for_zi_wu_days', () => {
      const zi = getDailyHourLuck('子', 0, 2)
      const wu = getDailyHourLuck('午', 6, 2)
      expect(zi.hours[8].huanghei).assertEqual('青龙')
      expect(wu.hours[8].huanghei).assertEqual('青龙')
      expect(zi.hours[8].isAuspicious).assertTrue()
    })

    it('qinglong_starts_at_zi_for_yin_shen_days', () => {
      const yin = getDailyHourLuck('寅', 2, 2)
      const shen = getDailyHourLuck('申', 8, 2)
      expect(yin.hours[0].huanghei).assertEqual('青龙')
      expect(shen.hours[0].huanghei).assertEqual('青龙')
    })

    it('every_day_has_six_auspicious_hours', () => {
      const daily = getDailyHourLuck('辰', 4, 2)
      expect(daily.bestHours.length).assertEqual(6)
      expect(daily.hours.length).assertEqual(12)
    })

    it('jianxing_matches_almanac_rule', () => {
      const daily = getDailyHourLuck('丑', 1, 2)
      const expected = JIAN_CHU_NAMES[getJianChuIndex(1, 2)]
      expect(daily.hours[0].jianxing).assertEqual(expected)
    })

    it('current_hour_luck_resolves', () => {
      const luck = getCurrentHourLuck('子', 0, 2, 12)
      expect(luck !== null).assertTrue()
      if (luck) {
        expect(luck.timeRange.length).assertLarger(0)
      }
    })
  })
}
