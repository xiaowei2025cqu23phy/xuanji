import { COLORS, ELEMENT_COLORS, ELEMENT_ORDER } from '../common/constants'
import { calculateBazi } from '../model/lunar-service'
import { BaziData, FIVE_ELEMENTS_ADVICE, PillarData } from '../model/bazi-data'
import { interpretMetaphysics, getOfflineBaziAnalysis, AIConfig, ChatMessage, QUESTION_CATEGORIES, QuestionCategory, makeChatMessage, CategoryInfo } from '../services/aiService'
import { WuXingCycle } from './WuXingCycle'

@Component
export struct BaziSection {
  @Prop aiConfig: AIConfig
  @State date: string = '2000-01-01'
  @State time: string = '12:00'
  @State gender: string = 'male'
  @State result: BaziData | null = null
  @State loading: boolean = false
  @State error: string = ''
  @State chatHistory: ChatMessage[] = []
  @State baseAnalysis: string = ''
  @State aiLoading: boolean = false
  @State followUp: string = ''
  @State selectedCategory: string = 'general'
  @State activeCategory: string = 'general'

  build() {
    Column({ space: 24 }) {
      // Input form
      this.InputForm()

      // Loading
      if (this.loading) {
        this.LoadingIndicator()
      }

      // Error
      if (this.error) {
        Text(this.error)
          .fontSize(12)
          .fontColor(COLORS.IMPERIAL_RED)
          .padding(12)
          .backgroundColor(COLORS.IMPERIAL_RED + '08')
          .width('100%')
      }

      // Results
      if (this.result) {
        this.ResultsDisplay()
      }
    }
    .width('100%')
  }

  @Builder
  InputForm() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        Column({ space: 8 }) {
          Text('出生日期')
            .fontSize(10)
            .fontColor(COLORS.INK_BLACK + '99')
            .fontWeight(FontWeight.Normal)

          DatePicker({
            start: new Date('1900-1-1'),
            end: new Date('2100-12-31'),
            selected: this.parseDate(this.date)
          })
            .onChange((value: DatePickerResult) => {
              this.date = `${value.year}-${String(value.month! + 1).padStart(2, '0')}-${String(value.day!).padStart(2, '0')}`
            })
        }
        .layoutWeight(1)

        Column({ space: 8 }) {
          Text('出生时辰')
            .fontSize(10)
            .fontColor(COLORS.INK_BLACK + '99')
            .fontWeight(FontWeight.Bold)

          TimePicker({
            selected: this.parseTime(this.time)
          })
            .onChange((value: TimePickerResult) => {
              this.time = `${String(value.hour!).padStart(2, '0')}:${String(value.minute!).padStart(2, '0')}`
            })
        }
      }
      .width('100%')

      // Gender selector
      Row({ space: 4 }) {
        Button('男 (Male)')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.gender === 'male' ? COLORS.INK_BLACK : COLORS.WHITE)
          .fontColor(this.gender === 'male' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.gender = 'male' })

        Button('女 (Female)')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.gender === 'female' ? COLORS.INK_BLACK : COLORS.WHITE)
          .fontColor(this.gender === 'female' ? COLORS.WHITE : COLORS.INK_BLACK + '66')
          .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.gender = 'female' })
      }

      // Calculate button
      Button('排 盘 解 析')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.IMPERIAL_RED)
        .backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: COLORS.IMPERIAL_RED + '33' })
        .padding({ left: 48, right: 48, top: 14, bottom: 14 })
        .onClick(() => { this.handleCalculate() })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  LoadingIndicator() {
    Row({ space: 12 }) {
      LoadingProgress()
        .width(20)
        .height(20)
        .color(COLORS.IMPERIAL_RED)
      Text('排盘计算中...')
        .fontSize(12)
        .fontColor(COLORS.INK_BLACK + '66')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .padding(24)
  }

  @Builder
  ResultsDisplay() {
    Column({ space: 20 }) {
      // Four Pillars Table
      this.PillarsTable()

      // Five Elements Chart
      this.FiveElementsAnalysis()

      // Day Master + Structure
      this.DayMasterCard()

      // AI Chat Panel
      this.AIChatPanel()
    }
  }

  @Builder
  PillarsTable() {
    Column({ space: 8 }) {
      Text('四柱八字')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.INK_BLACK + '66')

      Grid() {
        if (this.result) {
          GridItem() { this.PillarItem('年柱', this.result!.year) }
          GridItem() { this.PillarItem('月柱', this.result!.month) }
          GridItem() { this.PillarItem('日柱', this.result!.day) }
          GridItem() { this.PillarItem('时柱', this.result!.hour) }
        }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr')
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  PillarItem(label: string, p: PillarData) {
    Column({ space: 4 }) {
      Text(label)
        .fontSize(9)
        .fontColor(COLORS.INK_BLACK + '4D')
        .fontWeight(FontWeight.Bold)
      Column({ space: 2 }) {
        Text(p.stem)
          .fontSize(24)
          .fontColor(COLORS.INK_BLACK)
          .fontWeight(FontWeight.Bold)
        Text(p.branch)
          .fontSize(16)
          .fontColor(COLORS.INK_BLACK + '80')
        Text(p.element)
          .fontSize(9)
          .fontColor(ELEMENT_COLORS.get(p.element) ?? COLORS.INK_BLACK)
          .backgroundColor((ELEMENT_COLORS.get(p.element) ?? COLORS.INK_BLACK) + '1A')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .borderRadius(4)
      }
      .alignItems(HorizontalAlign.Center)
    }
    .padding(12)
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  FiveElementsAnalysis() {
    Column({ space: 16 }) {
      Text('五行分布与生克')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.INK_BLACK + '66')

      Row({ space: 16 }) {
        WuXingCycle({
          elements: this.result!.fiveElements,
          strengths: this.result!.monthCommand.strength
        })
          .width('45%')

        Column({ space: 8 }) {
          ForEach(ELEMENT_ORDER, (elem: string) => {
            Row({ space: 12 }) {
              Text(elem)
                .fontSize(12)
                .fontColor(ELEMENT_COLORS.get(elem))
                .fontWeight(FontWeight.Bold)
                .width(20)

              Progress({
                value: (this.result!.fiveElements.get(elem) || 0) * 12.5,
                total: 100,
                type: ProgressType.Linear
              })
                .color(ELEMENT_COLORS.get(elem))
                .layoutWeight(1)

              Text((this.result!.fiveElements.get(elem) || 0).toString())
                .fontSize(11)
                .fontColor(COLORS.INK_BLACK + '66')
            }
            .width('100%')
          }, (elem: string) => elem)
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
  }

  @Builder
  DayMasterCard() {
    if (this.result) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Circle({ width: 6, height: 6 })
            .fill(COLORS.IMPERIAL_RED)
          Text('日主分析')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.IMPERIAL_RED)
        }

        Text(this.result.dayMasterAnalysis)
          .fontSize(12)
          .fontColor(COLORS.INK_BLACK + '80')
          .lineHeight(20)

        Text(this.baseAnalysis)
          .fontSize(11)
          .fontColor(COLORS.INK_BLACK + '66')
          .lineHeight(18)
          .margin({ top: 4 })

        if (this.result.structure) {
          Row({ space: 8 }) {
            Text('格局：')
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '4D')
            Text(this.result.structure.name)
              .fontSize(11)
              .fontColor(COLORS.IMPERIAL_RED)
              .fontWeight(FontWeight.Bold)
              .backgroundColor(COLORS.IMPERIAL_RED + '0F')
              .padding({ left: 10, right: 10, top: 3, bottom: 3 })
              .borderRadius(4)
          }
          .margin({ top: 4 })

          Text(this.result.structure.description)
            .fontSize(11)
            .fontColor(COLORS.INK_BLACK + '66')
            .lineHeight(18)
        }

        Text(this.result.monthCommand.impact)
          .fontSize(10)
          .fontColor(COLORS.INK_BLACK + '4D')
          .fontStyle(FontStyle.Italic)
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(COLORS.ACTIVE_CARD_BG)
      .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
    }
  }

  @Builder
  AIChatPanel() {
    Column({ space: 16 }) {
      Divider().color(COLORS.INK_BLACK + '0D')

      Text('AI 大师解析')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(COLORS.INK_BLACK + '66')

      // Category selector
      Row({ space: 4 }) {
        ForEach(QUESTION_CATEGORIES, (cat: CategoryInfo) => {
          Text(cat.icon + ' ' + cat.label)
            .fontSize(9)
            .fontColor(this.activeCategory === cat.id ? COLORS.WHITE : COLORS.INK_BLACK + '66')
            .backgroundColor(this.activeCategory === cat.id ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '05')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(2)
            .onClick(() => { this.activeCategory = cat.id })
        }, (cat: CategoryInfo) => cat.id)
      }
      .width('100%')

      // Chat history
      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.chatHistory, (msg: ChatMessage, idx: number) => {
            Row() {
              Text(msg.content)
                .fontSize(11)
                .fontColor(COLORS.INK_BLACK + '80')
                .padding(12)
                .backgroundColor(msg.role === 'user' ? COLORS.INK_BLACK + '08' : COLORS.IMPERIAL_RED + '08')
                .borderRadius(4)
                .constraintSize({ maxWidth: '80%' })
            }
            .width('100%')
            .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
          }, (msg: ChatMessage, idx: number) => idx.toString())
        }
        .width('100%')
      }
      .height(this.chatHistory.length > 0 ? 200 : 0)

      // Input area
      Row({ space: 8 }) {
        TextInput({ placeholder: '输入追问...', text: this.followUp })
          .onChange((value: string) => { this.followUp = value })
          .layoutWeight(1)
          .fontSize(11)
          .padding(10)
          .backgroundColor(COLORS.INK_BLACK + '03')
          .border({ width: 1, color: COLORS.INK_BLACK + '0D' })

        Button('发送')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.IMPERIAL_RED)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .onClick(() => { this.sendFollowUp() })
      }
      .width('100%')
    }
    .width('100%')
  }

  // --- Logic methods ---
  parseDate(dateStr: string): Date {
    const parts = dateStr.split('-').map(Number)
    return new Date(parts[0], parts[1] - 1, parts[2])
  }

  parseTime(timeStr: string): Date {
    const parts = timeStr.split(':').map(Number)
    const d = new Date()
    d.setHours(parts[0], parts[1], 0, 0)
    return d
  }

  async handleCalculate() {
    if (!this.date) return

    this.loading = true
    this.error = ''

    try {
      const fullDate = new Date(
        Number(this.date.split('-')[0]),
        Number(this.date.split('-')[1]) - 1,
        Number(this.date.split('-')[2]),
        Number(this.time.split(':')[0]),
        Number(this.time.split(':')[1])
      )

      const data = calculateBazi(fullDate, this.gender as 'male' | 'female')
      this.result = data
      this.baseAnalysis = getOfflineBaziAnalysis(data.dayMaster)
      this.chatHistory = []
    } catch (e) {
      this.error = '排盘计算失败，请检查日期格式是否正确。'
    } finally {
      this.loading = false
    }
  }

  async sendFollowUp() {
    if (!this.followUp.trim() || !this.result) return

    this.aiLoading = true
    let userMsg: ChatMessage = makeChatMessage('user', this.followUp)
    let newHistory: ChatMessage[] = []
    for (let j = 0; j < this.chatHistory.length; j++) {
      newHistory.push(this.chatHistory[j])
    }
    newHistory.push(userMsg)
    this.chatHistory = newHistory
    this.followUp = ''

    try {
      const contextPrompt = this.buildBaziContext()
      let ctxMsg: ChatMessage = makeChatMessage('user', contextPrompt)
      let baseMsg: ChatMessage = makeChatMessage('assistant', this.baseAnalysis)

      let messages: ChatMessage[] = []
      messages.push(ctxMsg)
      messages.push(baseMsg)
      for (let k = 0; k < this.chatHistory.length; k++) {
        messages.push(this.chatHistory[k])
      }

      const reply = await interpretMetaphysics(messages, this.aiConfig)
      let replyMsg: ChatMessage = makeChatMessage('assistant', reply)
      this.chatHistory.push(replyMsg)
      this.chatHistory = this.chatHistory.slice()
    } catch (e) {
      let errMsg: ChatMessage = makeChatMessage('assistant', 'AI解析暂时不可用。' + this.baseAnalysis)
      this.chatHistory.push(errMsg)
      this.chatHistory = this.chatHistory.slice()
      this.aiLoading = false
    } finally {
      this.aiLoading = false
    }
  }

  buildBaziContext(): string {
    if (!this.result) return ''
    let r: BaziData = this.result
    let catLabel: string = '综合运势'
    for (let i = 0; i < QUESTION_CATEGORIES.length; i++) {
      if (QUESTION_CATEGORIES[i].id === this.activeCategory) {
        catLabel = QUESTION_CATEGORIES[i].label
      }
    }
    let analysisPart: string[] = r.dayMasterAnalysis.split('属')
    let elementPart: string = ''
    if (analysisPart.length > 1) {
      elementPart = analysisPart[1].split('。')[0] || ''
    }
    return '请作为天道先生，对以下八字格局进行【' + catLabel + '】方面的解析：\n' +
      '生辰：' + this.date + ' ' + this.time + ' (' + this.gender + ')\n' +
      '年柱：' + r.year.stem + r.year.branch + '(' + r.year.element + ') 月柱：' + r.month.stem + r.month.branch + '(' + r.month.element + ') ' +
      '日柱：' + r.day.stem + r.day.branch + '(' + r.day.element + ') 时柱：' + r.hour.stem + r.hour.branch + '(' + r.hour.element + ')\n' +
      '日主：' + r.dayMaster + '(' + elementPart + ')\n' +
      '五行分布：金' + (r.fiveElements.get('金') || 0) + ' 木' + (r.fiveElements.get('木') || 0) + ' 水' + (r.fiveElements.get('水') || 0) + ' 火' + (r.fiveElements.get('火') || 0) + ' 土' + (r.fiveElements.get('土') || 0) + '\n' +
      r.monthCommand.impact +
      (r.structure ? ('\n格局：' + r.structure.name + '\n' + r.structure.description) : '')
  }
}
