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
    }.width('100%')
  }

  @Builder PickerCard() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('黄历万年历').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
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
    .width('100%').padding(18)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
    .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
  }

  @Builder Tag(text: string, color: string) {
    Text(text).fontSize(10).fontWeight(FontWeight.Bold).fontColor(color)
      .backgroundColor(COLORS.alpha(color, 0.12))
      .borderRadius(8).padding({ left: 10, right: 10, top: 4, bottom: 4 })
  }

  @Builder InfoCard() {
    if (this.info) {
      Column({ space: 16 }) {
        // Date display — hero text
        Column({ space: 6 }) {
          Text(this.info!.dateText + ' · ' + '日一二三四五六'.charAt(this.selected.getDay()))
            .fontSize(11).fontColor(INK.PLACEHOLDER)
          Text('农历' + this.info!.lunarText)
            .fontSize(28).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        }.alignItems(HorizontalAlign.Center).width('100%')

        // Stem-Branch tags
        Row({ space: 6 }) {
          this.Tag(this.info!.yearStemBranch + '年', COLORS.IMPERIAL_RED)
          this.Tag('属' + this.info!.yearZodiac, COLORS.AMBER_GOLD)
          this.Tag(this.info!.monthStemBranch + '月', COLORS.WOOD)
          this.Tag(this.info!.dayStemBranch + '日', COLORS.WATER)
        }.width('100%').justifyContent(FlexAlign.Center)

        Divider().color(INK.HAIRLINE)

        // Solar term + ChongSha
        Row({ space: 8 }) {
          Column({ space: 3 }) {
            Text('节气').fontSize(9).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text('处' + this.info!.solarTerm).fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          }
          if (this.info!.isSolarTermDay) {
            Text('⚡今日交节').fontSize(9).fontWeight(FontWeight.Bold).fontColor(COLORS.WHITE)
              .backgroundColor(COLORS.IMPERIAL_RED).borderRadius(8)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          Blank().layoutWeight(1)
          Column({ space: 3 }) {
            Text('冲煞').fontSize(9).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.info!.chong + ' · ' + this.info!.sha)
              .fontSize(12).fontWeight(FontWeight.Bold).fontColor(RED.LABEL)
          }
        }.width('100%')

        // Jianchu
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text('建除十二神').fontSize(10).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
            Text(this.info!.jianchu + '日').fontSize(22).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
          }
          Text(this.info!.jianchuDesc).fontSize(9).fontColor(INK.SECONDARY)
        }

        // Yi / Ji columns
        Row({ space: 12 }) {
          Column({ space: 8 }) {
            Text('✅ 宜').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.WOOD)
            Row({ space: 4 }) {
              ForEach(this.info!.yi, (item: string) => {
                Text(item).fontSize(10).fontColor(COLORS.WOOD)
                  .backgroundColor(COLORS.alpha(COLORS.WOOD, 0.12))
                  .borderRadius(8).padding({ left: 10, right: 10, top: 5, bottom: 5 })
              })
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)

          Column({ space: 8 }) {
            Text('❌ 忌').fontSize(11).fontWeight(FontWeight.Bold).fontColor(COLORS.IMPERIAL_RED)
            Row({ space: 4 }) {
              ForEach(this.info!.ji, (item: string) => {
                Text(item).fontSize(10).fontColor(COLORS.IMPERIAL_RED)
                  .backgroundColor(RED.BG_MEDIUM)
                  .borderRadius(8).padding({ left: 10, right: 10, top: 5, bottom: 5 })
              })
            }
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }.width('100%')

        Text('黄历宜忌按建除十二神等传统规则离线生成，仅供文化娱乐参考。')
          .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
      }
      .width('100%').padding(18)
      .backgroundColor(COLORS.WHITE + '66')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(18)
      .shadow({ radius: 6, color: COLORS.INK_BLACK + '08', offsetY: 2 })
    }
  }
}
