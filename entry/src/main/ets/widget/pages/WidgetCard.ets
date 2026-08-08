import { HEAVENLY_STEMS, EARTHLY_BRANCHES, ZODIAC_NAMES } from '../../common/constants'
import { GET_HEX_BY_BINARY } from '../../model/iching-data'

// Daily hexagram widget card
@Entry
@Component
struct WidgetCard {
  @State currentDate: string = ''
  @State dayStemBranch: string = ''
  @State dayHexSymbol: string = ''
  @State dayHexName: string = ''
  @State dayHexMeaning: string = ''
  @State yearStemBranch: string = ''
  @State zodiac: string = ''

  aboutToAppear(): void {
    this.refreshDaily()
  }

  refreshDaily(): void {
    const now = new Date()
    const y = now.getFullYear()
    const m = now.getMonth() + 1
    const d = now.getDate()

    this.currentDate = y + '年' + m + '月' + d + '日'

    // Day stem-branch: continuous 60-day cycle from 1900-01-01 (甲戌日, index 10)
    const epoch = new Date(1900, 0, 1)
    const diffDays = Math.floor((now.getTime() - epoch.getTime()) / 86400000)
    const dayIdx = ((diffDays % 60) + 60 + 10) % 60
    this.dayStemBranch = HEAVENLY_STEMS[dayIdx % 10] + EARTHLY_BRANCHES[dayIdx % 12]
    this.yearStemBranch = HEAVENLY_STEMS[((y - 4) % 10 + 10) % 10] +
      EARTHLY_BRANCHES[((y - 4) % 12 + 12) % 12]
    this.zodiac = ZODIAC_NAMES[((y - 4) % 12 + 12) % 12]

    // Daily hexagram: tied to the day sexagenary index
    const hexIdx = dayIdx % 64
    const bin = hexIdx.toString(2).padStart(6, '0')
    const hex = GET_HEX_BY_BINARY(bin)
    this.dayHexName = hex.name
    this.dayHexSymbol = hex.symbol
    this.dayHexMeaning = '点击进入天道玄机查看详情'
  }

  build() {
    Stack() {
      Column({ space: 8 }) {
        // Header
        Row({ space: 8 }) {
          Column({ space: 2 }) {
            Text('天道玄机').fontSize(14).fontColor('#B91C1C').fontWeight(FontWeight.Bold)
            Text('HEAVENLY DECRYPT').fontSize(7).fontColor('#1A1A1C').opacity(0.5)
          }
        }.width('100%')

        // Daily info
        Row({ space: 12 }) {
          Column({ space: 4 }) {
            Text(this.currentDate).fontSize(10).fontColor('#1A1A1C').opacity(0.6)
            Text(this.yearStemBranch + '年（' + this.zodiac + '年）')
              .fontSize(11).fontColor('#1A1A1C').fontWeight(FontWeight.Bold)
            Text('干支日: ' + this.dayStemBranch).fontSize(9).fontColor('#B91C1C').opacity(0.7)
          }
        }.width('100%')

        Divider().color('#B91C1C').opacity(0.15).width('100%')

        // Daily hexagram
        Row({ space: 10 }) {
          Text(this.dayHexSymbol).fontSize(36).fontColor('#B91C1C')
          Column({ space: 2 }) {
            Text('今日卦象').fontSize(8).fontColor('#1A1A1C').opacity(0.5)
            Text(this.dayHexName).fontSize(18).fontColor('#1A1A1C').fontWeight(FontWeight.Bold)
            Text(this.dayHexMeaning).fontSize(8).fontColor('#1A1A1C').opacity(0.5).maxLines(1)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }.width('100%')
      }
      .width('100%').height('100%').padding(16)
      .backgroundColor('#FDFAF3')
    }
    .width('100%').height('100%')
  }
}
