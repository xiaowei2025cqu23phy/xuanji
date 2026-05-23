// Color Palette - Ink Wash Aesthetic
export class COLORS {
  static readonly PAPER: string = '#F4EFDF'
  static readonly INK_BLACK: string = '#1A1A1C'
  static readonly IMPERIAL_RED: string = '#B91C1C'
  static readonly AMBER_GOLD: string = '#A67C52'
  static readonly DARK_GOLD: string = '#5D4A2A'
  static readonly ACTIVE_CARD_BG: string = '#FDFAF3'
  static readonly WHITE: string = '#FFFFFF'
  static readonly WOOD: string = '#2D5A27'
  static readonly FIRE: string = '#C23B22'
  static readonly EARTH: string = '#7C512D'
  static readonly METAL: string = '#8A8A8A'
  static readonly WATER: string = '#1E3A8A'
}

// Heavenly Stems and Earthly Branches
export const HEAVENLY_STEMS: string[] = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸']
export const EARTHLY_BRANCHES: string[] = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']

function buildStemElementMap(): Map<string, string> {
  let m: Map<string, string> = new Map<string, string>()
  m.set('甲', '木'); m.set('乙', '木')
  m.set('丙', '火'); m.set('丁', '火')
  m.set('戊', '土'); m.set('己', '土')
  m.set('庚', '金'); m.set('辛', '金')
  m.set('壬', '水'); m.set('癸', '水')
  return m
}
export const STEM_ELEMENT: Map<string, string> = buildStemElementMap()

function buildBranchElementMap(): Map<string, string> {
  let m: Map<string, string> = new Map<string, string>()
  m.set('寅', '木'); m.set('卯', '木')
  m.set('巳', '火'); m.set('午', '火')
  m.set('辰', '土'); m.set('戌', '土'); m.set('丑', '土'); m.set('未', '土')
  m.set('申', '金'); m.set('酉', '金')
  m.set('亥', '水'); m.set('子', '水')
  return m
}
export const BRANCH_ELEMENT: Map<string, string> = buildBranchElementMap()

function buildElementColorsMap(): Map<string, string> {
  let m: Map<string, string> = new Map<string, string>()
  m.set('木', COLORS.WOOD)
  m.set('火', COLORS.FIRE)
  m.set('土', COLORS.EARTH)
  m.set('金', COLORS.METAL)
  m.set('水', COLORS.WATER)
  return m
}
export const ELEMENT_COLORS: Map<string, string> = buildElementColorsMap()

export const ELEMENT_ORDER: string[] = ['木', '火', '土', '金', '水']

function makeSeasonalSubMap(wangElem: string, xiangElem: string): Map<string, string> {
  let s: Map<string, string> = new Map<string, string>()
  s.set('木', '平'); s.set('火', '平'); s.set('土', '平'); s.set('金', '平'); s.set('水', '平')
  let xiuElem = ''; let qiuElem = ''; let siElem = ''
  if (wangElem === '木') { xiuElem = '水'; qiuElem = '金'; siElem = '土' }
  else if (wangElem === '火') { xiuElem = '木'; qiuElem = '水'; siElem = '金' }
  else if (wangElem === '金') { xiuElem = '土'; qiuElem = '火'; siElem = '木' }
  else if (wangElem === '水') { xiuElem = '金'; qiuElem = '土'; siElem = '火' }
  else if (wangElem === '土') { xiuElem = '火'; qiuElem = '木'; siElem = '水' }
  s.set(wangElem, '旺'); s.set(xiangElem, '相'); s.set(xiuElem, '休'); s.set(qiuElem, '囚'); s.set(siElem, '死')
  return s
}

function buildSeasonalStrength(): Map<string, Map<string, string>> {
  let m: Map<string, Map<string, string>> = new Map<string, Map<string, string>>()
  m.set('寅', makeSeasonalSubMap('木', '火')); m.set('卯', makeSeasonalSubMap('木', '火'))
  m.set('巳', makeSeasonalSubMap('火', '土')); m.set('午', makeSeasonalSubMap('火', '土'))
  m.set('申', makeSeasonalSubMap('金', '水')); m.set('酉', makeSeasonalSubMap('金', '水'))
  m.set('亥', makeSeasonalSubMap('水', '木')); m.set('子', makeSeasonalSubMap('水', '木'))
  m.set('辰', makeSeasonalSubMap('土', '金')); m.set('戌', makeSeasonalSubMap('土', '金'))
  m.set('丑', makeSeasonalSubMap('土', '金')); m.set('未', makeSeasonalSubMap('土', '金'))
  return m
}
export const SEASONAL_STRENGTH: Map<string, Map<string, string>> = buildSeasonalStrength()

function buildGenerativeCycle(): Map<string, string> {
  let m: Map<string, string> = new Map<string, string>()
  m.set('木', '火'); m.set('火', '土'); m.set('土', '金'); m.set('金', '水'); m.set('水', '木')
  return m
}
export const GENERATIVE_CYCLE: Map<string, string> = buildGenerativeCycle()

function buildOvercomingCycle(): Map<string, string> {
  let m: Map<string, string> = new Map<string, string>()
  m.set('木', '土'); m.set('土', '水'); m.set('水', '火'); m.set('火', '金'); m.set('金', '木')
  return m
}
export const OVERCOMING_CYCLE: Map<string, string> = buildOvercomingCycle()

// Trigram utilities
export function getTrigramName(binary: string): string {
  if (binary === '111') return '乾'
  if (binary === '000') return '坤'
  if (binary === '100') return '震'
  if (binary === '011') return '巽'
  if (binary === '010') return '坎'
  if (binary === '101') return '离'
  if (binary === '001') return '艮'
  if (binary === '110') return '兑'
  return ''
}

export function getTrigramElement(binary: string): string {
  if (binary === '111') return '金'
  if (binary === '000') return '土'
  if (binary === '100') return '木'
  if (binary === '011') return '木'
  if (binary === '010') return '水'
  if (binary === '101') return '火'
  if (binary === '001') return '土'
  if (binary === '110') return '金'
  return ''
}

export function getTrigramNature(binary: string): string {
  if (binary === '111') return '天'
  if (binary === '000') return '地'
  if (binary === '100') return '雷'
  if (binary === '011') return '风'
  if (binary === '010') return '水'
  if (binary === '101') return '火'
  if (binary === '001') return '山'
  if (binary === '110') return '泽'
  return ''
}
