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
  mingGong?: PalaceInfo   // 命宫
  taiYuan?: PalaceInfo    // 胎元
}

export interface PalaceInfo {
  stem: string
  branch: string
}

export interface PillarData {
  stem: string
  branch: string
  element: string
  nayin?: string        // 纳音名称, e.g. "海中金"
  nayinElement?: string // 纳音五行, e.g. "金"
  hiddenStems?: string[] // 地支藏干
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
  startAgeText?: string // 起运年龄（精确到月），如 "3岁6个月"
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
  '山头火','山头火', '涧下水','涧下水', '城头土','城头土', '白蜡金','白蜡金', '杨柳木','杨柳木',
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

// 六十甲子索引公式：sbIndex = (stemIdx * 6 - branchIdx * 5) mod 60
// 验证：甲子(0,0)→0、乙丑(1,1)→1、甲戌(0,10)→10、甲辰(0,4)→40
export function getNayin(stemIndex: number, branchIndex: number): Nayin {
  const sbIndex = ((stemIndex % 10) * 6 - (branchIndex % 12) * 5 + 60) % 60
  return { name: NAYIN_NAMES[sbIndex], element: NAYIN_ELEMENTS[sbIndex] }
}

export function getNayinByPair(stemIdx: number, branchIdx: number): string {
  return getNayin(stemIdx, branchIdx).name
}

export function getNayinElementByPair(stemIdx: number, branchIdx: number): string {
  return getNayin(stemIdx, branchIdx).element
}
