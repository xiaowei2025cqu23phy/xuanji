import { BRANCH_ELEMENT, getElementRelation } from '../common/constants'
import { GET_HEX_BY_BINARY, Hexagram } from './iching-data'

// ================================================================
// 京房八宫卦系统
// ================================================================
interface PalaceEntry {
  palace: string
  palaceElement: string
  position: number
  shiLine: number
  yingLine: number
}

let gPalaceMap: Map<string, PalaceEntry> = new Map()

function addP(bin: string, p: string, e: string, pos: number): void {
  let shiLut: number[] = [6, 1, 2, 3, 4, 5, 4, 3]
  let shi: number = shiLut[pos]
  let ying: number = ((shi - 1 + 3) % 6) + 1
  let entry: PalaceEntry = { palace: p, palaceElement: e, position: pos, shiLine: shi, yingLine: ying }
  gPalaceMap.set(bin, entry)
}

// 乾宫金
addP('111111','乾','金',0); addP('011111','乾','金',1); addP('001111','乾','金',2); addP('000111','乾','金',3)
addP('000011','乾','金',4); addP('000001','乾','金',5); addP('000101','乾','金',6); addP('111101','乾','金',7)
// 坎宫水
addP('010010','坎','水',0); addP('110010','坎','水',1); addP('100010','坎','水',2); addP('101010','坎','水',3)
addP('101110','坎','水',4); addP('101100','坎','水',5); addP('101000','坎','水',6); addP('010000','坎','水',7)
// 艮宫土
addP('001001','艮','土',0); addP('101001','艮','土',1); addP('111001','艮','土',2); addP('110001','艮','土',3)
addP('110101','艮','土',4); addP('110111','艮','土',5); addP('110011','艮','土',6); addP('001011','艮','土',7)
// 震宫木
addP('100100','震','木',0); addP('001000','震','木',1); addP('010100','震','木',2); addP('011100','震','木',3)
addP('011000','震','木',4); addP('011010','震','木',5); addP('011110','震','木',6); addP('100110','震','木',7)
// 巽宫木
addP('011011','巽','木',0); addP('111011','巽','木',1); addP('101011','巽','木',2); addP('100011','巽','木',3)
addP('100111','巽','木',4); addP('100101','巽','木',5); addP('100001','巽','木',6); addP('011001','巽','木',7)
// 离宫火
addP('101101','离','火',0); addP('001101','离','火',1); addP('011101','离','火',2); addP('010101','离','火',3)
addP('010001','离','火',4); addP('010011','离','火',5); addP('010111','离','火',6); addP('101111','离','火',7)
// 坤宫土
addP('000000','坤','土',0); addP('100000','坤','土',1); addP('110000','坤','土',2); addP('111000','坤','土',3)
addP('111100','坤','土',4); addP('111110','坤','土',5); addP('111010','坤','土',6); addP('000010','坤','土',7)
// 兑宫金
addP('110110','兑','金',0); addP('010110','兑','金',1); addP('000110','兑','金',2); addP('001110','兑','金',3)
addP('001010','兑','金',4); addP('000100','兑','金',5); addP('001100','兑','金',6); addP('110100','兑','金',7)

const FALLBACK_PALACE: PalaceEntry = { palace: '未知', palaceElement: '?', position: 0, shiLine: 0, yingLine: 0 }

export function getPalaceInfo(binary: string): PalaceEntry {
  let v: PalaceEntry | undefined = gPalaceMap.get(binary)
  if (v !== undefined) { return v }
  return FALLBACK_PALACE
}

// ================================================================
// 纳支
// ================================================================
let gNazhi: Map<string, string[]> = new Map()
gNazhi.set('111', ['子','寅','辰']); gNazhi.set('010', ['寅','辰','午'])
gNazhi.set('001', ['辰','午','申']); gNazhi.set('100', ['子','寅','辰'])
gNazhi.set('011', ['丑','亥','酉']); gNazhi.set('101', ['卯','丑','亥'])
gNazhi.set('000', ['未','巳','卯']); gNazhi.set('110', ['巳','卯','丑'])

// 纳干
let gNagan: Map<string, string[]> = new Map()
gNagan.set('乾', ['甲','甲','甲','壬','壬','壬']); gNagan.set('震', ['庚','庚','庚','庚','庚','庚'])
gNagan.set('坎', ['戊','戊','戊','戊','戊','戊']); gNagan.set('艮', ['丙','丙','丙','丙','丙','丙'])
gNagan.set('坤', ['乙','乙','乙','癸','癸','癸']); gNagan.set('巽', ['辛','辛','辛','辛','辛','辛'])
gNagan.set('离', ['己','己','己','己','己','己']); gNagan.set('兑', ['丁','丁','丁','丁','丁','丁'])
let gFallbackStems: string[] = ['?','?','?','?','?','?']

export interface NazhiStemEntry { stem: string; branch: string }

export function getNazhiForLine(binary: string, lineIdx: number): NazhiStemEntry {
  let lowerBin: string = binary.slice(0, 3)
  let upperBin: string = binary.slice(3, 6)
  let pi: PalaceEntry = getPalaceInfo(binary)
  let lowerBranches: string[] | undefined = gNazhi.get(lowerBin)
  let upperBranches: string[] | undefined = gNazhi.get(upperBin)
  let stems: string[] | undefined = gNagan.get(pi.palace)
  let stem: string = '?'
  if (stems !== undefined) { stem = stems[lineIdx] }
  let branch: string = '?'
  if (lineIdx < 3 && lowerBranches !== undefined) { branch = lowerBranches[lineIdx] }
  else if (lineIdx >= 3 && upperBranches !== undefined) { branch = upperBranches[lineIdx - 3] }
  let entry: NazhiStemEntry = { stem: stem, branch: branch }
  return entry
}

// ================================================================
// 六亲 / 六兽
// ================================================================
export interface LiuYaoLine {
  lineIdx: number
  positionName: string
  isMoving: boolean
  lineYang: boolean
  nazhi: NazhiStemEntry
  liuqin: string
  shiYing: string
  liushou: string
}

export interface LiuYaoPan {
  hex: Hexagram
  palace: string
  palaceElement: string
  lines: LiuYaoLine[]
  xunKong: string[]
  dayStemBranch: string
  monthStemBranch: string
}

function branchElem(branch: string): string {
  let v: string | undefined = BRANCH_ELEMENT.get(branch)
  if (v !== undefined) { return v }
  return ''
}

function tenGodFromRelation(selfElem: string, otherElem: string): string {
  let rel = getElementRelation(selfElem, otherElem)
  if (rel.label === '比和') { return '兄弟' }
  if (rel.label === '我生') { return '子孙' }
  if (rel.label === '生我') { return '父母' }
  if (rel.label === '我克') { return '妻财' }
  if (rel.label === '克我') { return '官鬼' }
  return '—'
}

function liuShouOrder(dayStem: string): string[] {
  let idx: number = 0
  if (dayStem === '甲' || dayStem === '乙') { idx = 0 }
  else if (dayStem === '丙' || dayStem === '丁') { idx = 1 }
  else if (dayStem === '戊') { idx = 2 }
  else if (dayStem === '己') { idx = 3 }
  else if (dayStem === '庚' || dayStem === '辛') { idx = 4 }
  else if (dayStem === '壬' || dayStem === '癸') { idx = 5 }
  let animals: string[] = ['青龙', '朱雀', '勾陈', '螣蛇', '白虎', '玄武']
  let out: string[] = []
  for (let i: number = 0; i < 6; i++) { out.push(animals[(idx + i) % 6]) }
  return out
}

export function computeLiuYao(binary: string, movingIndexes: number[], dayStem: string): LiuYaoLine[] {
  let pi: PalaceEntry = getPalaceInfo(binary)
  let palElem: string = pi.palaceElement
  let posNames: string[] = ['初', '二', '三', '四', '五', '上']
  let shouOrder: string[] = liuShouOrder(dayStem)
  let out: LiuYaoLine[] = []
  for (let i: number = 0; i < 6; i++) {
    let nazhi: NazhiStemEntry = getNazhiForLine(binary, i)
    let be: string = branchElem(nazhi.branch)
    let liuqin: string = tenGodFromRelation(palElem, be)
    let sy: string = '—'
    if (i + 1 === pi.shiLine) { sy = '世' }
    if (i + 1 === pi.yingLine) { sy = '应' }
    let isYang: boolean = binary[i] === '1'
    let line: LiuYaoLine = {
      lineIdx: i, positionName: posNames[i], isMoving: movingIndexes.indexOf(i) >= 0,
      lineYang: isYang, nazhi: nazhi, liuqin: liuqin, shiYing: sy, liushou: shouOrder[i]
    }
    out.push(line)
  }
  return out
}

// ================================================================
// 旬空
// ================================================================
let gXunKong: Map<string, string[]> = new Map()
// 甲子旬 戌亥空
gXunKong.set('甲子',['戌','亥']);gXunKong.set('乙丑',['戌','亥']);gXunKong.set('丙寅',['戌','亥']);gXunKong.set('丁卯',['戌','亥']);gXunKong.set('戊辰',['戌','亥'])
gXunKong.set('己巳',['戌','亥']);gXunKong.set('庚午',['戌','亥']);gXunKong.set('辛未',['戌','亥']);gXunKong.set('壬申',['戌','亥']);gXunKong.set('癸酉',['戌','亥'])
// 甲戌旬 申酉空
gXunKong.set('甲戌',['申','酉']);gXunKong.set('乙亥',['申','酉']);gXunKong.set('丙子',['申','酉']);gXunKong.set('丁丑',['申','酉']);gXunKong.set('戊寅',['申','酉'])
gXunKong.set('己卯',['申','酉']);gXunKong.set('庚辰',['申','酉']);gXunKong.set('辛巳',['申','酉']);gXunKong.set('壬午',['申','酉']);gXunKong.set('癸未',['申','酉'])
// 甲申旬 午未空
gXunKong.set('甲申',['午','未']);gXunKong.set('乙酉',['午','未']);gXunKong.set('丙戌',['午','未']);gXunKong.set('丁亥',['午','未']);gXunKong.set('戊子',['午','未'])
gXunKong.set('己丑',['午','未']);gXunKong.set('庚寅',['午','未']);gXunKong.set('辛卯',['午','未']);gXunKong.set('壬辰',['午','未']);gXunKong.set('癸巳',['午','未'])
// 甲午旬 辰巳空
gXunKong.set('甲午',['辰','巳']);gXunKong.set('乙未',['辰','巳']);gXunKong.set('丙申',['辰','巳']);gXunKong.set('丁酉',['辰','巳']);gXunKong.set('戊戌',['辰','巳'])
gXunKong.set('己亥',['辰','巳']);gXunKong.set('庚子',['辰','巳']);gXunKong.set('辛丑',['辰','巳']);gXunKong.set('壬寅',['辰','巳']);gXunKong.set('癸卯',['辰','巳'])
// 甲辰旬 寅卯空
gXunKong.set('甲辰',['寅','卯']);gXunKong.set('乙巳',['寅','卯']);gXunKong.set('丙午',['寅','卯']);gXunKong.set('丁未',['寅','卯']);gXunKong.set('戊申',['寅','卯'])
gXunKong.set('己酉',['寅','卯']);gXunKong.set('庚戌',['寅','卯']);gXunKong.set('辛亥',['寅','卯']);gXunKong.set('壬子',['寅','卯']);gXunKong.set('癸丑',['寅','卯'])
// 甲寅旬 子丑空
gXunKong.set('甲寅',['子','丑']);gXunKong.set('乙卯',['子','丑']);gXunKong.set('丙辰',['子','丑']);gXunKong.set('丁巳',['子','丑']);gXunKong.set('戊午',['子','丑'])
gXunKong.set('己未',['子','丑']);gXunKong.set('庚申',['子','丑']);gXunKong.set('辛酉',['子','丑']);gXunKong.set('壬戌',['子','丑']);gXunKong.set('癸亥',['子','丑'])

export function getXunKong(dayStem: string, dayBranch: string): string[] {
  let key: string = dayStem + dayBranch
  let v: string[] | undefined = gXunKong.get(key)
  if (v !== undefined) { return v }
  return []
}

// ================================================================
// buildLiuYaoPan — entry point
// ================================================================
export function buildLiuYaoPan(binary: string, movingIndexes: number[], dayStem: string, dayBranch: string, monthStem: string, monthBranch: string): LiuYaoPan {
  let hex: Hexagram = GET_HEX_BY_BINARY(binary)
  let pi: PalaceEntry = getPalaceInfo(binary)
  let lines: LiuYaoLine[] = computeLiuYao(binary, movingIndexes, dayStem)
  let xk: string[] = getXunKong(dayStem, dayBranch)
  let pan: LiuYaoPan = {
    hex: hex, palace: pi.palace, palaceElement: pi.palaceElement,
    lines: lines, xunKong: xk,
    dayStemBranch: dayStem + dayBranch, monthStemBranch: monthStem + monthBranch
  }
  return pan
}
