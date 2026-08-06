import { describe, it, expect } from '@ohos/hypium'
import {
  calculateBazi, applyTrueSolarTime, getTodayInfo, getYearStemBranch, getSolarTermDate
} from '../../../../main/ets/model/lunar-service'
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

    // -- 立春前出生属上一年（2000-01-01 → 己卯年） --
    it('year_pillar_before_lichun_belongs_to_previous_year', () => {
      const r = calculateBazi(new Date(2000, 0, 1, 12, 0), 'male')
      expect(r.year.stem + r.year.branch).assertEqual('己卯')
    })

    // -- 立春边界：2026 立春前 = 乙巳年，立春后 = 丙午年 --
    it('year_pillar_turns_at_lichun', () => {
      const lichun = getSolarTermDate(2026, 2)
      const before = new Date(lichun.getTime() - 3600000)
      const after = new Date(lichun.getTime() + 3600000)
      const r1 = calculateBazi(before, 'male')
      const r2 = calculateBazi(after, 'male')
      expect(r1.year.stem + r1.year.branch).assertEqual('乙巳')
      expect(r2.year.stem + r2.year.branch).assertEqual('丙午')
    })

    // -- 节气月：惊蛰后进入卯月（丙午年 → 辛卯） --
    it('month_pillar_turns_at_jingzhe', () => {
      const jingzhe = getSolarTermDate(2026, 4)
      const before = new Date(jingzhe.getTime() - 3600000)
      const after = new Date(jingzhe.getTime() + 3600000)
      const r0 = calculateBazi(before, 'male')
      const r1 = calculateBazi(after, 'male')
      expect(r0.month.stem + r0.month.branch).assertEqual('庚寅')
      expect(r1.month.stem + r1.month.branch).assertEqual('辛卯')
    })

    // -- 节气时刻精度：2000 春分 ≈ 2000-03-20 15:35 北京 --
    it('solar_term_precision_2000_equinox', () => {
      const d = getSolarTermDate(2000, 5)
      const bj = new Date(d.getTime() + 8 * 3600000)
      expect(bj.getUTCFullYear()).assertEqual(2000)
      expect(bj.getUTCMonth()).assertEqual(2)  // 3 月
      expect(bj.getUTCDate()).assertEqual(20)
      expect(bj.getUTCHours()).assertEqual(15)
    })

    // -- 2026 立春 = 2026-02-04 04:03 左右北京时 --
    it('solar_term_2026_lichun_time', () => {
      const d = getSolarTermDate(2026, 2)
      const bj = new Date(d.getTime() + 8 * 3600000)
      expect(bj.getUTCFullYear()).assertEqual(2026)
      expect(bj.getUTCMonth()).assertEqual(1)  // 2 月
      expect(bj.getUTCDate()).assertEqual(4)
      expect(bj.getUTCHours()).assertEqual(4)
    })

    // -- 大运 direction: 阳年男顺行 / 阴年女顺行 --
    it('yang_year_male_runs_forward_dayun', () => {
      const r = calculateBazi(new Date(2026, 5, 1, 12, 0), 'male')
      expect(r.dayun !== undefined).assertTrue()
      expect(r.dayun!.direction).assertEqual('forward')
    })

    it('yang_year_female_runs_backward_dayun', () => {
      const r = calculateBazi(new Date(2026, 5, 1, 12, 0), 'female')
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
