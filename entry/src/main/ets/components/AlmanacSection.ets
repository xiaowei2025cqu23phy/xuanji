import { COLORS, INK, RED } from '../common/constants'
import { getAlmanac, AlmanacInfo } from '../model/lunar-service'

@Component
export struct AlmanacSection {
  @StorageLink('uiDark') isDark: boolean = false
  @State selected: Date = new Date()
  @State info: AlmanacInfo | null = null

  aboutToAppear() {
    this.info = getAlmanac(this.selected)
  }

  build() {
    Column({ space: 20 }) {
      this.PickerCard()
      if (this.info) { this.InfoCard() }
    }.width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }

  @Builder PickerCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('黄历万年历').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('ALMANAC').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%')
      DatePicker({
        start: new Date('1900-1-1'),
        end: new Date('2100-12-31'),
        selected: this.selected
      })
        .onChange((value: DatePickerResult) => {
          this.selected = new Date(value.year!, value.month!, value.day!)
          this.info = getAlmanac(this.selected)
        })
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder Tag(text: string, color: string) {
    Text(text).fontSize(9).fontWeight(FontWeight.Bold).fontColor(color)
      .backgroundColor(COLORS.alpha(color, 0.1))
      .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(10)
  }

  @Builder InfoCard() {
    if (this.info) {
      Column({ space: 14 }) {
        Column({ space: 4 }) {
          Text(this.info!.dateText + ' · 星期' + '日一二三四五六'.charAt(this.selected.getDay()))
            .fontSize(10).fontColor(INK.PLACEHOLDER)
          Text('农历' + this.info!.lunarText)
            .fontSize(24).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
        }.alignItems(HorizontalAlign.Center).width('100%')

        Row({ space: 8 }) {
          this.Tag(this.info!.yearStemBranch + '年', COLORS.IMPERIAL_RED)
          this.Tag('属' + this.info!.yearZodiac, COLORS.AMBER_GOLD)
          this.Tag(this.info!.monthStemBranch + '月', COLORS.WOOD)
          this.Tag(this.info!.dayStemBranch + '日', COLORS.WATER)
        }.width('100%').justifyContent(FlexAlign.Center)

        Divider().color(INK.HAIRLINE)

        Row({ space: 8 }) {
          Text('节气').fontSize(10).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
          Text('处 ' + this.info!.solarTerm).fontSize(12).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          if (this.info!.isSolarTermDay) {
            Text('今日交节').fontSize(9).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              .backgroundColor(RED.BG_MEDIUM).padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8)
          }
          Blank().layoutWeight(1)
          Text(this.info!.chong + ' · ' + this.info!.sha).fontSize(10).fontColor(RED.LABEL).fontWeight(FontWeight.Bold)
        }.width('100%')

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text('建除十二神').fontSize(10).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.info!.jianchu + '日').fontSize(20).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
          }
          Text(this.info!.jianchuDesc).fontSize(9).fontColor(INK.SECONDARY)
        }.width('100%').alignItems(HorizontalAlign.Start)

        Row({ space: 16 }) {
          Column({ space: 6 }) {
            Text('宜').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.WOOD)
            ForEach(this.info!.yi, (item: string) => {
              Text(item).fontSize(9).fontColor(COLORS.WOOD)
                .backgroundColor(COLORS.WOOD + '12')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(8)
            }, (item: string) => item)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Column({ space: 6 }) {
            Text('忌').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
            ForEach(this.info!.ji, (item: string) => {
              Text(item).fontSize(9).fontColor(COLORS.IMPERIAL_RED)
                .backgroundColor(RED.BG_MEDIUM)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 }).borderRadius(8)
            }, (item: string) => item)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }.width('100%')

        Text('黄历宜忌按建除十二神等传统规则离线生成，仅供文化娱乐参考。')
          .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    }
  }
}
