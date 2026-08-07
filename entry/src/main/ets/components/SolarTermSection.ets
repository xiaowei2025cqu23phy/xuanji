import { COLORS, INK, RED } from '../common/constants'
import { getSolarTermDate, getSolarTermName } from '../model/lunar-service'
import { TERM_LONGITUDES } from '../model/solar-terms'

interface TermRow {
  idx: number
  name: string
  timeText: string
  longitude: number
  desc: string
}

const TERM_DESCS: string[] = [
  '寒潮频繁，进入一年中最冷的时段，宜温补养藏。',
  '一年最后一个节气，寒气至极，大地冰封，宜休养生息。',
  '春季开始，万物复苏，为一年之始，宜立志规划。',
  '气温回升，降水渐增，冰雪消融，万物萌动。',
  '春雷乍动，蛰虫惊醒，生机勃发。',
  '昼夜平分，阴阳调和，春色正中。',
  '气清景明，万物洁齐，宜祭祀踏青。',
  '雨生百谷，秧苗初插，作物新种。',
  '夏季开始，万物繁茂，气温渐升。',
  '麦类等夏熟作物籽粒开始饱满。',
  '有芒之谷可种，农事繁忙之时。',
  '白昼最长，阳气至极，一阴始生。',
  '暑气渐盛，尚未达极，注意防暑降温。',
  '一年中最热时节，雷雨频繁。',
  '秋季开始，暑去凉来，禾谷渐熟。',
  '暑气至此而止，秋意渐显。',
  '天气转凉，露珠凝白。',
  '昼夜平分，秋色平分，丰收时节。',
  '露气寒冷，将凝结为霜，注意保暖。',
  '气温骤降，露结为霜，宜润燥防寒。',
  '冬季开始，万物收藏，宜休养生息。',
  '开始降雪，量小而疏。',
  '降雪量增大，仲冬时节。',
  '白昼最短，阴极阳生，宜进补养藏。',
]

@Component
export struct SolarTermSection {
  @StorageLink('uiDark') isDark: boolean = false
  @State year: number = new Date().getFullYear()
  @State rows: TermRow[] = []
  @State currentIdx: number = -1

  aboutToAppear() {
    this.loadYear(this.year)
  }

  loadYear(y: number): void {
    const now = new Date()
    const rows: TermRow[] = []
    let cur = -1
    const p = (n: number): string => String(n).padStart(2, '0')
    for (let i = 0; i < 24; i++) {
      const d = getSolarTermDate(y, i)
      const bj = new Date(d.getTime() + 8 * 3600000)
      const timeText = bj.getUTCFullYear() + '-' + p(bj.getUTCMonth() + 1) + '-' + p(bj.getUTCDate()) +
        ' ' + p(bj.getUTCHours()) + ':' + p(bj.getUTCMinutes())
      rows.push({
        idx: i,
        name: getSolarTermName(i),
        timeText: timeText,
        longitude: TERM_LONGITUDES[i],
        desc: TERM_DESCS[i]
      })
      if (y === now.getFullYear() && d.getTime() <= now.getTime()) {
        cur = i
      }
    }
    this.rows = rows
    this.currentIdx = cur
  }

  build() {
    Column({ space: 20 }) {
      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
          Text('二十四节气').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          Text('VSOP87D 天文算法 · 精确到分钟').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
        }.width('100%')
        Row({ space: 8 }) {
          Button('‹ 上一年').fontSize(11).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 }).borderRadius(10)
            .onClick(() => { this.year -= 1; this.loadYear(this.year) })
          Text(this.year + ' 年').fontSize(16).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold).layoutWeight(1)
            .textAlign(TextAlign.Center)
          Button('下一年 ›').fontSize(11).fontColor(COLORS.IMPERIAL_RED).backgroundColor(RED.BG_MEDIUM)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 }).borderRadius(10)
            .onClick(() => { this.year += 1; this.loadYear(this.year) })
        }.width('100%')
      }
      .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
      .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)

      ForEach(this.rows, (row: TermRow) => {
        Column({ space: 6 }) {
          Row({ space: 10 }) {
            Column({ space: 2 }) {
              Text(row.name).fontSize(16).fontColor(
                row.idx === this.currentIdx ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
                .fontWeight(FontWeight.Bold)
              Text('黄经 ' + row.longitude + '°').fontSize(8).fontColor(INK.PLACEHOLDER)
            }.alignItems(HorizontalAlign.Start)
            Blank().layoutWeight(1)
            if (row.idx === this.currentIdx) {
              Text('今处此节气').fontSize(8).fontColor(COLORS.WHITE)
                .backgroundColor(COLORS.IMPERIAL_RED)
                .padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8)
            }
            Column({ space: 2 }) {
              Text(row.timeText).fontSize(12).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
              Text('北京时间').fontSize(8).fontColor(INK.PLACEHOLDER)
            }.alignItems(HorizontalAlign.End)
          }.width('100%')
          Text(row.desc).fontSize(10).fontColor(INK.BODY).lineHeight(16)
        }
        .width('100%').padding(12)
        .backgroundColor(row.idx === this.currentIdx ? COLORS.ACTIVE_CARD_BG : COLORS.WHITE + '66')
        .border({ width: 1, color: row.idx === this.currentIdx ? RED.BORDER : INK.HAIRLINE })
        .borderRadius(12)
      }, (row: TermRow) => row.idx.toString())

      Text('节气时刻由 VSOP87D 太阳黄经算法实时计算，误差约 1–2 分钟，与天文台历书数据一致。')
        .fontSize(9).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%').textAlign(TextAlign.Center)
    }.width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }
}
