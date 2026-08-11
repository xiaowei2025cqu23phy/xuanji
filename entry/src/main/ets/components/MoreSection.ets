import { COLORS, INK, RED } from '../common/constants'

interface MoreItem {
  id: string
  icon: string
  title: string
  desc: string
  color: string
  bgColor: string
}

const MORE_ITEMS: MoreItem[] = [
  { id: 'solar',   icon: '☀️', title: '二十四节气', desc: '精确节气时刻表 · VSOP87D 天文算法', color: '#C9A46B', bgColor: '#F9EFE0' },
  { id: 'zodiac',  icon: '🐯', title: '生肖运程',     desc: '十二生肖当年运程 · 与今日干支的关系', color: '#4C8A45', bgColor: '#E8F5E3' },
  { id: 'compat',  icon: '💞', title: '生肖配对',     desc: '六合/三合/六冲/相刑/相害/自刑全规则', color: '#E05252', bgColor: '#FCEAEA' },
  { id: 'hehun',   icon: '🈴', title: '八字合婚',     desc: '双方四柱 · 五行互补 · 纳音综合评分', color: '#5B82D8', bgColor: '#E7EEFA' },
  { id: 'cosmos',  icon: '☯️', title: '易理图鉴',     desc: '河图洛书 · 先天后天八卦 · 万物类象', color: '#A97845', bgColor: '#F5EFE6' },
  { id: 'privacy', icon: '🛡', title: '隐私与免责',   desc: '数据使用说明 · 免责声明 · 版本信息', color: '#B4B4B4', bgColor: '#F5F5F5' },
]

@Component
export struct MoreSection {
  @StorageLink('uiDark') isDark: boolean = false
  onSelect: (tabId: string) => void = (_id: string) => {}

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('更多功能').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('MORE').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%').margin({ bottom: 2 })

      ForEach(MORE_ITEMS, (item: MoreItem) => {
        Row({ space: 14 }) {
          // Colored icon circle
          Stack() {
            Circle({ width: 44, height: 44 }).fill(item.bgColor)
            Text(item.icon).fontSize(22)
          }

          Column({ space: 4 }) {
            Text(item.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
            Text(item.desc).fontSize(10).fontColor(INK.SECONDARY).lineHeight(15)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)

          Text('›').fontSize(20).fontColor(INK.PLACEHOLDER)
        }
        .width('100%').padding(16)
        .backgroundColor(COLORS.WHITE + '80')
        .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
        .shadow({ radius: 8, color: COLORS.INK_BLACK + '0A', offsetY: 3 })
        .onClick(() => { this.onSelect(item.id) })
      })

      Text('✨ 更多传统易学功能持续添加中...')
        .fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
        .width('100%').textAlign(TextAlign.Center).margin({ top: 8 })
    }.width('100%')
  }
}
