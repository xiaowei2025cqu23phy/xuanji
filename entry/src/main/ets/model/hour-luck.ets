import { HEAVENLY_STEMS, EARTHLY_BRANCHES } from '../common/constants'

// ============================================================
// 每日吉时查询（十二建星 + 黄黑道）
// ============================================================

// 十二建星（建除满平定执破危成收开闭）
const JIANXING_NAMES: string[] = ['建', '除', '满', '平', '定', '执', '破', '危', '成', '收', '开', '闭']

// 黄黑道十二神（青龙明堂天刑朱雀金匮天德白虎玉堂天牢玄武司命勾陈）
const HUANGHEI_NAMES: string[] = ['青龙', '明堂', '天刑', '朱雀', '金匮', '天德', '白虎', '玉堂', '天牢', '玄武', '司命', '勾陈']
// 黄道吉神：青龙、明堂、金匮、天德、玉堂、司命（索引 0,1,4,5,7,10）
// 黑道凶神：天刑、朱雀、白虎、天牢、玄武、勾陈（索引 2,3,6,8,9,11）

// 日支对应时支起青龙的位置（传统口诀：
// 子午日申起青龙、丑未日戌起、寅申日子起、卯酉日寅起、辰戌日辰起、巳亥日午起）
const QINGLONG_START: Map<string, number> = new Map<string, number>([
  ['子', 8], ['午', 8],
  ['丑', 10], ['未', 10],
  ['寅', 0], ['申', 0],
  ['卯', 2], ['酉', 2],
  ['辰', 4], ['戌', 4],
  ['巳', 6], ['亥', 6],
])

export interface HourLuck {
  branchIdx: number          // 时支索引 0-11
  branchName: string         // 时支名
  timeRange: string          // 时间段 "23:00-01:00"
  jianxing: string           // 建除
  huanghei: string           // 黄黑道神
  isAuspicious: boolean      // 是否吉时
  advice: string             // 宜忌提示
}

export interface DailyHourLuck {
  dayBranch: string
  hours: HourLuck[]          // 12 个时辰的吉凶
  bestHours: HourLuck[]      // 最吉时辰
}

const HOUR_RANGES: string[] = [
  '23:00-01:00', '01:00-03:00', '03:00-05:00', '05:00-07:00',
  '07:00-09:00', '09:00-11:00', '11:00-13:00', '13:00-15:00',
  '15:00-17:00', '17:00-19:00', '19:00-21:00', '21:00-23:00'
]

export function getDailyHourLuck(dayBranch: string, dayBranchIdx: number, monthBranchIdx: number): DailyHourLuck {
  const startIdx = QINGLONG_START.get(dayBranch) ?? 0
  const hours: HourLuck[] = []
  const bestHours: HourLuck[] = []

  for (let h = 0; h < 12; h++) {
    const huangheiIdx = (startIdx + h) % 12
    const huanghei = HUANGHEI_NAMES[huangheiIdx]
    const isAuspicious = huangheiIdx === 0 || huangheiIdx === 1 || huangheiIdx === 4 ||
      huangheiIdx === 5 || huangheiIdx === 7 || huangheiIdx === 10

    const jianchuIdx = ((dayBranchIdx - monthBranchIdx) % 12 + 12) % 12
    const jianxing = JIANXING_NAMES[jianchuIdx]

    let advice: string
    if (isAuspicious) {
      if (huanghei === '青龙') advice = '青龙（黄道吉神），大吉，万事皆宜'
      else if (huanghei === '明堂') advice = '明堂（黄道），利于文书、见贵'
      else if (huanghei === '金匮') advice = '金匮（黄道），利于求财、纳宝'
      else if (huanghei === '天德') advice = '天德（黄道），利于祈福、安葬'
      else if (huanghei === '玉堂') advice = '玉堂（黄道），利于婚嫁、置业'
      else advice = '司命（黄道），利于祭祀、求嗣'
    } else {
      if (huanghei === '天刑') advice = '天刑（黑道），不利出行、诉讼'
      else if (huanghei === '朱雀') advice = '朱雀（黑道），防口舌是非'
      else if (huanghei === '白虎') advice = '白虎（黑道），防血光凶险'
      else if (huanghei === '天牢') advice = '天牢（黑道），不利求功名'
      else if (huanghei === '玄武') advice = '玄武（黑道），防盗贼暗害'
      else advice = '勾陈（黑道），不利诉讼、牵连'
    }

    const entry: HourLuck = {
      branchIdx: h,
      branchName: EARTHLY_BRANCHES[h],
      timeRange: HOUR_RANGES[h],
      jianxing: jianxing,
      huanghei: huanghei,
      isAuspicious: isAuspicious,
      advice: advice
    }
    hours.push(entry)
    if (isAuspicious) {
      bestHours.push(entry)
    }
  }

  return {
    dayBranch: dayBranch,
    hours: hours,
    bestHours: bestHours
  }
}

// 获取当前时辰的吉凶
export function getCurrentHourLuck(dayBranch: string, dayBranchIdx: number, monthBranchIdx: number, hour: number): HourLuck | null {
  const daily = getDailyHourLuck(dayBranch, dayBranchIdx, monthBranchIdx)
  const currentBranchIdx = Math.floor((hour + 1) / 2) % 12
  if (currentBranchIdx < 0 || currentBranchIdx >= daily.hours.length) return null
  return daily.hours[currentBranchIdx]
}
