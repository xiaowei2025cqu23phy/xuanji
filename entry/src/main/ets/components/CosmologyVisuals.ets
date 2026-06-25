import { COLORS, INK, RED, OP } from '../common/constants'

// ---- HeTu (河图) - River Diagram ----
@Component
export struct HeTu {
  build() {
    Stack() {
      Text('河图').fontSize(80).fontColor(COLORS.INK_BLACK).opacity(0.05)
        .position({ x: '50%', y: '50%' }).translate({ x: '-50%', y: '-50%' })

      Grid() {
        GridItem() { this.HeTuPair(2, 7) }.rowStart(0).rowEnd(0).columnStart(2).columnEnd(2)
        GridItem() { this.HeTuPair(3, 8) }.rowStart(2).rowEnd(2).columnStart(0).columnEnd(0)
        GridItem() { this.HeTuPair(5, 10) }.rowStart(2).rowEnd(2).columnStart(2).columnEnd(2)
        GridItem() { this.HeTuPair(4, 9) }.rowStart(2).rowEnd(2).columnStart(4).columnEnd(4)
        GridItem() { this.HeTuPair(1, 6) }.rowStart(4).rowEnd(4).columnStart(2).columnEnd(2)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr').rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('100%').height('100%')
    }
    .width('100%').aspectRatio(1).constraintSize({ maxWidth: 300 })
    .backgroundColor(COLORS.WHITE + OP.LOW).borderRadius('50%')
    .border({ width: 1, color: INK.FAINT }).padding(16)
  }

  @Builder HeTuPair(n: number, total: number) {
    Column({ space: 2 }) {
      Row({ space: 2 }) {
        ForEach(Array.from({ length: n }), (_: Object, idx: number) => {
          Circle({ width: 8, height: 8 }).fill(COLORS.WHITE).stroke(COLORS.INK_BLACK).strokeWidth(1)
        }, (idx: number) => idx.toString())
      }.justifyContent(FlexAlign.Center)
      Row({ space: 2 }) {
        ForEach(Array.from({ length: total - n }), (_: Object, idx: number) => {
          Circle({ width: 8, height: 8 }).fill(COLORS.INK_BLACK)
        }, (idx: number) => idx.toString())
      }.justifyContent(FlexAlign.Center)
    }.justifyContent(FlexAlign.Center)
  }
}

// ---- LuoShu (洛书) - Magic Square ----
@Component
export struct LuoShu {
  private numbers: number[][] = [[4, 9, 2], [3, 5, 7], [8, 1, 6]]

  build() {
    Stack() {
      Text('洛书').fontSize(80).fontColor(COLORS.INK_BLACK).opacity(0.05)
        .position({ x: '50%', y: '50%' }).translate({ x: '-50%', y: '-50%' })

      Grid() {
        ForEach(this.numbers.flat(), (n: number, idx: number) => {
          GridItem() {
            Stack() {
              Row() {
                Text(n.toString()).fontSize(32).fontColor(COLORS.INK_BLACK).opacity(0.8)
              }.width('100%').height('100%').justifyContent(FlexAlign.Center)

              Row().width('100%').height('100%')
                .backgroundColor(n % 2 === 0 ? COLORS.IMPERIAL_RED : COLORS.AMBER_GOLD).opacity(0.03)
            }.border({ width: 1, color: INK.FAINT })
          }
        }, (n: number, idx: number) => idx.toString())
      }
      .columnsTemplate('1fr 1fr 1fr').rowsTemplate('1fr 1fr 1fr')
      .width('100%').height('100%')
    }
    .width('100%').aspectRatio(1).constraintSize({ maxWidth: 300 })
    .backgroundColor(COLORS.WHITE + OP.LOW).border({ width: 1, color: INK.FAINT }).padding(16)
  }
}

// ---- Bagua Circle (八卦图) ----
interface TrigramDetail {
  name: string; nature: string; element: string; symbol: string
  family: string; bodyPart: string; hint: string; prePos: string; postPos: string
}

function buildTrigramDetails(): Map<string, TrigramDetail> {
  const m = new Map<string, TrigramDetail>()
  m.set('乾', { name: '乾 (Qián)', nature: '天', element: '金', symbol: '刚健不息，权威统领', family: '父', bodyPart: '首', hint: '官鬼/妻财之源', prePos: '正南', postPos: '西北' })
  m.set('兑', { name: '兑 (Duì)', nature: '泽', element: '金', symbol: '喜悦滋润, 欢欣交流', family: '少女', bodyPart: '口', hint: '主交际与财源', prePos: '东南', postPos: '正西' })
  m.set('离', { name: '离 (Lí)', nature: '火', element: '火', symbol: '光明灿烂，附丽而生', family: '中女', bodyPart: '目', hint: '主明志与文书', prePos: '正东', postPos: '正南' })
  m.set('震', { name: '震 (Zhèn)', nature: '雷', element: '木', symbol: '奋发震动，生机勃发', family: '长男', bodyPart: '足', hint: '主执行与变动', prePos: '东北', postPos: '正东' })
  m.set('巽', { name: '巽 (Xùn)', nature: '风', element: '木', symbol: '柔顺渗透，无孔不入', family: '长女', bodyPart: '股', hint: '主柔和与财商', prePos: '西南', postPos: '东南' })
  m.set('坎', { name: '坎 (Kǎn)', nature: '水', element: '水', symbol: '艰难深邃，处险而不动', family: '中男', bodyPart: '耳', hint: '主智慧与困难', prePos: '正西', postPos: '正北' })
  m.set('艮', { name: '艮 (Gèn)', nature: '山', element: '土', symbol: '沉稳止息，厚重如山', family: '少男', bodyPart: '手', hint: '主守成与节点', prePos: '西北', postPos: '东北' })
  m.set('坤', { name: '坤 (Kūn)', nature: '地', element: '土', symbol: '厚德载物，包容万象', family: '母', bodyPart: '腹', hint: '主孕育与基础', prePos: '正北', postPos: '西南' })
  return m
}

@Component
export struct BaguaCircle {
  @State currentMode: string = 'pre'
  @State selectedTrigram: string = ''

  private trigramsPre: string[] = ['乾', '巽', '坎', '艮', '坤', '震', '离', '兑']
  private trigramsPost: string[] = ['离', '坤', '兑', '乾', '坎', '艮', '震', '巽']
  private trigramDetails: Map<string, TrigramDetail> = buildTrigramDetails()

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Button('先天八卦').fontSize(10).fontWeight(FontWeight.Bold)
          .backgroundColor(this.currentMode === 'pre' ? COLORS.IMPERIAL_RED : INK.HAIRLINE)
          .fontColor(this.currentMode === 'pre' ? COLORS.WHITE : COLORS.INK_BLACK)
          .onClick(() => { this.currentMode = 'pre'; this.selectedTrigram = '' })
        Button('后天八卦').fontSize(10).fontWeight(FontWeight.Bold)
          .backgroundColor(this.currentMode === 'post' ? COLORS.IMPERIAL_RED : INK.HAIRLINE)
          .fontColor(this.currentMode === 'post' ? COLORS.WHITE : COLORS.INK_BLACK)
          .onClick(() => { this.currentMode = 'post'; this.selectedTrigram = '' })
      }.justifyContent(FlexAlign.Center)

      Stack() {
        Circle({ width: '100%', height: '100%' }).fill(null)
          .stroke(COLORS.INK_BLACK + OP.X_FAINT).strokeWidth(1)
          .rotate({ angle: 0 }).animation({ duration: 240000, curve: Curve.Linear, iterations: -1 })
        Circle({ width: '85%', height: '85%' }).fill(null)
          .stroke(INK.FAINT).strokeWidth(1)
          .rotate({ angle: 0 }).animation({ duration: 120000, curve: Curve.Linear, iterations: -1 })

        Circle({ width: 64, height: 64 }).fill(COLORS.WHITE + OP.MEDIUM).stroke(RED.BORDER).strokeWidth(1)
        Text('太极').fontSize(20).fontColor(COLORS.INK_BLACK)

        ForEach(this.currentMode === 'pre' ? this.trigramsPre : this.trigramsPost,
          (trigram: string, idx: number) => { this.BaguaTrigramItem(trigram, idx) },
          (trigram: string) => trigram)
      }
      .width('100%').aspectRatio(1).constraintSize({ maxWidth: 320 }).alignContent(Alignment.Center)

      if (this.selectedTrigram) {
        this.TrigramDetailPanel(this.selectedTrigram)
      } else {
        Column({ space: 8 }) {
          Text('点击卦象图标，开启易理秘境').fontSize(10).fontColor(INK.PLACEHOLDER)
        }
        .width('100%').height(80).justifyContent(FlexAlign.Center)
        .border({ width: 1, color: INK.FAINT, style: BorderStyle.Dashed })
      }
    }
    .width('100%').padding(16)
  }

  @Builder BaguaTrigramItem(trigram: string, idx: number) {
    Column({ space: 4 }) {
      Text(trigram).fontSize(22)
        .fontColor(this.selectedTrigram === trigram ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)
      Divider().width(this.selectedTrigram === trigram ? 24 : 16).height(2)
        .color(this.selectedTrigram === trigram ? COLORS.IMPERIAL_RED : INK.PLACEHOLDER)
    }
    .position(this.getBaguaPosition(idx))
    .onClick(() => { this.selectedTrigram = this.selectedTrigram === trigram ? '' : trigram })
  }

  getBaguaPosition(idx: number): Position {
    const angle = idx * 45 - 90
    const radius = 90
    const x = Math.cos(angle * Math.PI / 180) * radius
    const y = Math.sin(angle * Math.PI / 180) * radius
    const center = 144
    return { x: center + x - 20, y: center + y - 20 }
  }

  @Builder TrigramDetailPanel(trigram: string) {
    Column() {
      Row({ space: 12 }) {
        Circle({ width: 40, height: 40 }).fill(RED.BG_FAINT).stroke(COLORS.IMPERIAL_RED)
        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(this.trigramDetails.get(trigram)?.name ?? '')
              .fontSize(14).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            Text((this.trigramDetails.get(trigram)?.element ?? '') + ' (' + (this.trigramDetails.get(trigram)?.nature ?? '') + ')')
              .fontSize(10).fontColor(INK.LABEL)
              .backgroundColor(INK.BG_LIGHT).padding({ left: 8, right: 8, top: 2, bottom: 2 }).borderRadius(8)
          }
          Text(this.trigramDetails.get(trigram)?.symbol ?? '').fontSize(11).fontColor(INK.BODY)
        }
      }.width('100%').alignItems(VerticalAlign.Top)

      Grid() {
        GridItem() {
          Column({ space: 2 }) {
            Text('家族 / 身体').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text((this.trigramDetails.get(trigram)?.family ?? '') + ' (' + (this.trigramDetails.get(trigram)?.bodyPart ?? '') + ')')
              .fontSize(10).fontColor(INK.BODY)
          }
        }
        GridItem() {
          Column({ space: 2 }) {
            Text('先天 / 后天位').fontSize(8).fontColor(INK.PLACEHOLDER)
            Text((this.trigramDetails.get(trigram)?.prePos ?? '') + ' / ' + (this.trigramDetails.get(trigram)?.postPos ?? ''))
              .fontSize(10).fontColor(INK.BODY)
          }
        }
      }
      .columnsTemplate('1fr 1fr').rowsTemplate('1fr').width('100%')

      Text(this.trigramDetails.get(trigram)?.hint ?? '')
        .fontSize(10).fontColor(RED.LABEL).fontStyle(FontStyle.Italic).margin({ top: 8 })
        .padding({ left: 8, top: 4, bottom: 4 })
        .border({ width: { left: 2 }, color: RED.BORDER })
        .backgroundColor(INK.BG_FAINT)
    }
    .width('100%').padding(16)
    .backgroundColor(COLORS.WHITE + OP.MEDIUM).border({ width: 1, color: INK.HAIRLINE })
  }
}
