// ============================================================
// 黄历核心规则：建除十二神 / 宜忌 / 冲煞
// ============================================================
const ZODIAC_NAMES: string[] = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪']

export const JIAN_CHU_NAMES: string[] = ['建', '除', '满', '平', '定', '执', '破', '危', '成', '收', '开', '闭']
export const JIAN_CHU_YI: string[][] = [
  ['出行', '上任', '祈福'], ['沐浴', '扫舍', '求医'], ['祭祀', '祈福', '结网'],
  ['修造', '平治', '移徙'], ['订婚', '纳财', '安床'], ['捕捉', '狩猎', '安葬'],
  ['破屋', '求医', '拆卸'], ['祈福', '祭祀', '安葬'], ['开业', '嫁娶', '入学'],
  ['纳财', '入宅', '嫁娶'], ['开市', '出行', '纳财'], ['修造', '安葬', '祭祀'],
]
export const JIAN_CHU_JI: string[][] = [
  ['动土', '开仓', '安葬'], ['嫁娶', '开市', '远行'], ['安葬', '开市', '动土'],
  ['开市', '纳财', '嫁娶'], ['诉讼', '出行', '开仓'], ['开市', '行船', '嫁娶'],
  ['嫁娶', '出行', '开市'], ['出行', '开市', '动土'], ['诉讼', '安葬', '动土'],
  ['安葬', '开市', '出行'], ['安葬', '动土', '伐木'], ['开市', '出行', '嫁娶'],
]

// 建除序号：正月建寅，月支与日支之差决定（0=建 ... 11=闭）
export function getJianChuIndex(dayBranchIdx: number, monthBranchIdx: number): number {
  return ((dayBranchIdx - monthBranchIdx) % 12 + 12) % 12
}

export interface ChongSha {
  chong: string
  sha: string
}

export function getChongSha(dayBranchIdx: number): ChongSha {
  const chongIdx = (dayBranchIdx + 6) % 12
  const b = dayBranchIdx
  let sha = '南'
  if (b === 2 || b === 6 || b === 10) { sha = '北' }       // 寅午戌
  else if (b === 1 || b === 5 || b === 9) { sha = '东' }   // 巳酉丑
  else if (b === 3 || b === 7 || b === 11) { sha = '西' }  // 亥卯未
  return { chong: ZODIAC_NAMES[chongIdx], sha: sha }
}
