import { COLORS, INK, RED, OP, EARTHLY_BRANCHES } from '../common/constants'
import { getZodiacRelation, ZodiacRelation, getAllZodiacPairs, ZodiacPairEntry } from '../model/zodiac-compat'

const ZODIAC_NAMES: string[] = ['鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪']
const ZODIAC_EMOJI: string[] = ['🐭', '🐮', '🐯', '🐰', '🐲', '🐍', '🐴', '🐑', '🐵', '🐔', '🐶', '🐷']

@Component
export struct ZodiacCompatSection {
  @State selectedIdx: number = 0
  @State pairs: ZodiacPairEntry[] = []

  aboutToAppear() {
    this.refreshPairs()
  }

  refreshPairs() {
    const branch = EARTHLY_BRANCHES[this.selectedIdx]
    this.pairs = getAllZodiacPairs(branch)
  }

  relColor(rel: ZodiacRelation): string {
    if (rel.score >= 85) return COLORS.WOOD
    if (rel.score >= 65) return COLORS.AMBER_GOLD
    if (rel.score >= 45) return INK.BODY
    return COLORS.IMPERIAL_RED
  }

  relBg(rel: ZodiacRelation): string {
    if (rel.score >= 85) return COLORS.WOOD + '08'
    if (rel.score >= 65) return COLORS.AMBER_GOLD + '08'
    if (rel.score >= 45) return COLORS.WHITE + '66'
    return RED.BG_FAINT
  }

  build() {
    Column({ space: 16 }) {
      Text('生肖配对').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)

      Scroll() {
        Row({ space: 6 }) {
          ForEach([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], (idx: number) => {
            Column({ space: 2 }) {
              Text(ZODIAC_EMOJI[idx]).fontSize(20)
              Text(ZODIAC_NAMES[idx]).fontSize(8).fontColor(this.selectedIdx === idx ? COLORS.WHITE : INK.BODY)
            }
            .width(44).height(50)
            .justifyContent(FlexAlign.Center)
            .backgroundColor(this.selectedIdx === idx ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
            .borderRadius(10)
            .onClick(() => { this.selectedIdx = idx; this.refreshPairs() })
          }, (idx: number) => idx.toString())
        }.padding({ left: 4, right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      .width('100%')

      Row({ space: 12 }) {
        Text(ZODIAC_EMOJI[this.selectedIdx]).fontSize(32)
        Column({ space: 4 }) {
          Text(ZODIAC_NAMES[this.selectedIdx] + '年').fontSize(16).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text('地支：' + EARTHLY_BRANCHES[this.selectedIdx]).fontSize(10).fontColor(INK.PLACEHOLDER)
        }.alignItems(HorizontalAlign.Start)
        Blank().layoutWeight(1)
        Text('与其他生肖配对').fontSize(9).fontColor(INK.SECONDARY)
      }.width('100%')

      Column({ space: 6 }) {
        ForEach(this.pairs, (pair: ZodiacPairEntry, idx: number) => {
          Row({ space: 10 }) {
            Row({ space: 4 }) {
              Text(ZODIAC_EMOJI[this.selectedIdx]).fontSize(16)
              Text('×').fontSize(10).fontColor(INK.PLACEHOLDER)
              Text(ZODIAC_EMOJI[EARTHLY_BRANCHES.indexOf(pair.branch2)]).fontSize(16)
            }.width(60)

            Column({ space: 2 }) {
              Row({ space: 6 }) {
                Text(pair.relation.label).fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.relColor(pair.relation))
                Text(pair.branch1 + pair.branch2).fontSize(9).fontColor(INK.PLACEHOLDER)
                Blank().layoutWeight(1)
                Text(pair.relation.score + '分').fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor(this.relColor(pair.relation))
              }.width('100%')
              Text(pair.relation.description).fontSize(9).fontColor(INK.BODY).lineHeight(14)
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          }
          .width('100%').padding(10)
          .backgroundColor(this.relBg(pair.relation))
          .border({ width: 1, color: INK.HAIRLINE }).borderRadius(8)
        }, (pair: ZodiacPairEntry) => pair.branch2)
      }.width('100%')
    }
    .width('100%').padding(20)
    .backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
    .shadow({ radius: 10, color: COLORS.INK_BLACK + '14', offsetY: 4 })
  }
}
