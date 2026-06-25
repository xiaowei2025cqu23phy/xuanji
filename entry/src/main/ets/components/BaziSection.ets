import { COLORS, ELEMENT_COLORS, ELEMENT_ORDER, INK, RED, OP } from '../common/constants'
import { calculateBazi } from '../model/lunar-service'
import { BaziData, PillarData, ShenshaEntry, DayunCycle, MonthlyFate } from '../model/bazi-data'
import { interpretMetaphysics, getOfflineBaziAnalysis, AIConfig, ChatMessage, QUESTION_CATEGORIES } from '../services/aiService'
import { WuXingCycle } from './WuXingCycle'
import { AIChatPanel } from './shared/AIChatPanel'

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
  @State activeCategory: string = 'general'
  @State activeSubTab: string = 'pillars' // pillars | nayin | shensha | dayun | liunian

  build() {
    Column({ space: 24 }) {
      this.InputForm()
      if (this.loading) { this.LoadingIndicator() }
      if (this.error) {
        Text(this.error).fontSize(12).fontColor(COLORS.IMPERIAL_RED)
          .padding(12).backgroundColor(RED.BG_FAINT).width('100%')
      }
      if (this.result) { this.ResultsDisplay() }
    }.width('100%')
  }

  @Builder InputForm() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        Column({ space: 8 }) {
          Text('出生日期').fontSize(10).fontColor(INK.LABEL)
          DatePicker({ start: new Date('1900-1-1'), end: new Date('2100-12-31'), selected: this.parseDate(this.date) })
            .onChange((value: DatePickerResult) => {
              this.date = `${value.year}-${String(value.month! + 1).padStart(2, '0')}-${String(value.day!).padStart(2, '0')}`
            })
        }.layoutWeight(1)
        Column({ space: 8 }) {
          Text('出生时辰').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
          TimePicker({ selected: this.parseTime(this.time) })
            .onChange((value: TimePickerResult) => {
              this.time = `${String(value.hour!).padStart(2, '0')}:${String(value.minute!).padStart(2, '0')}`
            })
        }
      }.width('100%')
      Row({ space: 4 }) {
        Button('男 (Male)').fontSize(12).fontWeight(FontWeight.Bold)
          .backgroundColor(this.gender === 'male' ? COLORS.INK_BLACK : COLORS.WHITE)
          .fontColor(this.gender === 'male' ? COLORS.WHITE : INK.SECONDARY)
          .border({ width: 1, color: INK.FAINT })
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.gender = 'male' })
        Button('女 (Female)').fontSize(12).fontWeight(FontWeight.Bold)
          .backgroundColor(this.gender === 'female' ? COLORS.INK_BLACK : COLORS.WHITE)
          .fontColor(this.gender === 'female' ? COLORS.WHITE : INK.SECONDARY)
          .border({ width: 1, color: INK.FAINT })
          .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.gender = 'female' })
      }
      Button('排 盘 解 析').fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.IMPERIAL_RED).backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: RED.BORDER })
        .padding({ left: 48, right: 48, top: 14, bottom: 14 })
        .onClick(() => { this.handleCalculate() })
    }
    .width('100%').padding(20).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder LoadingIndicator() {
    Row({ space: 12 }) {
      LoadingProgress().width(20).height(20).color(COLORS.IMPERIAL_RED)
      Text('排盘计算中...').fontSize(12).fontColor(INK.SECONDARY)
    }.width('100%').justifyContent(FlexAlign.Center).padding(24)
  }

  @Builder ResultsDisplay() {
    Column({ space: 20 }) {
      this.PillarsTable()
      // Sub-tabs for advanced analysis
      this.SubTabBar()
      if (this.activeSubTab === 'pillars') { this.PillarsDetailView() }
      if (this.activeSubTab === 'nayin') { this.NayinCard() }
      if (this.activeSubTab === 'shensha') { this.ShenshaCard() }
      if (this.activeSubTab === 'dayun') { this.DayunCard() }
      if (this.activeSubTab === 'liunian') { this.LiunianCard() }
      // AI Chat
      AIChatPanel({
        aiLoading: this.aiLoading, chatHistory: $chatHistory,
        activeCategory: this.activeCategory,
        onCategoryChange: (catId: string) => { this.activeCategory = catId },
        onSend: (text: string) => { this.sendFollowUp(text) }
      })
    }
  }

  @Builder SubTabBar() {
    Row({ space: 4 }) {
      ForEach(['pillars','nayin','shensha','dayun','liunian'] as string[], (tab: string) => {
        Button(tab === 'pillars' ? '五行格局' : tab === 'nayin' ? '纳音' : tab === 'shensha' ? '神煞' : tab === 'dayun' ? '大运' : '流年')
          .fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.activeSubTab === tab ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.activeSubTab === tab ? COLORS.INK_BLACK : INK.BG_FAINT)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .onClick(() => { this.activeSubTab = tab })
      }, (tab: string) => tab)
    }.width('100%')
  }

  // --- Pillars Table ---
  @Builder PillarsTable() {
    Column({ space: 8 }) {
      Text('四柱八字').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
      Grid() {
        if (this.result) {
          GridItem() { this.PillarItem('年柱', this.result!.year) }
          GridItem() { this.PillarItem('月柱', this.result!.month) }
          GridItem() { this.PillarItem('日柱', this.result!.day) }
          GridItem() { this.PillarItem('时柱', this.result!.hour) }
        }
      }.columnsTemplate('1fr 1fr 1fr 1fr').rowsTemplate('1fr').width('100%')
    }.width('100%')
  }

  @Builder PillarItem(label: string, p: PillarData) {
    Column({ space: 4 }) {
      Text(label).fontSize(9).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      Column({ space: 2 }) {
        Text(p.stem).fontSize(24).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
        Text(p.branch).fontSize(16).fontColor(INK.BODY)
        Text(p.element)
          .fontSize(9).fontColor(ELEMENT_COLORS.get(p.element) ?? COLORS.INK_BLACK)
          .backgroundColor(COLORS.alpha(ELEMENT_COLORS.get(p.element) ?? COLORS.INK_BLACK, 0.1))
          .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(4)
        if (p.nayin) {
          Text(p.nayin).fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).margin({ top: 2 })
        }
      }.alignItems(HorizontalAlign.Center)
    }.padding(12).border({ width: 1, color: INK.HAIRLINE })
  }

  // --- Pillars detail: Five Elements + Day Master ---
  @Builder PillarsDetailView() {
    Column({ space: 16 }) {
      this.FiveElementsAnalysis()
      this.DayMasterCard()
    }
  }

  @Builder FiveElementsAnalysis() {
    Column({ space: 16 }) {
      Text('五行分布与生克').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
      Row({ space: 16 }) {
        WuXingCycle({ elements: this.result!.fiveElements, strengths: this.result!.monthCommand.strength }).width('45%')
        Column({ space: 8 }) {
          ForEach(ELEMENT_ORDER, (elem: string) => {
            Row({ space: 12 }) {
              Text(elem).fontSize(12).fontColor(ELEMENT_COLORS.get(elem)).fontWeight(FontWeight.Bold).width(20)
              Progress({ value: (this.result!.fiveElements.get(elem) || 0) * 12.5, total: 100, type: ProgressType.Linear })
                .color(ELEMENT_COLORS.get(elem)).layoutWeight(1)
              Text((this.result!.fiveElements.get(elem) || 0).toString()).fontSize(11).fontColor(INK.SECONDARY)
            }.width('100%')
          }, (elem: string) => elem)
        }.layoutWeight(1)
      }.width('100%')
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder DayMasterCard() {
    if (this.result) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
          Text('日主分析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
        }
        Text(this.result.dayMasterAnalysis).fontSize(12).fontColor(INK.BODY).lineHeight(20)
        Text(this.baseAnalysis).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18).margin({ top: 4 })
        if (this.result.structure) {
          Row({ space: 8 }) { Text('格局：').fontSize(10).fontColor(INK.PLACEHOLDER)
            Text(this.result.structure.name).fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              .backgroundColor(RED.BG_MEDIUM).padding({ left: 10, right: 10, top: 3, bottom: 3 }).borderRadius(4)
          }.margin({ top: 4 })
          Text(this.result.structure.description).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)
        }
        Text(this.result.monthCommand.impact).fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).margin({ top: 8 })
      }
      .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG).border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // --- 纳音 Card ---
  @Builder NayinCard() {
    if (this.result && this.result.nayin) {
      Column({ space: 12 }) {
        Text('纳音五行').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Grid() {
          GridItem() {
            Column({ space: 4 }) {
              Text('年柱').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.nayin!.year.name).fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text(this.result!.nayin!.year.element).fontSize(11)
                .fontColor(ELEMENT_COLORS.get(this.result!.nayin!.year.element) ?? COLORS.INK_BLACK)
            }.padding(12)
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('月柱').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.nayin!.month.name).fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text(this.result!.nayin!.month.element).fontSize(11)
                .fontColor(ELEMENT_COLORS.get(this.result!.nayin!.month.element) ?? COLORS.INK_BLACK)
            }.padding(12)
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('日柱').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.nayin!.day.name).fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text(this.result!.nayin!.day.element).fontSize(11)
                .fontColor(ELEMENT_COLORS.get(this.result!.nayin!.day.element) ?? COLORS.INK_BLACK)
            }.padding(12)
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('时柱').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.nayin!.hour.name).fontSize(18).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text(this.result!.nayin!.hour.element).fontSize(11)
                .fontColor(ELEMENT_COLORS.get(this.result!.nayin!.hour.element) ?? COLORS.INK_BLACK)
            }.padding(12)
          }
        }
        .columnsTemplate('1fr 1fr').rowsTemplate('1fr 1fr').width('100%')
        Text('纳音将六十甲子配以五音十二律，以干支象数推演五行音律，反映先天禀赋与命运基调。')
          .fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).lineHeight(16)
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // --- 神煞 Card ---
  @Builder ShenshaCard() {
    if (this.result && this.result.shensha) {
      Column({ space: 12 }) {
        Text('命带神煞').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text(this.result!.shensha!.summary).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)
        if (this.result!.shensha!.entries.length > 0) {
          ForEach(this.result!.shensha!.entries, (entry: ShenshaEntry) => {
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 })
                .fill(entry.starType === 'good' ? COLORS.WOOD : entry.starType === 'bad' ? COLORS.IMPERIAL_RED : COLORS.AMBER_GOLD)
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(entry.name).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                  Text(entry.pillar).fontSize(9).fontColor(INK.PLACEHOLDER)
                    .backgroundColor(INK.BG_FAINT).padding({ left: 6, right: 6, top: 2, bottom: 2 }).borderRadius(4)
                }
                Text(entry.description).fontSize(10).fontColor(INK.SECONDARY).lineHeight(16)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            }
            .width('100%').padding(10)
            .backgroundColor(entry.starType === 'good' ? COLORS.WOOD + '08' : entry.starType === 'bad' ? RED.BG_FAINT : INK.BG_FAINT)
            .border({ width: 1, color: INK.HAIRLINE })
          }, (_e: ShenshaEntry, idx: number) => idx.toString())
        }
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // --- 大运 Card ---
  @Builder DayunCard() {
    if (this.result && this.result.dayun) {
      Column({ space: 12 }) {
        Text('大运排盘').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text(this.result!.dayun!.description).fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontStyle(FontStyle.Italic).lineHeight(18)

        // Scrollable list of 大运 cycles
        Scroll() {
          Column({ space: 4 }) {
            ForEach(this.result!.dayun!.cycles, (cycle: DayunCycle, idx: number) => {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(cycle.ageStart + '-' + cycle.ageEnd + '岁')
                    .fontSize(10).fontColor(COLORS.WHITE).fontWeight(FontWeight.Bold)
                    .backgroundColor(COLORS.INK_BLACK).padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(12)
                  Text(cycle.stem + cycle.branch)
                    .fontSize(20).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                  if (cycle.nayin) {
                    Text(cycle.nayin).fontSize(9).fontColor(INK.PLACEHOLDER)
                  }
                }
                Row({ space: 8 }) {
                  Text(cycle.tenGod).fontSize(11).fontColor(ELEMENT_COLORS.get(cycle.element) ?? COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                  Text(cycle.description).fontSize(10).fontColor(INK.SECONDARY).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                }.width('100%')
              }
              .width('100%').padding(10)
              .backgroundColor(COLORS.WHITE + '99').border({ width: 1, color: INK.HAIRLINE })
            }, (_cycle: DayunCycle, idx: number) => idx.toString())
          }.width('100%')
        }
        .height(360).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // --- 流年 Card ---
  @Builder LiunianCard() {
    if (this.result && this.result.liunian) {
      Column({ space: 12 }) {
        Text('流年分析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text(this.result!.liunian!.currentYear + '年').fontSize(10).fontColor(INK.PLACEHOLDER)
            Text(this.result!.liunian!.stem + this.result!.liunian!.branch).fontSize(32).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(this.result!.liunian!.zodiac + '年 · ' + (this.result!.liunian!.nayin || '')).fontSize(10).fontColor(INK.PLACEHOLDER)
          }
          Column({ space: 4 }) {
            Text('十神').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.result!.liunian!.tenGod).fontSize(18).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          }
        }.width('100%')
        Text(this.result!.liunian!.description).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)

        Divider().color(INK.HAIRLINE)

        Text('月度运势').fontSize(11).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Grid() {
          ForEach(this.result!.liunian!.monthlyBreakdown, (mf: MonthlyFate) => {
            GridItem() {
              Column({ space: 2 }) {
                Text(mf.month + '月').fontSize(8).fontColor(INK.PLACEHOLDER)
                Text(mf.stem + mf.branch).fontSize(14).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                Text(mf.tenGod).fontSize(9).fontColor(mf.tenGod === '财星' || mf.tenGod === '印枭' ? COLORS.WOOD :
                  mf.tenGod === '官杀' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
              }
              .padding(8).backgroundColor(COLORS.WHITE).border({ width: 1, color: INK.HAIRLINE })
            }
          }, (mf: MonthlyFate) => mf.month.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr').width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG).border({ width: 1, color: INK.HAIRLINE })
    }
  }

  // --- Logic ---
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
    this.loading = true; this.error = ''; this.activeSubTab = 'pillars'
    try {
      const fullDate = new Date(
        Number(this.date.split('-')[0]), Number(this.date.split('-')[1]) - 1,
        Number(this.date.split('-')[2]), Number(this.time.split('-')[0]),
        Number(this.time.split('-')[1])
      )
      const data = calculateBazi(fullDate, this.gender as 'male' | 'female')
      this.result = data
      this.baseAnalysis = getOfflineBaziAnalysis(data.dayMaster)
      this.chatHistory = []
    } catch (e) {
      this.error = '排盘计算失败，请检查日期格式是否正确。'
    } finally { this.loading = false }
  }

  async sendFollowUp(text: string) {
    if (!this.result) return
    this.aiLoading = true
    this.chatHistory = [...this.chatHistory, { role: 'user', content: text }]
    try {
      const contextPrompt = this.buildBaziContext()
      const messages: ChatMessage[] = [
        { role: 'user', content: contextPrompt },
        { role: 'assistant', content: this.baseAnalysis },
        ...this.chatHistory
      ]
      const reply = await interpretMetaphysics(messages, this.aiConfig)
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: reply }]
    } catch (_e) {
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: 'AI解析暂时不可用。' + this.baseAnalysis }]
    } finally { this.aiLoading = false }
  }

  buildBaziContext(): string {
    if (!this.result) return ''
    const r = this.result
    let catLabel: string = '综合运势'
    for (let i: number = 0; i < QUESTION_CATEGORIES.length; i++) {
      if (QUESTION_CATEGORIES[i].id === this.activeCategory) { catLabel = QUESTION_CATEGORIES[i].label; break }
    }
    const ap = r.dayMasterAnalysis.split('属')
    let ep = ''
    if (ap.length > 1) { ep = ap[1].split('。')[0] || '' }
    let ctx = '请作为天道先生，对以下八字格局进行【' + catLabel + '】方面的解析：\n' +
      '生辰：' + this.date + ' ' + this.time + ' (' + this.gender + ')\n' +
      '四柱：年' + r.year.stem + r.year.branch + '(' + r.year.element + (r.year.nayin ? '/' + r.year.nayin : '') + ') ' +
      '月' + r.month.stem + r.month.branch + '(' + r.month.element + ') ' +
      '日' + r.day.stem + r.day.branch + '(' + r.day.element + ') ' +
      '时' + r.hour.stem + r.hour.branch + '(' + r.hour.element + ')\n' +
      '日主：' + r.dayMaster + '(' + ep + ')\n' +
      '五行：金' + (r.fiveElements.get('金') || 0) + ' 木' + (r.fiveElements.get('木') || 0) + ' 水' + (r.fiveElements.get('水') || 0) +
      ' 火' + (r.fiveElements.get('火') || 0) + ' 土' + (r.fiveElements.get('土') || 0) + '\n' +
      r.monthCommand.impact
    if (r.structure) { ctx += '\n格局：' + r.structure.name + '\n' + r.structure.description }
    if (r.shensha && r.shensha.entries.length > 0) {
      ctx += '\n神煞：' + r.shensha.entries.map(e => e.name).join('、')
    }
    return ctx
  }
}
