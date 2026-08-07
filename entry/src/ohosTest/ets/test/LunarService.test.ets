import { describe, it, expect } from '@ohos/hypium'
import {
  calculateBazi, applyTrueSolarTime, getTodayInfo, getYearStemBranch, getSolarTermDate,
  getAlmanac, getTrueSolarTime, getLiunianForYear, getDayStemBranch, getMonthStemBranch
} from '../../../../main/ets/model/lunar-service'
import { getNayin } from '../../../../main/ets/model/bazi-data'
import {
  buildOfflineBaziReport, buildOfflineIChingReport
} from '../../../../main/ets/services/offlineInterpreter'
import {
  GET_HEX_BY_BINARY, getTiYong, getLineDetails, getMutualHexagram,
  getOppositeHexagram, getInverseHexagram, getChangedHexagram
} from '../../../../main/ets/model/iching-data'

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

    // -- 黄历信息完整性 --
    it('almanac_is_complete', () => {
      const info = getAlmanac(new Date())
      expect(info.lunarText.length).assertLarger(0)
      expect(info.dayStemBranch.length).assertEqual(2)
      expect(info.monthStemBranch.length).assertEqual(2)
      expect(info.jianchu.length).assertEqual(1)
      expect(info.yi.length).assertLarger(0)
      expect(info.ji.length).assertLarger(0)
      expect(info.chong.length).assertLarger(1)
      expect(info.sha.length).assertLarger(1)
    })

    // -- 真太阳时信息与校正一致性 --
    it('true_solar_info_matches_correction', () => {
      const base = new Date(2026, 5, 1, 12, 0)
      const info = getTrueSolarTime(base, 120)
      const diffMin = Math.round((info.correctedDate.getTime() - base.getTime()) / 60000)
      expect(diffMin).assertEqual(info.correctionMinutes)
      expect(Math.abs(info.correctionMinutes)).assertLarger(0) // 均时差非零
      const west = getTrueSolarTime(base, 90)
      expect(west.correctionMinutes).assertLarger(110)
    })

    // -- 离线八字报告详实 --
    it('offline_bazi_report_detailed', () => {
      const data = calculateBazi(new Date(2026, 5, 1, 12, 0), 'male')
      const report = buildOfflineBaziReport(data)
      expect(report.indexOf('日主')).assertLarger(-1)
      expect(report.indexOf('格局')).assertLarger(-1)
      expect(report.indexOf('五行分布')).assertLarger(-1)
      expect(report.indexOf('大运')).assertLarger(-1)
      expect(report.indexOf('流年')).assertLarger(-1)
    })

    // -- 离线卦象报告详实 --
    it('offline_iching_report_detailed', () => {
      const binary = '100010'
      const moving = [0]
      const hex = GET_HEX_BY_BINARY(binary)
      const report = buildOfflineIChingReport({
        originalHex: hex,
        changedHex: GET_HEX_BY_BINARY(getChangedHexagram(binary, moving)),
        mutualHex: GET_HEX_BY_BINARY(getMutualHexagram(binary)),
        oppositeHex: GET_HEX_BY_BINARY(getOppositeHexagram(binary)),
        inverseHex: GET_HEX_BY_BINARY(getInverseHexagram(binary)),
        tiYong: getTiYong(binary, 0),
        movingIndexes: moving,
        lineDetails: getLineDetails(hex, moving)
      })
      expect(report.indexOf('卦辞')).assertLarger(-1)
      expect(report.indexOf('动爻解读')).assertLarger(-1)
      expect(report.indexOf('体用生克')).assertLarger(-1)
      expect(report.indexOf('变卦')).assertLarger(-1)
    })

    // -- 命宫：按《三命通会》推法，与生时无关（月宫+4） --
    it('ming_gong_follows_standard_method', () => {
      // 2026-02-10 属寅月（立春后惊蛰前），午时生
      const noon = calculateBazi(new Date(2026, 1, 10, 12, 0), 'male')
      const night = calculateBazi(new Date(2026, 1, 10, 23, 0), 'male')
      // 寅月 → 月宫 = (13-1)%12 = 0（子）→ 命宫 = (0+4)%12 = 4（辰）
      expect(noon.mingGong !== undefined).assertTrue()
      expect(noon.mingGong!.branch).assertEqual('辰')
      // 命宫与生时无关
      expect(night.mingGong!.branch).assertEqual('辰')
      expect(noon.mingGong!.stem).assertEqual(night.mingGong!.stem)
    })

    // -- 晚子时换日：23:00–24:00 按次日日柱排 --
    it('late_zi_huan_ri_changes_day_pillar', () => {
      const birth = new Date(2026, 6, 1, 23, 30)
      const normal = calculateBazi(birth, 'male', false)
      const shifted = calculateBazi(birth, 'male', true)
      const nextNoon = calculateBazi(new Date(2026, 6, 2, 12, 0), 'male')
      expect(shifted.day.stem + shifted.day.branch).assertEqual(nextNoon.day.stem + nextNoon.day.branch)
      expect(shifted.day.stem + shifted.day.branch !== normal.day.stem + normal.day.branch).assertTrue()
    })

    // -- 流年可指定年份 --
    it('liunian_supports_target_year', () => {
      const r = calculateBazi(new Date(2026, 5, 1, 12, 0), 'male')
      const y2025 = getLiunianForYear(0, 0, '木', 2025)
      const y2026 = getLiunianForYear(0, 0, '木', 2026)
      expect(y2025.currentYear).assertEqual(2025)
      expect(y2026.currentYear).assertEqual(2026)
      expect(y2025.stem !== y2026.stem).assertTrue()
    })

    // -- 节气月柱（以节为界） --
    it('month_stem_branch_follows_jieqi', () => {
      // 2026-03-01 惊蛰前 → 寅月庚寅；2026-03-08 惊蛰后 → 卯月辛卯
      expect(getMonthStemBranch(new Date(2026, 2, 1))).assertEqual('庚寅')
      expect(getMonthStemBranch(new Date(2026, 2, 8))).assertEqual('辛卯')
    })

    // -- 日柱干支 --
    it('day_stem_branch_returns_two_chars', () => {
      expect(getDayStemBranch(new Date(2026, 5, 1)).length).assertEqual(2)
    })
  })
}
