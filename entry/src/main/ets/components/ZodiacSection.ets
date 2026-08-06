import { COLORS, INK, RED, EARTHLY_BRANCHES } from '../common/constants'
import { getYearStemBranch, getAlmanac } from '../model/lunar-service'

const ZODIAC_NAMES: string[] = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪']
const ZODIAC_FORTUNE: string[] = [
  '机遇与变动并存，宜顺势而为，善用人脉网络带来的机会，注意劳逸结合。',
  '稳重守成之年，宜深耕本职，财帛稳定，感情上多些主动沟通。',
  '冲太岁之年，变化较多，宜低调行事、稳中求进，注意健康与出行安全。',
  '贵人运佳，事业有进阶之机，宜广结善缘，财运稳中有升。',
  '文昌运旺，利于学习考试与创意表达，感情宜坦诚相待。',
  '与太岁相合，诸事顺遂，宜大胆规划，财运与事业双线向好。',
  '本命之年，能量充沛但也易有波动，宜张弛有度，重大决策三思后行。',
  '六合之年，人缘和顺，宜合作共赢，健康方面注意饮食。',
  '三合之象，事业有贵人提携，宜把握新机会，财运渐入佳境。',
  '伏吟之年，宜守不宜攻，稳健理财，注意情绪调节。',
  '三合之象，运势回升，宜积极行动，家庭关系和谐。',
  '与太岁相冲，变动较多，宜以静制动，注意财务规划与出行安全。',
]

// 六合：子丑、寅亥、卯戌、辰酉、巳申、午未
function isLiuHe(a: number, b: number): boolean {
  return (a === 0 && b === 1) || (a === 1 && b === 0) ||
    (a === 2 && b === 11) || (a === 11 && b === 2) ||
    (a === 3 && b === 10) || (a === 10 && b === 3) ||
    (a === 4 && b === 9) || (a === 9 && b === 4) ||
    (a === 5 && b === 8) || (a === 8 && b === 5) ||
    (a === 6 && b === 7) || (a === 7 && b === 6)
}

function isSanHe(a: number, b: number): boolean {
  const groups: number[][] = [[0, 4, 8], [2, 6, 10], [1, 5, 9], [3, 7, 11]]
  for (let g = 0; g < groups.length; g++) {
    if (groups[g].indexOf(a) >= 0 && groups[g].indexOf(b) >= 0) { return true }
  }
  return false
}

function todayRelation(z: number, todayBranchIdx: number): string {
  if (z === todayBranchIdx) { return '值日' }
  if (isLiuHe(z, todayBranchIdx)) { return '六合' }
  if (isSanHe(z, todayBranchIdx)) { return '三合' }
  if ((z + 6) % 12 === todayBranchIdx) { return '相冲' }
  return '平平'
}

@Component
export struct ZodiacSection {
  @StorageLink('uiDark') isDark: boolean = false
  @State year: number = new Date().getFullYear()
  @State yearStemBranch: string = ''
  @State todayBranchIdx: number = 0
  @State todayStemBranch: string = ''

  aboutToAppear() {
    this.refresh()
  }

  refresh(): void {
    this.yearStemBranch = getYearStemBranch(this.year)
    const info = getAlmanac(new Date())
    const branch = info.dayStemBranch.charAt(1)
    this.todayBranchIdx = EARTHLY_BRANCHES.indexOf(branch)
    this.todayStemBranch = info.dayStemBranch
  }

  build() {
    Column({ space: 20 }) {
      this.HeaderCard()
      this.TodayHint()
      this.ZodiacGrid()
      this.PairCard()
    }.width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }

  @Builder HeaderCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('生肖运程').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('ZODIAC').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%')
      Text(this.year + ' 年 · 岁次' + this.yearStemBranch + ' · 属' + ZODIAC_NAMES[(this.year - 4) % 12])
        .fontSize(13).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder TodayHint() {
    Row({ space: 8 }) {
      Text('今日').fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
      Text('干支日 ' + this.todayStemBranch + ' · 与各生肖的关系（值日 / 六合 / 三合 / 相冲 / 平平）')
        .fontSize(9).fontColor(INK.SECONDARY)
      Blank().layoutWeight(1)
      Button('刷新').fontSize(9).fontColor(INK.LABEL).backgroundColor(INK.BG_FAINT)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .onClick(() => { this.refresh() })
    }.width('100%').padding(10).backgroundColor(INK.BG_FAINT)
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(10)
  }

  @Builder ZodiacGrid() {
    Grid() {
      ForEach(ZODIAC_NAMES, (z: string, idx: number) => {
        GridItem() {
          Column({ space: 4 }) {
            Text(z).fontSize(20).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(todayRelation(idx, this.todayBranchIdx))
              .fontSize(9).fontWeight(FontWeight.Bold)
              .fontColor(this.relationColor(todayRelation(idx, this.todayBranchIdx)))
              .backgroundColor(COLORS.alpha(this.relationColor(todayRelation(idx, this.todayBranchIdx)), 0.1))
              .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8)
            Text(ZODIAC_FORTUNE[idx])
              .fontSize(9).fontColor(INK.SECONDARY).lineHeight(14)
          }.alignItems(HorizontalAlign.Center)
          .width('100%').padding(10)
          .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
        }
      }, (z: string, idx: number) => z)
    }
    .columnsTemplate('1fr 1fr').width('100%')
  }

  relationColor(rel: string): string {
    if (rel === '六合' || rel === '三合') { return COLORS.WOOD }
    if (rel === '相冲') { return COLORS.IMPERIAL_RED }
    if (rel === '值日') { return COLORS.AMBER_GOLD }
    return INK.PLACEHOLDER
  }

  @Builder PairCard() {
    Column({ space: 10 }) {
      Text('生肖配对速查').fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION).width('100%')
      this.PairRow('六合（最佳）', '鼠牛 · 虎猪 · 兔狗 · 龙鸡 · 蛇猴 · 马羊', COLORS.WOOD)
      this.PairRow('三合（大吉）', '猴鼠龙 · 虎马狗 · 蛇鸡牛 · 猪兔羊', COLORS.AMBER_GOLD)
      this.PairRow('六冲（需谨慎）', '子午 · 丑未 · 寅申 · 卯酉 · 辰戌 · 巳亥', COLORS.IMPERIAL_RED)
      Text('配对关系仅作文化参考，合婚宜以双方八字整体论之。')
        .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%')
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder PairRow(label: string, value: string, color: string) {
    Row({ space: 10 }) {
      Text(label).fontSize(10).fontWeight(FontWeight.Bold).fontColor(color).width(110)
      Text(value).fontSize(10).fontColor(INK.BODY).layoutWeight(1)
    }.width('100%')
  }
}
