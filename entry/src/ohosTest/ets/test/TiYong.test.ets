import { describe, it, expect } from '@ohos/hypium'
import { getTiYong, TiYongResult } from '../../../../main/ets/model/iching-data'

export default function TiYongTest() {
  describe('TiYong_Test', () => {

    // -- No moving line → returns neutral --
    it('no_moving_line_returns_neutral', () => {
      const r = getTiYong('111111', null)
      expect(r.relation).assertEqual('无动爻')
      expect(r.description).assertContain('无动爻不分体用')
    })

    // -- Qian hexagram, moving line 0 (bottom) --
    it('qian_with_bottom_moving', () => {
      // bottom trigram '111' = 乾(金), top trigram '111' = 乾(金)
      // moving line 0 means bottom trigram is Ti (体), top is Yong (用)
      // 金见金 = 比和
      const r = getTiYong('111111', 0)
      expect(r.ti).assertEqual('乾')
      expect(r.yong).assertEqual('乾')
      expect(r.tiElement).assertEqual('金')
      expect(r.yongElement).assertEqual('金')
      expect(r.relation).assertEqual('比和 (吉)')
    })

    // -- Moving line in top trigram → top is Yong --
    it('moving_line_in_top_makes_top_yong', () => {
      // moving line 3 (first line of top trigram)
      const r = getTiYong('111111', 3)
      expect(r.ti).assertEqual('乾')    // bottom trigram '111' = Qian → Ti
      expect(r.yong).assertEqual('乾')  // top trigram '111' = Qian → Yong
    })

    // -- Water conquers Fire: Ti=坎(水), Yong=离(火) --
    it('water_ti_fire_yong', () => {
      // '010101': bottom='010'=坎(水), top='101'=离(火)
      // moving line 0 → ti is bottom (坎/水), yong is top (离/火)
      // 水克火 = 我克 = 体克用 (小吉)
      const r = getTiYong('010101', 0)
      expect(r.ti).assertEqual('坎')
      expect(r.yong).assertEqual('离')
      expect(r.tiElement).assertEqual('水')
      expect(r.yongElement).assertEqual('火')
      expect(r.relation).assertEqual('体克用 (小吉)')
    })

    // -- Earth generates Metal: Ti=坤(土), Yong=乾(金) --
    it('earth_ti_metal_yong_shengwo', () => {
      // '000111': bottom='000'=坤(土), top='111'=乾(金)
      // moving line 5 → ti is bottom (坤/土), yong is top (乾/金)
      // 土生金 = 我生 = 体生用 (中吉)
      const r = getTiYong('000111', 5)
      expect(r.ti).assertEqual('坤')
      expect(r.yong).assertEqual('乾')
      expect(r.relation).assertEqual('体生用 (中吉)')
    })

    // -- Metal conquers Wood: Ti=震(木), Yong=兑(金) --
    it('wood_ti_metal_yong_kewo', () => {
      // '100110': bottom='100'=震(木), top='110'=兑(金)
      // moving line 1 → ti is bottom (震/木), yong is top (兑/金)
      // 金克木 = 克我 = 用克体 (凶)
      const r = getTiYong('100110', 1)
      expect(r.ti).assertEqual('震')
      expect(r.yong).assertEqual('兑')
      expect(r.relation).assertEqual('用克体 (凶)')
    })

    // -- Fire generates Earth: Ti=离(火), Yong=坤(土) --
    it('fire_ti_earth_yong', () => {
      // For this test, we can pick any valid combination
      // Use '000101': bottom='000'=坤(土), top='101'=离(火)
      // moving line 1 → ti = bottom (坤/土), yong = top (离/火)
      // 火生土 = 生我 = 用生体 (大吉)
      const r = getTiYong('000101', 1)
      expect(r.ti).assertEqual('坤')
      expect(r.yong).assertEqual('离')
      expect(r.relation).assertEqual('用生体 (大吉)')
    })

    // -- All moving lines > 0 produce valid relation --
    it('all_moving_positions_yield_valid_relation', () => {
      const bins = ['111111', '000000', '010010', '101101']
      for (const bin of bins) {
        for (let movingLine = 0; movingLine < 6; movingLine++) {
          const r = getTiYong(bin, movingLine)
          expect(r.ti.length).assertLarger(0)
          expect(r.yong.length).assertLarger(0)
          expect(r.relation.length).assertLarger(0)
        }
      }
    })
  })
}
