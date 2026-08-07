import { COLORS, INK, RED } from '../common/constants'

interface MoreItem {
  id: string
  icon: string
  title: string
  desc: string
  color: string
}

const MORE_ITEMS: MoreItem[] = [
  { id: 'solar', icon: '☀', title: '二十四节气', desc: '精确节气时刻表 · VSOP87D 天文算法', color: '#A67C52' },
  { id: 'zodiac', icon: '🐭', title: '生肖运程', desc: '当年运程 · 与今日干支的关系', color: '#2D5A27' },
  { id: 'compat', icon: '💞', title: '生肖配对', desc: '六合 / 三合 / 六冲 / 相刑 / 相害 / 自刑', color: '#B91C1C' },
  { id: 'hehun', icon: '🈴', title: '八字合婚', desc: '双方四柱 · 五行互补 · 综合评分', color: '#1E3A8A' },
  { id: 'cosmos', icon: '☯', title: '易理图鉴', desc: '河图洛书 · 先天后天八卦', color: '#7C512D' },
  { id: 'privacy', icon: '📄', title: '隐私与免责', desc: '数据使用说明 · 免责声明', color: '#5D4A2A' },
]

@Component
export struct MoreSection {
  @StorageLink('uiDark') isDark: boolean = false
  onSelect: (tabId: string) => void = (_id: string) => {}

  build() {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('更多功能').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('MORE').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%')

      ForEach(MORE_ITEMS, (item: MoreItem) => {
        Row({ space: 12 }) {
          Text(item.icon).fontSize(24).width(40).textAlign(TextAlign.Center)
          Column({ space: 3 }) {
            Text(item.title).fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
            Text(item.desc).fontSize(9).fontColor(INK.SECONDARY)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          Text('›').fontSize(18).fontColor(INK.PLACEHOLDER)
        }
        .width('100%').padding(14)
        .backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: INK.HAIRLINE }).borderRadius(14)
        .shadow({ radius: 6, color: COLORS.INK_BLACK + '0A', offsetY: 2 })
        .onClick(() => { this.onSelect(item.id) })
      }, (item: MoreItem) => item.id)

      Text('更多传统易学功能持续添加中。')
        .fontSize(9).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%').textAlign(TextAlign.Center)
    }
    .width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }
}
