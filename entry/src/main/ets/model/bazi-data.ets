export interface BaziData {
  year: PillarData
  month: PillarData
  day: PillarData
  hour: PillarData
  fiveElements: Map<string, number>
  dayMaster: string
  dayMasterAnalysis: string
  monthCommand: MonthCommand
  structure?: StructureInfo
  nayin?: NayinData
  shensha?: ShenshaResult
  dayun?: DayunData
  liunian?: LiunianResult
}

export interface PillarData {
  stem: string
  branch: string
  element: string
  nayin?: string        // 纳音名称, e.g. "海中金"
  nayinElement?: string // 纳音五行, e.g. "金"
}

export interface MonthCommand {
  branch: string
  element: string
  strength: Map<string, string>
  impact: string
}

export interface StructureInfo {
  name: string
  description: string
}

export interface Nayin {
  name: string
  element: string
}

export interface NayinData {
  year: Nayin
  month: Nayin
  day: Nayin
  hour: Nayin
}

export interface ShenshaEntry {
  name: string
  pillar: string    // which pillar(s) it appears in: year/month/day/hour
  description: string
  starType: 'good' | 'bad' | 'neutral'
}

export interface ShenshaResult {
  entries: ShenshaEntry[]
  summary: string
}

export interface DayunCycle {
  ageStart: number
  ageEnd: number
  stem: string
  branch: string
  nayin?: string
  element: string
  tenGod: string        // 十神 vs day master
  description: string
}

export interface DayunData {
  direction: string     // 'forward' or 'backward'
  startAge: number
  description: string
  cycles: DayunCycle[]
}

export interface LiunianResult {
  currentYear: number
  stem: string
  branch: string
  nayin?: string
  element: string
  tenGod: string
  zodiac: string
  description: string
  monthlyBreakdown: MonthlyFate[]
}

export interface MonthlyFate {
  month: number
  stem: string
  branch: string
  tenGod: string
}

export const TEN_STEMS_ANALYSIS: Map<string, string> = new Map([
  ['甲', '甲木为森林之木，位居东方。象征顶天立地、仁慈刚毅，具有向上发展的进取心，但性格有时过于刚直。'],
  ['乙', '乙木为花草之木，位居东方。象征柔美、灵活，适应能力强，外柔内刚，善于权变。'],
  ['丙', '丙火为太阳之火，位居南方。象征热情奔放、光明磊落，具有领导力，但脾气易急躁。'],
  ['丁', '丁火为灯烛之火，位居南方。象征细腻、温柔、富有奉献精神，外静内明，思想深邃。'],
  ['戊', '戊土为城墙之土，位居中央。象征稳重厚实、诚实守信，承载力强，但有时过于固执。'],
  ['己', '己土为田园之土，位居中央。象征包容、多才多艺，富有同情心，性格柔顺。'],
  ['庚', '庚金为斧钺之金，位居西方。象征果断杀伐、讲义气，刚健锐利，经得起磨练。'],
  ['辛', '辛金为首饰之金，位居西方。象征精致、贵气，感受力敏锐，讲究体面，温润如玉。'],
  ['壬', '壬水为江河之水，位居北方。象征奔放、智慧，具有极强的流动性和推动力，有时过于任性。'],
  ['癸', '癸水为雨露之水，位居北方。象征滋润、灵动，富于幻想，温柔顺从，适应力强。'],
])

export const FIVE_ELEMENTS_ADVICE: Map<string, string> = new Map([
  ['金', '五行属金者，宜讲求义气，坚定信念，可多接触白色、金属制品。'],
  ['木', '五行属木者，宜怀仁慈心，修身养性，多接触绿色、植物。'],
  ['水', '五行属水者，宜发挥智慧，灵活变通，多接触黑色、水体。'],
  ['火', '五行属火者，宜守礼待人，保持热情，多接触红色、阳光。'],
  ['土', '五行属土者，宜坚守信诚，稳重行事，多接触黄色、大地。'],
])

// ============================================================
// 六十甲子纳音表 (Sexagenary Nayin Table)
// ============================================================
// Indexed by sexagenary cycle index (0=甲子, 1=乙丑, ..., 59=癸亥)
// Each entry covers 2 consecutive pairs
const NAYIN_NAMES: string[] = [
  '海中金','海中金', '炉中火','炉中火', '大林木','大林木', '路旁土','路旁土', '剑锋金','剑锋金',
  '山头火','山头火', '漳下水','漳下水', '城头土','城头土', '白蜡金','白蜡金', '杨柳木','杨柳木',
  '泉中水','泉中水', '屋上土','屋上土', '霹雳火','霹雳火', '松柏木','松柏木', '常流水','常流水',
  '沙中金','沙中金', '山下火','山下火', '平地木','平地木', '壁上土','壁上土', '金箔金','金箔金',
  '覆灯火','覆灯火', '天河水','天河水', '大驿土','大驿土', '钗钏金','钗钏金', '桑柘木','桑柘木',
  '大溪水','大溪水', '沙中土','沙中土', '天上火','天上火', '石榴木','石榴木', '大海水','大海水',
]

// Nayin element extraction (last character usually indicates the element)
const NAYIN_ELEMENTS: string[] = [
  '金','金','火','火','木','木','土','土','金','金',
  '火','火','水','水','土','土','金','金','木','木',
  '水','水','土','土','火','火','木','木','水','水',
  '金','金','火','火','木','木','土','土','金','金',
  '火','火','水','水','土','土','金','金','木','木',
  '水','水','土','土','火','火','木','木','水','水',
]

export function getNayin(stemIndex: number, branchIndex: number): Nayin {
  const cycleIdx = (stemIndex % 10) * 6 + (branchIndex % 12) - (stemIndex % 10) // Simplified
  // Correct formula: sexagenary index = (stem*6 + branch*5) % 60
  // Actually: sbIndex = ((stemIdx * 12 + branchIdx) % 60 + 60) % 60
  // Hmm, let me use the simplest formula:
  // Each stem-branch pair: the stems cycle 10, branches cycle 12
  // The 60-cycle index = (stemIdx * 6 - branchIdx ...)?
  // Let me just use: for each stem from 0-9, the branches 0-11 map to a unique index

  // Proper formula: 60-cycle index = where stemIdx and branchIdx meet
  // stem 0 (甲) appears at cycle indices: 0, 10, 20, 30, 40, 50
  // stem 1 (乙): 1, 11, 21, 31, 41, 51
  // branch 0 (子): 0, 12, 24, 36, 48
  // branch 1 (丑): 1, 13, 25, 37, 49

  // The index is: find where stem and branch align
  // For stem 0 and branch 0: 0 (甲子)
  // For stem 1 and branch 1: 1 (乙丑)
  // For stem 2 and branch 2: 2 (丙寅)...
  // More generally: idx = (stemIdx * 6 - branchIdx + 60) * ... hmm

  // Actually the simple formula:
  // Difference between stem and branch: stemIdx=0, branchIdx=0 means 甲子 cycle=0
  // stemIdx=0,branchIdx=1: 甲戌 cycle=10
  // So: cycleIdx = ((stemIdx - branchIdx) % 12) * 10 + branchIdx? No.

  // Let me just use a direct formula:
  // The sexagenary pairs follow the pattern where:
  // - stem-branch pair index = the index where they appear together
  // - Once you find the month-stem-base formula, it's similar

  // Simplest: cycle index = ((stemIndex * 6) - (branchIndex * 5) mod 5?) ...

  // The standard formula: sb = ((stemIdx % 10) * 6 - (branchIdx % 12) * 5) mod 60
  // Let me verify: stemIdx=0(甲),branchIdx=0(子) → (0 - 0) % 60 = 0 ✓
  // stemIdx=0(甲),branchIdx=1(丑) → (0 - 5) % 60 = 55? That's 戊午, not 甲子+1

  // OK let me think more carefully.
  // 甲子: stem=0, branch=0 → cycle=0 ✓
  // 乙丑: stem=1, branch=1 → cycle=1 ✓
  // 丙寅: stem=2, branch=2 → cycle=2 ✓
  // 丁卯: stem=3, branch=3 → cycle=3 ✓
  // That only works for stem==branch.
  // When stem≠branch: 甲戌: stem=0,branch=10 → cycle=10

  // Building from the observation that:
  // cycleIdx when stemIdx == branchIdx: just equals stemIdx
  // The step between matching pairs is: ...

  // Actually, the standard Chinese formula for sexagenary index:
  // sb = (stemIdx * 6 + branchIdx * 5) ... no

  // Let me just use a lookup table approach:
  // For stemIdx 0(甲): possible branches are 0,2,4,6,8,10 (子寅辰午申戌)
  // These correspond to cycles: 0, 50, 40, 30, 20, 10
  // So stemIdx=0 offsets: [0:-5, 2:4, 4:3, 6:2, 8:1, 10:0] ? Nah.

  // Actually: cycles go 0(甲子),12(甲戌),24(甲申),36(甲午),48(甲辰),60→0(甲寅)
  // Wait. 甲子=0, 甲寅=50, 甲辰=40, 甲午=30, 甲申=20, 甲戌=10
  // For stem 0, branchIdx to cycleIdx: {0:0, 2:50, 4:40, 6:30, 8:20, 10:10}
  // Stem 0 branches are: 子(0),寅(2),辰(4),午(6),申(8),戌(10)

  // OK let me just build a simple formula:
  // Given 天干 stemIdx (0-9) and 地支 branchIdx (0-11):
  // The sexagenary index increments when both stem and branch advance by 1 together
  // This means: (stemIdx - branchIdx) must be even (0, 2, 4, ..., 10)

  // The formula I'll use:
  // sbIndex = ((stemIdx % 10) * 6 - (branchIdx % 12) * 5 + 60) % 60

  // Let me test:
  // 甲(0)子(0): (0*6 - 0*5) % 60 = 0 ✓
  // 乙(1)丑(1): (1*6 - 1*5) % 60 = (6-5) % 60 = 1 ✓
  // 丙(2)寅(2): (12 - 10) % 60 = 2 ✓
  // 甲(0)戌(10): (0*6 - 10*5 + 60) % 60 = (-50 + 60) % 60 = 10 ✓
  // 甲(0)辰(4): (0*6 - 4*5 + 60) % 60 = (-20 + 60) % 60 = 40 ✓
  // 壬(8)子(0): (8*6 - 0*5) % 60 = 48 ✓
  // 丙(2)申(8): (12 - 40 + 60) % 60 = 32 ✓? 丙申 should be...let me count:
  //  0甲子 1乙丑 2丙寅... 甲戌10 乙亥11 丙子12 ...丙申=? let's count from 甲申20, so 丙申=32 ✓

  // Actually wait - 甲申=20, 乙酉=21, 丙戌=22... no.
  // From 0: 甲子0 乙丑1 丙寅2 丁卯3 戊辰4 己巳5 庚午6 辛未7 壬申8 癸酉9 甲戌10...
  // So 甲戌=10, 乙亥=11, 丙子=12, 丁丑=13, etc.
  // 甲申=20, 乙酉=21, 丙戌=22, 丁亥=23...
  // 丙申: 32? Let me check: 甲午=30, 乙未=31, 丙申=32 ✓

  // Great, the formula works!

  // Actually wait. I realized: nayin data is organized by TWO consecutive pairs sharing the same nayin.
  // So 甲子(0)+乙丑(1) = 海中金, 丙寅(2)+丁卯(3)=炉中火, etc.
  // Since I already stored the array where index 0 and 1 both have '海中金',
  // I just need to compute the sexagenary index and use it directly.

  const sbIndex = ((stemIndex % 10) * 6 - (branchIndex % 12) * 5 + 60) % 60
  return { name: NAYIN_NAMES[sbIndex], element: NAYIN_ELEMENTS[sbIndex] }
}

export function getNayinByPair(stemIdx: number, branchIdx: number): string {
  return getNayin(stemIdx, branchIdx).name
}

export function getNayinElementByPair(stemIdx: number, branchIdx: number): string {
  return getNayin(stemIdx, branchIdx).element
}
