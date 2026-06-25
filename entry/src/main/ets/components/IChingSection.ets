import { COLORS, INK, RED, OP } from '../common/constants'
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
          if (bit === '0') {
            Row().height(2).backgroundColor(this.color).opacity(0.8).layoutWeight(1)
          }
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

  build() {
    Column({ space: 24 }) {
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
      this.HexagramCard()
      if (this.result && this.result.changedHex) { this.EvolutionText() }
      if (this.result) { this.TiYongCard() }
      if (this.result && this.result.originalHex.lines) { this.LineDetailsContent() }
      this.ChatContent()
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
        const isMoving = this.isMovingLine(idx)
        Column({ space: 8 }) {
          Row() {
            Text(isMoving ? '⚡ 第' + (idx + 1) + '爻 (动爻)' : '第' + (idx + 1) + '爻')
              .fontSize(10)
              .fontColor(isMoving ? COLORS.IMPERIAL_RED : INK.BODY)
              .fontWeight(isMoving ? FontWeight.Bold : FontWeight.Normal)
          }
          Text(detail.text).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text(detail.positionContext).fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
          Text(detail.analysis).fontSize(10).fontColor(INK.SECONDARY).lineHeight(16)
          Text(detail.allusion).fontSize(9).fontColor(INK.PLACEHOLDER).lineHeight(14)
            .padding(8).backgroundColor(INK.BG_FAINT)
        }
        .width('100%').padding(12).backgroundColor(COLORS.WHITE + '99')
        .border({ width: 1, color: isMoving ? RED.BORDER : INK.HAIRLINE })
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
    const catLabel = QUESTION_CATEGORIES.find(c => c.id === this.activeCategory)?.label ?? '综合运势'
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
