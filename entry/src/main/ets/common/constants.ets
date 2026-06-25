// ============================================================
// Color Palette - Ink Wash Aesthetic
// ============================================================
export class COLORS {
  // Light mode (ink wash)
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

  // Dark mode palette
  static readonly DARK_BG: string = '#1A1A1C'
  static readonly DARK_SURFACE: string = '#252528'
  static readonly DARK_CARD: string = '#2C2C30'
  static readonly DARK_BORDER: string = '#3A3A3C'
  static readonly DARK_TEXT_PRIMARY: string = '#E8E8E1'
  static readonly DARK_TEXT_SECONDARY: string = '#A0A0A0'
  static readonly DARK_TEXT_CAPTION: string = '#6E6E6E'
  static readonly DARK_RED: string = '#E04545'
  static readonly DARK_GOLD_BRIGHT: string = '#C4A46C'

  // Alpha compositing
  static alpha(hex: string, opacity: number): string {
    const clamped = Math.max(0, Math.min(1, opacity))
    const byte = Math.round(clamped * 255)
    const suffix = byte.toString(16).toUpperCase().padStart(2, '0')
    return hex + suffix
  }
}

// Common opacity token shortcuts (hex suffix for colors without alpha channel)
export interface OpColors {
  FULL: string
  HIGH: string
  MEDIUM: string
  LOW: string
  X_LOW: string
  LIGHT: string
  FAINT: string
  X_FAINT: string
  TINY: string
  TRACE: string
  GHOST: string
}

export const OP: OpColors = {
  FULL:   'FF',
  HIGH:   'CC',
  MEDIUM: '99',
  LOW:    '66',
  X_LOW:  '4D',
  LIGHT:  '33',
  FAINT:  '1A',
  X_FAINT:'0D',
  TINY:   '08',
  TRACE:  '05',
  GHOST:  '03',
}

// Pre-composed semantic ink colors (avoids repeated `COLORS.INK_BLACK + OP.XXX` inline)
export interface InkColors {
  PRIMARY: string
  SECONDARY: string
  BODY: string
  CAPTION: string
  LABEL: string
  BORDER: string
  HAIRLINE: string
  FAINT: string
  BG_LIGHT: string
  BG_MEDIUM: string
  BG_FAINT: string
  PLACEHOLDER: string
}

export const INK: InkColors = {
  PRIMARY:   COLORS.INK_BLACK,
  SECONDARY: COLORS.INK_BLACK + OP.LOW,
  BODY:      COLORS.INK_BLACK + '80',
  CAPTION:   COLORS.INK_BLACK + OP.X_LOW,
  LABEL:     COLORS.INK_BLACK + OP.MEDIUM,
  BORDER:    COLORS.INK_BLACK + OP.FAINT,
  HAIRLINE:  COLORS.INK_BLACK + OP.X_FAINT,
  FAINT:     COLORS.INK_BLACK + OP.FAINT,
  BG_LIGHT:  COLORS.INK_BLACK + OP.TINY,
  BG_MEDIUM: COLORS.INK_BLACK + OP.TRACE,
  BG_FAINT:  COLORS.INK_BLACK + OP.GHOST,
  PLACEHOLDER: COLORS.INK_BLACK + OP.LIGHT,
}

// Pre-composed imperial red colors
export interface RedColors {
  PRIMARY: string
  BORDER: string
  BG_LIGHT: string
  BG_MEDIUM: string
  BG_FAINT: string
  LABEL: string
}

export const RED: RedColors = {
  PRIMARY:   COLORS.IMPERIAL_RED,
  BORDER:    COLORS.IMPERIAL_RED + OP.LIGHT,
  BG_LIGHT:  COLORS.IMPERIAL_RED + '0F',
  BG_MEDIUM: COLORS.IMPERIAL_RED + OP.TINY,
  BG_FAINT:  COLORS.IMPERIAL_RED + OP.TRACE,
  LABEL:     COLORS.IMPERIAL_RED + OP.MEDIUM,
}

// ============================================================
// Heavenly Stems and Earthly Branches
// ============================================================
export const HEAVENLY_STEMS: string[] = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸']
export const EARTHLY_BRANCHES: string[] = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']

export const STEM_ELEMENT: Map<string, string> = new Map([
  ['甲', '木'], ['乙', '木'],
  ['丙', '火'], ['丁', '火'],
  ['戊', '土'], ['己', '土'],
  ['庚', '金'], ['辛', '金'],
  ['壬', '水'], ['癸', '水'],
])

export const BRANCH_ELEMENT: Map<string, string> = new Map([
  ['寅', '木'], ['卯', '木'],
  ['巳', '火'], ['午', '火'],
  ['辰', '土'], ['戌', '土'], ['丑', '土'], ['未', '土'],
  ['申', '金'], ['酉', '金'],
  ['亥', '水'], ['子', '水'],
])

export const ELEMENT_COLORS: Map<string, string> = new Map([
  ['木', COLORS.WOOD],
  ['火', COLORS.FIRE],
  ['土', COLORS.EARTH],
  ['金', COLORS.METAL],
  ['水', COLORS.WATER],
])

export const ELEMENT_ORDER: string[] = ['木', '火', '土', '金', '水']

// Build seasonal strength maps (旺相休囚死) for each branch
function makeSeasonal(wang: string, xiang: string): Map<string, string> {
  let xiu = '', qiu = '', si = ''
  if (wang === '木') { xiu = '水'; qiu = '金'; si = '土' }
  else if (wang === '火') { xiu = '木'; qiu = '水'; si = '金' }
  else if (wang === '金') { xiu = '土'; qiu = '火'; si = '木' }
  else if (wang === '水') { xiu = '金'; qiu = '土'; si = '火' }
  else if (wang === '土') { xiu = '火'; qiu = '木'; si = '水' }
  const m = new Map<string, string>()
  ELEMENT_ORDER.forEach((e: string) => { m.set(e, '平') })
  m.set(wang, '旺'); m.set(xiang, '相'); m.set(xiu, '休'); m.set(qiu, '囚'); m.set(si, '死')
  return m
}

export const SEASONAL_STRENGTH: Map<string, Map<string, string>> = (() => {
  const m = new Map<string, Map<string, string>>()
  m.set('寅', makeSeasonal('木', '火')); m.set('卯', makeSeasonal('木', '火'))
  m.set('巳', makeSeasonal('火', '土')); m.set('午', makeSeasonal('火', '土'))
  m.set('申', makeSeasonal('金', '水')); m.set('酉', makeSeasonal('金', '水'))
  m.set('亥', makeSeasonal('水', '木')); m.set('子', makeSeasonal('水', '木'))
  m.set('辰', makeSeasonal('土', '金')); m.set('戌', makeSeasonal('土', '金'))
  m.set('丑', makeSeasonal('土', '金')); m.set('未', makeSeasonal('土', '金'))
  return m
})()

// Five-element cycles
export const GENERATIVE_CYCLE: Map<string, string> = new Map([
  ['木', '火'], ['火', '土'], ['土', '金'], ['金', '水'], ['水', '木'],
])

export const OVERCOMING_CYCLE: Map<string, string> = new Map([
  ['木', '土'], ['土', '水'], ['水', '火'], ['火', '金'], ['金', '木'],
])

// ============================================================
// Five-element relation engine (shared by Ba Zi & I Ching)
// ============================================================
export interface ElementRelation {
  label: string
  relative: string
  desc: string
}

// Ordered by element cycle: how 'self' relates to 'other'
// q(我) is self element, p(彼) is other element
export function getElementRelation(qSelf: string, pOther: string): ElementRelation {
  if (qSelf === pOther) return { label: '比和', relative: '兄弟', desc: '同气相求，协力齐心。' }
  if (GENERATIVE_CYCLE.get(pOther) === qSelf) return { label: '我生', relative: '子孙', desc: '我生者泄，当下虽有损耗，长远有利。' }
  if (GENERATIVE_CYCLE.get(qSelf) === pOther) return { label: '生我', relative: '父母', desc: '生我者助，得外部相助或贵人提携。' }
  if (OVERCOMING_CYCLE.get(qSelf) === pOther) return { label: '我克', relative: '妻财', desc: '我克者为财，事虽繁杂但可掌控。' }
  if (OVERCOMING_CYCLE.get(pOther) === qSelf) return { label: '克我', relative: '官鬼', desc: '克我者制，受外部环境压制，宜退避守正。' }
  return { label: '平平', relative: '比和', desc: '五行气息平和，无特殊利害。' }
}

// ============================================================
// Trigram utilities
// ============================================================
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

// ============================================================
// Theme support
// ============================================================
export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark'
}

export interface ThemeColors {
  bg: string
  surface: string
  card: string
  border: string
  textPrimary: string
  textSecondary: string
  textCaption: string
  red: string
  gold: string
  cardActive: string
  paper: string
}

export function themeColors(mode: ThemeMode): ThemeColors {
  if (mode === ThemeMode.DARK) {
    return {
      bg: COLORS.DARK_BG, surface: COLORS.DARK_SURFACE, card: COLORS.DARK_CARD, border: COLORS.DARK_BORDER,
      textPrimary: COLORS.DARK_TEXT_PRIMARY, textSecondary: COLORS.DARK_TEXT_SECONDARY, textCaption: COLORS.DARK_TEXT_CAPTION,
      red: COLORS.DARK_RED, gold: COLORS.DARK_GOLD_BRIGHT, cardActive: COLORS.DARK_CARD, paper: COLORS.DARK_BG
    }
  }
  return {
    bg: COLORS.WHITE, surface: COLORS.WHITE + '80', card: COLORS.WHITE + '80', border: COLORS.INK_BLACK + OP.FAINT,
    textPrimary: COLORS.INK_BLACK, textSecondary: INK.BODY, textCaption: INK.CAPTION,
    red: COLORS.IMPERIAL_RED, gold: COLORS.AMBER_GOLD, cardActive: COLORS.ACTIVE_CARD_BG, paper: COLORS.PAPER
  }
}
