import { COLORS, INK, RED, OP } from '../common/constants'
import { getDayStemBranch, getMonthStemBranch } from '../model/lunar-service'
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
import {
  SavedIChingReading, saveIChingReading, loadIChingReadings, deleteIChingReading
} from '../services/readingStore'
import { buildOfflineIChingReport } from '../services/offlineInterpreter'
import { formatIChingShareText, shareText } from '../services/exportService'
import pasteboard from '@ohos.pasteboard'

interface Line {
  value: number
  isMoving: boolean
  type: string
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

// Pre-build all 64 hexagrams for search (lazy-initialized on first search)
let allHexagramsCache: Hexagram[] | null = null
function getAllHexagrams(): Hexagram[] {
  if (allHexagramsCache !== null) return allHexagramsCache
  const hexagrams: Hexagram[] = []
  for (let i = 0; i < 64; i++) {
    const bin = i.toString(2).padStart(6, '0')
    hexagrams.push(GET_HEX_BY_BINARY(bin))
  }
  allHexagramsCache = hexagrams
  return hexagrams
}

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
  return TRIGRAM_MAP.get(bin) ?? { name: '?', nature: '?', element: '?' }
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
      })
    }.width(24)
  }
}

// ---- Main IChing Section ----
@Component
export struct IChingSection {
  @Prop aiConfig: AIConfig
  @StorageLink('uiDark') isDark: boolean = false
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
  @State records: SavedIChingReading[] = []
  @State showRecords: boolean = false
  @State offlineReport: string = ''
  @State showOffline: boolean = false
  @State liuyaoPan: LiuYaoPan | null = null
  @State searchQuery: string = ''
  @State searchResults: Hexagram[] = []
  @State showSearch: boolean = false

  async aboutToAppear() {
    this.records = await loadIChingReadings()
  }

  build() {
    Column({ space: 22 }) {
      // Search bar
      this.SearchBar()

      // Method tabs — nicer pill selector
      Column({ space: 6 }) {
        Text('起卦方式').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
        Row({ space: 6 }) {
          this.MethodButton('coin', '🪙', '硬币')
          this.MethodButton('number', '🔢', '数字')
          this.MethodButton('time', '🕐', '时间')
          this.MethodButton('manual', '✋', '手动')
        }.width('100%').justifyContent(FlexAlign.SpaceBetween)
      }

      // Records toggle
      Row({ space: 8 }) {
        Text('📋 我的记录').fontSize(10).fontColor(INK.CAPTION).fontWeight(FontWeight.Bold)
        Blank().layoutWeight(1)
        Button(this.showRecords ? '收起 ▲' : `展开 (${this.records.length})`)
          .fontSize(9).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
          .borderRadius(10).padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => { this.showRecords = !this.showRecords })
      }.width('100%')
      if (this.showRecords) { this.RecordsPanel() }

      // Method-specific input
      this.InputForMethod()

      // Loading / Error
      if (this.loading) {
        Row({ space: 12 }) {
          LoadingProgress().width(22).height(22).color(COLORS.IMPERIAL_RED)
          Text('起卦中...').fontSize(12).fontColor(INK.SECONDARY)
        }.width('100%').justifyContent(FlexAlign.Center).padding(24)
      }
      if (this.error.length > 0) {
        Text(this.error).fontSize(12).fontColor(COLORS.IMPERIAL_RED)
          .padding(14).backgroundColor(RED.BG_FAINT).borderRadius(12).width('100%')
      }

      // Results
      if (this.result) { this.ResultContent() }
    }.width('100%')
  }

  @Builder MethodButton(methodId: string, icon: string, label: string) {
    Button(icon + ' ' + label)
      .fontSize(11).fontWeight(FontWeight.Bold)
      .fontColor(this.method === methodId ? COLORS.WHITE : INK.SECONDARY)
      .backgroundColor(this.method === methodId ? COLORS.INK_BLACK : INK.BG_FAINT)
      .borderRadius(12).padding({ left: 16, right: 16, top: 9, bottom: 9 })
      .onClick(() => { this.method = methodId; this.resetDivination() })
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
        TextInput({ placeholder: '🔍 搜索卦名、拼音、卦辞...', text: this.searchQuery })
          .onChange((v: string) => {
            this.searchQuery = v
            this.onSearch(v)
          })
          .layoutWeight(1).fontSize(12).padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor(INK.BG_FAINT).border({ width: 1.5, color: INK.FAINT }).borderRadius(14)
        if (this.searchQuery.length > 0) {
          Button('✕').fontSize(13).width(32).height(32)
            .fontColor(INK.SECONDARY).backgroundColor(INK.BG_FAINT).borderRadius(16)
            .onClick(() => { this.searchQuery = ''; this.searchResults = []; this.showSearch = false })
        }
      }.width('100%')
      if (this.showSearch && this.searchResults.length > 0) {
        Column({ space: 4 }) {
          ForEach(this.searchResults.slice(0, 8), (hex: Hexagram) => {
            Row({ space: 12 }) {
              Text(hex.symbol).fontSize(24).fontColor(COLORS.IMPERIAL_RED)
              Column({ space: 2 }) {
                Text(hex.name).fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
                Text(hex.pinyin + ' · 第' + hex.number + '卦').fontSize(9).fontColor(INK.PLACEHOLDER)
                Text(hex.judgement).fontSize(9).fontColor(INK.SECONDARY)
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }
            .width('100%').padding(10)
            .backgroundColor(COLORS.WHITE).border({ width: 1, color: INK.HAIRLINE }).borderRadius(10)
            .onClick(() => {
              this.showHexagramDetail(hex)
              this.searchQuery = ''; this.searchResults = []; this.showSearch = false
            })
          })
        }
        .width('100%').constraintSize({ maxHeight: 320 })
        .border({ width: 1.5, color: INK.FAINT }).borderRadius(14)
        .padding(4)
      }
    }.width('100%')
  }

  onSearch(query: string): void {
    if (query.trim().length === 0) { this.searchResults = []; this.showSearch = false; return }
    const q = query.trim().toLowerCase()
    this.searchResults = getAllHexagrams().filter(h =>
      h.name.includes(q) || h.pinyin.toLowerCase().includes(q) ||
      h.judgement.includes(q) || h.meaning.includes(q)
    )
    this.showSearch = this.searchResults.length > 0
  }

  showHexagramDetail(hex: Hexagram): void {
    this.method = ''
    this.lines = []
    this.applyResult(this.buildResultFromBinary(hex.binary, []), false)
  }

  // ========== Method inputs ==========

  @Builder InputForMethod() {
    if (this.method === 'coin')   { this.CoinInput() }
    if (this.method === 'number') { this.NumberInput() }
    if (this.method === 'time')   { this.TimeInput() }
    if (this.method === 'manual') { this.ManualInput() }
  }

  @Builder CoinInput() {
    Column({ space: 14 }) {
      Text('🪙 模拟三钱法起卦，请连续掷出 6 爻')
        .fontSize(11).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      if (this.lines.length < 6) {
        Text('第 ' + (this.lines.length + 1) + ' 爻（从下往上）')
          .fontSize(13).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Button('🎲 掷钱起卦')
          .fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.IMPERIAL_RED).backgroundColor(COLORS.WHITE)
          .border({ width: 1.5, color: RED.BORDER }).borderRadius(14)
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.castCoin() })
      }
      this.LineDisplay()
      if (this.lines.length === 6 && !this.result) {
        Button('🔮 完成起卦 · 解卦')
          .fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).borderRadius(14)
          .padding({ top: 13, bottom: 13 }).width('100%')
          .shadow({ radius: 8, color: COLORS.INK_BLACK + '20', offsetY: 3 })
          .onClick(() => { this.calculateResult() })
      }
      if (this.lines.length > 0) {
        Button('🔄 重新起卦').fontSize(10).fontColor(INK.SECONDARY)
          .onClick(() => { this.resetDivination() })
      }
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
  }

  @Builder NumberInput() {
    Column({ space: 14 }) {
      Text('🔢 输入 3 个数字，系统将据此推演卦象')
        .fontSize(11).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      Row({ space: 10 }) {
        TextInput({ placeholder: '数字1', text: this.number1 })
          .onChange((v: string) => { this.number1 = v }).type(InputType.Number)
          .width(80).fontSize(14).textAlign(TextAlign.Center)
          .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
        TextInput({ placeholder: '数字2', text: this.number2 })
          .onChange((v: string) => { this.number2 = v }).type(InputType.Number)
          .width(80).fontSize(14).textAlign(TextAlign.Center)
          .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
        TextInput({ placeholder: '数字3', text: this.number3 })
          .onChange((v: string) => { this.number3 = v }).type(InputType.Number)
          .width(80).fontSize(14).textAlign(TextAlign.Center)
          .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
      }.justifyContent(FlexAlign.Center)
      Button('🔮 数字起卦').fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED).borderRadius(14)
        .padding({ left: 32, right: 32, top: 12, bottom: 12 })
        .shadow({ radius: 6, color: COLORS.IMPERIAL_RED + '25', offsetY: 2 })
        .onClick(() => { this.calculateNumberDivination() })
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
  }

  @Builder TimeInput() {
    Column({ space: 14 }) {
      Text('🕐 依据当前时间自动起卦')
        .fontSize(11).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      Button('⏰ 时间起卦').fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED).borderRadius(14)
        .padding({ left: 32, right: 32, top: 12, bottom: 12 })
        .shadow({ radius: 6, color: COLORS.IMPERIAL_RED + '25', offsetY: 2 })
        .onClick(() => { this.calculateTimeDivination() })
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
  }

  @Builder ManualInput() {
    Column({ space: 12 }) {
      Text('✋ 手动选择每爻的阴阳属性（自下而上）')
        .fontSize(11).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).margin({ bottom: 4 })
      ForEach([0, 1, 2, 3, 4, 5], (idx: number) => {
        Row({ space: 6 }) {
          Text('第' + (idx + 1) + '爻').fontSize(10).fontColor(INK.BODY).width(36)
          this.ManualLineButton(idx, 7, '少阳 ⚊')
          this.ManualLineButton(idx, 8, '少阴 ⚋')
          this.ManualLineButton(idx, 9, '老阳 ⚊')
          this.ManualLineButton(idx, 6, '老阴 ⚋')
        }
      })
      if (this.lines.length === 6 && !this.result) {
        Button('🔮 排卦解卦').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).borderRadius(14)
          .padding({ top: 13, bottom: 13 }).width('100%')
          .shadow({ radius: 8, color: COLORS.INK_BLACK + '20', offsetY: 3 })
          .onClick(() => { this.calculateResult() })
      }
      if (this.lines.length > 0) {
        Button('🔄 重新起卦').fontSize(10).fontColor(INK.SECONDARY)
          .onClick(() => { this.resetDivination() })
      }
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
  }

  @Builder ManualLineButton(idx: number, value: number, label: string) {
    Button(label).fontSize(9).fontWeight(FontWeight.Bold)
      .fontColor(this.isManualLineSelected(idx, value) ? COLORS.WHITE : (value >= 7 ? INK.SECONDARY : RED.LABEL))
      .backgroundColor(this.isManualLineSelected(idx, value) ? (value >= 7 ? COLORS.INK_BLACK : COLORS.IMPERIAL_RED) : INK.BG_FAINT)
      .borderRadius(8).padding({ left: 8, right: 8, top: 5, bottom: 5 })
      .onClick(() => { this.setManualLine(idx, value) })
  }

  isManualLineSelected(idx: number, value: number): boolean {
    return idx < this.lines.length && this.lines[idx].value === value
  }

  @Builder LineDisplay() {
    if (this.lines.length > 0) {
      Column({ space: 3 }) {
        ForEach([...this.lines].reverse(), (line: Line, _idx: number) => {
          Row() {
            if (line.type === 'yang') {
              Row().width(80).height(5)
                .backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                .borderRadius(2)
            } else {
              Row({ space: 10 }) {
                Row().width(32).height(5)
                  .backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                  .borderRadius(2)
                Row().width(32).height(5)
                  .backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                  .borderRadius(2)
              }.width(80)
            }
          }.width(80).justifyContent(FlexAlign.Center).padding({ top: 5, bottom: 5 })
        })
      }
      .padding(14).backgroundColor(COLORS.WHITE + '99')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(14)
    }
  }

  // ========== Result display ==========

  @Builder ResultContent() {
    Column({ space: 18 }) {
      // 1. 六爻排盘表
      if (this.result) { this.LiuYaoTable() }
      // 2. 卦辞
      this.HexagramCard()
      if (this.result && this.result.changedHex) { this.EvolutionText() }
      // 3. 上下卦
      if (this.result) { this.TrigramBreakdownCard() }
      // 4. 彖传 / 大象 / 序卦
      if (this.result && this.result.originalHex.tuanZhuan) { this.TuanZhuanCard() }
      if (this.result && this.result.originalHex.daXiang)  { this.DaXiangCard() }
      if (this.result && this.result.originalHex.xuGua)    { this.XuGuaCard() }
      // 5. 体用
      if (this.result) { this.TiYongCard() }
      // 6. 爻位详情
      if (this.result && this.result.originalHex.lines) { this.LineDetailsContent() }

      // Actions
      Row({ space: 10 }) {
        Button('📋 复制').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).layoutWeight(1)
          .borderRadius(12).padding({ top: 11, bottom: 11 })
          .onClick(() => { this.copyResult() })
        Button('📤 分享').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED).layoutWeight(1)
          .borderRadius(12).padding({ top: 11, bottom: 11 })
          .onClick(() => { this.shareResult() })
        Button('🗑 清空对话').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(INK.LABEL).backgroundColor(INK.BG_FAINT).layoutWeight(1)
          .borderRadius(12).padding({ top: 11, bottom: 11 })
          .onClick(() => { this.chatHistory = [] })
      }.width('100%')

      this.OfflineReportCard()
      this.ChatContent()
    }
  }

  @Builder OfflineReportCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('📜 离线详析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text('OFFLINE').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
        Blank().layoutWeight(1)
        Button(this.showOffline ? '收起 ▲' : '展开 ▼')
          .fontSize(9).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
          .borderRadius(10).padding({ left: 10, right: 10, top: 5, bottom: 5 })
          .onClick(() => { this.showOffline = !this.showOffline })
      }.width('100%')
      Text('未配置 AI 也能获得完整解读：卦辞、彖象、动爻、体用、互错综一应俱全。')
        .fontSize(9).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      if (this.showOffline && this.offlineReport.length > 0) {
        Scroll() {
          Text(this.offlineReport)
            .fontSize(11).fontColor(INK.BODY).lineHeight(19)
            .width('100%').padding(14)
            .backgroundColor(COLORS.WHITE + '99')
            .border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
        }.height(380).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      }
    }
    .width('100%').padding(14)
    .backgroundColor(COLORS.ACTIVE_CARD_BG)
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
  }

  // ========== 六爻排盘表 ==========

  @Builder LiuYaoTable() {
    if (this.liuyaoPan !== null) {
      Column({ space: 0 }) {
        // Header info
        Row({ space: 12 }) {
          Text(this.liuyaoPan!.hex.symbol + ' ' + this.liuyaoPan!.hex.name)
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          Text('属' + this.liuyaoPan!.palace + '宫').fontSize(10).fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .backgroundColor(COLORS.INK_BLACK)
            .borderRadius(8).padding({ left: 10, right: 10, top: 4, bottom: 4 })
          Blank().layoutWeight(1)
          Column({ space: 2 }) {
            Row({ space: 6 }) {
              Text('月建 ' + this.liuyaoPan!.monthStemBranch).fontSize(9).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              Text('·').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text('日辰 ' + this.liuyaoPan!.dayStemBranch).fontSize(9).fontWeight(FontWeight.Bold)
            }
            Text('旬空：' + this.liuyaoPan!.xunKong.join('、'))
              .fontSize(8).fontColor(INK.PLACEHOLDER)
          }.alignItems(HorizontalAlign.End)
        }.width('100%').padding(14)

        // Column headers
        Row() {
          Text('爻').width(26).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('动').width(22).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('六亲').width(40).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('世应').width(26).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('纳甲').width(44).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('六兽').width(38).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
          Text('爻辞').layoutWeight(1).fontSize(8).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
        }
        .width('100%').padding({ left: 8, right: 8, top: 7, bottom: 7 })
        .backgroundColor(COLORS.INK_BLACK)

        // Rows
        ForEach(this.liuyaoPan!.lines.slice().reverse(), (line: LiuYaoLine, ri: number) => {
          Row() {
            Text(line.positionName + (line.lineYang ? ' ⚊' : ' ⚋'))
              .width(26).fontSize(10)
              .fontColor(line.isMoving ? COLORS.IMPERIAL_RED :
                line.shiYing !== '—' ? COLORS.INK_BLACK : INK.BODY)
              .fontWeight(line.isMoving || line.shiYing !== '—' ? FontWeight.Bold : FontWeight.Normal)
            Text(line.isMoving ? '○' : '')
              .width(22).fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            Text(line.liuqin).width(40).fontSize(10).fontWeight(FontWeight.Bold)
              .fontColor(line.liuqin === '官鬼' ? COLORS.IMPERIAL_RED :
                         line.liuqin === '妻财' ? COLORS.WOOD :
                         line.liuqin === '子孙' ? COLORS.AMBER_GOLD : COLORS.INK_BLACK)
            Text(line.shiYing).width(26).fontSize(10).fontWeight(FontWeight.Bold)
              .fontColor(line.shiYing === '世' ? COLORS.IMPERIAL_RED :
                         line.shiYing === '应' ? COLORS.WATER : INK.PLACEHOLDER)
            Text(line.nazhi.stem + line.nazhi.branch)
              .width(44).fontSize(9)
              .fontColor(this.isLiuYaoKong(line) ? INK.PLACEHOLDER : INK.BODY)
              .decoration(this.isLiuYaoKong(line) ?
                { type: TextDecorationType.LineThrough } : { type: TextDecorationType.None })
            Text(line.liushou).width(38).fontSize(8)
              .fontColor(line.liushou === '青龙' ? COLORS.WOOD :
                         line.liushou === '朱雀' ? COLORS.IMPERIAL_RED :
                         line.liushou === '玄武' ? COLORS.WATER :
                         line.liushou === '白虎' ? COLORS.METAL : INK.SECONDARY)
            Text(this.getHexLineText(5 - ri))
              .layoutWeight(1).fontSize(9).fontColor(INK.SECONDARY)
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%').padding({ left: 8, right: 8, top: 8, bottom: 8 })
          .backgroundColor(line.shiYing !== '—' ? COLORS.ACTIVE_CARD_BG :
                           line.isMoving ? RED.BG_FAINT : COLORS.WHITE + '66')
          .border({ width: { bottom: 1 }, color: INK.HAIRLINE })
        })
      }
      .width('100%')
      .backgroundColor(COLORS.WHITE)
      .border({ width: 1.5, color: COLORS.INK_BLACK }).borderRadius(14)
      .shadow({ radius: 8, color: COLORS.INK_BLACK + '10', offsetY: 2 })
    }
  }

  // ========== Hexagram card ==========

  @Builder HexagramCard() {
    if (this.result) {
      Column({ space: 14 }) {
        Row({ space: 16 }) {
          Text(this.result!.originalHex.symbol).fontSize(72).fontColor(COLORS.IMPERIAL_RED)
          if (this.result!.changedHex) {
            Text('→').fontSize(28).fontColor(INK.PLACEHOLDER)
            Text(this.result!.changedHex.symbol).fontSize(72).fontColor(COLORS.INK_BLACK)
          }
          Column({ space: 4 }) {
            Text(this.result!.originalHex.name).fontSize(34).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
            Text(this.result!.originalHex.pinyin).fontSize(13).fontColor(INK.SECONDARY)
            Text('第' + this.result!.originalHex.number + '卦')
              .fontSize(10).fontColor(INK.PLACEHOLDER)
              .backgroundColor(INK.BG_FAINT).borderRadius(6)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }.alignItems(HorizontalAlign.Start)
        }
        Divider().color(RED.BORDER)
        Text(this.result!.originalHex.judgement)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text(this.result!.originalHex.meaning)
          .fontSize(12).fontColor(INK.BODY).lineHeight(20)
      }
      .width('100%').padding(22)
      .backgroundColor(COLORS.ACTIVE_CARD_BG)
      .border({ width: 1.5, color: RED.BORDER }).borderRadius(18)
      .shadow({ radius: 8, color: COLORS.INK_BLACK + '0C', offsetY: 3 })
    }
  }

  @Builder EvolutionText() {
    if (this.result && this.result.changedHex) {
      Text('⚡ 由于动爻能量波动，【' + this.result.originalHex.name + '】正在向【' +
        this.result.changedHex.name + '】卦演化。')
        .fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED).lineHeight(19)
        .width('100%').padding(14)
        .backgroundColor(RED.BG_FAINT)
        .border({ width: { left: 3 }, color: COLORS.IMPERIAL_RED }).borderRadius(12)
    }
  }

  @Builder TrigramBreakdownCard() {
    if (this.result) {
      Column({ space: 12 }) {
        Text('上下卦').fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Row({ space: 10 }) {
          Column({ space: 4 }) {
            Text('下卦（内卦）').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.getLowerTrigram().name + ' ' + this.getLowerTrigram().nature)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
            Text('五行 ' + this.getLowerTrigram().element)
              .fontSize(10).fontColor(INK.SECONDARY)
              .backgroundColor(INK.BG_FAINT).borderRadius(6)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .padding(14).backgroundColor(INK.BG_FAINT).borderRadius(14).layoutWeight(1)
          Text('→').fontSize(20).fontColor(INK.PLACEHOLDER)
          Column({ space: 4 }) {
            Text('上卦（外卦）').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.getUpperTrigram().name + ' ' + this.getUpperTrigram().nature)
              .fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
            Text('五行 ' + this.getUpperTrigram().element)
              .fontSize(10).fontColor(INK.SECONDARY)
              .backgroundColor(INK.BG_FAINT).borderRadius(6)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          }
          .padding(14).backgroundColor(INK.BG_FAINT).borderRadius(14).layoutWeight(1)
        }.width('100%')
      }
      .width('100%').padding(16)
      .backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
      .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
    }
  }

  @Builder TuanZhuanCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Circle({ width: 7, height: 7 }).fill(COLORS.IMPERIAL_RED)
        Text('📖 彖传（卦辞诠释）').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
      }
      Text(this.result!.originalHex.tuanZhuan!)
        .fontSize(11).fontColor(INK.SECONDARY).lineHeight(20)
    }
    .width('100%').padding(16)
    .backgroundColor(COLORS.ACTIVE_CARD_BG)
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
  }

  @Builder DaXiangCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Circle({ width: 7, height: 7 }).fill(COLORS.AMBER_GOLD)
        Text('⚡ 大象传（象辞启示）').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.AMBER_GOLD)
      }
      Text(this.result!.originalHex.daXiang!)
        .fontSize(13).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK).lineHeight(22)
    }
    .width('100%').padding(16)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
  }

  @Builder XuGuaCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('📜 序卦传（卦序由来）').fontSize(11).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
      }
      Text(this.result!.originalHex.xuGua!)
        .fontSize(10).fontColor(INK.SECONDARY).fontStyle(FontStyle.Italic).lineHeight(17)
    }
    .width('100%').padding(14)
    .backgroundColor(INK.BG_FAINT).borderRadius(12)
  }

  @Builder TiYongCard() {
    if (this.result) {
      Column({ space: 12 }) {
        Text('体用生克').fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Row({ space: 14 }) {
          Column({ space: 4 }) {
            Text('体卦（主方）').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.result!.tiYong.ti + '（' + this.result!.tiYong.tiElement + '）')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          }
          Text('↔').fontSize(22).fontColor(INK.PLACEHOLDER)
          Column({ space: 4 }) {
            Text('用卦（客方）').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.result!.tiYong.yong + '（' + this.result!.tiYong.yongElement + '）')
              .fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          }
        }
        Text(this.result!.tiYong.relation + ' · ' + this.result!.tiYong.relative)
          .fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
        Text(this.result!.tiYong.description)
          .fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)
      }
      .width('100%').padding(16)
      .backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    }
  }

  @Builder LineDetailsContent() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('爻位详情').fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text(this.result!.movingIndexes.length + ' 动爻').fontSize(9).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
          .borderRadius(8).padding({ left: 10, right: 10, top: 3, bottom: 3 })
      }
      ForEach(this.result!.lineDetails, (detail: LineDetail, idx: number) => {
        Column({ space: 8 }) {
          Row() {
            Text(this.isMovingLine(idx) ? '⚡ 第' + (idx + 1) + '爻（动爻）' : '第' + (idx + 1) + '爻')
              .fontSize(10).fontWeight(this.isMovingLine(idx) ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(this.isMovingLine(idx) ? COLORS.IMPERIAL_RED : INK.BODY)
          }
          Text(detail.text).fontSize(15).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          if (detail.xiaoXiang) {
            Text('《象》曰：' + detail.xiaoXiang)
              .fontSize(10).fontColor(COLORS.AMBER_GOLD).fontStyle(FontStyle.Italic)
              .padding({ left: 8, top: 4, bottom: 4 })
              .border({ width: { left: 3 }, color: COLORS.AMBER_GOLD + '40' })
          }
          if (detail.yaoWei) {
            Text(detail.yaoWei).fontSize(9).fontColor(INK.PLACEHOLDER).lineHeight(14)
              .padding(8).backgroundColor(INK.BG_FAINT).borderRadius(8)
          }
          Text(detail.positionContext).fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
          Text(detail.analysis).fontSize(10).fontColor(INK.SECONDARY).lineHeight(17)
          Text(detail.allusion).fontSize(9).fontColor(INK.PLACEHOLDER).lineHeight(14)
            .padding(10).backgroundColor(INK.BG_FAINT).borderRadius(10)
        }
        .width('100%').padding(14)
        .backgroundColor(COLORS.WHITE + '99')
        .border({ width: 1.5, color: this.isMovingLine(idx) ? RED.BORDER : INK.HAIRLINE })
        .borderRadius(14)
      })
    }.width('100%')
  }

  @Builder ChatContent() {
    AIChatPanel({
      aiLoading: this.aiLoading,
      chatHistory: $chatHistory,
      activeCategory: this.activeCategory,
      onCategoryChange: (catId: string) => { this.activeCategory = catId },
      onSend: (text: string) => { this.sendFollowUp(text) },
      onClear: () => { this.chatHistory = [] }
    })
  }

  @Builder RecordsPanel() {
    Column({ space: 6 }) {
      if (this.records.length === 0) {
        Text('暂无保存的记录，起卦后将自动保存。')
          .fontSize(10).fontColor(INK.PLACEHOLDER).padding(14)
      } else {
        ForEach(this.records, (rec: SavedIChingReading) => {
          Row({ space: 10 }) {
            Column({ space: 3 }) {
              Text(rec.hexagramSymbol + ' ' + rec.hexagramName + ' · 第' + rec.hexagramNumber + '卦')
                .fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
              Text((rec.changedName ? rec.hexagramName + '→' + rec.changedName : rec.judgement) +
                ' · ' + rec.movingCount + '动爻')
                .fontSize(9).fontColor(INK.SECONDARY)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button('恢复').fontSize(9).fontColor(COLORS.IMPERIAL_RED)
              .backgroundColor(RED.BG_MEDIUM).borderRadius(8)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .onClick(() => { this.restoreRecord(rec) })
            Button('删除').fontSize(9).fontColor(INK.SECONDARY)
              .backgroundColor(INK.BG_FAINT).borderRadius(8)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .onClick(() => { this.removeRecord(rec) })
          }
          .width('100%').padding(12)
          .backgroundColor(COLORS.WHITE + '99')
          .border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
        })
      }
    }
    .width('100%').padding(12)
    .backgroundColor(INK.BG_FAINT).borderRadius(14)
    .border({ width: 1, color: INK.HAIRLINE })
  }

  // ========== Logic (unchanged) ==========

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
    this.applyResult(this.buildResultFromBinary(binary, movingIndexes), true)
  }

  buildResultFromBinary(binary: string, movingIndexes: number[]): DivinationResult {
    const originalHex = GET_HEX_BY_BINARY(binary)
    const changedBin = movingIndexes.length > 0 ? getChangedHexagram(binary, movingIndexes) : undefined
    const changedHex = changedBin ? GET_HEX_BY_BINARY(changedBin) : undefined
    return {
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
  }

  applyResult(res: DivinationResult, recordIt: boolean): void {
    this.result = res
    this.baseAnalysis = getOfflineIChingAnalysis(res.originalBinary)
    this.offlineReport = buildOfflineIChingReport({
      originalHex: res.originalHex, changedHex: res.changedHex,
      mutualHex: res.mutualHex, oppositeHex: res.oppositeHex, inverseHex: res.inverseHex,
      tiYong: res.tiYong, movingIndexes: res.movingIndexes, lineDetails: res.lineDetails
    })
    this.chatHistory = []
    this.history = [res, ...this.history.slice(0, 9)]

    const now = new Date()
    const daySBText = getDayStemBranch(now)
    const monthSBText = getMonthStemBranch(now)
    this.liuyaoPan = buildLiuYaoPan(res.originalBinary, res.movingIndexes,
      daySBText.charAt(0), daySBText.charAt(1), monthSBText.charAt(0), monthSBText.charAt(1))

    if (recordIt) { this.saveRecord(res) }
  }

  async saveRecord(res: DivinationResult) {
    const rec: SavedIChingReading = {
      id: 'i' + Date.now() + Math.floor(Math.random() * 10000),
      timestamp: Date.now(),
      method: this.method || 'coin',
      binary: res.originalBinary,
      moving: JSON.stringify(res.movingIndexes),
      hexagramName: res.originalHex.name,
      hexagramSymbol: res.originalHex.symbol,
      hexagramNumber: res.originalHex.number,
      judgement: res.originalHex.judgement,
      changedName: res.changedHex ? res.changedHex.name : undefined,
      changedSymbol: res.changedHex ? res.changedHex.symbol : undefined,
      movingCount: res.movingIndexes.length,
      tiYongRelation: res.tiYong.relation
    }
    await saveIChingReading(rec)
    this.records = [rec, ...this.records].slice(0, 20)
  }

  async restoreRecord(rec: SavedIChingReading) {
    let moving: number[] = []
    try { moving = JSON.parse(rec.moving) as number[] } catch (_e) { moving = [] }
    this.applyResult(this.buildResultFromBinary(rec.binary, moving), false)
  }

  async removeRecord(rec: SavedIChingReading) {
    await deleteIChingReading(rec.id)
    this.records = this.records.filter(r => r.id !== rec.id)
  }

  buildShareText(): string {
    if (!this.result) return ''
    const r = this.result
    return formatIChingShareText(
      r.originalHex.symbol, r.originalHex.name, r.originalHex.number,
      r.originalHex.judgement, r.originalHex.meaning,
      r.changedHex ? r.changedHex.symbol : '', r.changedHex ? r.changedHex.name : '',
      r.tiYong.ti, r.tiYong.tiElement, r.tiYong.yong, r.tiYong.yongElement,
      r.tiYong.relation, r.movingIndexes.length
    )
  }

  copyResult(): void {
    const text = this.buildShareText()
    if (text.length === 0) return
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '卦象结果已复制' })
    }).catch(() => {
      this.getUIContext().getPromptAction().showToast({ message: '复制失败' })
    })
  }

  shareResult(): void {
    const text = this.buildShareText()
    if (text.length === 0) return
    const ctx = this.getUIContext().getHostContext()
    if (ctx) {
      shareText(text, ctx).catch(() => {
        this.getUIContext().getPromptAction().showToast({ message: '分享失败' })
      })
    }
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
      const v = ((seed * (i + 1) * mul + i * add) % 16) < 1 ? 6 :
        ((seed * (i + 1) * mul + i * add) % 16) < 4 ? 9 :
        ((seed * (i + 1) * mul + i * add) % 16) < 8 ? 7 : 8
      this.lines.push({ value: v, isMoving: v === 6 || v === 9, type: (v === 7 || v === 9) ? 'yang' : 'yin' })
    }
  }

  isMovingLine(idx: number): boolean { return this.result ? this.result.movingIndexes.indexOf(idx) >= 0 : false }
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
  getLowerTrigram(): TrigramBrief { if (!this.result) return { name: '?', nature: '?', element: '?' }; return getTrigramFromBin(this.result.originalHex.binary.slice(0, 3)) }
  getUpperTrigram(): TrigramBrief { if (!this.result) return { name: '?', nature: '?', element: '?' }; return getTrigramFromBin(this.result.originalHex.binary.slice(3, 6)) }

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
      let reply: string
      if (!this.aiConfig.apiKey) { reply = this.offlineReport }
      else { reply = await interpretMetaphysics(messages, this.aiConfig) }
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: reply }]
    } catch (_e) {
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: 'AI解析暂时不可用。' + this.baseAnalysis }]
    } finally { this.aiLoading = false }
  }

  buildHexagramContext(): string {
    if (!this.result) return ''
    const r = this.result
    let catLabel: string = '综合运势'
    for (let i: number = 0; i < QUESTION_CATEGORIES.length; i++) {
      if (QUESTION_CATEGORIES[i].id === this.activeCategory) { catLabel = QUESTION_CATEGORIES[i].label; break }
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
}
