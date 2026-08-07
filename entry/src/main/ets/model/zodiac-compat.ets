import { HEAVENLY_STEMS, EARTHLY_BRANCHES, STEM_ELEMENT, getElementRelation, ElementRelation } from '../common/constants'
import { BaziData } from './bazi-data'

// ============================================================
// 生肖配对 / 合婚引擎
// ============================================================

// 六合：子丑 寅亥 卯戌 辰酉 巳申 午未
const LIUHE: Map<string, string> = new Map<string, string>([
  ['子', '丑'], ['丑', '子'],
  ['寅', '亥'], ['亥', '寅'],
  ['卯', '戌'], ['戌', '卯'],
  ['辰', '酉'], ['酉', '辰'],
  ['巳', '申'], ['申', '巳'],
  ['午', '未'], ['未', '午'],
])

// 三合局：申子辰（水）、寅午戌（火）、巳酉丑（金）、亥卯未（木）
const SANHE: string[][] = [
  ['申', '子', '辰'],
  ['寅', '午', '戌'],
  ['巳', '酉', '丑'],
  ['亥', '卯', '未'],
]

// 六冲：子午 丑未 寅申 卯酉 辰戌 巳亥
const LIUCHONG: Map<string, string> = new Map<string, string>([
  ['子', '午'], ['午', '子'],
  ['丑', '未'], ['未', '丑'],
  ['寅', '申'], ['申', '寅'],
  ['卯', '酉'], ['酉', '卯'],
  ['辰', '戌'], ['戌', '辰'],
  ['巳', '亥'], ['亥', '巳'],
])

// 相刑：寅巳申（无恩之刑）、丑戌未（恃势之刑）、子卯（无礼之刑）、辰辰/午午/酉酉/亥亥（自刑）
const XING: Map<string, string[]> = new Map<string, string[]>([
  ['寅', ['巳', '申']], ['巳', ['寅', '申']], ['申', ['寅', '巳']],
  ['丑', ['戌', '未']], ['戌', ['丑', '未']], ['未', ['丑', '戌']],
  ['子', ['卯']], ['卯', ['子']],
])

// 相害：子未 丑午 寅巳 卯辰 申亥 酉戌
const XIHAI: Map<string, string> = new Map<string, string>([
  ['子', '未'], ['未', '子'],
  ['丑', '午'], ['午', '丑'],
  ['寅', '巳'], ['巳', '寅'],
  ['卯', '辰'], ['辰', '卯'],
  ['申', '亥'], ['亥', '申'],
  ['酉', '戌'], ['戌', '酉'],
])

export interface ZodiacRelation {
  type: string          // 'liuhe' | 'sanhe' | 'liuchong' | 'xiangxing' | 'xianghai' | 'ping'
  label: string         // 六合 / 三合 / 六冲 / 相刑 / 相害 / 平平
  description: string   // 详细说明
  score: number         // 0-100 配对评分
}

export function getZodiacRelation(branch1: string, branch2: string): ZodiacRelation {
  if (branch1 === branch2) {
    // 自刑：辰辰、午午、酉酉、亥亥
    if (branch1 === '辰' || branch1 === '午' || branch1 === '酉' || branch1 === '亥') {
      return {
        type: 'zixing',
        label: '自刑',
        description: branch1 + branch1 + '自刑，同属一相却易自我纠结、情绪内耗，宜修身养性、放平心态。',
        score: 35
      }
    }
    return {
      type: 'same',
      label: '比和',
      description: '同属一相，性情相近，如镜照影，和而不同。',
      score: 70
    }
  }

  // 六合
  const lh = LIUHE.get(branch1)
  if (lh === branch2) {
    return {
      type: 'liuhe',
      label: '六合',
      description: branch1 + branch2 + '六合，暗中相合，默契极佳，主贵人相助、姻缘和合。',
      score: 95
    }
  }

  // 三合
  for (let i = 0; i < SANHE.length; i++) {
    const group = SANHE[i]
    if (group.indexOf(branch1) >= 0 && group.indexOf(branch2) >= 0) {
      const element = i === 0 ? '水' : i === 1 ? '火' : i === 2 ? '金' : '木'
      return {
        type: 'sanhe',
        label: '三合（' + element + '局）',
        description: branch1 + branch2 + '同属' + element + '局三合，明合互助，主情谊深厚、事业协力。',
        score: 90
      }
    }
  }

  // 六冲
  const lc = LIUCHONG.get(branch1)
  if (lc === branch2) {
    return {
      type: 'liuchong',
      label: '六冲',
      description: branch1 + branch2 + '相冲，性情对立，冲突频繁，需以包容化解。',
      score: 30
    }
  }

  // 相刑
  const xing = XING.get(branch1)
  if (xing && xing.indexOf(branch2) >= 0) {
    return {
      type: 'xiangxing',
      label: '相刑',
      description: branch1 + branch2 + '相刑，互有刑伤，关系复杂，宜保持距离或以德化之。',
      score: 25
    }
  }

  // 相害
  const hai = XIHAI.get(branch1)
  if (hai === branch2) {
    return {
      type: 'xianghai',
      label: '相害',
      description: branch1 + branch2 + '相害，暗中不利，易生误解矛盾，需坦诚相待。',
      score: 40
    }
  }

  return {
    type: 'ping',
    label: '平平',
    description: branch1 + branch2 + '无特殊合冲，关系平淡，可正常交往。',
    score: 60
  }
}

// ============================================================
// 八字合婚（简化版）：以日柱为主，看日干五行生克与日支合冲
// ============================================================

export interface HehunResult {
  overallScore: number         // 综合评分 0-100
  level: string                // 吉 / 中吉 / 平 / 慎
  stemRelation: ElementRelation  // 日干五行关系
  branchRelation: ZodiacRelation // 日支关系
  summary: string              // 综合评语
}

export function calculateHehun(
  maleDayStem: string, maleDayBranch: string,
  femaleDayStem: string, femaleDayBranch: string
): HehunResult {
  const maleElem = STEM_ELEMENT.get(maleDayStem) || ''
  const femaleElem = STEM_ELEMENT.get(femaleDayStem) || ''
  const stemRel = getElementRelation(maleElem, femaleElem)
  const branchRel = getZodiacRelation(maleDayBranch, femaleDayBranch)

  // 日干生克评分
  let stemScore = 60
  if (stemRel.label === '比和') stemScore = 75
  else if (stemRel.label === '生我' || stemRel.label === '我生') stemScore = 70
  else if (stemRel.label === '我克' || stemRel.label === '克我') stemScore = 45

  const overallScore = Math.round(stemScore * 0.4 + branchRel.score * 0.6)

  let level: string
  if (overallScore >= 80) level = '吉'
  else if (overallScore >= 65) level = '中吉'
  else if (overallScore >= 50) level = '平'
  else level = '慎'

  let summary = '日干' + maleDayStem + '(' + maleElem + ') 与 ' + femaleDayStem + '(' + femaleElem + ') ' + stemRel.label + '；'
  summary += '日支' + maleDayBranch + femaleDayBranch + branchRel.label + '。'
  summary += '综合评分 ' + overallScore + ' 分，属"' + level + '"。'
  if (overallScore >= 80) {
    summary += '天作之合，宜珍惜缘分。'
  } else if (overallScore >= 65) {
    summary += '整体和睦，小处需磨合。'
  } else if (overallScore >= 50) {
    summary += '缘分平平，需双方共同努力经营。'
  } else {
    summary += '冲克较多，宜谨慎相处，以德化之。'
  }

  return {
    overallScore,
    level,
    stemRelation: stemRel,
    branchRelation: branchRel,
    summary
  }
}

// ============================================================
// 完整八字合婚（双方四柱）：日干 + 日支 + 生肖 + 纳音 + 五行互补
// ============================================================
export interface HehunFullResult {
  overallScore: number
  level: string
  stemRelation: ElementRelation
  branchRelation: ZodiacRelation
  zodiacRelation: ZodiacRelation
  nayinText: string
  complementText: string
  summary: string
}

function relationScore(rel: ZodiacRelation): number {
  return rel.score
}

function elementScore(label: string): number {
  if (label === '比和') return 75
  if (label === '生我' || label === '我生') return 70
  if (label === '我克' || label === '克我') return 45
  return 60
}

export function calculateHehunFull(male: BaziData, female: BaziData): HehunFullResult {
  const maleElem = STEM_ELEMENT.get(male.dayMaster) || ''
  const femaleElem = STEM_ELEMENT.get(female.dayMaster) || ''
  const stemRel = getElementRelation(maleElem, femaleElem)
  const branchRel = getZodiacRelation(male.day.branch, female.day.branch)
  const zodiacRel = getZodiacRelation(male.year.branch, female.year.branch)

  // 纳音：日柱纳音五行是否相生/相同
  const maleNayin = male.day.nayinElement || ''
  const femaleNayin = female.day.nayinElement || ''
  let nayinScore = 60
  let nayinText = ''
  if (maleNayin.length > 0 && femaleNayin.length > 0) {
    const rel = getElementRelation(maleNayin, femaleNayin)
    nayinScore = rel.label === '比和' ? 80 : (rel.label === '生我' || rel.label === '我生') ? 75 : 50
    nayinText = male.day.nayin + '（' + maleNayin + '） vs ' + female.day.nayin + '（' + femaleNayin + '）· ' + rel.label
  } else {
    nayinText = '日柱纳音暂无'
  }

  // 五行互补：统计双方日主所在五行，缺项互补提示
  const maleCounts: string[] = []
  const femaleCounts: string[] = []
  for (let i = 0; i < 5; i++) {
    const e = ['木', '火', '土', '金', '水'][i]
    maleCounts.push(e + (male.fiveElements.get(e) || 0))
    femaleCounts.push(e + (female.fiveElements.get(e) || 0))
  }
  let complementText = '男命：' + maleCounts.join(' ') + '；女命：' + femaleCounts.join(' ')
  const maleMissing = ['木', '火', '土', '金', '水'].filter(e => (male.fiveElements.get(e) || 0) === 0)
  const femaleMissing = ['木', '火', '土', '金', '水'].filter(e => (female.fiveElements.get(e) || 0) === 0)
  const mutual = maleMissing.filter(e => femaleMissing.indexOf(e) < 0)
  if (mutual.length > 0) {
    complementText += '；男命所缺' + maleMissing.join('、') + '，女命可补' + mutual.join('、')
  }

  const overallScore = Math.round(
    elementScore(stemRel.label) * 0.3 +
    relationScore(branchRel) * 0.4 +
    relationScore(zodiacRel) * 0.2 +
    nayinScore * 0.1
  )

  let level = '吉'
  if (overallScore >= 85) level = '上吉'
  else if (overallScore >= 70) level = '吉'
  else if (overallScore >= 55) level = '中吉'
  else if (overallScore >= 40) level = '平'
  else level = '慎'

  let summary = '日干' + male.dayMaster + '(' + maleElem + ')与' + female.dayMaster + '(' + femaleElem + ')' +
    stemRel.label + '；日支' + branchRel.label + '；生肖' + zodiacRel.label + '。'
  summary += '综合评分 ' + overallScore + ' 分，属"' + level + '"。'
  if (overallScore >= 85) summary += '天作之合，五行相济，宜珍惜。'
  else if (overallScore >= 70) summary += '整体和睦，小处磨合即可长久。'
  else if (overallScore >= 55) summary += '缘分尚可，需双方用心经营。'
  else if (overallScore >= 40) summary += '冲克并存，宜以包容与理解为先。'
  else summary += '矛盾较多，建议谨慎相处、以德化之。'

  return {
    overallScore: overallScore,
    level: level,
    stemRelation: stemRel,
    branchRelation: branchRel,
    zodiacRelation: zodiacRel,
    nayinText: nayinText,
    complementText: complementText,
    summary: summary
  }
}

// ============================================================
// 生肖速查表（全部 12 生肖两两关系）
// ============================================================
export interface ZodiacPairEntry {
  branch1: string
  branch2: string
  relation: ZodiacRelation
}

export function getAllZodiacPairs(branch: string): ZodiacPairEntry[] {
  const result: ZodiacPairEntry[] = []
  for (let i = 0; i < EARTHLY_BRANCHES.length; i++) {
    const b = EARTHLY_BRANCHES[i]
    if (b === branch) continue
    result.push({
      branch1: branch,
      branch2: b,
      relation: getZodiacRelation(branch, b)
    })
  }
  return result
}
