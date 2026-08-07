import { COLORS, INK, RED, OP, HEAVENLY_STEMS, EARTHLY_BRANCHES } from '../common/constants'
import { getDailyHourLuck, HourLuck, DailyHourLuck } from '../model/hour-luck'
import { getAlmanac } from '../model/lunar-service'

@Component
export struct HourLuckSection {
  @State selectedDate: Date = new Date()
  @State dailyLuck: DailyHourLuck | null = null
  @State dayStemBranch: string = ''

  aboutToAppear() {
    this.loadLuck()
  }

  loadLuck() {
    const almanac = getAlmanac(this.selectedDate)
    const dayBranch = almanac.dayStemBranch.charAt(1)
    const dayBranchIdx = EARTHLY_BRANCHES.indexOf(dayBranch)
    const monthBranch = almanac.monthStemBranch.charAt(1)
    const monthBranchIdx = EARTHLY_BRANCHES.indexOf(monthBranch)
    this.dayStemBranch = almanac.dayStemBranch
    this.dailyLuck = getDailyHourLuck(dayBranch, dayBranchIdx, monthBranchIdx)
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Text('吉时查询').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Blank().layoutWeight(1)
        DatePicker({
          start: new Date('1900-1-1'),
          end: new Date('2100-12-31'),
          selected: this.selectedDate
        })
          .onChange((value: DatePickerResult) => {
            this.selectedDate = new Date(value.year!, value.month!, value.day!)
            this.loadLuck()
          })
          .width(140)
      }.width('100%')

      if (this.dailyLuck) {
        Row({ space: 12 }) {
          Text('日柱').fontSize(10).fontColor(INK.PLACEHOLDER)
          Text(this.dayStemBranch).fontSize(16).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          Text('·').fontSize(12).fontColor(INK.PLACEHOLDER)
          Text(this.dailyLuck!.bestHours.length + ' 个吉时').fontSize(10).fontColor(COLORS.WOOD).fontWeight(FontWeight.Bold)
        }.width('100%')

        if (this.dailyLuck!.bestHours.length > 0) {
          Row({ space: 8 }) {
            Text('吉时').fontSize(10).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            ForEach(this.dailyLuck!.bestHours, (h: HourLuck) => {
              Text(h.branchName + '时')
                .fontSize(9).fontColor(COLORS.WHITE)
                .backgroundColor(COLORS.IMPERIAL_RED)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(8)
            }, (h: HourLuck) => h.branchIdx.toString())
          }.width('100%')
        }

        Column({ space: 0 }) {
          ForEach(this.dailyLuck!.hours, (h: HourLuck, idx: number) => {
            Row({ space: 8 }) {
              Text(h.branchName + '时')
                .width(40).fontSize(11)
                .fontColor(h.isAuspicious ? COLORS.IMPERIAL_RED : INK.BODY)
                .fontWeight(h.isAuspicious ? FontWeight.Bold : FontWeight.Normal)
              Text(h.timeRange)
                .width(100).fontSize(9).fontColor(INK.PLACEHOLDER)
              Text(h.huanghei)
                .width(50).fontSize(10)
                .fontColor(h.isAuspicious ? COLORS.WOOD : COLORS.IMPERIAL_RED)
                .fontWeight(FontWeight.Bold)
              Text(h.jianxing)
                .width(24).fontSize(9).fontColor(INK.SECONDARY)
              Text(h.advice)
                .layoutWeight(1).fontSize(9).fontColor(INK.BODY)
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%').padding({ left: 10, right: 10, top: 8, bottom: 8 })
            .backgroundColor(h.isAuspicious ? COLORS.WOOD + '0A' : COLORS.WHITE + '66')
            .border({ width: { bottom: 1 }, color: INK.HAIRLINE })
          }, (h: HourLuck) => h.branchIdx.toString())
        }
        .width('100%')
        .backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)

        Text('黄道吉时利于出行、会谈、签约等正事；黑道时辰宜静守，不宜启动重大事项。')
          .fontSize(9).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      }
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    .shadow({ radius: 10, color: COLORS.INK_BLACK + '14', offsetY: 4 })
  }
}
