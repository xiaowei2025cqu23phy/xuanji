import { describe, it, expect } from '@ohos/hypium'
import {
  getNazhiForLine, computeLiuYao, getPalaceInfo, getXunKong, buildLiuYaoPan
} from '../../../../main/ets/model/liuyao-engine'

export default function LiuYaoEngineTest() {
  describe('LiuYaoEngine_Test', () => {

    // -- Inner trigram 纳支 (乾: 子寅辰) --
    it('nazhi_inner_lines_qian', () => {
      expect(getNazhiForLine('111111', 0).branch).assertEqual('子')
      expect(getNazhiForLine('111111', 1).branch).assertEqual('寅')
      expect(getNazhiForLine('111111', 2).branch).assertEqual('辰')
    })

    // -- Outer trigram 纳支 must use outer table (乾: 午申戌) --
    it('nazhi_outer_lines_use_outer_table', () => {
      expect(getNazhiForLine('111111', 3).branch).assertEqual('午')
      expect(getNazhiForLine('111111', 4).branch).assertEqual('申')
      expect(getNazhiForLine('111111', 5).branch).assertEqual('戌')
    })

    // -- Kun hexagram outer lines (坤: 丑亥酉) --
    it('nazhi_outer_lines_kun', () => {
      expect(getNazhiForLine('000000', 3).branch).assertEqual('丑')
      expect(getNazhiForLine('000000', 4).branch).assertEqual('亥')
      expect(getNazhiForLine('000000', 5).branch).assertEqual('酉')
    })

    // -- 六亲 derived from palace element vs branch element --
    it('qian_palace_six_relatives', () => {
      const lines = computeLiuYao('111111', [], '甲')
      expect(lines[0].liuqin).assertEqual('子孙')  // 乾金 子水 → 金生水
      expect(lines[3].liuqin).assertEqual('官鬼')  // 乾金 午火 → 火克金
    })

    // -- 世应 positions for 本宫卦 --
    it('qian_hexagram_shi_ying', () => {
      const lines = computeLiuYao('111111', [], '甲')
      expect(lines[5].shiYing).assertEqual('世')
      expect(lines[2].shiYing).assertEqual('应')
    })

    // -- 八宫归属 --
    it('palace_mapping', () => {
      expect(getPalaceInfo('111111').palace).assertEqual('乾')
      expect(getPalaceInfo('010010').palace).assertEqual('坎')
      expect(getPalaceInfo('101101').palace).assertEqual('离')
    })

    // -- 旬空 --
    it('xun_kong_lookup', () => {
      const kong = getXunKong('甲', '子')
      expect(kong.length).assertEqual(2)
      expect(kong[0]).assertEqual('戌')
      expect(kong[1]).assertEqual('亥')
    })

    // -- Full pan build --
    it('build_pan_has_6_lines', () => {
      const pan = buildLiuYaoPan('111111', [], '甲', '子', '丙', '寅')
      expect(pan.lines.length).assertEqual(6)
      expect(pan.palace).assertEqual('乾')
      expect(pan.xunKong.length).assertEqual(2)
    })
  })
}
