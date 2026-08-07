import { COLORS, INK, RED, ELEMENT_COLORS } from '../common/constants'
import { calculateBazi } from '../model/lunar-service'
import { BaziData, PillarData } from '../model/bazi-data'
import { calculateHehunFull, HehunFullResult } from '../model/zodiac-compat'

@Component
export struct HehunSection {
  @StorageLink('uiDark') isDark: boolean = false
  @State maleDate: string = '1990-06-15'
  @State maleTime: string = '10:00'
  @State femaleDate: string = '1992-10-01'
  @State femaleTime: string = '14:30'
  @State maleResult: BaziData | null = null
  @State femaleResult: BaziData | null = null
  @State hehun: HehunFullResult | null = null
  @State loading: boolean = false
  @State error: string = ''

  parseDate(s: string): Date {
    const p = s.split('-').map(Number)
    return new Date(p[0], p[1] - 1, p[2])
  }

  parseTime(s: string): Date {
    const p = s.split(':').map(Number)
    const d = new Date()
    d.setHours(p[0], p[1], 0, 0)
    return d
  }

  combineDateTime(dateStr: string, timeStr: string): Date {
    const d = this.parseDate(dateStr)
    const t = this.parseTime(timeStr)
    d.setHours(t.getHours(), t.getMinutes(), 0, 0)
    return d
  }

  buildDateTime(s: DatePickerResult, isMale: boolean, isDate: boolean): void {
    const y = s.year!
    const m = s.month!
    const d = s.day!
    if (isMale) {
      this.maleDate = isDate ? y + '-' + String(m + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0') : this.maleDate
    } else {
      this.femaleDate = isDate ? y + '-' + String(m + 1).padStart(2, '0') + '-' + String(d).padStart(2, '0') : this.femaleDate
    }
  }

  buildTime(t: TimePickerResult, isMale: boolean): void {
    const v = String(t.hour!).padStart(2, '0') + ':' + String(t.minute!).padStart(2, '0')
    if (isMale) { this.maleTime = v } else { this.femaleTime = v }
  }

  runHehun(): void {
    this.loading = true
    this.error = ''
    this.hehun = null
    try {
      const male = calculateBazi(this.combineDateTime(this.maleDate, this.maleTime), 'male')
      const female = calculateBazi(this.combineDateTime(this.femaleDate, this.femaleTime), 'female')
      this.maleResult = male
      this.femaleResult = female
      this.hehun = calculateHehunFull(male, female)
    } catch (e) {
      this.error = '合婚测算失败，请检查日期格式。'
    } finally {
      this.loading = false
    }
  }

  build() {
    Column({ space: 20 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('八字合婚').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('HEHUN').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%')

      this.InputCard('男方', this.maleDate, this.maleTime, true)
      this.InputCard('女方', this.femaleDate, this.femaleTime, false)

      Button(this.loading ? '测算中...' : '开始合婚')
        .fontSize(13).fontWeight(FontWeight.Bold)
        .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
        .padding({ left: 40, right: 40, top: 12, bottom: 12 }).borderRadius(14)
        .enabled(!this.loading)
        .onClick(() => { this.runHehun() })

      if (this.error.length > 0) {
        Text(this.error).fontSize(11).fontColor(COLORS.IMPERIAL_RED).padding(10).backgroundColor(RED.BG_FAINT)
      }

      if (this.hehun && this.maleResult && this.femaleResult) {
        this.ResultCard()
      }
    }.width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }

  @Builder InputCard(label: string, dateStr: string, timeStr: string, isMale: boolean) {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text(label).fontSize(12).fontWeight(FontWeight.Bold)
          .fontColor(isMale ? COLORS.WATER : COLORS.IMPERIAL_RED)
        Blank().layoutWeight(1)
      }.width('100%')
      Row({ space: 12 }) {
        DatePicker({
          start: new Date('1900-1-1'),
          end: new Date('2100-12-31'),
          selected: this.parseDate(dateStr)
        })
          .onChange((v: DatePickerResult) => { this.buildDateTime(v, isMale, true) })
        TimePicker({ selected: this.parseTime(timeStr) })
          .onChange((v: TimePickerResult) => { this.buildTime(v, isMale) })
      }.width('100%')
    }
    .width('100%').padding(14).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(14)
  }

  @Builder PillarLine(p: PillarData, color: string) {
    Text(p.stem + p.branch).fontSize(20).fontWeight(FontWeight.Bold).fontColor(color)
  }

  @Builder ResultCard() {
    Column({ space: 14 }) {
      // 双方四柱
      Row({ space: 12 }) {
        Column({ space: 4 }) {
          Text('男方').fontSize(10).fontColor(INK.PLACEHOLDER)
          Row({ space: 6 }) {
            this.PillarLine(this.maleResult!.year, COLORS.INK_BLACK)
            this.PillarLine(this.maleResult!.month, COLORS.INK_BLACK)
            this.PillarLine(this.maleResult!.day, COLORS.INK_BLACK)
            this.PillarLine(this.maleResult!.hour, COLORS.INK_BLACK)
          }
        }.alignItems(HorizontalAlign.Start)
        Blank().layoutWeight(1)
        Column({ space: 4 }) {
          Text('女方').fontSize(10).fontColor(INK.PLACEHOLDER)
          Row({ space: 6 }) {
            this.PillarLine(this.femaleResult!.year, COLORS.IMPERIAL_RED)
            this.PillarLine(this.femaleResult!.month, COLORS.IMPERIAL_RED)
            this.PillarLine(this.femaleResult!.day, COLORS.IMPERIAL_RED)
            this.PillarLine(this.femaleResult!.hour, COLORS.IMPERIAL_RED)
          }
        }.alignItems(HorizontalAlign.End)
      }.width('100%')

      // 评分
      Row({ space: 12 }) {
        Text(this.hehun!.overallScore + '').fontSize(48).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
        Column({ space: 4 }) {
          Text('综合评分').fontSize(10).fontColor(INK.PLACEHOLDER)
          Text(this.hehun!.level).fontSize(18).fontColor(COLORS.AMBER_GOLD).fontWeight(FontWeight.Bold)
        }.alignItems(HorizontalAlign.Start)
        Blank().layoutWeight(1)
      }.width('100%')

      Divider().color(INK.HAIRLINE)

      this.DetailRow('日干五行', this.hehun!.stemRelation.label + ' · ' + this.hehun!.stemRelation.desc)
      this.DetailRow('日支关系', this.hehun!.branchRelation.label + ' · ' + this.hehun!.branchRelation.description)
      this.DetailRow('生肖关系', this.hehun!.zodiacRelation.label + ' · ' + this.hehun!.zodiacRelation.description)
      this.DetailRow('日柱纳音', this.hehun!.nayinText)
      this.DetailRow('五行互补', this.hehun!.complementText)

      Divider().color(INK.HAIRLINE)

      Text(this.hehun!.summary).fontSize(11).fontColor(INK.BODY).lineHeight(18)

      Text('合婚结果基于传统命理规则离线生成，仅供文化娱乐参考，请理性看待。')
        .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%')
    }
    .width('100%').padding(16).backgroundColor(COLORS.ACTIVE_CARD_BG)
    .border({ width: 1, color: RED.BORDER }).borderRadius(16)
  }

  @Builder DetailRow(label: string, value: string) {
    Column({ space: 3 }) {
      Text(label).fontSize(9).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold).width('100%')
      Text(value).fontSize(10).fontColor(INK.BODY).lineHeight(15).width('100%')
    }.width('100%').alignItems(HorizontalAlign.Start)
  }
}
