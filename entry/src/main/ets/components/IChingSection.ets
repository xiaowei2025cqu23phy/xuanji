import { COLORS } from '../common/constants'
import {
  GET_HEX_BY_BINARY, Hexagram, LineDetail,
  getMutualHexagram, getChangedHexagram, getOppositeHexagram, getInverseHexagram,
  getTiYong, TiYongResult, getLineDetails
} from '../model/iching-data'
import {
  interpretMetaphysics, getOfflineIChingAnalysis, AIConfig, ChatMessage,
  QUESTION_CATEGORIES, makeChatMessage, CategoryInfo
} from '../services/aiService'

interface Line {
  value: number
  isMoving: boolean
  type: string
}

function makeLine(value: number, isMoving: boolean, type: string): Line {
  let line: Line = { value: value, isMoving: isMoving, type: type }
  return line
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

@Component
struct MiniHexagram {
  @Prop binary: string
  @Prop color: string

  build() {
    Column({ space: 2 }) {
      ForEach(this.binary.split('').reverse(), (bit: string, idx: number) => {
        if (bit === '1') {
          Row()
            .width('100%')
            .height(2)
            .backgroundColor(this.color)
            .opacity(0.8)
        } else {
          Row({ space: 4 }) {
            Row().height(2).backgroundColor(this.color).opacity(0.8).layoutWeight(1)
            Row().height(2).backgroundColor(this.color).opacity(0.8).layoutWeight(1)
          }
          .width('100%')
        }
      }, (bit: string, idx: number) => idx.toString())
    }
    .width(24)
  }
}

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
  @State followUp: string = ''
  @State activeCategory: string = 'general'
  @State number1: string = ''
  @State number2: string = ''
  @State number3: string = ''
  @State history: DivinationResult[] = []

  build() {
    Column({ space: 24 }) {
      // Method selector
      Row({ space: 4 }) {
        Button('硬币起卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'coin' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .backgroundColor(this.method === 'coin' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'coin'; this.resetDivination() })

        Button('数字起卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'number' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .backgroundColor(this.method === 'number' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'number'; this.resetDivination() })

        Button('时间起卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'time' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .backgroundColor(this.method === 'time' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'time'; this.resetDivination() })

        Button('手动排卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.method === 'manual' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .backgroundColor(this.method === 'manual' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .onClick(() => { this.method = 'manual'; this.resetDivination() })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)

      // Method-specific input
      this.InputForMethod()

      // Loading/Error
      if (this.loading) {
        Row({ space: 12 }) {
          LoadingProgress().width(20).height(20).color(COLORS.IMPERIAL_RED)
          Text('起卦中...').fontSize(12).fontColor(COLORS.INK_BLACK + '66')
        }
        .width('100%').justifyContent(FlexAlign.Center).padding(24)
      }
      if (this.error.length > 0) {
        Text(this.error).fontSize(12).fontColor(COLORS.IMPERIAL_RED)
          .padding(12).backgroundColor(COLORS.IMPERIAL_RED + '08').width('100%')
      }

      // Results
      if (this.result) {
        this.ResultContent()
      }

      // History
      if (this.history.length > 0) {
        this.HistoryContent()
      }
    }
    .width('100%')
  }

  resetDivination(): void {
    this.lines = []
    this.result = null
    this.error = ''
    this.chatHistory = []
  }

  @Builder
  InputForMethod() {
    if (this.method === 'coin') {
      this.CoinInput()
    }
    if (this.method === 'number') {
      this.NumberInput()
    }
    if (this.method === 'time') {
      this.TimeInput()
    }
    if (this.method === 'manual') {
      this.ManualInput()
    }
  }

  @Builder
  CoinInput() {
    Column({ space: 16 }) {
      Text('模拟三钱法起卦，请连续掷出6爻')
        .fontSize(10)
        .fontColor(COLORS.INK_BLACK + '4D')

      if (this.lines.length < 6) {
        Text('第 ' + (this.lines.length + 1) + ' 爻 (从下往上)')
          .fontSize(12)
          .fontColor(COLORS.INK_BLACK + '80')
          .fontWeight(FontWeight.Bold)
        Button('掷钱起卦')
          .onClick(() => { this.castCoin() })
      }

      this.LineDisplay()

      if (this.lines.length === 6 && !this.result) {
        Button('完成起卦 · 解卦')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.INK_BLACK)
          .onClick(() => { this.calculateResult() })
      }

      if (this.lines.length > 0) {
        Button('重新起卦')
          .fontSize(10)
          .fontColor(COLORS.INK_BLACK + '66')
          .onClick(() => { this.resetDivination() })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  NumberInput() {
    Column({ space: 16 }) {
      Text('输入3个数字，系统将据此推演卦象')
        .fontSize(10)
        .fontColor(COLORS.INK_BLACK + '4D')

      Row({ space: 12 }) {
        TextInput({ placeholder: '数字1', text: this.number1 })
          .onChange((v: string) => { this.number1 = v })
          .type(InputType.Number)
          .width(80)
        TextInput({ placeholder: '数字2', text: this.number2 })
          .onChange((v: string) => { this.number2 = v })
          .type(InputType.Number)
          .width(80)
        TextInput({ placeholder: '数字3', text: this.number3 })
          .onChange((v: string) => { this.number3 = v })
          .type(InputType.Number)
          .width(80)
      }
      .justifyContent(FlexAlign.Center)

      Button('数字起卦')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE)
        .backgroundColor(COLORS.IMPERIAL_RED)
        .onClick(() => { this.calculateNumberDivination() })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  TimeInput() {
    Column({ space: 16 }) {
      Text('依据当前时间自动起卦')
        .fontSize(10)
        .fontColor(COLORS.INK_BLACK + '4D')

      Button('时间起卦')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE)
        .backgroundColor(COLORS.IMPERIAL_RED)
        .onClick(() => { this.calculateTimeDivination() })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  ManualInput() {
    Column({ space: 12 }) {
      Text('手动选择每爻的阴阳属性 (自下而上)')
        .fontSize(10)
        .fontColor(COLORS.INK_BLACK + '4D')
        .margin({ bottom: 4 })

      ForEach([0, 1, 2, 3, 4, 5], (idx: number) => {
        Row({ space: 8 }) {
          Text('第' + (idx + 1) + '爻：')
            .fontSize(11)
            .fontColor(COLORS.INK_BLACK + '80')

          Button('⚊ 少阳')
            .fontSize(10)
            .fontColor(this.getLineValueOr(idx, 7) === 7 ? COLORS.WHITE : COLORS.INK_BLACK + '66')
            .backgroundColor(this.getLineValueOr(idx, 7) === 7 ? COLORS.INK_BLACK : COLORS.INK_BLACK + '05')
            .onClick(() => { this.setManualLine(idx, 7) })

          Button('⚋ 少阴')
            .fontSize(10)
            .fontColor(this.getLineValueOr(idx, 8) === 8 ? COLORS.WHITE : COLORS.INK_BLACK + '66')
            .backgroundColor(this.getLineValueOr(idx, 8) === 8 ? COLORS.INK_BLACK : COLORS.INK_BLACK + '05')
            .onClick(() => { this.setManualLine(idx, 8) })

          Button('⚊ 老阳')
            .fontSize(10)
            .fontColor(this.getLineValueOr(idx, 9) === 9 ? COLORS.WHITE : COLORS.IMPERIAL_RED + '66')
            .backgroundColor(this.getLineValueOr(idx, 9) === 9 ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
            .onClick(() => { this.setManualLine(idx, 9) })

          Button('⚋ 老阴')
            .fontSize(10)
            .fontColor(this.getLineValueOr(idx, 6) === 6 ? COLORS.WHITE : COLORS.IMPERIAL_RED + '66')
            .backgroundColor(this.getLineValueOr(idx, 6) === 6 ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
            .onClick(() => { this.setManualLine(idx, 6) })
        }
      }, (idx: number) => idx.toString())

      if (this.lines.length === 6 && !this.result) {
        Button('排卦解卦')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.IMPERIAL_RED)
          .onClick(() => { this.calculateResult() })
      }

      if (this.lines.length > 0) {
        Button('重新起卦')
          .fontSize(10)
          .fontColor(COLORS.INK_BLACK + '66')
          .onClick(() => { this.resetDivination() })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  getLineValueOr(idx: number, defaultVal: number): number {
    if (idx < this.lines.length) {
      return this.lines[idx].value
    }
    return defaultVal
  }

  setManualLine(idx: number, value: number): void {
    while (this.lines.length <= idx) {
      let defaultLine: Line = makeLine(7, false, 'yang')
      this.lines.push(defaultLine)
    }
    this.lines[idx] = makeLine(value, value === 6 || value === 9, (value === 7 || value === 9) ? 'yang' : 'yin')
    this.lines = this.lines.slice()
  }

  @Builder
  LineDisplay() {
    if (this.lines.length > 0) {
      Column({ space: 2 }) {
        ForEach(this.lines, (line: Line, idx: number) => {
          Row() {
            if (line.type === 'yang') {
              Row()
                .width(80)
                .height(4)
                .backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
            } else {
              Row({ space: 8 }) {
                Row().width(32).height(4).backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                Row().width(32).height(4).backgroundColor(line.isMoving ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
              }
              .width(80)
            }
          }
          .width(80)
          .justifyContent(FlexAlign.Center)
          .padding({ top: 4, bottom: 4 })
        }, (line: Line, idx: number) => idx.toString())
      }
      .padding(12)
      .backgroundColor(COLORS.WHITE + '99')
      .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
    }
  }

  // Logic methods
  castCoin(): void {
    const r = Math.random() * 16
    let value: number = 8
    if (r < 1) value = 6
    else if (r < 4) value = 9
    else if (r < 8) value = 7
    else value = 8

    this.lines.push(makeLine(value, value === 6 || value === 9, (value === 7 || value === 9) ? 'yang' : 'yin'))
    this.lines = this.lines.slice()
  }

  calculateResult(): void {
    if (this.lines.length < 6) return

    const binary = this.lines.map((l: Line) => {
      if (l.type === 'yang') return '1'
      return '0'
    }).join('')

    const movingIndexes: number[] = []
    for (let i = 0; i < this.lines.length; i++) {
      if (this.lines[i].isMoving) { movingIndexes.push(i) }
    }

    const originalHex = GET_HEX_BY_BINARY(binary)
    const changedBin = movingIndexes.length > 0 ? getChangedHexagram(binary, movingIndexes) : undefined
    const changedHex = changedBin ? GET_HEX_BY_BINARY(changedBin) : undefined
    const mutualBin = getMutualHexagram(binary)
    const mutualHex = GET_HEX_BY_BINARY(mutualBin)
    const oppositeBin = getOppositeHexagram(binary)
    const oppositeHex = GET_HEX_BY_BINARY(oppositeBin)
    const inverseBin = getInverseHexagram(binary)
    const inverseHex = GET_HEX_BY_BINARY(inverseBin)
    const tiYong = getTiYong(binary, movingIndexes.length > 0 ? movingIndexes[0] : null)
    const lineDetails = getLineDetails(originalHex, movingIndexes)

    let res: DivinationResult = {
      originalBinary: binary,
      changedBinary: changedBin,
      movingIndexes: movingIndexes,
      originalHex: originalHex,
      changedHex: changedHex,
      mutualHex: mutualHex,
      oppositeHex: oppositeHex,
      inverseHex: inverseHex,
      tiYong: tiYong,
      lineDetails: lineDetails
    }
    this.result = res
    this.baseAnalysis = getOfflineIChingAnalysis(binary)
    this.chatHistory = []

    let newHistory: DivinationResult[] = []
    newHistory.push(res)
    for (let h = 0; h < this.history.length && h < 9; h++) {
      newHistory.push(this.history[h])
    }
    this.history = newHistory
  }

  calculateNumberDivination(): void {
    const n1 = parseInt(this.number1) || Math.floor(Math.random() * 100)
    const n2 = parseInt(this.number2) || Math.floor(Math.random() * 100)
    const n3 = parseInt(this.number3) || Math.floor(Math.random() * 100)
    const seed = n1 * 10000 + n2 * 100 + n3
    this.generateLines(seed, 31, 7)
    this.calculateResult()
  }

  calculateTimeDivination(): void {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth() + 1
    const day = now.getDate()
    const hour = now.getHours()
    const seed = year * 10000 + month * 100 + day
    this.generateLines(seed, 37, hour * 7 + 13)
    this.calculateResult()
  }

  generateLines(seed: number, mul: number, add: number): void {
    this.lines = []
    for (let i = 0; i < 6; i++) {
      const r = ((seed * (i + 1) * mul + i * add) % 16)
      const value = r < 1 ? 6 : r < 4 ? 9 : r < 8 ? 7 : 8
      this.lines.push(makeLine(value, value === 6 || value === 9, (value === 7 || value === 9) ? 'yang' : 'yin'))
    }
  }

  // Result content builder
  @Builder
  ResultContent() {
    Column({ space: 20 }) {
      // Hexagram Card
      if (this.result) {
        Column({ space: 12 }) {
          Row({ space: 16 }) {
            Text(this.result!.originalHex.symbol)
              .fontSize(64)
              .fontColor(COLORS.IMPERIAL_RED)

            if (this.result!.changedHex) {
              Text('→').fontSize(24).fontColor(COLORS.INK_BLACK + '4D')
              Text(this.result!.changedHex.symbol).fontSize(64).fontColor(COLORS.INK_BLACK)
            }

            Column({ space: 4 }) {
              Text(this.result!.originalHex.name)
                .fontSize(32).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text(this.result!.originalHex.pinyin).fontSize(12).fontColor(COLORS.INK_BLACK + '66')
              Text('第' + this.result!.originalHex.number + '卦').fontSize(10).fontColor(COLORS.INK_BLACK + '4D')
            }
            .alignItems(HorizontalAlign.Start)
          }

          Text(this.result!.originalHex.judgement).fontSize(14).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text(this.result!.originalHex.meaning).fontSize(12).fontColor(COLORS.INK_BLACK + '80').lineHeight(20)
        }
        .width('100%')
        .padding(24)
        .backgroundColor(COLORS.ACTIVE_CARD_BG)
        .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
      }

      // Evolution text
      if (this.result && this.result.changedHex) {
        Text('目前处于【' + this.result.originalHex.name + '】之势，由于能量在爻位的剧烈波动，正在向【' + this.result.changedHex.name + '】卦演化。')
          .fontSize(11).fontColor(COLORS.INK_BLACK + '66').fontStyle(FontStyle.Italic).lineHeight(18)
          .width('100%').padding(12)
          .backgroundColor(COLORS.IMPERIAL_RED + '05')
          .border({ width: { left: 2 }, color: COLORS.IMPERIAL_RED + '20' })
      }

      // TiYong
      if (this.result) { this.TiYongCard() }

      // Line details
      if (this.result && this.result.originalHex.lines) { this.LineDetailsContent() }

      // AI Chat
      this.ChatContent()
    }
  }

  @Builder
  TiYongCard() {
    if (this.result) {
      Column({ space: 8 }) {
        Text('体用生克').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK + '66')

        Row({ space: 16 }) {
          Column({ space: 4 }) {
            Text('体卦 (主方)').fontSize(9).fontColor(COLORS.INK_BLACK + '4D')
            Text(this.result!.tiYong.ti + ' (' + this.result!.tiYong.tiElement + ')').fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }
          Text('⚡').fontSize(20)
          Column({ space: 4 }) {
            Text('用卦 (客方)').fontSize(9).fontColor(COLORS.INK_BLACK + '4D')
            Text(this.result!.tiYong.yong + ' (' + this.result!.tiYong.yongElement + ')').fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }
        }

        Text(this.result!.tiYong.relation + ' · ' + this.result!.tiYong.relative)
          .fontSize(14).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
        Text(this.result!.tiYong.description).fontSize(11).fontColor(COLORS.INK_BLACK + '66').lineHeight(18)
      }
      .width('100%').padding(16)
      .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: COLORS.INK_BLACK + '0D' })
    }
  }

  @Builder
  LineDetailsContent() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('爻位详情').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK + '66')
        Text(this.result!.movingIndexes.length + ' 个动爻')
          .fontSize(9).fontColor(COLORS.IMPERIAL_RED)
          .backgroundColor(COLORS.IMPERIAL_RED + '0F')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
      }

      ForEach(this.result!.lineDetails, (detail: LineDetail, idx: number) => {
        Column({ space: 8 }) {
          Row() {
            Text(this.isMovingLine(idx) ? '⚡ 第' + (idx + 1) + '爻 (动爻)' : '第' + (idx + 1) + '爻')
              .fontSize(10)
              .fontColor(this.isMovingLine(idx) ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '80')
              .fontWeight(this.isMovingLine(idx) ? FontWeight.Bold : FontWeight.Normal)
          }
          Text(detail.text).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text(detail.positionContext).fontSize(10).fontColor(COLORS.INK_BLACK + '4D').fontStyle(FontStyle.Italic)
          Text(detail.analysis).fontSize(10).fontColor(COLORS.INK_BLACK + '66').lineHeight(16)
          Text(detail.allusion).fontSize(9).fontColor(COLORS.INK_BLACK + '4D').lineHeight(14)
            .padding(8).backgroundColor(COLORS.INK_BLACK + '03')
        }
        .width('100%').padding(12).backgroundColor(COLORS.WHITE + '99')
        .border({ width: 1, color: this.isMovingLine(idx) ? COLORS.IMPERIAL_RED + '33' : COLORS.INK_BLACK + '0D' })
      }, (detail: LineDetail, idx: number) => idx.toString())
    }
    .width('100%')
  }

  isMovingLine(idx: number): boolean {
    if (!this.result) return false
    for (let i = 0; i < this.result.movingIndexes.length; i++) {
      if (this.result.movingIndexes[i] === idx) return true
    }
    return false
  }

  @Builder
  ChatContent() {
    Column({ space: 16 }) {
      Divider().color(COLORS.INK_BLACK + '0D')
      Text('AI 大师解析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK + '66')

      Row({ space: 4 }) {
        ForEach(QUESTION_CATEGORIES, (cat: CategoryInfo) => {
          Text(cat.icon + ' ' + cat.label)
            .fontSize(9)
            .fontColor(this.activeCategory === cat.id ? COLORS.WHITE : COLORS.INK_BLACK + '66')
            .backgroundColor(this.activeCategory === cat.id ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .onClick(() => { this.activeCategory = cat.id })
        }, (cat: CategoryInfo) => cat.id)
      }
      .width('100%')

      if (this.chatHistory.length > 0) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.chatHistory, (msg: ChatMessage, idx: number) => {
              Row() {
                Text(msg.content)
                  .fontSize(11).fontColor(COLORS.INK_BLACK + '80').padding(12)
                  .backgroundColor(msg.role === 'user' ? COLORS.INK_BLACK + '08' : COLORS.IMPERIAL_RED + '08')
                  .constraintSize({ maxWidth: '80%' })
              }
              .width('100%')
              .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
            }, (msg: ChatMessage, idx: number) => idx.toString())
          }
          .width('100%')
        }
        .height(200)
      }

      Row({ space: 8 }) {
        TextInput({ placeholder: '输入追问...', text: this.followUp })
          .onChange((v: string) => { this.followUp = v })
          .layoutWeight(1).fontSize(11).padding(10)
          .backgroundColor(COLORS.INK_BLACK + '03').border({ width: 1, color: COLORS.INK_BLACK + '0D' })

        Button('发送')
          .fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.IMPERIAL_RED)
          .onClick(() => { this.sendFollowUp() })
      }
      .width('100%')
    }
    .width('100%')
  }

  async sendFollowUp(): Promise<void> {
    if (this.followUp.trim().length === 0 || !this.result) return

    this.aiLoading = true
    let userMsg: ChatMessage = makeChatMessage('user', this.followUp)
    let newHist: ChatMessage[] = []
    for (let j = 0; j < this.chatHistory.length; j++) { newHist.push(this.chatHistory[j]) }
    newHist.push(userMsg)
    this.chatHistory = newHist
    this.followUp = ''

    try {
      const contextPrompt = this.buildHexagramContext()
      let ctxMsg: ChatMessage = makeChatMessage('user', contextPrompt)
      let baseMsg: ChatMessage = makeChatMessage('assistant', this.baseAnalysis)

      let messages: ChatMessage[] = []
      messages.push(ctxMsg)
      messages.push(baseMsg)
      for (let k = 0; k < this.chatHistory.length; k++) { messages.push(this.chatHistory[k]) }

      const reply = await interpretMetaphysics(messages, this.aiConfig)
      let replyMsg: ChatMessage = makeChatMessage('assistant', reply)
      this.chatHistory.push(replyMsg)
      this.chatHistory = this.chatHistory.slice()
    } catch (e) {
      let errMsg: ChatMessage = makeChatMessage('assistant', 'AI解析暂时不可用。' + this.baseAnalysis)
      this.chatHistory.push(errMsg)
      this.chatHistory = this.chatHistory.slice()
    } finally {
      this.aiLoading = false
    }
  }

  buildHexagramContext(): string {
    if (!this.result) return ''
    const r = this.result
    let catLabel = '综合运势'
    for (let i = 0; i < QUESTION_CATEGORIES.length; i++) {
      if (QUESTION_CATEGORIES[i].id === this.activeCategory) { catLabel = QUESTION_CATEGORIES[i].label }
    }
    let ctx = '请作为天道先生，对以下卦象进行【' + catLabel + '】方面的解析：\n' +
      '本卦：' + r.originalHex.symbol + ' ' + r.originalHex.name + '(' + r.originalHex.pinyin + ')\n' +
      '卦辞：' + r.originalHex.judgement + '\n' +
      '释义：' + r.originalHex.meaning + '\n'
    if (r.changedHex) {
      ctx = ctx + '变卦：' + r.changedHex.symbol + ' ' + r.changedHex.name + '\n'
    }
    ctx = ctx + '互卦：' + r.mutualHex.symbol + ' ' + r.mutualHex.name + '\n' +
      '体用：' + r.tiYong.ti + '(' + r.tiYong.tiElement + ')为体，' + r.tiYong.yong + '(' + r.tiYong.yongElement + ')为用\n' +
      '体用关系：' + r.tiYong.relation + ' - ' + r.tiYong.description + '\n' +
      '动爻数量：' + r.movingIndexes.length + '个'
    return ctx
  }

  @Builder
  HistoryContent() {
    Column({ space: 8 }) {
      Text('历史记录').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK + '66')

      ForEach(this.history, (item: DivinationResult, idx: number) => {
        Row({ space: 12 }) {
          Text(item.originalHex.symbol).fontSize(24).fontColor(COLORS.IMPERIAL_RED)
          Column({ space: 2 }) {
            Text(item.originalHex.name).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(item.originalHex.judgement)
              .fontSize(10).fontColor(COLORS.INK_BLACK + '66')
              .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Start).layoutWeight(1)
        }
        .width('100%').padding(12)
        .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: COLORS.INK_BLACK + '0D' })
        .onClick(() => {
          this.result = item
          this.baseAnalysis = getOfflineIChingAnalysis(item.originalBinary)
        })
      }, (item: DivinationResult, idx: number) => idx.toString())
    }
    .width('100%')
  }
}
