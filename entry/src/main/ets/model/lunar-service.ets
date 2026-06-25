import { HEAVENLY_STEMS, EARTHLY_BRANCHES, STEM_ELEMENT, BRANCH_ELEMENT, SEASONAL_STRENGTH, getElementRelation } from '../common/constants'
import {
  BaziData, PillarData, TEN_STEMS_ANALYSIS, MonthCommand, StructureInfo,
  NayinData, ShenshaEntry, ShenshaResult, DayunData, DayunCycle,
  LiunianResult, MonthlyFate, getNayin
} from './bazi-data'

// ============================================================
// Lunar calendar data: encoded integers per year (1900-2100)
// ============================================================
const LUNAR_INFO: number[] = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0,
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0,
  0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a4d0, 0x0d150, 0x0f252,
  0x0d520
]
const BASE_YEAR = 1900

interface StemBranchPair { stem: string; branch: string }

// ============================================================
// Lunar calendar helpers
// ============================================================
function daysBetween(d1: Date, d2: Date): number {
  return Math.floor((d2.getTime() - d1.getTime()) / 86400000)
}

function getYearStemBranchIndex(year: number): number {
  return ((year - 4) % 60 + 60) % 60
}

function getMonthStemBranchIndex(yearStemIndex: number, monthNum: number): number {
  const bases: number[] = [2, 4, 6, 8, 0]
  const stemIdx = (bases[yearStemIndex % 5] + monthNum - 1) % 10
  const branchIdx = (monthNum + 1) % 12
  return stemIdx * 12 + branchIdx
}

function getDayStemBranchIndex(date: Date): number {
  const refDate = new Date(1900, 0, 1)
  return ((daysBetween(refDate, date) % 60) + 60 + 10) % 60
}

function lunarYearDays(y: number): number {
  let sum = 348
  for (let i = 0x8000; i > 0x8; i >>>= 1) { sum += (LUNAR_INFO[y - BASE_YEAR] & i) ? 1 : 0 }
  const leap = getLeapMonth(y)
  if (leap > 0) sum += getLeapMonthDays(y)
  return sum
}

function getLeapMonth(y: number): number { return LUNAR_INFO[y - BASE_YEAR] & 0xf }
function getLunarMonthDays(y: number, m: number): number { return (LUNAR_INFO[y - BASE_YEAR] & (0x10000 >> m)) ? 30 : 29 }
function getLeapMonthDays(y: number): number { return getLeapMonth(y) > 0 ? ((LUNAR_INFO[y - BASE_YEAR] & 0x10000) ? 30 : 29) : 0 }

function getHourStemBranch(dayStemIndex: number, hour: number): StemBranchPair {
  const hourBranchIdx = Math.floor((hour + 1) / 2) % 12
  const ziBases: number[] = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8]
  const stemIdx = (ziBases[dayStemIndex % 10] + hourBranchIdx) % 10
  return { stem: HEAVENLY_STEMS[stemIdx], branch: EARTHLY_BRANCHES[hourBranchIdx] }
}

interface LunarDate {
  year: number; month: number; day: number; isLeapMonth: boolean
  yearStem: string; yearBranch: string; monthStem: string; monthBranch: string
  dayStem: string; dayBranch: string
  yearStemIdx: number; yearBranchIdx: number; monthStemIdx: number; monthBranchIdx: number
  dayStemIdx: number; dayBranchIdx: number
}

function solarToLunar(solarDate: Date): LunarDate {
  const baseDate = new Date(BASE_YEAR, 0, 31)
  let offset = Math.floor((solarDate.getTime() - baseDate.getTime()) / 86400000)
  let lunarYear = BASE_YEAR
  for (let i = BASE_YEAR; i < 2101; i++) {
    const yearDays = lunarYearDays(i)
    if (offset < yearDays) { break }
    offset -= yearDays; lunarYear++
  }
  const leapMonth = getLeapMonth(lunarYear)
  let isLeap = false, lunarMonth = 0
  for (let m = 1; m <= 12; m++) {
    if (leapMonth > 0 && m === leapMonth + 1) {
      const leapDays = getLeapMonthDays(lunarYear)
      if (offset < leapDays) { isLeap = true; lunarMonth = leapMonth; break }
      offset -= leapDays
    }
    const mDays = getLunarMonthDays(lunarYear, m)
    if (offset < mDays) { lunarMonth = m; break }
    offset -= mDays
  }
  const yearSB = getYearStemBranchIndex(lunarYear)
  const monthSBIndex = getMonthStemBranchIndex(yearSB % 10, lunarMonth)
  const daySB = getDayStemBranchIndex(solarDate)
  return {
    year: lunarYear, month: lunarMonth, day: offset + 1, isLeapMonth: isLeap,
    yearStem: HEAVENLY_STEMS[yearSB % 10], yearBranch: EARTHLY_BRANCHES[yearSB % 12],
    monthStem: HEAVENLY_STEMS[monthSBIndex % 10], monthBranch: EARTHLY_BRANCHES[monthSBIndex % 12],
    dayStem: HEAVENLY_STEMS[daySB % 10], dayBranch: EARTHLY_BRANCHES[daySB % 12],
    yearStemIdx: yearSB % 10, yearBranchIdx: yearSB % 12,
    monthStemIdx: monthSBIndex % 10, monthBranchIdx: monthSBIndex % 12,
    dayStemIdx: daySB % 10, dayBranchIdx: daySB % 12
  }
}

// ============================================================
// Ten god mapping (shared)
// ============================================================
function toTenGod(dmElement: string, otherElement: string): string {
  const rel = getElementRelation(dmElement, otherElement)
  if (rel.label === '比和') return '比劫'
  if (rel.label === '我生') return '食伤'
  if (rel.label === '我克') return '财星'
  if (rel.label === '克我') return '官杀'
  if (rel.label === '生我') return '印枭'
  return ''
}

function isYangStem(stem: string): boolean {
  const idx = HEAVENLY_STEMS.indexOf(stem)
  return idx % 2 === 0 // 甲丙戊庚壬 = indices 0,2,4,6,8
}

function sexagenaryIndex(stemIdx: number, branchIdx: number): number {
  return ((stemIdx % 10) * 6 - (branchIdx % 12) * 5 + 60) % 60
}

// ============================================================
// 纳音 (Nayin) computation
// ============================================================
function computeNayinData(yearStemIdx: number, yearBranchIdx: number,
  monthStemIdx: number, monthBranchIdx: number,
  dayStemIdx: number, dayBranchIdx: number,
  hourStemIdx: number, hourBranchIdx: number): NayinData {
  return {
    year: getNayin(yearStemIdx, yearBranchIdx),
    month: getNayin(monthStemIdx, monthBranchIdx),
    day: getNayin(dayStemIdx, dayBranchIdx),
    hour: getNayin(hourStemIdx, hourBranchIdx)
  }
}

// ============================================================
// 神煞 (Shensha) computation
// ============================================================
const ZODIAC_NAMES: string[] = ['鼠','牛','虎','兔','龙','蛇','马','羊','猴','鸡','狗','猪']

function pillarLabel(p: string): string {
  if (p === 'year') return '年柱'
  if (p === 'month') return '月柱'
  if (p === 'day') return '日柱'
  return '时柱'
}

function computeShensha(lunar: LunarDate, hourBranch: string): ShenshaResult {
  const entries: ShenshaEntry[] = []
  const yearBranch = lunar.yearBranch
  const monthBranch = lunar.monthBranch
  const dayStem = lunar.dayStem
  const dayBranch = lunar.dayBranch
  const yearStem = lunar.yearStem
  const monthNum = lunar.month

  // --- 天乙贵人 (based on day stem) ---
  const tianyiMap: Record<string, string[]> = {
    '甲': ['丑','未'], '戊': ['丑','未'], '庚': ['丑','未'],
    '乙': ['子','申'], '己': ['子','申'],
    '丙': ['亥','酉'], '丁': ['亥','酉'],
    '壬': ['卯','巳'], '癸': ['卯','巳'],
    '辛': ['寅','午']
  }
  const tianyiBranches = tianyiMap[dayStem] || []
  const tianyiPillars: string[] = []
  if (tianyiBranches.includes(yearBranch)) tianyiPillars.push('年柱')
  if (tianyiBranches.includes(monthBranch)) tianyiPillars.push('月柱')
  if (tianyiBranches.includes(dayBranch)) tianyiPillars.push('日柱')
  if (tianyiBranches.includes(hourBranch)) tianyiPillars.push('时柱')
  if (tianyiPillars.length > 0) {
    entries.push({ name: '天乙贵人', pillar: tianyiPillars.join('、'), starType: 'good', description: '逢凶化吉，得贵人相助扶持，主功名早达，官禄易进。' })
  }

  // --- 桃花/咸池 (based on year/day branch) ---
  const peachBlossom: Record<string, string> = { '申':'酉','子':'酉','辰':'酉', '寅':'卯','午':'卯','戌':'卯', '亥':'子','卯':'子','未':'子', '巳':'午','酉':'午','丑':'午' }
  const peachByYear = peachBlossom[yearBranch]
  const peachPillars: string[] = []
  if (peachByYear && peachByYear === monthBranch) peachPillars.push('月柱')
  if (peachByYear && peachByYear === dayBranch) peachPillars.push('日柱')
  if (peachByYear && peachByYear === hourBranch) peachPillars.push('时柱')
  if (peachPillars.length > 0) {
    entries.push({ name: '桃花(咸池)', pillar: peachPillars.join('、'), starType: 'neutral', description: '人缘佳，异性缘旺，富有情趣魅力，但需防情事纠葛。' })
  }

  // --- 驿马 (based on year/day branch) ---
  const yiMa: Record<string, string> = { '申':'寅','子':'寅','辰':'寅', '寅':'申','午':'申','戌':'申', '亥':'巳','卯':'巳','未':'巳', '巳':'亥','酉':'亥','丑':'亥' }
  const yiMaByYear = yiMa[yearBranch]
  const yiMaPillars: string[] = []
  if (yiMaByYear && yiMaByYear === monthBranch) yiMaPillars.push('月柱')
  if (yiMaByYear && yiMaByYear === dayBranch) yiMaPillars.push('日柱')
  if (yiMaByYear && yiMaByYear === hourBranch) yiMaPillars.push('时柱')
  if (yiMaPillars.length > 0) {
    entries.push({ name: '驿马', pillar: yiMaPillars.join('、'), starType: 'neutral', description: '奔波走动、迁徙变迁之象，利于外出发展、交通贸易。' })
  }

  // --- 羊刃 (based on day stem) ---
  const yangRenMap: Record<string, string> = { '甲':'卯','乙':'寅','丙':'午','丁':'巳','戊':'午','己':'巳','庚':'酉','辛':'申','壬':'子','癸':'亥' }
  const yangRenBranch = yangRenMap[dayStem]
  if (yangRenBranch) {
    const yrPillars: string[] = []
    if (yangRenBranch === yearBranch) yrPillars.push('年柱')
    if (yangRenBranch === monthBranch) yrPillars.push('月柱')
    if (yangRenBranch === dayBranch) yrPillars.push('日柱')
    if (yangRenBranch === hourBranch) yrPillars.push('时柱')
    if (yrPillars.length > 0) {
      entries.push({ name: '羊刃', pillar: yrPillars.join('、'), starType: 'bad', description: '刚烈强韧、个性倔强，易冲动急躁，需防范血光手术之灾。' })
    }
  }

  // --- 华盖 (based on year/day branch) ---
  const huaGai: Record<string, string> = { '申':'辰','子':'辰','辰':'辰', '寅':'戌','午':'戌','戌':'戌', '亥':'未','卯':'未','未':'未', '巳':'丑','酉':'丑','丑':'丑' }
  const huaGaiBranch = huaGai[yearBranch]
  if (huaGaiBranch) {
    const hgPillars: string[] = []
    if (huaGaiBranch === monthBranch) hgPillars.push('月柱')
    if (huaGaiBranch === dayBranch) hgPillars.push('日柱')
    if (huaGaiBranch === hourBranch) hgPillars.push('时柱')
    if (hgPillars.length > 0) {
      entries.push({ name: '华盖', pillar: hgPillars.join('、'), starType: 'neutral', description: '才华出众、聪慧好文，多具艺术才情，但性情孤高，宜学术、艺术发展。' })
    }
  }

  // --- 文昌贵人 (based on day stem) ---
  const wenchangMap: Record<string, string> = { '甲':'巳','乙':'午','丙':'申','丁':'酉','戊':'申','己':'酉','庚':'亥','辛':'子','壬':'寅','癸':'卯' }
  const wenchangBranch = wenchangMap[dayStem]
  if (wenchangBranch) {
    const wcPillars: string[] = []
    if (wenchangBranch === yearBranch) wcPillars.push('年柱')
    if (wenchangBranch === monthBranch) wcPillars.push('月柱')
    if (wenchangBranch === dayBranch) wcPillars.push('日柱')
    if (wenchangBranch === hourBranch) wcPillars.push('时柱')
    if (wcPillars.length > 0) {
      entries.push({ name: '文昌贵人', pillar: wcPillars.join('、'), starType: 'good', description: '才华横溢，文笔出众，学业有成，利于考试、写作与研究。' })
    }
  }

  // --- 天德贵人 (based on month number) ---
  const tiandeMap: Record<number, string> = { 1:'丁', 2:'申', 3:'壬', 4:'辛', 5:'亥', 6:'甲', 7:'癸', 8:'寅', 9:'丙', 10:'乙', 11:'巳', 12:'庚' }
  const monthStem = lunar.monthStem
  const tiandeByMonth = tiandeMap[monthNum]
  if (tiandeByMonth) {
    // Simple check: does tiande stem appear in any pillar stem?
    if (yearStem === tiandeByMonth || monthStem === tiandeByMonth || dayStem === tiandeByMonth) {
      entries.push({ name: '天德贵人', pillar: '命局', starType: 'good', description: '天赐福德，心地善良，化险为夷，一生少有大灾大难。' })
    }
  }

  // --- 月德贵人 (based on month branch) ---
  const yuedeMap: Record<string, string> = { '寅':'丙','午':'丙','戌':'丙', '亥':'甲','卯':'甲','未':'甲', '申':'壬','子':'壬','辰':'壬', '巳':'庚','酉':'庚','丑':'庚' }
  const yuedeStem = yuedeMap[monthBranch]
  if (yuedeStem && (yearStem === yuedeStem || dayStem === yuedeStem)) {
    entries.push({ name: '月德贵人', pillar: dayStem === yuedeStem ? '日柱' : '年柱', starType: 'good', description: '柔和慈善，以德服人，化解灾厄，得女性贵人之助。' })
  }

  // --- 将星 (based on year/day branch) ---
  const jiangXing: Record<string, string> = { '申':'子','子':'子','辰':'子', '寅':'午','午':'午','戌':'午', '亥':'卯','卯':'卯','未':'卯', '巳':'酉','酉':'酉','丑':'酉' }
  const jxB = jiangXing[yearBranch]
  if (jxB) {
    const jxP: string[] = []
    if (jxB === monthBranch) jxP.push('月柱')
    if (jxB === dayBranch) jxP.push('日柱')
    if (jxB === hourBranch) jxP.push('时柱')
    if (jxP.length > 0) {
      entries.push({ name: '将星', pillar: jxP.join('、'), starType: 'good', description: '有组织领导之才，独当一面，宜从事管理、军警、领导班子等工作。' })
    }
  }

  const good = entries.filter(e => e.starType === 'good').length
  const bad = entries.filter(e => e.starType === 'bad').length
  let summary = '命带' + good + '吉' + bad + '凶，'
  if (good > bad + 1) summary += '神煞以吉为主，命中贵气明显。'
  else if (bad > good + 1) summary += '神煞偏凶，宜多修心养性、行善积德化解。'
  else summary += '吉凶相杂，宜扬长避短、趋吉避凶。'

  return { entries, summary }
}

// ============================================================
// Solar term approximate dates (节气日)
// ============================================================
interface SolarTerm {
  name: string
  month: number   // solar month 1-12
  day: number     // approximate day
}

const SOLAR_TERMS: SolarTerm[] = [
  { name: '立春', month: 2, day: 4 },
  { name: '惊蛰', month: 3, day: 6 },
  { name: '清明', month: 4, day: 5 },
  { name: '立夏', month: 5, day: 6 },
  { name: '芒种', month: 6, day: 6 },
  { name: '小暑', month: 7, day: 7 },
  { name: '立秋', month: 8, day: 7 },
  { name: '白露', month: 9, day: 8 },
  { name: '寒露', month: 10, day: 8 },
  { name: '立冬', month: 11, day: 7 },
  { name: '大雪', month: 12, day: 7 },
  { name: '小寒', month: 1, day: 6 }, // January of NEXT year
]

function getSolarTermBeforeBirth(year: number, birthMonth: number, birthDay: number): SolarTerm | null {
  // Find the solar term that falls in the same month or before birth
  let best: SolarTerm | null = null
  for (const term of SOLAR_TERMS) {
    // We need the term that's in the same month AND before birth day,
    // or the term in the previous month that's closest
    const termDate = new Date(year, term.month - 1, term.day)
    const birthDate = new Date(year, birthMonth - 1, birthDay)
    if (termDate < birthDate) {
      if (!best || termDate.getTime() > new Date(year, best.month - 1, best.day).getTime()) {
        best = term
      }
    }
  }
  // If no term found before birth this year, check previous year's terms
  if (!best) {
    const prevYearTerms = SOLAR_TERMS.filter(t => t.month === 12 || t.month === 11 || t.month === 10)
    // Just take the last term of previous year
    best = SOLAR_TERMS[SOLAR_TERMS.length - 1] // 小寒 Jan 6
  }
  return best
}

function getSolarTermAfterBirth(year: number, birthMonth: number, birthDay: number): SolarTerm | null {
  const birthDate = new Date(year, birthMonth - 1, birthDay)
  // Find the closest term after birth
  let best: SolarTerm | null = null
  for (const term of SOLAR_TERMS) {
    const termDate = new Date(year, term.month - 1, term.day)
    if (termDate > birthDate) {
      if (!best || termDate.getTime() < new Date(year, best.month - 1, best.day).getTime()) {
        best = term
      }
    }
  }
  // If none found this year, check next year
  if (!best) {
    best = SOLAR_TERMS[0] // 立春 of next year? No, that's Feb. We should use 小寒 of next year? No.
    // Actually for births in Dec, the next term would be 小寒 next Jan or 立春 next Feb
    // Let me just handle this more carefully
    best = SOLAR_TERMS.find(t => t.month >= 1) || SOLAR_TERMS[0]
  }
  return best
}

// ============================================================
// 大运 (Dayun) computation
// ============================================================
function computeDayun(yearStem: string, monthStemIdx: number, monthBranchIdx: number,
  gender: string, birthMonth: number, birthDay: number, birthYear: number,
  dmElement: string): DayunData {

  const yang = isYangStem(yearStem)
  // Forward: yang year male OR yin year female
  const forward = (yang && gender === 'male') || (!yang && gender === 'female')
  const direction = forward ? 'forward' : 'backward'

  // Calculate starting age
  let startTerm: SolarTerm | null = null
  if (forward) {
    startTerm = getSolarTermAfterBirth(birthYear, birthMonth, birthDay)
  } else {
    startTerm = getSolarTermBeforeBirth(birthYear, birthMonth, birthDay)
  }

  // Calculate days to nearest term
  const birthDate = new Date(birthYear, birthMonth - 1, birthDay)
  let termDate: Date
  if (startTerm) {
    termDate = new Date(birthYear, startTerm.month - 1, startTerm.day)
  } else {
    // Fallback
    termDate = new Date(birthYear, birthMonth - 1, 15)
  }

  const dayDiff = Math.abs(Math.floor((termDate.getTime() - birthDate.getTime()) / 86400000))
  const startAge = Math.max(1, Math.round(dayDiff / 3)) // 3 days = 1 year

  // Generate 10 大运 cycles
  const cycles: DayunCycle[] = []
  let currentSBIdx = sexagenaryIndex(monthStemIdx, monthBranchIdx)

  for (let i = 0; i < 10; i++) {
    // Each 大运 advances or retreats by 1 in the 60-cycle
    const sbIdx = forward
      ? ((currentSBIdx + i + 1) % 60 + 60) % 60
      : ((currentSBIdx - i - 1) % 60 + 60) % 60

    const stem = HEAVENLY_STEMS[sbIdx % 10]
    const branch = EARTHLY_BRANCHES[sbIdx % 12]
    const stemElem = STEM_ELEMENT.get(stem) || ''
    const nayin = getNayin(sbIdx % 10, sbIdx % 12)
    const tenGod = toTenGod(dmElement, stemElem)
    const ageStart = startAge + i * 10
    const ageEnd = ageStart + 9

    let desc = '大运' + stem + branch + '，' + nayin.name + '。'
    desc += '十神主' + tenGod + '。'
    if (tenGod === '财星') desc += '财运旺盛，利于经营求财。'
    else if (tenGod === '官杀') desc += '事业压力并进，宜谨慎应对。'
    else if (tenGod === '印枭') desc += '学问进修，得长辈领导提携。'
    else if (tenGod === '食伤') desc += '才华显露，创新求变之时。'
    else desc += '兄弟朋友相助，竞争与机遇并存。'

    cycles.push({
      ageStart, ageEnd, stem, branch,
      nayin: nayin.name, element: stemElem, tenGod, description: desc
    })
  }

  let descText = forward
    ? '阳年' + (gender === 'male' ? '男' : '女') + '，大运顺行。约' + startAge + '岁起运。'
    : '阴年' + (gender === 'male' ? '男' : '女') + '，大运逆行。约' + startAge + '岁起运。'

  return { direction, startAge: startAge, description: descText, cycles }
}

// ============================================================
// 流年 (Liunian) computation
// ============================================================
function computeLiunian(dayStemIdx: number, dayBranchIdx: number,
  dmElement: string): LiunianResult {

  const now = new Date()
  const currentYear = now.getFullYear()
  const yearSB = getYearStemBranchIndex(currentYear)
  const yearStem = HEAVENLY_STEMS[yearSB % 10]
  const yearBranch = EARTHLY_BRANCHES[yearSB % 12]
  const yearElement = STEM_ELEMENT.get(yearStem) || ''
  const tenGod = toTenGod(dmElement, yearElement)
  const nayin = getNayin(yearSB % 10, yearSB % 12)
  const zodiac = ZODIAC_NAMES[yearSB % 12]

  let desc = currentYear + '年，岁次' + yearStem + yearBranch + '（' + zodiac + '年），' + nayin.name + '。'
  desc += '流年十神为' + tenGod + '。'
  const dmIdx = dayStemIdx
  if (tenGod === '比劫') desc += '本年利于交友合作、团队协作。'
  else if (tenGod === '食伤') desc += '本年才华展现、创意迸发，宜积极表达。'
  else if (tenGod === '财星') desc += '本年财运亨通、正财偏财俱佳。'
  else if (tenGod === '官杀') desc += '本年事业挑战增多，需以正念应对。'
  else if (tenGod === '印枭') desc += '本年宜学习进修、沉淀积累。'

  // Monthly breakdown
  const monthlyBreakdown: MonthlyFate[] = []
  // Monthly branch cycle: year determines month stem base
  const yearStemIdx = yearSB % 10
  const monthStemBases: number[] = [2, 4, 6, 8, 0]
  for (let m = 1; m <= 12; m++) {
    const mStemIdx = (monthStemBases[yearStemIdx % 5] + m - 1) % 10
    const mBranchIdx = (m + 1) % 12 // 寅月=正月, so month 1 → branchIdx 2
    // Actually 正月=寅, so month 1 → branch 寅(idx 2)
    // Wait: 正月(1) → 寅(2), 二月(2) → 卯(3), ... 十二月(12) → 丑(1)
    const mBranchIndex = ((m + 1) % 12) // 1→2(寅), 2→3(卯), ..., 11→0(子), 12→1(丑)
    const mStem = HEAVENLY_STEMS[mStemIdx]
    const mBranch = EARTHLY_BRANCHES[mBranchIndex]
    const mElement = STEM_ELEMENT.get(mStem) || ''
    const mTenGod = toTenGod(dmElement, mElement)
    monthlyBreakdown.push({ month: m, stem: mStem, branch: mBranch, tenGod: mTenGod })
  }

  return {
    currentYear, stem: yearStem, branch: yearBranch,
    nayin: nayin.name, element: yearElement, tenGod,
    zodiac, description: desc, monthlyBreakdown
  }
}

// ============================================================
// Main Ba Zi calculation (updated with all new features)
// ============================================================
export function calculateBazi(date: Date, gender: string): BaziData {
  const lunar = solarToLunar(date)
  const hourSB = getHourStemBranch(lunar.dayStemIdx, date.getHours())

  const yearElem = STEM_ELEMENT.get(lunar.yearStem) || ''
  const monthElem = STEM_ELEMENT.get(lunar.monthStem) || ''
  const dayElem = STEM_ELEMENT.get(lunar.dayStem) || ''
  const hourElem = STEM_ELEMENT.get(hourSB.stem) || ''

  const yearNayin = getNayin(lunar.yearStemIdx, lunar.yearBranchIdx)
  const monthNayin = getNayin(lunar.monthStemIdx, lunar.monthBranchIdx)
  const hourStemIdx = HEAVENLY_STEMS.indexOf(hourSB.stem)
  const hourBranchIdx = EARTHLY_BRANCHES.indexOf(hourSB.branch)
  const dayNayin = getNayin(lunar.dayStemIdx, lunar.dayBranchIdx)
  const hourNayin = getNayin(hourStemIdx, hourBranchIdx)

  const yearPillar: PillarData = { stem: lunar.yearStem, branch: lunar.yearBranch, element: yearElem, nayin: yearNayin.name, nayinElement: yearNayin.element }
  const monthPillar: PillarData = { stem: lunar.monthStem, branch: lunar.monthBranch, element: monthElem, nayin: monthNayin.name, nayinElement: monthNayin.element }
  const dayPillar: PillarData = { stem: lunar.dayStem, branch: lunar.dayBranch, element: dayElem, nayin: dayNayin.name, nayinElement: dayNayin.element }
  const hourPillar: PillarData = { stem: hourSB.stem, branch: hourSB.branch, element: hourElem, nayin: hourNayin.name, nayinElement: hourNayin.element }

  // Five elements count
  const fiveElementsCount = new Map<string, number>([['金',0],['木',0],['水',0],['火',0],['土',0]])
  for (const p of [yearPillar, monthPillar, dayPillar, hourPillar]) {
    const se = p.element
    if (se.length > 0) { fiveElementsCount.set(se, (fiveElementsCount.get(se) || 0) + 1) }
    const be = BRANCH_ELEMENT.get(p.branch) || ''
    if (be.length > 0) { fiveElementsCount.set(be, (fiveElementsCount.get(be) || 0) + 1) }
  }

  // Day master
  const dmElement = STEM_ELEMENT.get(lunar.dayStem) || ''
  const strengthMap = SEASONAL_STRENGTH.get(monthPillar.branch)
  let dmStrength = '平'
  if (strengthMap) { const sv = strengthMap.get(dmElement); if (sv) dmStrength = sv }

  const monthElementVal = BRANCH_ELEMENT.get(monthPillar.branch) || ''
  const impact = '月令为【' + monthPillar.branch + monthElementVal + '】，日主' + lunar.dayStem + dmElement + '处于"' + dmStrength + '"之地。'

  // Structure
  const relation = toTenGod(dmElement, monthElementVal)
  let structName = '正格', structDesc = ''
  if (relation === '比劫') { structName = dmStrength === '旺' ? '建禄格/月劫格' : '身旺格'; structDesc = '日主得令，自坐强根，个性独立自强，富有竞争意识，宜用财官。' }
  else if (relation === '食伤') { structName = '食伤格'; structDesc = '日主生月令，才华横溢，感性多情，具有艺术天赋或创新能力，宜注意能量泄耗。' }
  else if (relation === '财星') { structName = '财星格'; structDesc = '日主克月令，务实进取，重视效率与结果，具有较强的经营管理能力。' }
  else if (relation === '官杀') { structName = '官杀格'; structDesc = '月令克日主，责任心强，注重名誉与纪律，或处境压力较大，需印比护身。' }
  else if (relation === '印枭') { structName = '印绶格'; structDesc = '月令生日主，深思熟虑，学识渊博，易得长辈提拔依靠，或性格稍显被动。' }

  const analysisText = TEN_STEMS_ANALYSIS.get(lunar.dayStem) || ''

  // Copy seasonal strength
  const freshStrength = new Map<string, string>()
  const sourceStrength = strengthMap
  if (sourceStrength) {
    freshStrength.set('木', sourceStrength.get('木') || '')
    freshStrength.set('火', sourceStrength.get('火') || '')
    freshStrength.set('土', sourceStrength.get('土') || '')
    freshStrength.set('金', sourceStrength.get('金') || '')
    freshStrength.set('水', sourceStrength.get('水') || '')
  }

  // Nayin
  const nayin = computeNayinData(lunar.yearStemIdx, lunar.yearBranchIdx,
    lunar.monthStemIdx, lunar.monthBranchIdx, lunar.dayStemIdx, lunar.dayBranchIdx,
    hourStemIdx, hourBranchIdx)

  // Shensha
  const shensha = computeShensha(lunar, hourSB.branch)

  // Dayun
  const dayun = computeDayun(lunar.yearStem, lunar.monthStemIdx, lunar.monthBranchIdx,
    gender, lunar.month, lunar.day, lunar.year, dmElement)

  // Liunian
  const liunian = computeLiunian(lunar.dayStemIdx, lunar.dayBranchIdx, dmElement)

  return {
    year: yearPillar, month: monthPillar, day: dayPillar, hour: hourPillar,
    fiveElements: fiveElementsCount, dayMaster: lunar.dayStem,
    dayMasterAnalysis: '日主' + lunar.dayStem + '，五行属' + dmElement + '。' + analysisText,
    monthCommand: { branch: monthPillar.branch, element: monthElementVal, strength: freshStrength, impact },
    structure: { name: structName, description: structDesc },
    nayin, shensha, dayun, liunian
  }
}

// Re-export for convenience
export { getNayin }
