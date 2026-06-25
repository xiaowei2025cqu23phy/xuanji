import { COLORS, INK, RED, OP, HEAVENLY_STEMS, EARTHLY_BRANCHES } from '../common/constants'
import {
  GET_HEX_BY_BINARY, Hexagram, LineDetail,
  getMutualHexagram, getChangedHexagram, getOppositeHexagram, getInverseHexagram,
  getTiYong, TiYongResult, getLineDetails
} from '../model/iching-data'
import {
  interpretMetaphysics, getOfflineIChingAnalysis, AIConfig, ChatMessage,
  QUESTION_CATEGORIES
} from '../services/aiService'
import { AIChatPanel } from './shared/AIChatPanel'
import { buildLiuYaoPan, LiuYaoLine, LiuYaoPan } from '../model/liuyao-engine'

interface Line {
  value: number
  isMoving: boolean
  type: string
}

interface StemBranch {
  stem: string
  branch: string
}

interface DivinationResult {
  originalBinary: string
  changedBinary?: string
  movingIndexes: number[]
  originalHex: Hexagram
  changedHex?: Hexagram
  mutualHex: Hexagram
  oppositeHex: Hexagram
  inverseHex: Hexagram
  tiYong: TiYongResult
  lineDetails: LineDetail[]
}

// Pre-build all 64 hexagrams for search
function getAllHexagrams(): Hexagram[] {
  const hexagrams: Hexagram[] = []
  for (let i = 0; i < 64; i++) {
    const bin = i.toString(2).padStart(6, '0')
    hexagrams.push(GET_HEX_BY_BINARY(bin))
  }
  return hexagrams
}
const ALL_HEXAGRAMS: Hexagram[] = getAllHexagrams()

// Trigram lookup (3-bit binary → name/nature/element)
interface TrigramBrief { name: string; nature: string; element: string }
const TRIGRAM_MAP: Map<string, TrigramBrief> = ((): Map<string, TrigramBrief> => {
  const m: Map<string, TrigramBrief> = new Map()
  m.set('111', { name: '乾', nature: '天', element: '金' }); m.set('000', { name: '坤', nature: '地', element: '土' })
  m.set('100', { name: '震', nature: '雷', element: '木' }); m.set('011', { name: '巽', nature: '风', element: '木' })
  m.set('010', { name: '坎', nature: '水', element: '水' }); m.set('101', { name: '离', nature: '火', element: '火' })
  m.set('001', { name: '艮', nature: '山', element: '土' }); m.set('110', { name: '兑', nature: '泽', element: '金' })
  return m
})()
function getTrigramFromBin(bin: string): TrigramBrief {
  const result: TrigramBrief | undefined = TRIGRAM_MAP.get(bin)
  if (result !== undefined) { return result }
  return { name: '?', nature: '?', element: '?' }
}

// ---- Mini hexagram display ----
@Component
struct MiniHexagram {
  @Prop binary: string
  @Prop color: string
  build() {
    Column({ space: 2 }) {
      ForEach(this.binary.split('').reverse(), (bit: string, idx: number) => {
        Row({ space: bit === '1' ? 0 : 4 }) {
          Row().height(2).backgroundColor(this.color).opacity(0.8).layoutWeight(1)
          if (bit === '0') { Row().height(2).backgroundColor(this.color).opacity(0.8).layoutWeight(1) }
        }.width('100%')
      }, (_bit: string, idx: number) => idx.toString())
    }.width(24)
  }
}

// ---- Main IChing Section ----
@Component
export struct IChingSection {
  @Prop aiConfig: AIConfig
  @State method: string = 'coin'
  @State lines: Line[] = []
  @State result: DivinationResult | null = null
  @State loading: boolean = false
  @State error: string = ''
  @State chatHistory: ChatMessage[] = []
  @State baseAnalysis: string = ''
  @State aiLoading: boolean = false
  @State activeCategory: string = 'general'
  @State number1: string = ''
  @State number2: string = ''
  @State number3: string = ''
  @State history: DivinationResult[] = []
  @State liuyaoPan: LiuYaoPan | null = null  // 六爻排盘
  // Search state
  @State searchQuery: string = ''
  @State searchResults: Hexagram[] = []
  @State showSearch: boolean = false

  build() {
    Column({ space: 24 }) {
      // Hexagram search bar (always visible)
      this.SearchBar()

      // Method selector
      Row({ space: 4 }) {
        Button('硬币起卦').fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'coin' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.method === 'coin' ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'coin'; this.resetDivination() })
        Button('数字起卦').fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'number' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.method === 'number' ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'number'; this.resetDivination() })
        Button('时间起卦').fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'time' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.method === 'time' ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'time'; this.resetDivination() })
        Button('手动排卦').fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'manual' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.method === 'manual' ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'manual'; this.resetDivination() })
      }.width('100%').justifyContent(FlexAlign.Center)

      // Method-specific input
      this.InputForMethod()

      // Loading / Error
      if (this.loading) {
        Row({ space: 12 }) {
          LoadingProgress().width(20).height(20).color(COLORS.IMPERIAL_RED)
          Text('起卦中...').fontSize(12).fontColor(INK.SECONDARY)
        }.width('100%').justifyContent(FlexAlign.Center).padding(24)
      }
      if (this.error.length > 0) {
        Text(this.error).fontSize(12).fontColor(COLORS.IMPERIAL_RED)
          .padding(12).backgroundColor(RED.BG_FAINT).width('100%')
      }

      // Results
      if (this.result) { this.ResultContent() }

      // History
      if (this.history.length > 0) { this.HistoryContent() }
    }.width('100%')
  }

  resetDivination(): void {
    this.lines = []
    this.result = null
    this.error = ''
    this.chatHistory = []
  }

  // ========== Search ==========

  @Builder SearchBar() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        TextInput({ placeholder: '搜索卦名、拼音、卦辞...', text: this.searchQuery })
          .onChange((v: string) => {
            this.searchQuery = v
            this.onSearch(v)
          })
          .layoutWeight(1).fontSize(11).padding(8)
          .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE })
        if (this.searchQuery.length > 0) {
          Button('✕').fontSize(12).width(28).height(28)
            .fontColor(INK.SECONDARY).backgroundColor(INK.BG_FAINT)
            .onClick(() => { this.searchQuery = ''; this.searchResults = []; this.showSearch = false })
        }
      }.width('100%')
      if (this.showSearch && this.searchResults.length > 0) {
        Column({ space: 2 }) {
          ForEach(this.searchResults.slice(0, 8), (hex: Hexagram) => {
            Row({ space: 12 }) {
              Text(hex.symbol).fontSize(20).fontColor(COLORS.IMPERIAL_RED)
              Column({ space: 2 }) {
                Text(hex.name).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                Text(hex.pinyin + ' · 第' + hex.number + '卦').fontSize(9).fontColor(INK.PLACEHOLDER)
                Text(hex.judgement).fontSize(9).fontColor(INK.SECONDARY).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }
            .width('100%').padding(8)
            .backgroundColor(COLORS.WHITE).border({ width: 1, color: INK.HAIRLINE })
            .onClick(() => {
              // Show this hexagram as a result
              this.showHexagramDetail(hex)
              this.searchQuery = ''; this.searchResults = []; this.showSearch = false
            })
          }, (hex: Hexagram) => hex.binary)
        }
        .width('100%').constraintSize({ maxHeight: 320 })
        .border({ width: 1, color: INK.FAINT })
      }
    }.width('100%')
  }

  onSearch(query: string): void {
    if (query.trim().length === 0) { this.searchResults = []; this.showSearch = false; return }
    const q = query.trim().toLowerCase()
    this.searchResults = ALL_HEXAGRAMS.filter(h =>
      h.name.includes(q) || h.pinyin.toLowerCase().includes(q) ||
      h.judgement.includes(q) || h.meaning.includes(q)
    )
    this.showSearch = this.searchResults.length > 0
  }

  showHexagramDetail(hex: Hexagram): void {
    // Build a synthetic divination result to display the searched hexagram
    const res: DivinationResult = {
      originalBinary: hex.binary,
      movingIndexes: [],
      originalHex: hex,
      mutualHex: GET_HEX_BY_BINARY(getMutualHexagram(hex.binary)),
      oppositeHex: GET_HEX_BY_BINARY(getOppositeHexagram(hex.binary)),
      inverseHex: GET_HEX_BY_BINARY(getInverseHexagram(hex.binary)),
      tiYong: getTiYong(hex.binary, null),
      lineDetails: getLineDetails(hex)
    }
    this.result = res
    this.baseAnalysis = getOfflineIChingAnalysis(hex.binary)
    this.chatHistory = []
    this.method = '' // clear method
    this.lines = []
    // Build liuyao pan
    const now = new Date()
    const daySB = this.computeDayStemBranch(now)
    const monthSB = this.computeMonthStemBranch(now)
    this.liuyaoPan = buildLiuYaoPan(hex.binary, [], daySB.stem, daySB.branch, monthSB.stem, monthSB.branch)
  }

  // ========== Method inputs ==========

  @Builder InputForMethod() {
    if (this.method === 'coin') { this.CoinInput() }
    if (this.method === 'number') { this.NumberInput() }
    if (this.method === 'time') { this.TimeInput() }
    if (this.method === 'manual') { this.ManualInput() }
  }

  @Builder CoinInput() {
    Column({ space: 16 }) {
      Text('模拟三钱法起卦，请连续掷出6爻').fontSize(10).fontColor(INK.PLACEHOLDER)
      if (this.lines.length < 6) {
        Text('第 ' + (this.lines.length + 1) + ' 爻 (从下往上)').fontSize(12).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Button('掷钱起卦').onClick(() => { this.castCoin() })
      }
      this.LineDisplay()
      if (this.lines.length === 6 && !this.result) {
        Button('完成起卦 · 解卦').fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK)
          .onClick(() => { this.calculateResult() })
      }
      if (this.lines.length > 0) {
        Button('重新起卦').fontSize(10).fontColor(INK.SECONDARY).onClick(() => { this.resetDivination() })
      }
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder NumberInput() {
    Column({ space: 16 }) {
      Text('输入3个数字，系统将据此推演卦象').fontSize(10).fontColor(INK.PLACEHOLDER)
      Row({ space: 12 }) {
        TextInput({ placeholder: '数字1', text: this.number1 }).onChange((v: string) => { this.number1 = v }).type(InputType.Number).width(80)
        TextInput({ placeholder: '数字2', text: this.number2 }).onChange((v: string) => { this.number2 = v }).type(InputType.Number).width(80)
        TextInput({ placeholder: '数字3', text: this.number3 }).onChange((v: string) => { this.number3 = v }).type(InputType.Number).width(80)
      }.justifyContent(FlexAlign.Center)
      Button('数字起卦').fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
        .onClick(() => { this.calculateNumberDivination() })
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder TimeInput() {
    Column({ space: 16 }) {
      Text('依据当前时间自动起卦').fontSize(10).fontColor(INK.PLACEHOLDER)
      Button('时间起卦').fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
        .onClick(() => { this.calculateTimeDivination() })
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder ManualInput() {
    Column({ space: 12 }) {
      Text('手动选择每爻的阴阳属性 (自下而上)').fontSize(10).fontColor(INK.PLACEHOLDER).margin({ bottom: 4 })
      ForEach([0, 1, 2, 3, 4, 5], (idx: number) => {
        Row({ space: 8 }) {
          Text('第' + (idx + 1) + '爻：').fontSize(11).fontColor(INK.BODY)
          Button('⚊ 少阳').fontSize(10)
            .fontColor(this.getLineValueOr(idx, 7) === 7 ? COLORS.WHITE : INK.SECONDARY)
            .backgroundColor(this.getLineValueOr(idx, 7) === 7 ? COLORS.INK_BLACK : INK.BG_FAINT)
            .onClick(() => { this.setManualLine(idx, 7) })
          Button('⚋ 少阴').fontSize(10)
            .fontColor(this.getLineValueOr(idx, 8) === 8 ? COLORS.WHITE : INK.SECONDARY)
            .backgroundColor(this.getLineValueOr(idx, 8) === 8 ? COLORS.INK_BLACK : INK.BG_FAINT)
            .onClick(() => { this.setManualLine(idx, 8) })
          Button('⚊ 老阳').fontSize(10)
            .fontColor(this.getLineValueOr(idx, 9) === 9 ? COLORS.WHITE : RED.LABEL)
            .backgroundColor(this.getLineValueOr(idx, 9) === 9 ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
            .onClick(() => { this.setManualLine(idx, 9) })
          Button('⚋ 老阴').fontSize(10)
            .fontColor(this.getLineValueOr(idx, 6) === 6 ? COLORS.WHITE : RED.LABEL)
            .backgroundColor(this.getLineValueOr(idx, 6) === 6 ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
            .onClick(() => { this.setManualLine(idx, 6) })
        }
      }, (idx: number) => idx.toString())
      if (this.lines.length === 6 && !this.result) {
        Button('排卦解卦').fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
          .onClick(() => { this.calculateResult() })
      }
      if (this.lines.length > 0) {
        Button('重新起卦').fontSize(10).fontColor(INK.SECONDARY).onClick(() => { this.resetDivination() })
      }
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder LineDisplay() {
    if (this.lines.length > 0) {
      Column({ space: 2 }) {
        ForEach(this.lines, (line: Line, _idx: number) => {
          Row() {
            if (line.type === 'yang') {
              Row().width(80).height(4)
                .backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
            } else {
              Row({ space: 8 }) {
                Row().width(32).height(4).backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                Row().width(32).height(4).backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
              }.width(80)
            }
          }.width(80).justifyContent(FlexAlign.Center).padding({ top: 4, bottom: 4 })
        }, (_line: Line, idx: number) => idx.toString())
      }
      .padding(12).backgroundColor(COLORS.WHITE + '99')
      .border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // ========== Result display ==========

  @Builder ResultContent() {
    Column({ space: 20 }) {
      // 六爻排盘表 (京房纳甲系统) — professional table
      if (this.result) { this.LiuYaoTable() }
      // 卦辞
      this.HexagramCard()
      if (this.result && this.result.changedHex) { this.EvolutionText() }
      // 上下卦分析
      if (this.result) { this.TrigramBreakdownCard() }
      // 彖传
      if (this.result && this.result.originalHex.tuanZhuan) { this.TuanZhuanCard() }
      // 大象传
      if (this.result && this.result.originalHex.daXiang) { this.DaXiangCard() }
      // 序卦传
      if (this.result && this.result.originalHex.xuGua) { this.XuGuaCard() }
      // 体用
      if (this.result) { this.TiYongCard() }
      // 爻位详情
      if (this.result && this.result.originalHex.lines) { this.LineDetailsContent() }
      this.ChatContent()
    }
  }

  // ========== 六爻排盘表 (京房纳甲系统) ==========

  @Builder LiuYaoTable() {
    if (this.liuyaoPan !== null) {
      Column({ space: 8 }) {
        // Header info row
        Row({ space: 12 }) {
          Text(this.liuyaoPan!.hex.symbol + ' ' + this.liuyaoPan!.hex.name).fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text('属' + this.liuyaoPan!.palace + '宫(' + this.liuyaoPan!.palaceElement + ')').fontSize(10).fontColor(INK.PLACEHOLDER)
          Blank().layoutWeight(1)
          Column({ space: 2 }) {
            Text('月建：' + this.liuyaoPan!.monthStemBranch).fontSize(9).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            Text('日辰：' + this.liuyaoPan!.dayStemBranch).fontSize(9).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text('旬空：' + this.liuyaoPan!.xunKong.join('、')).fontSize(9).fontColor(INK.PLACEHOLDER)
          }.alignItems(HorizontalAlign.End)
        }.width('100%').padding({ bottom: 4 })

        Divider().color(COLORS.INK_BLACK).opacity(0.3)

        // Column headers
        Row() {
          Text('爻').width(30).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('动').width(20).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('六亲').width(40).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('世应').width(30).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('纳甲').width(46).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('六兽').width(40).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('爻 辞').layoutWeight(1).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
        }
        .width('100%').padding({ left: 6, right: 6, top: 6, bottom: 6 })
        .backgroundColor(COLORS.INK_BLACK)

        // Rows: 上→初 (reverse from top to bottom)
        ForEach(this.liuyaoPan!.lines.slice().reverse(), (line: LiuYaoLine, ri: number) => {
          Row() {
            // 爻位 + 阴阳符号
            Text(line.positionName + (line.lineYang ? ' ⚊' : ' ⚋'))
              .width(30).fontSize(10)
              .fontColor(line.isMoving ? COLORS.IMPERIAL_RED : line.shiYing !== '—' ? COLORS.INK_BLACK : INK.BODY)
              .fontWeight(line.isMoving || line.shiYing !== '—' ? FontWeight.Bold : FontWeight.Normal)
            // 动
            Text(line.isMoving ? '○' : '')
              .width(20).fontSize(10)
              .fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            // 六亲 (colored)
            Text(line.liuqin)
              .width(40).fontSize(10)
              .fontColor(line.liuqin === '官鬼' ? COLORS.IMPERIAL_RED :
                line.liuqin === '妻财' ? COLORS.WOOD :
                line.liuqin === '子孙' ? COLORS.AMBER_GOLD : COLORS.INK_BLACK)
              .fontWeight(FontWeight.Bold)
            // 世应
            Text(line.shiYing)
              .width(30).fontSize(10)
              .fontColor(line.shiYing === '世' ? COLORS.IMPERIAL_RED :
                line.shiYing === '应' ? COLORS.WATER : INK.PLACEHOLDER)
              .fontWeight(FontWeight.Bold)
            // 纳甲 (strikethrough if 旬空)
            Text(line.nazhi.stem + line.nazhi.branch)
              .width(46).fontSize(9)
              .fontColor(this.isLiuYaoKong(line) ? INK.PLACEHOLDER : INK.BODY)
              .decoration(this.isLiuYaoKong(line) ? { type: TextDecorationType.LineThrough } : { type: TextDecorationType.None })
            // 六兽
            Text(line.liushou)
              .width(40).fontSize(8)
              .fontColor(line.liushou === '青龙' ? COLORS.WOOD :
                line.liushou === '朱雀' ? COLORS.IMPERIAL_RED :
                line.liushou === '玄武' ? COLORS.WATER :
                line.liushou === '白虎' ? COLORS.METAL : INK.SECONDARY)
            // 爻辞
            Text(this.getHexLineText(5 - ri))
              .layoutWeight(1).fontSize(9).fontColor(INK.SECONDARY)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').padding({ left: 6, right: 6, top: 7, bottom: 7 })
          .backgroundColor(line.shiYing !== '—' ? COLORS.ACTIVE_CARD_BG : COLORS.WHITE)
          .border({ width: { bottom: 1 }, color: INK.HAIRLINE })
        }, (_line: LiuYaoLine, idx: number) => idx.toString())
      }
      .width('100%').padding(12)
      .backgroundColor(COLORS.WHITE).border({ width: 1, color: COLORS.INK_BLACK })
    }
  }

  @Builder HexagramCard() {
    if (this.result) {
      Column({ space: 12 }) {
        Row({ space: 16 }) {
          Text(this.result!.originalHex.symbol).fontSize(64).fontColor(COLORS.IMPERIAL_RED)
          if (this.result!.changedHex) {
            Text('→').fontSize(24).fontColor(INK.PLACEHOLDER)
            Text(this.result!.changedHex.symbol).fontSize(64).fontColor(COLORS.INK_BLACK)
          }
          Column({ space: 4 }) {
            Text(this.result!.originalHex.name).fontSize(32).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(this.result!.originalHex.pinyin).fontSize(12).fontColor(INK.SECONDARY)
            Text('第' + this.result!.originalHex.number + '卦').fontSize(10).fontColor(INK.PLACEHOLDER)
          }.alignItems(HorizontalAlign.Start)
        }
        Text(this.result!.originalHex.judgement).fontSize(14).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
        Text(this.result!.originalHex.meaning).fontSize(12).fontColor(INK.BODY).lineHeight(20)
      }
      .width('100%').padding(24)
      .backgroundColor(COLORS.ACTIVE_CARD_BG).border({ width: 1, color: INK.HAIRLINE })
    }
  }

  @Builder EvolutionText() {
    if (this.result && this.result.changedHex) {
      Text('目前处于【' + this.result.originalHex.name + '】之势，由于能量在爻位的剧烈波动，正在向【' + this.result.changedHex.name + '】卦演化。')
        .fontSize(11).fontColor(INK.SECONDARY).fontStyle(FontStyle.Italic).lineHeight(18)
        .width('100%').padding(12)
        .backgroundColor(RED.BG_FAINT)
        .border({ width: { left: 2 }, color: RED.BORDER })
    }
  }

  // 上下卦分析
  @Builder TrigramBreakdownCard() {
    if (this.result) {
      Column({ space: 8 }) {
        Text('上下卦').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Row({ space: 12 }) {
          // Lower trigram
          Column({ space: 4 }) {
            Text('下卦（内卦）').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.getLowerTrigram().name + ' ' + this.getLowerTrigram().nature).fontSize(16).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text('五行：' + this.getLowerTrigram().element).fontSize(10).fontColor(INK.SECONDARY)
          }
          .padding(12).backgroundColor(INK.BG_FAINT).layoutWeight(1)
          Text('⚡').fontSize(16)
          // Upper trigram
          Column({ space: 4 }) {
            Text('上卦（外卦）').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.getUpperTrigram().name + ' ' + this.getUpperTrigram().nature).fontSize(16).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text('五行：' + this.getUpperTrigram().element).fontSize(10).fontColor(INK.SECONDARY)
          }
          .padding(12).backgroundColor(INK.BG_FAINT).layoutWeight(1)
        }.width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // 彖传
  @Builder TuanZhuanCard() {
    if (this.result && this.result.originalHex.tuanZhuan) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
          Text('彖传').fontSize(13).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
          Text('（卦辞诠释）').fontSize(9).fontColor(INK.PLACEHOLDER)
        }
        Text(this.result.originalHex.tuanZhuan)
          .fontSize(11).fontColor(INK.SECONDARY).lineHeight(20)
      }
      .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG).border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // 大象传
  @Builder DaXiangCard() {
    if (this.result && this.result.originalHex.daXiang) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Circle({ width: 6, height: 6 }).fill(COLORS.AMBER_GOLD)
          Text('大象传').fontSize(13).fontWeight(FontWeight.Bold).fontColor(COLORS.AMBER_GOLD)
          Text('（象辞启示）').fontSize(9).fontColor(INK.PLACEHOLDER)
        }
        Text(this.result.originalHex.daXiang)
          .fontSize(12).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold).lineHeight(22)
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // 序卦传
  @Builder XuGuaCard() {
    if (this.result && this.result.originalHex.xuGua) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('📜').fontSize(12)
          Text('序卦传').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
          Text('（卦序由来）').fontSize(9).fontColor(INK.PLACEHOLDER)
        }
        Text(this.result.originalHex.xuGua)
          .fontSize(10).fontColor(INK.SECONDARY).fontStyle(FontStyle.Italic).lineHeight(17)
      }
      .width('100%').padding(12)
      .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE })
    }
  }

  @Builder TiYongCard() {
    if (this.result) {
      Column({ space: 8 }) {
        Text('体用生克').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text('体卦 (主方)').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.result!.tiYong.ti + ' (' + this.result!.tiYong.tiElement + ')').fontSize(18)
              .fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }
          Text('⚡').fontSize(20)
          Column({ space: 4 }) {
            Text('用卦 (客方)').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.result!.tiYong.yong + ' (' + this.result!.tiYong.yongElement + ')').fontSize(18)
              .fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }
        }
        Text(this.result!.tiYong.relation + ' · ' + this.result!.tiYong.relative)
          .fontSize(14).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
        Text(this.result!.tiYong.description).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)
      }
      .width('100%').padding(16)
      .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  @Builder LineDetailsContent() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('爻位详情').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text(this.result!.movingIndexes.length + ' 个动爻').fontSize(9)
          .fontColor(COLORS.IMPERIAL_RED)
          .backgroundColor(RED.BG_MEDIUM)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(4)
      }
      ForEach(this.result!.lineDetails, (detail: LineDetail, idx: number) => {
        Column({ space: 8 }) {
          // Header
          Row() {
            Text(this.isMovingLine(idx) ? '⚡ 第' + (idx + 1) + '爻 (动爻)' : '第' + (idx + 1) + '爻')
              .fontSize(10)
              .fontColor(this.isMovingLine(idx) ? COLORS.IMPERIAL_RED : INK.BODY)
              .fontWeight(this.isMovingLine(idx) ? FontWeight.Bold : FontWeight.Normal)
          }
          // 爻辞
          Text(detail.text).fontSize(14).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          // 小象传 (NEW)
          if (detail.xiaoXiang) {
            Text('《象》曰：' + detail.xiaoXiang)
              .fontSize(10).fontColor(COLORS.AMBER_GOLD).fontStyle(FontStyle.Italic)
              .padding({ left: 8, top: 4, bottom: 4 })
              .border({ width: { left: 2 }, color: COLORS.AMBER_GOLD + '33' })
          }
          // 爻位分析 (NEW)
          if (detail.yaoWei) {
            Text(detail.yaoWei)
              .fontSize(9).fontColor(INK.PLACEHOLDER).lineHeight(14)
              .padding(6).backgroundColor(INK.BG_FAINT)
          }
          // Position context
          Text(detail.positionContext).fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
          // Analysis
          Text(detail.analysis).fontSize(10).fontColor(INK.SECONDARY).lineHeight(16)
          // Allusion
          Text(detail.allusion).fontSize(9).fontColor(INK.PLACEHOLDER).lineHeight(14)
            .padding(8).backgroundColor(INK.BG_FAINT)
        }
        .width('100%').padding(12).backgroundColor(COLORS.WHITE + '99')
        .border({ width: 1, color: this.isMovingLine(idx) ? RED.BORDER : INK.HAIRLINE })
      }, (_detail: LineDetail, idx: number) => idx.toString())
    }.width('100%')
  }

  @Builder ChatContent() {
    AIChatPanel({
      aiLoading: this.aiLoading,
      chatHistory: $chatHistory,
      activeCategory: this.activeCategory,
      onCategoryChange: (catId: string) => { this.activeCategory = catId },
      onSend: (text: string) => { this.sendFollowUp(text) }
    })
  }

  @Builder HistoryContent() {
    Column({ space: 8 }) {
      Text('历史记录').fontSize(11).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
      ForEach(this.history, (item: DivinationResult, idx: number) => {
        Row({ space: 12 }) {
          Text(item.originalHex.symbol).fontSize(24).fontColor(COLORS.IMPERIAL_RED)
          Column({ space: 2 }) {
            Text(item.originalHex.name).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(item.originalHex.judgement).fontSize(10).fontColor(INK.SECONDARY)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%').padding(12)
        .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
        .onClick(() => {
          this.result = item
          this.baseAnalysis = getOfflineIChingAnalysis(item.originalBinary)
        })
      }, (_item: DivinationResult, idx: number) => idx.toString())
    }.width('100%')
  }

  // ========== Logic ==========

  getLineValueOr(idx: number, defaultVal: number): number {
    return idx < this.lines.length ? this.lines[idx].value : defaultVal
  }

  setManualLine(idx: number, value: number): void {
    while (this.lines.length <= idx) {
      this.lines.push({ value: 7, isMoving: false, type: 'yang' })
    }
    this.lines[idx] = { value, isMoving: value === 6 || value === 9, type: (value === 7 || value === 9) ? 'yang' : 'yin' }
    this.lines = [...this.lines]
  }

  castCoin(): void {
    const r = Math.random() * 16
    let value = 8
    if (r < 1) value = 6
    else if (r < 4) value = 9
    else if (r < 8) value = 7
    this.lines = [...this.lines, { value, isMoving: value === 6 || value === 9, type: (value === 7 || value === 9) ? 'yang' : 'yin' }]
  }

  calculateResult(): void {
    if (this.lines.length < 6) return
    const binary = this.lines.map((l: Line) => l.type === 'yang' ? '1' : '0').join('')
    const movingIndexes: number[] = []
    this.lines.forEach((l: Line, i: number) => { if (l.isMoving) movingIndexes.push(i) })

    const originalHex = GET_HEX_BY_BINARY(binary)
    const changedBin = movingIndexes.length > 0 ? getChangedHexagram(binary, movingIndexes) : undefined
    const changedHex = changedBin ? GET_HEX_BY_BINARY(changedBin) : undefined

    const res: DivinationResult = {
      originalBinary: binary,
      changedBinary: changedBin,
      movingIndexes: movingIndexes,
      originalHex: originalHex,
      changedHex: changedHex,
      mutualHex: GET_HEX_BY_BINARY(getMutualHexagram(binary)),
      oppositeHex: GET_HEX_BY_BINARY(getOppositeHexagram(binary)),
      inverseHex: GET_HEX_BY_BINARY(getInverseHexagram(binary)),
      tiYong: getTiYong(binary, movingIndexes.length > 0 ? movingIndexes[0] : null),
      lineDetails: getLineDetails(originalHex, movingIndexes)
    }
    this.result = res
    this.baseAnalysis = getOfflineIChingAnalysis(binary)
    this.chatHistory = []
    this.history = [res, ...this.history.slice(0, 9)]

    // Build liuyao pan with current time
    const now = new Date()
    const daySB = this.computeDayStemBranch(now)
    const monthSB = this.computeMonthStemBranch(now)
    this.liuyaoPan = buildLiuYaoPan(binary, movingIndexes, daySB.stem, daySB.branch, monthSB.stem, monthSB.branch)
  }

  calculateNumberDivination(): void {
    const n1 = parseInt(this.number1) || Math.floor(Math.random() * 100)
    const n2 = parseInt(this.number2) || Math.floor(Math.random() * 100)
    const n3 = parseInt(this.number3) || Math.floor(Math.random() * 100)
    this.generateLines(n1 * 10000 + n2 * 100 + n3, 31, 7)
    this.calculateResult()
  }

  calculateTimeDivination(): void {
    const now = new Date()
    const seed = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate()
    this.generateLines(seed, 37, now.getHours() * 7 + 13)
    this.calculateResult()
  }

  generateLines(seed: number, mul: number, add: number): void {
    this.lines = []
    for (let i = 0; i < 6; i++) {
      const v = ((seed * (i + 1) * mul + i * add) % 16) < 1 ? 6 : ((seed * (i + 1) * mul + i * add) % 16) < 4 ? 9 : ((seed * (i + 1) * mul + i * add) % 16) < 8 ? 7 : 8
      this.lines.push({ value: v, isMoving: v === 6 || v === 9, type: (v === 7 || v === 9) ? 'yang' : 'yin' })
    }
  }

  isMovingLine(idx: number): boolean {
    return this.result ? this.result.movingIndexes.indexOf(idx) >= 0 : false
  }

  isLiuYaoKong(line: LiuYaoLine): boolean {
    if (!this.liuyaoPan) return false
    return line.nazhi.branch === this.liuyaoPan.xunKong[0] || line.nazhi.branch === this.liuyaoPan.xunKong[1]
  }

  getHexLineText(lineIdx: number): string {
    if (!this.liuyaoPan) return ''
    const lines = this.liuyaoPan.hex.lines
    if (!lines || lineIdx < 0 || lineIdx >= lines.length) return ''
    return lines[lineIdx]
  }

  getLowerTrigram(): TrigramBrief {
    if (!this.result) return { name: '?', nature: '?', element: '?' }
    return getTrigramFromBin(this.result.originalHex.binary.slice(0, 3))
  }

  getUpperTrigram(): TrigramBrief {
    if (!this.result) return { name: '?', nature: '?', element: '?' }
    return getTrigramFromBin(this.result.originalHex.binary.slice(3, 6))
  }

  async sendFollowUp(text: string) {
    if (!this.result) return
    this.aiLoading = true
    this.chatHistory = [...this.chatHistory, { role: 'user', content: text }]
    try {
      const contextPrompt = this.buildHexagramContext()
      const messages: ChatMessage[] = [
        { role: 'user', content: contextPrompt },
        { role: 'assistant', content: this.baseAnalysis },
        ...this.chatHistory
      ]
      const reply = await interpretMetaphysics(messages, this.aiConfig)
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: reply }]
    } catch (_e) {
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: 'AI解析暂时不可用。' + this.baseAnalysis }]
    } finally {
      this.aiLoading = false
    }
  }

  buildHexagramContext(): string {
    if (!this.result) return ''
    const r = this.result
    let catLabel: string = '综合运势'
    for (let i: number = 0; i < QUESTION_CATEGORIES.length; i++) {
      if (QUESTION_CATEGORIES[i].id === this.activeCategory) {
        catLabel = QUESTION_CATEGORIES[i].label
        break
      }
    }
    let ctx = '请作为天道先生，对以下卦象进行【' + catLabel + '】方面的解析：\n' +
      '本卦：' + r.originalHex.symbol + ' ' + r.originalHex.name + '(' + r.originalHex.pinyin + ')\n' +
      '卦辞：' + r.originalHex.judgement + '\n' +
      '释义：' + r.originalHex.meaning + '\n'
    if (r.changedHex) { ctx += '变卦：' + r.changedHex.symbol + ' ' + r.changedHex.name + '\n' }
    ctx += '互卦：' + r.mutualHex.symbol + ' ' + r.mutualHex.name + '\n' +
      '体用：' + r.tiYong.ti + '(' + r.tiYong.tiElement + ')为体，' + r.tiYong.yong + '(' + r.tiYong.yongElement + ')为用\n' +
      '体用关系：' + r.tiYong.relation + ' - ' + r.tiYong.description + '\n' +
      '动爻数量：' + r.movingIndexes.length + '个'
    return ctx
  }

  // Compute day stem-branch from solar date
  computeDayStemBranch(date: Date): StemBranch {
    const refDate = new Date(1900, 0, 1)
    const diff = Math.floor((date.getTime() - refDate.getTime()) / 86400000)
    const idx = ((diff % 60) + 60 + 10) % 60
    return { stem: HEAVENLY_STEMS[idx % 10], branch: EARTHLY_BRANCHES[idx % 12] }
  }

  // Compute month stem-branch from solar date
  computeMonthStemBranch(date: Date): StemBranch {
    const yearSB = ((date.getFullYear() - 4) % 60 + 60) % 60
    const monthNum = date.getMonth() + 1
    const bases: number[] = [2, 4, 6, 8, 0]
    const stemIdx = (bases[yearSB % 5] + monthNum - 1) % 10
    const branchIdx = (monthNum + 1) % 12
    return { stem: HEAVENLY_STEMS[stemIdx], branch: EARTHLY_BRANCHES[branchIdx] }
  }
}
