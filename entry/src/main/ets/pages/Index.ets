import { COLORS, INK, RED, OP } from '../common/constants'
import { BaziSection } from '../components/BaziSection'
import { IChingSection } from '../components/IChingSection'
import { AISettingsModal } from '../components/AISettingsModal'
import { AIConfig, DEFAULT_AI_CONFIG, loadAIConfig, saveAIConfig } from '../services/aiService'

@Entry
@Component
struct Index {
  @State activeTab: string = 'bazi'
  @State aiConfig: AIConfig = DEFAULT_AI_CONFIG
  @State showSettings: boolean = false
  private settingsDialogController: CustomDialogController | null = null

  async aboutToAppear() {
    this.settingsDialogController = new CustomDialogController({
      builder: AISettingsModal({
        controller: this.settingsDialogController!,
        onSave: (config: AIConfig) => {
          this.aiConfig = config
          saveAIConfig(config)
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    })
    this.aiConfig = await loadAIConfig()
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 0 }) {
          this.HeaderSection()
          this.TabNavigation()
          if (this.activeTab === 'bazi') {
            BaziSection({ aiConfig: this.aiConfig }).padding({ left: 24, right: 24, bottom: 24 })
          } else {
            IChingSection({ aiConfig: this.aiConfig }).padding({ left: 24, right: 24, bottom: 24 })
          }
          this.FooterSection()
        }
        .width('100%').height('100%')
      }
      .width('100%').height('100%').scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

      // Settings button
      Row() {
        Button('⚙').fontSize(18).fontColor(INK.SECONDARY)
          .backgroundColor(COLORS.WHITE + 'E6')
          .border({ width: 1, color: INK.FAINT }).borderRadius(24)
          .width(44).height(44)
          .shadow({ radius: 8, color: COLORS.INK_BLACK + OP.LIGHT })
          .onClick(() => {
            if (this.settingsDialogController) { this.settingsDialogController.open() }
          })
      }
      .width('100%').justifyContent(FlexAlign.End).padding({ right: 16, top: 16 })
      .position({ x: 0, y: 0 })

      this.BackgroundDecorations()
    }
    .width('100%').height('100%').backgroundColor(COLORS.PAPER)
  }

  @Builder
  BackgroundDecorations() {
    Stack() {
      // Four corner lattice decorations
      Row().width(16).height(16).border({ width: { left: 1, top: 1 }, color: COLORS.INK_BLACK + OP.LIGHT })
        .position({ x: 16, y: 16 }).hitTestBehavior(HitTestMode.None)
      Row().width(16).height(16).border({ width: { right: 1, top: 1 }, color: COLORS.INK_BLACK + OP.LIGHT })
        .position({ x: 'calc(100% - 16px)', y: 16 }).hitTestBehavior(HitTestMode.None)
      Row().width(16).height(16).border({ width: { left: 1, bottom: 1 }, color: COLORS.INK_BLACK + OP.LIGHT })
        .position({ x: 16, y: 'calc(100% - 16px)' }).hitTestBehavior(HitTestMode.None)
      Row().width(16).height(16).border({ width: { right: 1, bottom: 1 }, color: COLORS.INK_BLACK + OP.LIGHT })
        .position({ x: 'calc(100% - 16px)', y: 'calc(100% - 16px)' }).hitTestBehavior(HitTestMode.None)

      // Ink wash blobs
      Circle({ width: '40%', height: '40%' }).fill(COLORS.INK_BLACK).opacity(0.03)
        .blendMode(BlendMode.MULTIPLY).position({ x: '-10%', y: '-10%' }).hitTestBehavior(HitTestMode.None)
      Circle({ width: '50%', height: '50%' }).fill(COLORS.IMPERIAL_RED).opacity(0.03)
        .blendMode(BlendMode.MULTIPLY).position({ x: '60%', y: '60%' }).hitTestBehavior(HitTestMode.None)

      // Plum blossom poetry
      Text('墙角数枝梅\n凌寒独自开\n遥知不是雪\n为有暗香来')
        .fontSize(13).fontColor(COLORS.IMPERIAL_RED).opacity(0.15)
        .fontStyle(FontStyle.Italic).fontWeight(FontWeight.Bold)
        .position({ x: 'calc(100% - 48px)', y: '25%' }).hitTestBehavior(HitTestMode.None)

      // Brush accent
      Text('乾').fontSize(160).fontColor(COLORS.INK_BLACK).opacity(0.03)
        .position({ x: '10%', y: '10%' }).hitTestBehavior(HitTestMode.None)
      Text('坤').fontSize(160).fontColor(COLORS.IMPERIAL_RED).opacity(0.03)
        .position({ x: '60%', y: '60%' }).hitTestBehavior(HitTestMode.None)

      // Outer frame
      Row().width('calc(100% - 16px)').height('calc(100% - 16px)')
        .border({ width: 1, color: INK.HAIRLINE })
        .position({ x: 8, y: 8 }).hitTestBehavior(HitTestMode.None)

      // Bagua ring
      Circle({ width: 300, height: 300 }).fill(null).stroke(COLORS.INK_BLACK)
        .strokeWidth(1).strokeDashArray([4, 8]).opacity(0.04)
        .position({ x: 'calc(50% - 150px)', y: 'calc(50% - 150px)' })
        .hitTestBehavior(HitTestMode.None)
    }
    .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }

  @Builder HeaderSection() {
    Column({ space: 16 }) {
      Column({ space: 8 }) {
        Text('天道玄机').fontSize(48).fontColor(COLORS.INK_BLACK)
          .fontWeight(FontWeight.Bold).lineHeight(56)
        Row({ space: 16 }) {
          Text('梅香透骨').fontSize(12).fontColor(COLORS.IMPERIAL_RED)
            .fontWeight(FontWeight.Bold).opacity(0.6)
          Divider().vertical(true).width(1).height(12).color(RED.BORDER)
          Text('格物致知').fontSize(12).fontColor(COLORS.IMPERIAL_RED)
            .fontWeight(FontWeight.Bold).opacity(0.6)
        }
      }
      Column({ space: 4 }) {
        Text('岁次 丙午年').fontSize(16).fontColor(COLORS.INK_BLACK).opacity(0.9)
        Text('甲辰冬月 · 梅月').fontSize(10).fontColor(COLORS.IMPERIAL_RED)
          .fontWeight(FontWeight.Bold).opacity(0.5)
      }.alignItems(HorizontalAlign.End)
    }
    .width('100%').padding({ left: 24, right: 24, top: 60, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder TabNavigation() {
    Row() {
      Row() {
        Button('生辰八字').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.activeTab === 'bazi' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.activeTab === 'bazi' ? COLORS.INK_BLACK : 'transparent')
          .border({ width: 1, color: INK.FAINT }).padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.activeTab = 'bazi' }).layoutWeight(1)
        Button('周易起卦').fontSize(14).fontWeight(FontWeight.Bold)
          .fontColor(this.activeTab === 'iching' ? COLORS.WHITE : INK.SECONDARY)
          .backgroundColor(this.activeTab === 'iching' ? COLORS.INK_BLACK : 'transparent')
          .border({ width: 1, color: INK.FAINT }).padding({ left: 24, right: 24, top: 12, bottom: 12 })
          .onClick(() => { this.activeTab = 'iching' }).layoutWeight(1)
      }
      .backgroundColor(COLORS.WHITE + '80').border({ width: 1, color: INK.HAIRLINE })
    }
    .width('100%').justifyContent(FlexAlign.Center).padding({ left: 24, right: 24, bottom: 24 })
  }

  @Builder FooterSection() {
    Column({ space: 16 }) {
      Divider().color(COLORS.DARK_GOLD + '1A')
      Row({ space: 16 }) {
        Text('梅花易数 MEIHUA').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Text('·').fontSize(8).fontColor(INK.PLACEHOLDER)
        Text('河图洛书 COSMOLOGY').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Text('·').fontSize(8).fontColor(INK.PLACEHOLDER)
        Text('纳甲排盘 NAJIA').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
      }.justifyContent(FlexAlign.Center)
      Text('© 2026 · 天道玄机 · 顺天应人 · HEAVENLY DECRYPT')
        .fontSize(8).fontColor(INK.SECONDARY).fontWeight(FontWeight.Bold)
    }
    .width('100%').padding({ left: 24, right: 24, top: 24, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }
}
