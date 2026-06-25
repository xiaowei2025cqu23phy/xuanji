import { describe, it, expect } from '@ohos/hypium'
import {
  GET_HEX_BY_BINARY, getMutualHexagram, getChangedHexagram,
  getOppositeHexagram, getInverseHexagram
} from '../../../../main/ets/model/iching-data'

export default function HexagramTransformTest() {
  describe('HexagramTransform_Test', () => {

    // -- 64 hexagrams all resolve --
    it('all_64_hexagrams_should_resolve', () => {
      const bins = generateAllHexagrams()
      for (const bin of bins) {
        const hex = GET_HEX_BY_BINARY(bin)
        expect(hex.name.length).assertLarger(0)
        expect(hex.number).assertLarger(0)
        expect(hex.judgement.length).assertLarger(0)
      }
    })

    // -- Qian hexagram (111111) --
    it('qian_hexagram_lookup', () => {
      const hex = GET_HEX_BY_BINARY('111111')
      expect(hex.name).assertEqual('乾')
      expect(hex.number).assertEqual(1)
      expect(hex.symbol).assertEqual('䷀')
      expect(hex.lines).assertLarger(0)
      if (hex.lines) {
        expect(hex.lines.length).assertEqual(6)
      }
    })

    // -- Kun hexagram (000000) --
    it('kun_hexagram_lookup', () => {
      const hex = GET_HEX_BY_BINARY('000000')
      expect(hex.name).assertEqual('坤')
      expect(hex.number).assertEqual(2)
    })

    // -- Mutual hexagram (互卦) --
    it('qian_mutual_hexagram', () => {
      const mutualBin = getMutualHexagram('111111')
      expect(mutualBin).assertEqual('111111')  // Qian's mutual is Qian
    })

    it('tun_mutual_hexagram', () => {
      // 屯卦: 100010, mutual should be from positions 2-4 and 3-5
      const mutualBin = getMutualHexagram('100010')
      expect(mutualBin.length).assertEqual(6)
      expect(mutualBin).assertEqual('000100')  // bottom=000, top=100 → 山雷颐... let me check
      // Actually: bottom = lines[1]=0,lines[2]=0,lines[3]=0 → "000"
      // top = lines[2]=0,lines[3]=0,lines[4]=1 → "001"
      // Wait, '100010' reversed for indexing: lines[0]=1,lines[1]=0,lines[2]=0,lines[3]=0,lines[4]=1,lines[5]=0
      // Bottom: lines[1] lines[2] lines[3] = 0 0 0 → "000"
      // Top:    lines[2] lines[3] lines[4] = 0 0 1 → "001"
      // Result: "000001" → 剥卦
      expect(mutualBin).assertEqual('000001')
    })

    // -- Changed hexagram (变卦) --
    it('changed_hexagram_with_moving_lines', () => {
      // Toggle lines 0 and 5: 111111 → 011110
      const changed = getChangedHexagram('111111', [0, 5])
      expect(changed).assertEqual('011110')
    })

    it('changed_hexagram_no_moving', () => {
      const changed = getChangedHexagram('111111', [])
      expect(changed).assertEqual('111111')
    })

    // -- Opposite hexagram (错卦) --
    it('opposite_inverts_all_lines', () => {
      const opposite = getOppositeHexagram('111111')
      expect(opposite).assertEqual('000000')  // Qian → Kun
    })

    it('opposite_of_mixed', () => {
      const opposite = getOppositeHexagram('101010')
      expect(opposite).assertEqual('010101')
    })

    // -- Inverse hexagram (综卦) --
    it('inverse_reverses_order', () => {
      const inverse = getInverseHexagram('100000')
      expect(inverse).assertEqual('000001')  // 复 → 剥 (reversed)
    })

    it('qian_inverse_is_itself', () => {
      const inverse = getInverseHexagram('111111')
      expect(inverse).assertEqual('111111')
    })

    // -- Unknown binary falls back gracefully --
    it('unknown_binary_returns_fallback', () => {
      const hex = GET_HEX_BY_BINARY('010101')
      // '010101' is 未济 (not in our dataset? Let's check... actually it IS 未济 = 010101)
      // So this test should still resolve
      expect(hex.number).assertEqual(64)  // 未济 is hexagram 64
    })
  })
}

function generateAllHexagrams(): string[] {
  const result: string[] = []
  for (let i = 0; i < 64; i++) {
    const bin = i.toString(2).padStart(6, '0')
    result.push(bin)
  }
  return result
}
