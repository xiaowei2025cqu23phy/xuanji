import { describe, it, expect } from '@ohos/hypium'
import { getElementRelation } from '../../../../main/ets/common/constants'

export default function FiveElementRelationTest() {
  describe('FiveElementRelation_Test', () => {

    // -- 比和 (same element) --
    it('same_element_should_be_bihe', () => {
      const r = getElementRelation('木', '木')
      expect(r.label).assertEqual('比和')
      expect(r.relative).assertEqual('兄弟')
    })

    // -- 生我 (other generates self) --
    it('water_generates_wood_is_shengwo', () => {
      const r = getElementRelation('木', '水')
      expect(r.label).assertEqual('生我')
      expect(r.relative).assertEqual('父母')
    })

    it('wood_generates_fire_is_shengwo', () => {
      const r = getElementRelation('火', '木')
      expect(r.label).assertEqual('生我')
    })

    // -- 我生 (self generates other) --
    it('wood_generates_fire_is_wosheng', () => {
      const r = getElementRelation('木', '火')
      expect(r.label).assertEqual('我生')
      expect(r.relative).assertEqual('子孙')
    })

    // -- 我克 (self overcomes other) --
    it('wood_overcomes_earth_is_woke', () => {
      const r = getElementRelation('木', '土')
      expect(r.label).assertEqual('我克')
      expect(r.relative).assertEqual('妻财')
    })

    // -- 克我 (other overcomes self) --
    it('metal_overcomes_wood_is_kewo', () => {
      const r = getElementRelation('木', '金')
      expect(r.label).assertEqual('克我')
      expect(r.relative).assertEqual('官鬼')
    })

    // -- Exhaustive check: all 5 elements have 5 relations = 25 total --
    it('all_25_combinations_return_valid', () => {
      const elements = ['木', '火', '土', '金', '水']
      for (const a of elements) {
        for (const b of elements) {
          const r = getElementRelation(a, b)
          expect(r.label.length).assertLarger(0)
          expect(r.relative.length).assertLarger(0)
          expect(r.desc.length).assertLarger(0)
        }
      }
    })
  })
}
