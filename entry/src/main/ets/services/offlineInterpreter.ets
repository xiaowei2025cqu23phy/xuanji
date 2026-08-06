import { BaziData, PillarData } from '../model/bazi-data'
import { ELEMENT_ORDER, getElementRelation } from '../common/constants'
import { Hexagram, TiYongResult, LineDetail } from '../model/iching-data'

// ============================================================
// 离线解读引擎：不依赖 AI，基于排盘数据生成详实的中文分析
// ============================================================

function pillarText(p: PillarData, label: string): string {
  let s = label + p.stem + p.branch + '（' + p.element
  if (p.nayin) { s += ' · ' + p.nayin }
  if (p.hiddenStems && p.hiddenStems.length > 0) { s += ' · 藏干' + p.hiddenStems.join('') }
  s += '）'
  return s
}

export function buildOfflineBaziReport(data: BaziData): string {
  let s = ''
  s += '【天道玄机 · 离线详析】\n'
  s += '\n■ 四柱八字\n'
  s += pillarText(data.year, '年柱') + '\n'
  s += pillarText(data.month, '月柱') + '\n'
  s += pillarText(data.day, '日柱') + '\n'
  s += pillarText(data.hour, '时柱') + '\n'

  s += '\n■ 日主\n'
  s += data.dayMasterAnalysis + '\n'

  if (data.structure) {
    s += '\n■ 格局\n'
    s += data.structure.name + '：' + data.structure.description + '\n'
  }

  s += '\n■ 月令\n'
  s += data.monthCommand.impact + '\n'

  // 五行分布与喜忌提示
  s += '\n■ 五行分布\n'
  let maxElem = ELEMENT_ORDER[0]
  let minElem = ELEMENT_ORDER[0]
  let maxCount = -1
  let minCount = 99
  let parts: string[] = []
  for (let i = 0; i < ELEMENT_ORDER.length; i++) {
    const e = ELEMENT_ORDER[i]
    const c = data.fiveElements.get(e) || 0
    parts.push(e + c)
    if (c > maxCount) { maxCount = c; maxElem = e }
    if (c < minCount) { minCount = c; minElem = e }
  }
  s += parts.join('  ') + '\n'
  if (minCount === 0) {
    s += '命局缺' + minElem + '，传统上可从方位、颜色、职业方向适当补益，亦可随缘而安，不必强求。\n'
  }
  if (maxCount >= 3) {
    s += '命中' + maxElem + '偏旺，主该行能量过剩，宜以泄化生克之法调和，顺势而为。\n'
  }

  if (data.nayin) {
    s += '\n■ 纳音\n'
    s += '年柱' + data.nayin.year.name + ' · 月柱' + data.nayin.month.name +
      ' · 日柱' + data.nayin.day.name + ' · 时柱' + data.nayin.hour.name + '\n'
  }

  if (data.shensha) {
    s += '\n■ 神煞\n'
    s += data.shensha.summary + '\n'
    const shown = data.shensha.entries.slice(0, 5)
    for (let i = 0; i < shown.length; i++) {
      const e = shown[i]
      s += '· ' + e.name + '（' + e.pillar + '）：' + e.description + '\n'
    }
  }

  if (data.mingGong && data.taiYuan) {
    s += '\n■ 命宫 · 胎元\n'
    s += '命宫' + data.mingGong.stem + data.mingGong.branch +
      ' · 胎元' + data.taiYuan.stem + data.taiYuan.branch + '\n'
  }

  if (data.dayun) {
    s += '\n■ 大运\n'
    s += data.dayun.description + '\n'
    const cycles = data.dayun.cycles.slice(0, 4)
    for (let i = 0; i < cycles.length; i++) {
      const c = cycles[i]
      s += '· ' + c.ageStart + '-' + c.ageEnd + '岁 ' + c.stem + c.branch +
        '（' + c.tenGod + (c.nayin ? ' · ' + c.nayin : '') + '）：' + c.description + '\n'
    }
    s += '……\n'
  }

  if (data.liunian) {
    s += '\n■ 流年\n'
    s += data.liunian.description + '\n'
  }

  s += '\n—— 以上内容由离线规则引擎基于传统命理生成，仅供文化娱乐参考。\n'
  return s
}

export interface IChingReportInput {
  originalHex: Hexagram
  changedHex?: Hexagram
  mutualHex: Hexagram
  oppositeHex: Hexagram
  inverseHex: Hexagram
  tiYong: TiYongResult
  movingIndexes: number[]
  lineDetails: LineDetail[]
}

export function buildOfflineIChingReport(input: IChingReportInput): string {
  const h = input.originalHex
  let s = ''
  s += '【天道玄机 · 离线详析】\n'

  s += '\n■ 本卦\n'
  s += h.symbol + ' ' + h.name + '（第' + h.number + '卦 · ' + h.pinyin + '）\n'
  s += '卦辞：' + h.judgement + '\n'
  s += '释义：' + h.meaning + '\n'

  if (h.tuanZhuan) { s += '\n■ 彖传\n' + h.tuanZhuan + '\n' }
  if (h.daXiang) { s += '\n■ 大象传\n' + h.daXiang + '\n' }
  if (h.xuGua) { s += '\n■ 序卦传\n' + h.xuGua + '\n' }

  s += '\n■ 变卦\n'
  if (input.changedHex) {
    s += input.changedHex.symbol + ' ' + input.changedHex.name +
      '（第' + input.changedHex.number + '卦）—— 动爻使卦象由' + h.name + '演化至' +
      input.changedHex.name + '\n'
  } else {
    s += '无动爻，卦象稳定，本卦即所问之全部信息。\n'
  }

  s += '\n■ 互卦 · 错卦 · 综卦\n'
  s += '互卦：' + input.mutualHex.symbol + input.mutualHex.name +
    '；错卦：' + input.oppositeHex.symbol + input.oppositeHex.name +
    '；综卦：' + input.inverseHex.symbol + input.inverseHex.name + '\n'

  s += '\n■ 体用生克\n'
  s += input.tiYong.ti + '（' + input.tiYong.tiElement + '）为体，' +
    input.tiYong.yong + '（' + input.tiYong.yongElement + '）为用\n'
  s += input.tiYong.relation + '：' + input.tiYong.description + '\n'

  s += '\n■ 动爻解读（' + input.movingIndexes.length + '个动爻）\n'
  if (input.movingIndexes.length === 0) {
    s += '六爻安静，主事态平稳，宜静观其变。\n'
  }
  for (let i = 0; i < input.movingIndexes.length; i++) {
    const idx = input.movingIndexes[i]
    if (idx < 0 || idx >= input.lineDetails.length) { continue }
    const d = input.lineDetails[idx]
    s += '第' + (idx + 1) + '爻：' + d.text + '\n'
    if (d.xiaoXiang) { s += '《象》曰：' + d.xiaoXiang + '\n' }
    if (d.yaoWei) { s += '爻位：' + d.yaoWei + '\n' }
    s += '时位：' + d.positionContext + '\n'
    s += '解析：' + d.analysis + '\n'
    if (d.allusion) { s += '典出：' + d.allusion + '\n' }
    s += '\n'
  }

  s += '—— 以上内容由离线规则引擎基于卦象生成，仅供文化娱乐参考。\n'
  return s
}

// 五行互化提示（供离线报告补充）
export function elementAdvice(selfElem: string, otherElem: string): string {
  const rel = getElementRelation(selfElem, otherElem)
  return rel.label + '：' + rel.desc
}
