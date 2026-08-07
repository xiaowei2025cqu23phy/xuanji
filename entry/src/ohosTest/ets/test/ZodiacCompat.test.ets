import { describe, it, expect } from '@ohos/hypium'
import { getZodiacRelation, calculateHehun, calculateHehunFull } from '../../../../main/ets/model/zodiac-compat'
import { calculateBazi } from '../../../../main/ets/model/lunar-service'

export default function ZodiacCompatTest() {
  describe('ZodiacCompat_Test', () => {

    it('liuhe_detected', () => {
      expect(getZodiacRelation('子', '丑').label).assertEqual('六合')
      expect(getZodiacRelation('午', '未').label).assertEqual('六合')
    })

    it('sanhe_detected_with_element', () => {
      const rel = getZodiacRelation('申', '子')
      expect(rel.label).assertEqual('三合（水局）')
    })

    it('liuchong_detected', () => {
      expect(getZodiacRelation('子', '午').label).assertEqual('六冲')
    })

    it('xiangxing_detected', () => {
      expect(getZodiacRelation('寅', '巳').label).assertEqual('相刑')
    })

    it('xianghai_detected', () => {
      expect(getZodiacRelation('子', '未').label).assertEqual('相害')
    })

    it('self_xing_for_chen_wu_you_hai', () => {
      expect(getZodiacRelation('辰', '辰').label).assertEqual('自刑')
      expect(getZodiacRelation('午', '午').label).assertEqual('自刑')
      expect(getZodiacRelation('酉', '酉').label).assertEqual('自刑')
      expect(getZodiacRelation('亥', '亥').label).assertEqual('自刑')
    })

    it('ping_for_neutral_pair', () => {
      expect(getZodiacRelation('寅', '卯').label).assertEqual('平平')
    })

    it('hehun_basic_scoring', () => {
      const r = calculateHehun('丙', '午', '辛', '卯')
      expect(r.overallScore).assertLarger(0)
      expect(r.overallScore).assertLess(101)
      expect(r.summary.indexOf('评分')).assertLarger(-1)
    })

    it('hehun_full_uses_two_charts', () => {
      const male = calculateBazi(new Date(1990, 5, 15, 10, 0), 'male')
      const female = calculateBazi(new Date(1992, 9, 1, 14, 30), 'female')
      const r = calculateHehunFull(male, female)
      expect(r.overallScore).assertLarger(0)
      expect(r.overallScore).assertLess(101)
      expect(r.level.length).assertLarger(0)
      expect(r.nayinText.length).assertLarger(0)
      expect(r.complementText.indexOf('男命')).assertLarger(-1)
    })
  })
}
