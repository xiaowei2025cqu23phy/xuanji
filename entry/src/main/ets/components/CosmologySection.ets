import { COLORS, INK, RED } from '../common/constants'
import { HeTu, LuoShu, BaguaCircle } from './CosmologyVisuals'

@Component
export struct CosmologySection {
  @StorageLink('uiDark') isDark: boolean = false

  build() {
    Column({ space: 24 }) {
      this.IntroHeader()
      this.HeTuCard()
      this.LuoShuCard()
      this.BaguaCard()
      Text('河图洛书为中华易学之根，八卦为万物类象之纲。观象玩辞，明理致用。')
        .fontSize(10).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).textAlign(TextAlign.Center)
        .width('100%').padding({ left: 24, right: 24 })
    }.width('100%').backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }

  @Builder IntroHeader() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Circle({ width: 8, height: 8 }).fill(COLORS.IMPERIAL_RED)
        Text('易理图鉴').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('COSMOLOGY').fontSize(9).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }
      Text('河图洛书 · 先天后天八卦 · 万物类象')
        .fontSize(10).fontColor(INK.SECONDARY)
    }.width('100%').alignItems(HorizontalAlign.Start)
  }

  @Builder HeTuCard() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('河图').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('天一生水 · 五行生成').fontSize(9).fontColor(COLORS.AMBER_GOLD).fontWeight(FontWeight.Bold)
      }.width('100%')
      Text('一六共宗居北，二七同道居南，三八为朋居东，四九为友居西，五十同途居中。河图乃五行生成之数，天一生水、地二生火、天三生木、地四生金、天五生土。')
        .fontSize(10).fontColor(INK.BODY).lineHeight(17)
      HeTu()
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder LuoShuCard() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('洛书').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('戴九履一 · 纵横皆十五').fontSize(9).fontColor(COLORS.AMBER_GOLD).fontWeight(FontWeight.Bold)
      }.width('100%')
      Text('戴九履一，左三右七，二四为肩，六八为足，五居中央。纵横斜三数之和皆为十五，为后天八卦之数理根源，亦为奇门遁甲九宫之基。')
        .fontSize(10).fontColor(INK.BODY).lineHeight(17)
      LuoShu()
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }

  @Builder BaguaCard() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('八卦').fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('先天为体 · 后天为用').fontSize(9).fontColor(COLORS.AMBER_GOLD).fontWeight(FontWeight.Bold)
      }.width('100%')
      Text('先天八卦主对待之序（天地定位，山泽通气，雷风相薄，水火不相射）；后天八卦主流行之用（帝出乎震，齐乎巽，相见乎离，致役乎坤）。')
        .fontSize(10).fontColor(INK.BODY).lineHeight(17)
      BaguaCircle()
    }
    .width('100%').padding(16).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(16)
  }
}
