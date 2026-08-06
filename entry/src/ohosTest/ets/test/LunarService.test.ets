import { describe, it, expect } from '@ohos/hypium'
import { calculateBazi, applyTrueSolarTime, getTodayInfo, getYearStemBranch } from '../../../../main/ets/model/lunar-service'
import { getNayin } from '../../../../main/ets/model/bazi-data'

export default function LunarServiceTest() {
  describe('LunarService_Test', () => {

    // -- Hour pillar must reflect the selected birth time (regression: was always 子时) --
    it('hour_pillar_reflects_birth_time', () => {
      const noon = calculateBazi(new Date(2000, 0, 1, 12, 30), 'male')
      expect(noon.hour.branch).assertEqual('午')
      expect(noon.hour.stem).assertEqual('丙')

      const midnight = calculateBazi(new Date(2000, 0, 1, 0, 30), 'male')
      expect(midnight.hour.branch).assertEqual('子')
      expect(midnight.hour.stem).assertEqual('庚')

      const lateNight = calculateBazi(new Date(2000, 0, 1, 23, 30), 'male')
      expect(lateNight.hour.branch).assertEqual('子')
    })

    // -- 大运 direction: 阳年男顺行 / 阴年女顺行 --
    it('yang_year_male_runs_forward_dayun', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'male')
      expect(r.dayun !== undefined).assertTrue()
      expect(r.dayun!.direction).assertEqual('forward')
    })

    it('yang_year_female_runs_backward_dayun', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'female')
      expect(r.dayun !== undefined).assertTrue()
      expect(r.dayun!.direction).assertEqual('backward')
    })

    // -- 流年 monthly breakdown --
    it('liunian_has_12_monthly_entries', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'male')
      expect(r.liunian !== undefined).assertTrue()
      expect(r.liunian!.monthlyBreakdown.length).assertEqual(12)
    })

    // -- 命宫 / 胎元 are computed --
    it('ming_gong_and_tai_yuan_present', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'male')
      expect(r.mingGong !== undefined).assertTrue()
      expect(r.taiYuan !== undefined).assertTrue()
      expect(r.mingGong!.stem.length).assertLarger(0)
      expect(r.mingGong!.branch.length).assertLarger(0)
      expect(r.taiYuan!.stem.length).assertLarger(0)
      expect(r.taiYuan!.branch.length).assertLarger(0)
    })

    // -- Hidden stems attached to pillars --
    it('pillars_include_hidden_stems', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'male')
      expect(r.year.hiddenStems !== undefined).assertTrue()
      expect(r.year.hiddenStems!.length).assertLarger(0)
    })

    // -- 纳音 lookup --
    it('nayin_lookup_basic_pairs', () => {
      expect(getNayin(0, 0).name).assertEqual('海中金')
      expect(getNayin(0, 0).element).assertEqual('金')
      expect(getNayin(9, 11).name).assertEqual('大海水')
      expect(getNayin(0, 10).name).assertEqual('山头火')
    })

    // -- Year stem-branch --
    it('year_stem_branch_for_2026', () => {
      expect(getYearStemBranch(2026)).assertEqual('丙午')
    })

    // -- True solar time correction shifts the clock --
    it('true_solar_time_moves_toward_longitude', () => {
      const base = new Date(2026, 5, 1, 12, 0)
      const shifted = applyTrueSolarTime(base, 90)
      const diffMin = Math.round((shifted.getTime() - base.getTime()) / 60000)
      expect(diffMin).assertLarger(60)   // 120°E − 90°E = 30° → at least +120min (EoT small in June)
      expect(diffMin).assertLarger(115)
    })

    // -- Today info is well-formed --
    it('today_info_is_complete', () => {
      const info = getTodayInfo()
      expect(info.dayStemBranch.length).assertEqual(2)
      expect(info.yearStemBranch.length).assertEqual(2)
      expect(info.lunarText.length).assertLarger(0)
      expect(info.hexName.length).assertLarger(0)
      expect(info.hexSymbol.length).assertLarger(0)
    })
  })
}
