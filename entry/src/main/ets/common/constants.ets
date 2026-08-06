// ============================================================
// Color Palette - Ink Wash Aesthetic (Light / Dark adaptive)
// ============================================================
interface ColorTokens {
  PAPER: string
  INK_BLACK: string
  IMPERIAL_RED: string
  AMBER_GOLD: string
  DARK_GOLD: string
  ACTIVE_CARD_BG: string
  WHITE: string
  WOOD: string
  FIRE: string
  EARTH: string
  METAL: string
  WATER: string
  DARK_BG: string
  DARK_SURFACE: string
  DARK_CARD: string
  DARK_BORDER: string
  DARK_TEXT_PRIMARY: string
  DARK_TEXT_SECONDARY: string
  DARK_TEXT_CAPTION: string
  DARK_RED: string
  DARK_GOLD_BRIGHT: string
  alpha: (hex: string, opacity: number) => string
}

// Light mode (ink wash)
export const COLORS: ColorTokens = {
  PAPER: '#F4EFDF',
  INK_BLACK: '#1A1A1C',
  IMPERIAL_RED: '#B91C1C',
  AMBER_GOLD: '#A67C52',
  DARK_GOLD: '#5D4A2A',
  ACTIVE_CARD_BG: '#FDFAF3',
  WHITE: '#FFFFFF',
  WOOD: '#2D5A27',
  FIRE: '#C23B22',
  EARTH: '#7C512D',
  METAL: '#8A8A8A',
  WATER: '#1E3A8A',

  // Dark mode palette (kept for reference / fallback)
  DARK_BG: '#1A1A1C',
  DARK_SURFACE: '#252528',
  DARK_CARD: '#2C2C30',
  DARK_BORDER: '#3A3A3C',
  DARK_TEXT_PRIMARY: '#E8E8E1',
  DARK_TEXT_SECONDARY: '#A0A0A0',
  DARK_TEXT_CAPTION: '#6E6E6E',
  DARK_RED: '#E04545',
  DARK_GOLD_BRIGHT: '#C4A46C',

  alpha: (hex: string, opacity: number): string => {
    const clamped = Math.max(0, Math.min(1, opacity))
    const byte = Math.round(clamped * 255)
    const suffix = byte.toString(16).toUpperCase().padStart(2, '0')
    return hex + suffix
  }
}

let darkModeActive: boolean = false

export function isDarkMode(): boolean {
  return darkModeActive
}

export function applyTheme(dark: boolean): void {
  darkModeActive = dark
  if (dark) {
    // Paper-ink inversion: dark paper, light ink
    COLORS.PAPER = '#131316'
    COLORS.INK_BLACK = '#ECE8DC'
    COLORS.IMPERIAL_RED = '#E05252'
    COLORS.AMBER_GOLD = '#C9A46B'
    COLORS.DARK_GOLD = '#C9A46B'
    COLORS.ACTIVE_CARD_BG = '#26262B'
    COLORS.WHITE = '#202024'
    COLORS.WOOD = '#4C8A45'
    COLORS.FIRE = '#D9543B'
    COLORS.EARTH = '#A97845'
    COLORS.METAL = '#B4B4B4'
    COLORS.WATER = '#5B82D8'
    COLORS.DARK_BG = '#131316'
    COLORS.DARK_SURFACE = '#202024'
    COLORS.DARK_CARD = '#26262B'
    COLORS.DARK_BORDER = '#3A3A3C'
    COLORS.DARK_TEXT_PRIMARY = '#ECE8DC'
    COLORS.DARK_TEXT_SECONDARY = '#B0B0B0'
    COLORS.DARK_TEXT_CAPTION = '#7A7A7A'
    COLORS.DARK_RED = '#E05252'
    COLORS.DARK_GOLD_BRIGHT = '#C9A46B'
  } else {
    COLORS.PAPER = '#F4EFDF'
    COLORS.INK_BLACK = '#1A1A1C'
    COLORS.IMPERIAL_RED = '#B91C1C'
    COLORS.AMBER_GOLD = '#A67C52'
    COLORS.DARK_GOLD = '#5D4A2A'
    COLORS.ACTIVE_CARD_BG = '#FDFAF3'
    COLORS.WHITE = '#FFFFFF'
    COLORS.WOOD = '#2D5A27'
    COLORS.FIRE = '#C23B22'
    COLORS.EARTH = '#7C512D'
    COLORS.METAL = '#8A8A8A'
    COLORS.WATER = '#1E3A8A'
    COLORS.DARK_BG = '#1A1A1C'
    COLORS.DARK_SURFACE = '#252528'
    COLORS.DARK_CARD = '#2C2C30'
    COLORS.DARK_BORDER = '#3A3A3C'
    COLORS.DARK_TEXT_PRIMARY = '#E8E8E1'
    COLORS.DARK_TEXT_SECONDARY = '#A0A0A0'
    COLORS.DARK_TEXT_CAPTION = '#6E6E6E'
    COLORS.DARK_RED = '#E04545'
    COLORS.DARK_GOLD_BRIGHT = '#C4A46C'
  }
  refreshElementColors()
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
  PRIMARY: COLORS.INK_BLACK,
  SECONDARY: COLORS.INK_BLACK + OP.LOW,
  BODY: COLORS.INK_BLACK + '80',
  CAPTION: COLORS.INK_BLACK + OP.X_LOW,
  LABEL: COLORS.INK_BLACK + OP.MEDIUM,
  BORDER: COLORS.INK_BLACK + OP.FAINT,
  HAIRLINE: COLORS.INK_BLACK + OP.X_FAINT,
  FAINT: COLORS.INK_BLACK + OP.FAINT,
  BG_LIGHT: COLORS.INK_BLACK + OP.TINY,
  BG_MEDIUM: COLORS.INK_BLACK + OP.TRACE,
  BG_FAINT: COLORS.INK_BLACK + OP.GHOST,
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
  PRIMARY: COLORS.IMPERIAL_RED,
  BORDER: COLORS.IMPERIAL_RED + OP.LIGHT,
  BG_LIGHT: COLORS.IMPERIAL_RED + '0F',
  BG_MEDIUM: COLORS.IMPERIAL_RED + OP.TINY,
  BG_FAINT: COLORS.IMPERIAL_RED + OP.TRACE,
  LABEL: COLORS.IMPERIAL_RED + OP.MEDIUM,
}

// Refresh derived tokens after theme switch
function refreshDerivedTokens(): void {
  INK.PRIMARY = COLORS.INK_BLACK
  INK.SECONDARY = COLORS.INK_BLACK + OP.LOW
  INK.BODY = COLORS.INK_BLACK + '80'
  INK.CAPTION = COLORS.INK_BLACK + OP.X_LOW
  INK.LABEL = COLORS.INK_BLACK + OP.MEDIUM
  INK.BORDER = COLORS.INK_BLACK + OP.FAINT
  INK.HAIRLINE = COLORS.INK_BLACK + OP.X_FAINT
  INK.FAINT = COLORS.INK_BLACK + OP.FAINT
  INK.BG_LIGHT = COLORS.INK_BLACK + OP.TINY
  INK.BG_MEDIUM = COLORS.INK_BLACK + OP.TRACE
  INK.BG_FAINT = COLORS.INK_BLACK + OP.GHOST
  INK.PLACEHOLDER = COLORS.INK_BLACK + OP.LIGHT

  RED.PRIMARY = COLORS.IMPERIAL_RED
  RED.BORDER = COLORS.IMPERIAL_RED + OP.LIGHT
  RED.BG_LIGHT = COLORS.IMPERIAL_RED + '0F'
  RED.BG_MEDIUM = COLORS.IMPERIAL_RED + OP.TINY
  RED.BG_FAINT = COLORS.IMPERIAL_RED + OP.TRACE
  RED.LABEL = COLORS.IMPERIAL_RED + OP.MEDIUM

  refreshElementColors()
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

// 地支藏干 (hidden stems inside each earthly branch)
export const BRANCH_HIDDEN_STEMS: Map<string, string[]> = new Map([
  ['子', ['癸']],
  ['丑', ['己', '癸', '辛']],
  ['寅', ['甲', '丙', '戊']],
  ['卯', ['乙']],
  ['辰', ['戊', '乙', '癸']],
  ['巳', ['丙', '庚', '戊']],
  ['午', ['丁', '己']],
  ['未', ['己', '丁', '乙']],
  ['申', ['庚', '壬', '戊']],
  ['酉', ['辛']],
  ['戌', ['戊', '辛', '丁']],
  ['亥', ['壬', '甲']],
])

export const ELEMENT_COLORS: Map<string, string> = new Map()

function refreshElementColors(): void {
  ELEMENT_COLORS.clear()
  ELEMENT_COLORS.set('木', COLORS.WOOD)
  ELEMENT_COLORS.set('火', COLORS.FIRE)
  ELEMENT_COLORS.set('土', COLORS.EARTH)
  ELEMENT_COLORS.set('金', COLORS.METAL)
  ELEMENT_COLORS.set('水', COLORS.WATER)
}

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
    applyTheme(true)
  } else {
    applyTheme(false)
  }
  return {
    bg: COLORS.PAPER, surface: COLORS.WHITE + '80', card: COLORS.WHITE + '80', border: COLORS.INK_BLACK + OP.FAINT,
    textPrimary: COLORS.INK_BLACK, textSecondary: INK.BODY, textCaption: INK.CAPTION,
    red: COLORS.IMPERIAL_RED, gold: COLORS.AMBER_GOLD, cardActive: COLORS.ACTIVE_CARD_BG, paper: COLORS.PAPER
  }
}

refreshDerivedTokens()
