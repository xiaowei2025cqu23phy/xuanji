import { HEAVENLY_STEMS, EARTHLY_BRANCHES, STEM_ELEMENT, BRANCH_ELEMENT, SEASONAL_STRENGTH } from '../common/constants'
import { BaziData, PillarData, TEN_STEMS_ANALYSIS, MonthCommand, StructureInfo } from './bazi-data'

// Lunar calendar data: encoded as 4-byte integers per year (1900-2100)
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

interface StemBranchPair {
  stem: string
  branch: string
}

function daysBetween(d1: Date, d2: Date): number {
  const msPerDay = 24 * 60 * 60 * 1000
  return Math.floor((d2.getTime() - d1.getTime()) / msPerDay)
}

function getYearStemBranchIndex(year: number): number {
  return ((year - 4) % 60 + 60) % 60
}

function getMonthStemBranchIndex(yearStemIndex: number, monthNum: number): number {
  const bases: number[] = [2, 4, 6, 8, 0]
  const monthStemBase = bases[yearStemIndex % 5]
  const stemIndex = (monthStemBase + monthNum - 1) % 10
  const branchIndex = (monthNum + 1) % 12
  return stemIndex * 12 + branchIndex
}

function getDayStemBranchIndex(date: Date): number {
  const refDate = new Date(1900, 0, 1)
  const diff = daysBetween(refDate, date)
  const index = ((diff % 60) + 60 + 10) % 60
  return index
}

function lunarYearDays(y: number): number {
  let sum = 348
  for (let i = 0x8000; i > 0x8; i >>>= 1) {
    sum += (LUNAR_INFO[y - BASE_YEAR] & i) ? 1 : 0
  }
  const leap = getLeapMonth(y)
  if (leap > 0) {
    sum += getLeapMonthDays(y)
  }
  return sum
}

function getLeapMonth(y: number): number {
  return LUNAR_INFO[y - BASE_YEAR] & 0xf
}

function getLunarMonthDays(y: number, m: number): number {
  return (LUNAR_INFO[y - BASE_YEAR] & (0x10000 >> m)) ? 30 : 29
}

function getLeapMonthDays(y: number): number {
  if (getLeapMonth(y) > 0) {
    return (LUNAR_INFO[y - BASE_YEAR] & 0x10000) ? 30 : 29
  }
  return 0
}

function getHourStemBranch(dayStemIndex: number, hour: number): StemBranchPair {
  const hourBranchIdx = Math.floor((hour + 1) / 2) % 12
  const ziBases: number[] = [0, 2, 4, 6, 8, 0, 2, 4, 6, 8]
  const ziStemBase = ziBases[dayStemIndex % 10]
  const stemIdx = (ziStemBase + hourBranchIdx) % 10
  let result: StemBranchPair = {
    stem: HEAVENLY_STEMS[stemIdx],
    branch: EARTHLY_BRANCHES[hourBranchIdx]
  }
  return result
}

interface LunarDate {
  year: number
  month: number
  day: number
  isLeapMonth: boolean
  yearStem: string
  yearBranch: string
  monthStem: string
  monthBranch: string
  dayStem: string
  dayBranch: string
}

function solarToLunar(solarDate: Date): LunarDate {
  const baseDate = new Date(BASE_YEAR, 0, 31)
  let offset = Math.floor((solarDate.getTime() - baseDate.getTime()) / 86400000)

  let lunarYear = BASE_YEAR
  for (let i = BASE_YEAR; i < 2101; i++) {
    const yearDays = lunarYearDays(i)
    if (offset < yearDays) {
      break
    }
    offset -= yearDays
    lunarYear++
  }

  const leapMonth = getLeapMonth(lunarYear)
  let isLeap = false
  let lunarMonth = 0

  for (let m = 1; m <= 12; m++) {
    if (leapMonth > 0 && m === leapMonth + 1) {
      const leapDays = getLeapMonthDays(lunarYear)
      if (offset < leapDays) {
        isLeap = true
        lunarMonth = leapMonth
        break
      }
      offset -= leapDays
    }
    const mDays = getLunarMonthDays(lunarYear, m)
    if (offset < mDays) {
      lunarMonth = m
      break
    }
    offset -= mDays
  }

  const lunarDay = offset + 1
  const yearSB = getYearStemBranchIndex(lunarYear)
  const yearStemIdx = yearSB % 10
  const yearBranchIdx = yearSB % 12
  const monthSBIndex = getMonthStemBranchIndex(yearStemIdx, lunarMonth)
  const monthStemIdx = monthSBIndex % 10
  const monthBranchIdx = monthSBIndex % 12
  const daySB = getDayStemBranchIndex(solarDate)
  const dayStemIdx = daySB % 10
  const dayBranchIdx = daySB % 12

  let result: LunarDate = {
    year: lunarYear,
    month: lunarMonth,
    day: lunarDay,
    isLeapMonth: isLeap,
    yearStem: HEAVENLY_STEMS[yearStemIdx % 10],
    yearBranch: EARTHLY_BRANCHES[yearBranchIdx % 12],
    monthStem: HEAVENLY_STEMS[monthStemIdx % 10],
    monthBranch: EARTHLY_BRANCHES[monthBranchIdx % 12],
    dayStem: HEAVENLY_STEMS[dayStemIdx % 10],
    dayBranch: EARTHLY_BRANCHES[dayBranchIdx % 12]
  }
  return result
}

function makeElementCount(): Map<string, number> {
  let result: Map<string, number> = new Map<string, number>()
  result.set('金', 0); result.set('木', 0); result.set('水', 0); result.set('火', 0); result.set('土', 0)
  return result
}

function makeEmptyStrength(): Map<string, string> {
  let result: Map<string, string> = new Map<string, string>()
  return result
}

function copyStrengthFromMap(src: Map<string, string>): Map<string, string> {
  let result: Map<string, string> = new Map<string, string>()
  result.set('木', src.get('木') || '')
  result.set('火', src.get('火') || '')
  result.set('土', src.get('土') || '')
  result.set('金', src.get('金') || '')
  result.set('水', src.get('水') || '')
  return result
}

function getRelation(dmElement: string, monthElement: string): string {
  // Flattened lookup using string comparison
  if (dmElement === '木') {
    if (monthElement === '木') return '比劫'
    if (monthElement === '火') return '食伤'
    if (monthElement === '土') return '财星'
    if (monthElement === '金') return '官杀'
    if (monthElement === '水') return '印枭'
  }
  if (dmElement === '火') {
    if (monthElement === '火') return '比劫'
    if (monthElement === '土') return '食伤'
    if (monthElement === '金') return '财星'
    if (monthElement === '水') return '官杀'
    if (monthElement === '木') return '印枭'
  }
  if (dmElement === '土') {
    if (monthElement === '土') return '比劫'
    if (monthElement === '金') return '食伤'
    if (monthElement === '水') return '财星'
    if (monthElement === '木') return '官杀'
    if (monthElement === '火') return '印枭'
  }
  if (dmElement === '金') {
    if (monthElement === '金') return '比劫'
    if (monthElement === '水') return '食伤'
    if (monthElement === '木') return '财星'
    if (monthElement === '火') return '官杀'
    if (monthElement === '土') return '印枭'
  }
  if (dmElement === '水') {
    if (monthElement === '水') return '比劫'
    if (monthElement === '木') return '食伤'
    if (monthElement === '火') return '财星'
    if (monthElement === '土') return '官杀'
    if (monthElement === '金') return '印枭'
  }
  return ''
}

export function calculateBazi(date: Date, gender: string): BaziData {
  const lunar = solarToLunar(date)
  const hourSB = getHourStemBranch(
    HEAVENLY_STEMS.indexOf(lunar.dayStem),
    date.getHours()
  )

  let yearElem = STEM_ELEMENT.get(lunar.yearStem)
  let yearPillar: PillarData = {
    stem: lunar.yearStem,
    branch: lunar.yearBranch,
    element: yearElem !== undefined ? yearElem : ''
  }
  let monthElem = STEM_ELEMENT.get(lunar.monthStem)
  let monthPillar: PillarData = {
    stem: lunar.monthStem,
    branch: lunar.monthBranch,
    element: monthElem !== undefined ? monthElem : ''
  }
  let dayElem = STEM_ELEMENT.get(lunar.dayStem)
  let dayPillar: PillarData = {
    stem: lunar.dayStem,
    branch: lunar.dayBranch,
    element: dayElem !== undefined ? dayElem : ''
  }
  let hourElemStr = STEM_ELEMENT.get(hourSB.stem)
  let hourPillar: PillarData = {
    stem: hourSB.stem,
    branch: hourSB.branch,
    element: hourElemStr !== undefined ? hourElemStr : ''
  }

  const fiveElementsCount = makeElementCount()
  const allBranches: string[] = [yearPillar.branch, monthPillar.branch, dayPillar.branch, hourPillar.branch]
  const allStems: string[] = [yearPillar.stem, monthPillar.stem, dayPillar.stem, hourPillar.stem]

  for (let i = 0; i < allStems.length; i++) {
    const s = allStems[i]
    if (s.length > 0) {
      const stemElemVal = STEM_ELEMENT.get(s)
      if (stemElemVal !== undefined && stemElemVal.length > 0) {
        const elem = stemElemVal
        const curVal = fiveElementsCount.get(elem)
        fiveElementsCount.set(elem, (curVal !== undefined ? curVal : 0) + 1)
      }
    }
  }
  for (let i = 0; i < allBranches.length; i++) {
    const b = allBranches[i]
    if (b.length > 0) {
      const branchElemVal = BRANCH_ELEMENT.get(b)
      if (branchElemVal !== undefined && branchElemVal.length > 0) {
        const elem = branchElemVal
        const curVal = fiveElementsCount.get(elem)
        fiveElementsCount.set(elem, (curVal !== undefined ? curVal : 0) + 1)
      }
    }
  }

  const dmElementVal = STEM_ELEMENT.get(lunar.dayStem)
  const dmElement = dmElementVal !== undefined ? dmElementVal : ''
  const strengthMap = SEASONAL_STRENGTH.get(monthPillar.branch)
  let dmStrength = '平'
  if (strengthMap !== undefined) {
    const strengthVal = strengthMap.get(dmElement)
    if (strengthVal !== undefined) { dmStrength = strengthVal }
  }

  const monthElementVal = BRANCH_ELEMENT.get(monthPillar.branch)
  const monthElement = monthElementVal !== undefined ? monthElementVal : ''
  const impact = '月令为【' + monthPillar.branch + monthElement + '】，日主' + lunar.dayStem + dmElement + '处于"' + dmStrength + '"之地。'

  const relation = getRelation(dmElement, monthElement)
  let structName = '正格'
  let structDesc = ''

  if (relation === '比劫') {
    structName = dmStrength === '旺' ? '建禄格/月劫格' : '身旺格'
    structDesc = '日主得令，自坐强根，个性独立自强，富有竞争意识，宜用财官。'
  } else if (relation === '食伤') {
    structName = '食伤格'
    structDesc = '日主生月令，才华横溢，感性多情，具有艺术天赋或创新能力，宜注意能量泄耗。'
  } else if (relation === '财星') {
    structName = '财星格'
    structDesc = '日主克月令，务实进取，重视效率与结果，具有较强的经营管理能力。'
  } else if (relation === '官杀') {
    structName = '官杀格'
    structDesc = '月令克日主，责任心强，注重名誉与纪律，或处境压力较大，需印比护身。'
  } else if (relation === '印枭') {
    structName = '印绶格'
    structDesc = '月令生日主，深思熟虑，学识渊博，易得长辈提拔依靠，或性格稍显被动。'
  }

  const analysisText = TEN_STEMS_ANALYSIS.get(lunar.dayStem)
  const analysisStr = analysisText !== undefined ? analysisText : ''

  let freshStrength = makeEmptyStrength()
  if (strengthMap !== undefined) {
    freshStrength = copyStrengthFromMap(strengthMap)
  }
  let monthCmd: MonthCommand = {
    branch: monthPillar.branch,
    element: monthElement,
    strength: freshStrength,
    impact: impact
  }

  let structure: StructureInfo = {
    name: structName,
    description: structDesc
  }

  let result: BaziData = {
    year: yearPillar,
    month: monthPillar,
    day: dayPillar,
    hour: hourPillar,
    fiveElements: fiveElementsCount,
    dayMaster: lunar.dayStem,
    dayMasterAnalysis: '日主' + lunar.dayStem + '，五行属' + dmElement + '。' + analysisStr,
    monthCommand: monthCmd,
    structure: structure
  }
  return result
}
