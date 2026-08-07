import { COLORS, ELEMENT_COLORS, ELEMENT_ORDER, INK, RED, OP, HEAVENLY_STEMS, EARTHLY_BRANCHES, STEM_ELEMENT } from '../common/constants'
import { calculateBazi, getTrueSolarTime, TrueSolarInfo, getLiunianForYear } from '../model/lunar-service'
import { BaziData, PillarData, ShenshaEntry, DayunCycle, MonthlyFate, LiunianResult } from '../model/bazi-data'
import { buildOfflineBaziReport } from '../services/offlineInterpreter'
import {
  interpretMetaphysics, getOfflineBaziAnalysis, AIConfig, ChatMessage,
  QUESTION_CATEGORIES, loadLateZiHuanRi
} from '../services/aiService'
import {
  SavedBaziReading, saveBaziReading, loadBaziReadings, deleteBaziReading
} from '../services/readingStore'
import { formatBaziShareText, shareText } from '../services/exportService'
import pasteboard from '@ohos.pasteboard'
import { WuXingCycle } from './WuXingCycle'
import { AIChatPanel } from './shared/AIChatPanel'

@Component
export struct BaziSection {
  @Prop aiConfig: AIConfig
  @StorageLink('uiDark') isDark: boolean = false
  @State date: string = '2000-01-01'
  @State time: string = '12:00'
  @State gender: string = 'male'
  @State useTrueSolar: boolean = false
  @State longitude: string = '120'
  @State lateZiHuanRi: boolean = false
  @State trueSolar: TrueSolarInfo | null = null
  @State result: BaziData | null = null
  @State offlineReport: string = ''
  @State showOffline: boolean = false
  @State loading: boolean = false
  @State error: string = ''
  @State chatHistory: ChatMessage[] = []
  @State baseAnalysis: string = ''
  @State aiLoading: boolean = false
  @State activeCategory: string = 'general'
  @State activeSubTab: string = 'pillars' // pillars | nayin | shensha | dayun | liunian
  @State records: SavedBaziReading[] = []
  @State showRecords: boolean = false
  @State liunian: LiunianResult | null = null
  @State liunianYear: number = new Date().getFullYear()
  private liunianDayStemIdx: number = 0
  private liunianDayBranchIdx: number = 0
  private liunianDmElement: string = ''

  async aboutToAppear() {
    this.records = await loadBaziReadings()
    this.lateZiHuanRi = await loadLateZiHuanRi()
  }

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
          DatePicker({
            start: new Date('1900-1-1'),
            end: new Date('2100-12-31'),
            selected: this.parseDate(this.date)
          })
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

      // 真太阳时 (optional)
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('真太阳时校正').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
          Toggle({ type: ToggleType.Switch, isOn: this.useTrueSolar })
            .selectedColor(COLORS.IMPERIAL_RED)
            .onChange((v: boolean) => { this.useTrueSolar = v })
          if (this.useTrueSolar) {
            Text('东经').fontSize(9).fontColor(INK.PLACEHOLDER)
            TextInput({ placeholder: '120', text: this.longitude })
              .type(InputType.Number).fontSize(10).width(90)
              .onChange((v: string) => { this.longitude = v })
          }
        }.width('100%')
        Text('以 120°E 为基准，按出生地经度校正时辰（命理进阶功能，可选）')
          .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      }.width('100%').padding(10).backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE })

      Button('排 盘 解 析').fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.IMPERIAL_RED).backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: RED.BORDER })
        .padding({ left: 48, right: 48, top: 14, bottom: 14 })
        .onClick(() => { this.handleCalculate() })
    }
    .width('100%').padding(20).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    .shadow({ radius: 10, color: COLORS.INK_BLACK + '14', offsetY: 4 })
  }

  @Builder LoadingIndicator() {
    Row({ space: 12 }) {
      LoadingProgress().width(20).height(20).color(COLORS.IMPERIAL_RED)
      Text('排盘计算中...').fontSize(12).fontColor(INK.SECONDARY)
    }.width('100%').justifyContent(FlexAlign.Center).padding(24)
  }

  @Builder ResultsDisplay() {
    Column({ space: 20 }) {
      Row({ space: 8 }) {
        Text('四柱八字').fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION).layoutWeight(1)
        Text('已保存到记录').fontSize(9).fontColor(COLORS.WOOD)
        Button(this.showRecords ? '收起记录' : '历史记录 (' + this.records.length + ')')
          .fontSize(9).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.showRecords = !this.showRecords })
      }.width('100%')
      this.PillarsTable()
      if (this.trueSolar) { this.TrueSolarCard() }
      if (this.showRecords) { this.RecordsPanel() }
      // Sub-tabs for advanced analysis
      this.SubTabBar()
      if (this.activeSubTab === 'pillars') { this.PillarsDetailView() }
      if (this.activeSubTab === 'nayin') { this.NayinCard() }
      if (this.activeSubTab === 'shensha') { this.ShenshaCard() }
      if (this.activeSubTab === 'dayun') { this.DayunCard() }
      if (this.activeSubTab === 'liunian') { this.LiunianCard() }
      // Actions
      Row({ space: 12 }) {
        Button('复制排盘').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).layoutWeight(1)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => { this.copyResult() })
        Button('分享').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED).layoutWeight(1)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => { this.shareResult() })
        Button('清空对话').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(INK.LABEL).backgroundColor(INK.BG_FAINT).layoutWeight(1)
          .padding({ top: 10, bottom: 10 })
          .onClick(() => { this.chatHistory = [] })
      }.width('100%')
      this.OfflineReportCard()
      // AI Chat
      AIChatPanel({
        aiLoading: this.aiLoading, chatHistory: $chatHistory,
        activeCategory: this.activeCategory,
        onCategoryChange: (catId: string) => { this.activeCategory = catId },
        onSend: (text: string) => { this.sendFollowUp(text) },
        onClear: () => { this.chatHistory = [] }
      })
    }
  }

  @Builder TrueSolarCard() {
    if (this.trueSolar) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('真太阳时校正').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          Text('TRUE SOLAR TIME').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
        }.width('100%')
        Row({ space: 16 }) {
          Column({ space: 2 }) {
            Text('出生地经度').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text(this.trueSolar!.longitude + '°E').fontSize(12).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }.alignItems(HorizontalAlign.Start)
          Column({ space: 2 }) {
            Text('均时差').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text((this.trueSolar!.eotMinutes >= 0 ? '+' : '') + this.trueSolar!.eotMinutes + ' 分钟')
              .fontSize(12).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          }.alignItems(HorizontalAlign.Start)
          Column({ space: 2 }) {
            Text('校正量').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text((this.trueSolar!.correctionMinutes >= 0 ? '+' : '') + this.trueSolar!.correctionMinutes + ' 分钟')
              .fontSize(12).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          }.alignItems(HorizontalAlign.Start)
          Blank().layoutWeight(1)
          Column({ space: 2 }) {
            Text('真太阳时').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text(this.pad2(this.trueSolar!.correctedDate.getHours()) + ':' + this.pad2(this.trueSolar!.correctedDate.getMinutes()))
              .fontSize(16).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          }.alignItems(HorizontalAlign.End)
        }.width('100%')
        Text(this.date + ' ' + this.time + ' → 真太阳时 ' +
          this.pad2(this.trueSolar!.correctedDate.getHours()) + ':' + this.pad2(this.trueSolar!.correctedDate.getMinutes()) +
          '，时柱按真太阳时排')
          .fontSize(9).fontColor(INK.SECONDARY).fontStyle(FontStyle.Italic)
      }
      .width('100%').padding(12).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: RED.BORDER }).borderRadius(12)
    }
  }

  @Builder OfflineReportCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('离线详析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Text('OFFLINE REPORT').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
        Blank().layoutWeight(1)
        Button(this.showOffline ? '收起' : '展开')
          .fontSize(9).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .onClick(() => { this.showOffline = !this.showOffline })
      }.width('100%')
      Text('未配置 AI 也能获得完整分析：格局、五行、神煞、大运、流年一应俱全。')
        .fontSize(9).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      if (this.showOffline && this.offlineReport.length > 0) {
        Scroll() {
          Text(this.offlineReport)
            .fontSize(11).fontColor(INK.BODY).lineHeight(18)
            .width('100%').padding(12)
            .backgroundColor(COLORS.WHITE + '99')
            .border({ width: 1, color: INK.HAIRLINE }).borderRadius(10)
        }.height(380).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      }
    }
    .width('100%').padding(14).backgroundColor(COLORS.ACTIVE_CARD_BG)
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder RecordsPanel() {
    Column({ space: 8 }) {
      if (this.records.length === 0) {
        Text('暂无保存的记录，排盘后将自动保存。')
          .fontSize(10).fontColor(INK.PLACEHOLDER).padding(12)
      } else {
        ForEach(this.records, (rec: SavedBaziReading) => {
          Row({ space: 8 }) {
            Column({ space: 2 }) {
              Text(rec.date + ' ' + rec.time + ' · ' + (rec.gender === 'male' ? '男' : '女'))
                .fontSize(10).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text('日主' + rec.dayMaster + (rec.structure ? ' · ' + rec.structure : ''))
                .fontSize(9).fontColor(INK.SECONDARY).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Button('恢复').fontSize(9).fontColor(COLORS.IMPERIAL_RED)
              .backgroundColor(RED.BG_MEDIUM).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .onClick(() => { this.restoreRecord(rec) })
            Button('删除').fontSize(9).fontColor(INK.SECONDARY)
              .backgroundColor(INK.BG_FAINT).padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .onClick(() => { this.removeRecord(rec) })
          }
          .width('100%').padding(10).backgroundColor(COLORS.WHITE + '99')
          .border({ width: 1, color: INK.HAIRLINE }).borderRadius(8)
        }, (rec: SavedBaziReading) => rec.id)
      }
    }.width('100%').padding(12).backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE })
  }

  @Builder SubTabBar() {
    Row({ space: 4 }) {
      ForEach(['pillars', 'nayin', 'shensha', 'dayun', 'liunian'] as string[], (tab: string) => {
        Button(tab === 'pillars' ? '五行格局' : tab === 'nayin' ? '纳音' : tab === 'shensha' ? '神煞' : tab === 'dayun' ? '大运' : '流年')
          .fontSize(10).fontWeight(FontWeight.Bold)
          .fontColor(this.activeSubTab === tab ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.activeSubTab === tab ? COLORS.INK_BLACK : INK.BG_FAINT)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(14)
          .onClick(() => { this.activeSubTab = tab })
      }, (tab: string) => tab)
    }.width('100%')
  }

  // --- Pillars Table ---
  @Builder PillarsTable() {
    Grid() {
      if (this.result) {
        GridItem() { this.PillarItem('年柱', this.result!.year) }
        GridItem() { this.PillarItem('月柱', this.result!.month) }
        GridItem() { this.PillarItem('日柱', this.result!.day) }
        GridItem() { this.PillarItem('时柱', this.result!.hour) }
      }
    }.columnsTemplate('1fr 1fr 1fr 1fr').rowsTemplate('1fr').width('100%')
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
        if (p.hiddenStems && p.hiddenStems.length > 0) {
          Text('藏干 ' + p.hiddenStems.join(' ')).fontSize(8).fontColor(RED.LABEL)
            .backgroundColor(RED.BG_FAINT).padding({ left: 6, right: 6, top: 1, bottom: 1 }).borderRadius(4)
        }
      }.alignItems(HorizontalAlign.Center)
    }.padding(12).border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
      .backgroundColor(COLORS.WHITE + '66')
  }

  // --- Pillars detail: Five Elements + Day Master + 命宫胎元 ---
  @Builder PillarsDetailView() {
    Column({ space: 16 }) {
      this.FiveElementsAnalysis()
      this.DayMasterCard()
      this.MingGongTaiYuanCard()
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
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
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
          Row({ space: 8 }) {
            Text('格局：').fontSize(10).fontColor(INK.PLACEHOLDER)
            Text(this.result.structure.name).fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              .backgroundColor(RED.BG_MEDIUM).padding({ left: 10, right: 10, top: 3, bottom: 3 }).borderRadius(4)
          }.margin({ top: 4 })
          Text(this.result.structure.description).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)
        }
        Text(this.result.monthCommand.impact).fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).margin({ top: 8 })
      }
      .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG)
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    }
  }

  @Builder MingGongTaiYuanCard() {
    if (this.result && this.result.mingGong && this.result.taiYuan) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text('命宫 · 胎元').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
          Text('（进阶格局参考）').fontSize(8).fontColor(INK.PLACEHOLDER)
        }
        Grid() {
          GridItem() {
            Column({ space: 4 }) {
              Text('命宫').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.mingGong!.stem + this.result!.mingGong!.branch)
                .fontSize(20).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
              Text('先天根基 · 性情禀赋').fontSize(8).fontColor(INK.SECONDARY)
            }.padding(12).alignItems(HorizontalAlign.Center)
          }
          GridItem() {
            Column({ space: 4 }) {
              Text('胎元').fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(this.result!.taiYuan!.stem + this.result!.taiYuan!.branch)
                .fontSize(20).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              Text('受孕月令 · 体质根基').fontSize(8).fontColor(INK.SECONDARY)
            }.padding(12).alignItems(HorizontalAlign.Center)
          }
        }
        .columnsTemplate('1fr 1fr').rowsTemplate('1fr').width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
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
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
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
            .border({ width: 1, color: INK.HAIRLINE }).borderRadius(8)
          }, (_e: ShenshaEntry, idx: number) => idx.toString())
        }
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
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
              .backgroundColor(COLORS.WHITE + '99').border({ width: 1, color: INK.HAIRLINE }).borderRadius(8)
            }, (_cycle: DayunCycle, idx: number) => idx.toString())
          }.width('100%')
        }
        .height(360).scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    }
  }

  // --- 流年 Card ---
  @Builder LiunianCard() {
    if (this.liunian) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text('流年分析').fontSize(12).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
          Blank().layoutWeight(1)
          Button('‹').fontSize(12).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
            .width(28).height(28).borderRadius(14)
            .onClick(() => { this.changeLiunianYear(-1) })
          Text(this.liunian!.currentYear + '年').fontSize(11).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Button('›').fontSize(12).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
            .width(28).height(28).borderRadius(14)
            .onClick(() => { this.changeLiunianYear(1) })
        }.width('100%')
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text(this.liunian!.stem + this.liunian!.branch).fontSize(32).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(this.liunian!.zodiac + '年 · ' + (this.liunian!.nayin || '')).fontSize(10).fontColor(INK.PLACEHOLDER)
          }
          Column({ space: 4 }) {
            Text('十神').fontSize(9).fontColor(INK.PLACEHOLDER)
            Text(this.liunian!.tenGod).fontSize(18).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          }
        }.width('100%')
        Text(this.liunian!.description).fontSize(11).fontColor(INK.SECONDARY).lineHeight(18)

        Divider().color(INK.HAIRLINE)

        Text('月度运势').fontSize(11).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Grid() {
          ForEach(this.liunian!.monthlyBreakdown, (mf: MonthlyFate) => {
            GridItem() {
              Column({ space: 2 }) {
                Text(mf.month + '月').fontSize(8).fontColor(INK.PLACEHOLDER)
                Text(mf.stem + mf.branch).fontSize(14).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                Text(mf.tenGod).fontSize(9).fontColor(mf.tenGod === '财星' || mf.tenGod === '印枭' ? COLORS.WOOD :
                  mf.tenGod === '官杀' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
              }
              .padding(8).backgroundColor(COLORS.WHITE).border({ width: 1, color: INK.HAIRLINE }).borderRadius(8)
            }
          }, (mf: MonthlyFate) => mf.month.toString())
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr').width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG)
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
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

  pad2(n: number): string {
    return String(n).padStart(2, '0')
  }

  async handleCalculate() {
    if (!this.date) return
    this.loading = true
    this.error = ''
    this.activeSubTab = 'pillars'
    try {
      this.lateZiHuanRi = await loadLateZiHuanRi()
      const tParts = this.time.split(':')
      const hours = isNaN(Number(tParts[0])) ? 12 : Number(tParts[0])
      const minutes = isNaN(Number(tParts[1])) ? 0 : Number(tParts[1])
      let fullDate = new Date(
        Number(this.date.split('-')[0]),
        Number(this.date.split('-')[1]) - 1,
        Number(this.date.split('-')[2]),
        hours, minutes
      )

      let calcDate = fullDate
      this.trueSolar = null
      if (this.useTrueSolar) {
        const lon = parseFloat(this.longitude)
        if (!isNaN(lon) && lon >= 70 && lon <= 150) {
          this.trueSolar = getTrueSolarTime(fullDate, lon)
          calcDate = this.trueSolar.correctedDate
        } else {
          this.error = '经度需为 70–150 之间的东经度数，已按北京时间排盘。'
        }
      }

      const data = calculateBazi(calcDate, this.gender as 'male' | 'female', this.lateZiHuanRi)
      this.result = data
      this.baseAnalysis = getOfflineBaziAnalysis(data.dayMaster)
      this.offlineReport = buildOfflineBaziReport(data)
      this.liunian = data.liunian ? data.liunian : null
      this.liunianYear = data.liunian ? data.liunian.currentYear : new Date().getFullYear()
      this.liunianDayStemIdx = HEAVENLY_STEMS.indexOf(data.day.stem)
      this.liunianDayBranchIdx = EARTHLY_BRANCHES.indexOf(data.day.branch)
      this.liunianDmElement = STEM_ELEMENT.get(data.dayMaster) || ''
      this.chatHistory = []
      await this.saveRecord(data)
    } catch (e) {
      this.error = '排盘计算失败，请检查日期格式是否正确。'
    } finally {
      this.loading = false
    }
  }

  async saveRecord(data: BaziData) {
    const rec: SavedBaziReading = {
      id: 'b' + Date.now() + Math.floor(Math.random() * 10000),
      timestamp: Date.now(),
      date: this.date,
      time: this.time,
      gender: this.gender,
      useTrueSolar: this.useTrueSolar,
      longitude: this.longitude,
      yearPillar: data.year.stem + data.year.branch,
      monthPillar: data.month.stem + data.month.branch,
      dayPillar: data.day.stem + data.day.branch,
      hourPillar: data.hour.stem + data.hour.branch,
      dayMaster: data.dayMaster,
      structure: data.structure ? data.structure.name : '',
      fiveElements: JSON.stringify(Array.from(data.fiveElements.entries()))
    }
    await saveBaziReading(rec)
    this.records = [rec, ...this.records].slice(0, 20)
  }

  async restoreRecord(rec: SavedBaziReading) {
    this.date = rec.date
    this.time = rec.time
    this.gender = rec.gender
    this.useTrueSolar = rec.useTrueSolar || false
    if (rec.longitude) { this.longitude = rec.longitude }
    await this.handleCalculate()
  }

  async removeRecord(rec: SavedBaziReading) {
    await deleteBaziReading(rec.id)
    this.records = this.records.filter(r => r.id !== rec.id)
  }

  changeLiunianYear(delta: number): void {
    if (!this.result) return
    this.liunianYear += delta
    this.liunian = getLiunianForYear(
      this.liunianDayStemIdx, this.liunianDayBranchIdx, this.liunianDmElement, this.liunianYear)
  }

  buildShareText(): string {
    if (!this.result) return ''
    const r = this.result
    let text = formatBaziShareText(
      this.date, this.time, this.gender,
      r.year.stem, r.year.branch, r.month.stem, r.month.branch,
      r.day.stem, r.day.branch, r.hour.stem, r.hour.branch,
      r.dayMaster, r.dayMasterAnalysis,
      r.structure ? r.structure.name : '', r.structure ? r.structure.description : ''
    )
    if (r.mingGong) { text += '命宫：' + r.mingGong.stem + r.mingGong.branch + '\n' }
    if (r.taiYuan) { text += '胎元：' + r.taiYuan.stem + r.taiYuan.branch + '\n' }
    if (this.trueSolar) {
      text += '真太阳时：' + this.pad2(this.trueSolar.correctedDate.getHours()) + ':' +
        this.pad2(this.trueSolar.correctedDate.getMinutes()) +
        '（校正' + this.trueSolar.correctionMinutes + '分钟）\n'
    }
    text += '—— 天道玄机 · 仅供文化娱乐参考'
    return text
  }

  copyResult(): void {
    const text = this.buildShareText()
    if (text.length === 0) return
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      this.getUIContext().getPromptAction().showToast({ message: '排盘结果已复制' })
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
      let reply: string
      if (!this.aiConfig.apiKey) {
        reply = this.offlineReport
      } else {
        reply = await interpretMetaphysics(messages, this.aiConfig)
      }
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: reply }]
    } catch (_e) {
      this.chatHistory = [...this.chatHistory, { role: 'assistant', content: 'AI解析暂时不可用。' + this.baseAnalysis }]
    } finally {
      this.aiLoading = false
    }
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
    if (r.mingGong) { ctx += '\n命宫：' + r.mingGong.stem + r.mingGong.branch }
    if (r.taiYuan) { ctx += '\n胎元：' + r.taiYuan.stem + r.taiYuan.branch }
    if (r.shensha && r.shensha.entries.length > 0) {
      ctx += '\n神煞：' + r.shensha.entries.map(e => e.name).join('、')
    }
    return ctx
  }
}
