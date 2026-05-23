import { COLORS } from '../common/constants'

// HeTu (河图) - River Diagram
@Component
export struct HeTu {
  build() {
    Stack() {
      // Background watermark
      Text('河图')
        .fontSize(80)
        .fontColor(COLORS.INK_BLACK)
        .opacity(0.05)
        .position({ x: '50%', y: '50%' })
        .translate({ x: '-50%', y: '-50%' })

      Grid() {
        // Row 0: Top
        GridItem() {
          this.HeTuPair(2, 7)
        }.rowStart(0).rowEnd(0).columnStart(2).columnEnd(2)

        // Row 2: Left and Right
        GridItem() {
          this.HeTuPair(3, 8)
        }.rowStart(2).rowEnd(2).columnStart(0).columnEnd(0)

        GridItem() {
          this.HeTuPair(5, 10)
        }.rowStart(2).rowEnd(2).columnStart(2).columnEnd(2)

        GridItem() {
          this.HeTuPair(4, 9)
        }.rowStart(2).rowEnd(2).columnStart(4).columnEnd(4)

        // Row 4: Bottom
        GridItem() {
          this.HeTuPair(1, 6)
        }.rowStart(4).rowEnd(4).columnStart(2).columnEnd(2)
      }
      .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .aspectRatio(1)
    .maxWidth(300)
    .backgroundColor(COLORS.WHITE + '66')
    .borderRadius('50%')
    .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
    .padding(16)
  }

  @Builder
  HeTuPair(n: number, total: number) {
    Row({ space: 2 }) {
      ForEach(Array.from({ length: n }), (_: Object, idx: number) => {
        Circle({ width: 8, height: 8 })
          .fill(COLORS.INK_BLACK)
      }, (idx: number) => idx.toString())
    }
    .justifyContent(FlexAlign.Center)
  }
}

// LuoShu (洛书) - Magic Square
@Component
export struct LuoShu {
  build() {
    Stack() {
      Text('洛书')
        .fontSize(80)
        .fontColor(COLORS.INK_BLACK)
        .opacity(0.05)
        .position({ x: '50%', y: '50%' })
        .translate({ x: '-50%', y: '-50%' })

      Grid() {
        const numbers = [[4, 9, 2], [3, 5, 7], [8, 1, 6]]
        ForEach(numbers.flat(), (n: number, idx: number) => {
          GridItem() {
            Stack() {
              Row() {
                Text(n.toString())
                  .fontSize(32)
                  .fontColor(COLORS.INK_BLACK)
                  .opacity(0.8)
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)

              Row()
                .width('100%')
                .height('100%')
                .backgroundColor(n % 2 === 0 ? COLORS.IMPERIAL_RED : COLORS.AMBER_GOLD)
                .opacity(0.03)
            }
            .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
          }
        }, (n: number, idx: number) => idx.toString())
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .aspectRatio(1)
    .maxWidth(300)
    .backgroundColor(COLORS.WHITE + '66')
    .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
    .padding(16)
  }
}

// Bagua Circle (八卦图)
interface TrigramDetailItem {
  name: string
  nature: string
  element: string
  symbol: string
  family: string
  bodyPart: string
  hint: string
  prePos: string
  postPos: string
}
interface TrigramDetailMap {
  [key: string]: TrigramDetailItem
}

function makeTrigramDetail(name: string, nature: string, element: string, symbol: string, family: string, bodyPart: string, hint: string, prePos: string, postPos: string): TrigramDetailItem {
  let item: TrigramDetailItem = { name: name, nature: nature, element: element, symbol: symbol, family: family, bodyPart: bodyPart, hint: hint, prePos: prePos, postPos: postPos }
  return item
}

function buildTrigramDetails(): TrigramDetailMap {
  let m: TrigramDetailMap = {}
  m['乾'] = makeTrigramDetail('乾 (Qián)', '天', '金', '刚健不息，权威统领', '父', '首', '官鬼/妻财之源', '正南', '西北')
  m['兑'] = makeTrigramDetail('兑 (Duì)', '泽', '金', '喜悦滋润, 欢欣交流', '少女', '口', '主交际与财源', '东南', '正西')
  m['离'] = makeTrigramDetail('离 (Lí)', '火', '火', '光明灿烂，附丽而生', '中女', '目', '主明志与文书', '正东', '正南')
  m['震'] = makeTrigramDetail('震 (Zhèn)', '雷', '木', '奋发震动，生机勃发', '长男', '足', '主执行与变动', '东北', '正东')
  m['巽'] = makeTrigramDetail('巽 (Xùn)', '风', '木', '柔顺渗透，无孔不入', '长女', '股', '主柔和与财商', '西南', '东南')
  m['坎'] = makeTrigramDetail('坎 (Kǎn)', '水', '水', '艰难深邃，处险而不动', '中男', '耳', '主智慧与困难', '正西', '正北')
  m['艮'] = makeTrigramDetail('艮 (Gèn)', '山', '土', '沉稳止息，厚重如山', '少男', '手', '主守成与节点', '西北', '东北')
  m['坤'] = makeTrigramDetail('坤 (Kūn)', '地', '土', '厚德载物，包容万象', '母', '腹', '主孕育与基础', '正北', '西南')
  return m
}

export struct BaguaCircle {
  @State currentMode: string = 'pre'
  @State selectedTrigram: string = ''

  private trigramsPre: string[] = ['乾', '巽', '坎', '艮', '坤', '震', '离', '兑']
  private trigramsPost: string[] = ['离', '坤', '兑', '乾', '坎', '艮', '震', '巽']
  private trigramDetails: TrigramDetailMap = buildTrigramDetails()

  build() {
    Column({ space: 16 }) {
      // Mode selector
      Row({ space: 8 }) {
        Button('先天八卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.currentMode === 'pre' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '0D')
          .fontColor(this.currentMode === 'pre' ? COLORS.WHITE : COLORS.INK_BLACK)
          .onClick(() => {
            this.currentMode = 'pre'
            this.selectedTrigram = ''
          })

        Button('后天八卦')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(this.currentMode === 'post' ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '0D')
          .fontColor(this.currentMode === 'post' ? COLORS.WHITE : COLORS.INK_BLACK)
          .onClick(() => {
            this.currentMode = 'post'
            this.selectedTrigram = ''
          })
      }
      .justifyContent(FlexAlign.Center)

      // Bagua circle
      Stack() {
        // Animated rings
        Circle({ width: '100%', height: '100%' })
          .fill(null)
          .stroke(COLORS.INK_BLACK + '0D')
          .strokeWidth(1)
          .rotate({ angle: 0 })
          .animation({ duration: 240000, curve: Curve.Linear, iterations: -1 })

        Circle({ width: '85%', height: '85%' })
          .fill(null)
          .stroke(COLORS.INK_BLACK + '1A')
          .strokeWidth(1)
          .rotate({ angle: 0 })
          .animation({ duration: 120000, curve: Curve.Linear, iterations: -1 })

        // Taiji center
        Circle({ width: 64, height: 64 })
          .fill(COLORS.WHITE + '99')
          .stroke(COLORS.IMPERIAL_RED + '33')
          .strokeWidth(1)

        Text('太极')
          .fontSize(20)
          .fontColor(COLORS.INK_BLACK)

        // Trigrams around circle
        ForEach(this.currentMode === 'pre' ? this.trigramsPre : this.trigramsPost,
          (trigram: string, idx: number) => {
            this.BaguaTrigramItem(trigram, idx)
          }, (trigram: string) => trigram)
      }
      .width('100%')
      .aspectRatio(1)
      .maxWidth(320)
      .alignContent(Alignment.Center)
      .justifyContent(FlexAlign.Center)

      // Detail panel
      if (this.selectedTrigram) {
        this.TrigramDetailPanel(this.selectedTrigram)
      } else {
        Column({ space: 8 }) {
          Text('点击卦象图标，开启易理秘境')
            .fontSize(10)
            .fontColor(COLORS.INK_BLACK + '33')
        }
        .width('100%')
        .height(80)
        .justifyContent(FlexAlign.Center)
        .border({ width: 1, color: COLORS.INK_BLACK + '1A', style: BorderStyle.Dashed })
      }
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  BaguaTrigramItem(trigram: string, idx: number) {
    Column({ space: 4 }) {
      Text(trigram)
        .fontSize(22)
        .fontColor(this.selectedTrigram === trigram ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK)

      Divider()
        .width(this.selectedTrigram === trigram ? 24 : 16)
        .height(2)
        .color(this.selectedTrigram === trigram ? COLORS.IMPERIAL_RED : COLORS.INK_BLACK + '33')
    }
    .position(this.getBaguaPosition(idx))
    .onClick(() => {
      this.selectedTrigram = this.selectedTrigram === trigram ? '' : trigram
    })
  }

  getBaguaPosition(idx: number): Position {
    const angle = idx * 45 - 90
    const radius = 90
    const x = Math.cos(angle * Math.PI / 180) * radius
    const y = Math.sin(angle * Math.PI / 180) * radius
    return {
      x: `calc(50% + ${x}px)`,
      y: `calc(50% + ${y}px)`
    }
  }

  @Builder
  TrigramDetailPanel(trigram: string) {
    let details = this.trigramDetails.get(trigram)
    if (details !== undefined) {
    Column() {
      Row({ space: 12 }) {
        Circle({ width: 40, height: 40 })
          .fill(COLORS.IMPERIAL_RED + '0D')
          .stroke(COLORS.IMPERIAL_RED)

        Column({ space: 4 }) {
          Row({ space: 8 }) {
            Text(details.name)
              .fontSize(14)
              .fontColor(COLORS.IMPERIAL_RED)
              .fontWeight(FontWeight.Bold)

            Text(`${details.element} (${details.nature})`)
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '99')
              .backgroundColor(COLORS.INK_BLACK + '08')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(8)
          }

          Text(`${details.symbol}`)
            .fontSize(11)
            .fontColor(COLORS.INK_BLACK + '80')
        }
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Grid() {
        GridItem() {
          Column({ space: 2 }) {
            Text('家族 / 身体')
              .fontSize(8)
              .fontColor(COLORS.INK_BLACK + '4D')
            Text(`${details.family} (${details.bodyPart})`)
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '80')
          }
        }
        GridItem() {
          Column({ space: 2 }) {
            Text('先天 / 后天位')
              .fontSize(8)
              .fontColor(COLORS.INK_BLACK + '4D')
            Text(`${details.prePos} / ${details.postPos}`)
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '80')
          }
        }
      }
      .columnsTemplate('1fr 1fr')
      .rowsTemplate('1fr')
      .width('100%')

      Text(details.hint)
        .fontSize(10)
        .fontColor(COLORS.IMPERIAL_RED + '99')
        .fontStyle(FontStyle.Italic)
        .margin({ top: 8 })
        .padding({ left: 8, top: 4, bottom: 4 })
        .border({ width: { left: 2 }, color: COLORS.IMPERIAL_RED + '33' })
        .backgroundColor(COLORS.INK_BLACK + '03')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE + '99')
    .border({ width: 1, color: COLORS.INK_BLACK + '0D' })
    }
  }
}
