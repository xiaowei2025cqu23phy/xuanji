import { describe, it, expect } from '@ohos/hypium'
import { formatBaziShareText, formatIChingShareText } from '../../../../main/ets/services/exportService'

export default function ExportServiceTest() {
  describe('ExportService_Test', () => {

    it('bazi_share_text_contains_key_sections', () => {
      const text = formatBaziShareText(
        '2000-01-01', '12:00', 'male',
        '庚', '辰', '戊', '子', '丙', '寅', '甲', '午',
        '丙', '日主丙火，五行属火。', '正格', '日主得令。'
      )
      expect(text.indexOf('天道玄机')).assertLarger(-1)
      expect(text.indexOf('四柱')).assertLarger(-1)
      expect(text.indexOf('日主解析')).assertLarger(-1)
      expect(text.indexOf('格局解析')).assertLarger(-1)
    })

    it('iching_share_text_contains_key_sections', () => {
      const text = formatIChingShareText(
        '䷀', '乾', 1, '元亨利贞。', '天行健。',
        '䷁', '坤', '乾', '金', '乾', '金', '比和 (吉)', 0
      )
      expect(text.indexOf('本卦')).assertLarger(-1)
      expect(text.indexOf('卦辞')).assertLarger(-1)
      expect(text.indexOf('体用')).assertLarger(-1)
      expect(text.indexOf('动爻：0个')).assertLarger(-1)
    })
  })
}
