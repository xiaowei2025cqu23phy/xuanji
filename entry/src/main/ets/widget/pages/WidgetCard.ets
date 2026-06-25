import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit'
import { Want } from '@kit.AbilityKit'

// Daily hexagram widget card
@Entry
@Component
struct WidgetCard {
  @State currentDate: string = ''
  @State dayStemBranch: string = ''
  @State dayHexagram: string = ''
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

    // Simple date display
    this.currentDate = y + '年' + m + '月' + d + '日'

    // Day stem-branch (simplified)
    const stemIdx = ((y - 4) * 5 + (m - 1) * 2 + d) % 10
    const branchIdx = ((y - 4) * 7 + (m - 1) * 2 + d + 3) % 12
    const stems = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸']
    const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']
    const zodiacNames = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪']

    this.dayStemBranch = stems[(stemIdx % 10 + 10) % 10] + branches[(branchIdx % 12 + 12) % 12]
    this.yearStemBranch = stems[((y - 4) % 10 + 10) % 10] + branches[((y - 4) % 12 + 12) % 12]
    this.zodiac = zodiacNames[((y - 4) % 12 + 12) % 12]

    // Daily hexagram (simplified: use date as seed to pick one of 64)
    const hexIdx = (y * 365 + m * 31 + d) % 64
    const bin = hexIdx.toString(2).padStart(6, '0')
    this.dayHexagram = bin

    // Popular hexagrams for display
    const hexNames = [
      '乾', '坤', '屯', '蒙', '需', '讼', '师', '比', '小畜', '履',
      '泰', '否', '同人', '大有', '谦', '豫', '随', '蛊', '临', '观',
      '噬嗑', '贲', '剥', '复', '无妄', '大畜', '颐', '大过', '坎', '离',
      '咸', '恒', '遁', '大壮', '晋', '明夷', '家人', '睽', '蹇', '解',
      '损', '益', '夬', '姤', '萃', '升', '困', '井', '革', '鼎',
      '震', '艮', '渐', '归妹', '丰', '旅', '巽', '兑', '涣', '节',
      '中孚', '小过', '既济', '未济'
    ]
    const hexSymbols = [
      '䷀', '䷁', '䷂', '䷃', '䷄', '䷅', '䷆', '䷇', '䷈', '䷉',
      '䷊', '䷋', '䷌', '䷍', '䷎', '䷏', '䷐', '䷑', '䷒', '䷓',
      '䷔', '䷕', '䷖', '䷗', '䷘', '䷙', '䷚', '䷛', '䷜', '䷝',
      '䷞', '䷟', '䷠', '䷡', '䷢', '䷣', '䷤', '䷥', '䷦', '䷧',
      '䷨', '䷩', '䷪', '䷫', '䷬', '䷭', '䷮', '䷯', '䷰', '䷱',
      '䷲', '䷳', '䷴', '䷵', '䷶', '䷷', '䷸', '䷹', '䷺', '䷻',
      '䷼', '䷽', '䷾', '䷿'
    ]
    this.dayHexName = hexNames[hexIdx]
    this.dayHexSymbol = hexSymbols[hexIdx]
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
