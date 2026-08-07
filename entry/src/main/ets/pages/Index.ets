import { COLORS, INK, RED, OP, applyTheme, isDarkMode } from '../common/constants'
import { BaziSection } from '../components/BaziSection'
import { IChingSection } from '../components/IChingSection'
import { CosmologySection } from '../components/CosmologySection'
import { AlmanacSection } from '../components/AlmanacSection'
import { SolarTermSection } from '../components/SolarTermSection'
import { ZodiacSection } from '../components/ZodiacSection'
import { ZodiacCompatSection } from '../components/ZodiacCompatSection'
import { HourLuckSection } from '../components/HourLuckSection'
import { HehunSection } from '../components/HehunSection'
import { MoreSection } from '../components/MoreSection'
import { PrivacySection } from '../components/PrivacySection'
import { AISettingsModal } from '../components/AISettingsModal'
import {
  AIConfig, DEFAULT_AI_CONFIG, loadAIConfig, saveAIConfig, loadDarkMode, saveDarkMode
} from '../services/aiService'
import { getTodayInfo, TodayInfo } from '../model/lunar-service'

@Entry
@Component
struct Index {
  @StorageLink('uiDark') isDark: boolean = false
  @State activeTab: string = 'bazi'
  @State aiConfig: AIConfig = DEFAULT_AI_CONFIG
  @State today: TodayInfo | null = null
  private settingsDialogController: CustomDialogController | null = null

  async aboutToAppear() {
    const dark = await loadDarkMode()
    AppStorage.setOrCreate('uiDark', dark)
    applyTheme(dark)
    this.today = getTodayInfo()

    this.settingsDialogController = new CustomDialogController({
      builder: AISettingsModal({
        controller: this.settingsDialogController!,
        onSave: (config: AIConfig) => {
          this.aiConfig = config
          saveAIConfig(config).catch(() => {
            this.getUIContext().getPromptAction().showToast({ message: '配置保存失败' })
          })
        }
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center,
      customStyle: true
    })
    this.aiConfig = await loadAIConfig()
  }

  toggleTheme(): void {
    this.isDark = !this.isDark
    applyTheme(this.isDark)
    saveDarkMode(this.isDark)
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 0 }) {
          this.HeaderSection()
          this.TodayCard()
          this.TabNavigation()
          if (this.activeTab === 'bazi') {
            BaziSection({ aiConfig: this.aiConfig }).padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'iching') {
            IChingSection({ aiConfig: this.aiConfig }).padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'almanac') {
            AlmanacSection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'hourluck') {
            HourLuckSection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'hehun') {
            HehunSection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'privacy') {
            PrivacySection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'more') {
            MoreSection({ onSelect: (id: string) => { this.activeTab = id } }).padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'solar') {
            SolarTermSection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'zodiac') {
            ZodiacSection().padding({ left: 24, right: 24, bottom: 24 })
          } else if (this.activeTab === 'compat') {
            ZodiacCompatSection().padding({ left: 24, right: 24, bottom: 24 })
          } else {
            CosmologySection().padding({ left: 24, right: 24, bottom: 24 })
          }
          this.FooterSection()
        }
        .width('100%').height('100%')
      }
      .width('100%').height('100%').scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)

      // Settings + theme toggle buttons
      Row({ space: 8 }) {
        Button(this.isDark ? '☀' : '☾').fontSize(16).fontColor(INK.SECONDARY)
          .backgroundColor(COLORS.WHITE + 'E6')
          .border({ width: 1, color: INK.FAINT }).borderRadius(24)
          .width(44).height(44)
          .shadow({ radius: 8, color: COLORS.INK_BLACK + OP.LIGHT })
          .onClick(() => { this.toggleTheme() })
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
    .width('100%').height('100%')
    .linearGradient({ angle: 165, colors: [[COLORS.PAPER, 0.0], [COLORS.ACTIVE_CARD_BG, 1.0]] })
  }

  @Builder BackgroundDecorations() {
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

      // Brush accents
      Text('乾').fontSize(160).fontColor(COLORS.INK_BLACK).opacity(0.03)
        .position({ x: '10%', y: '10%' }).hitTestBehavior(HitTestMode.None)
      Text('坤').fontSize(160).fontColor(COLORS.IMPERIAL_RED).opacity(0.03)
        .position({ x: '60%', y: '60%' }).hitTestBehavior(HitTestMode.None)

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
      Row({ space: 14 }) {
        Stack() {
          Circle({ width: 62, height: 62 }).fill(COLORS.WHITE + OP.MEDIUM)
            .stroke(RED.BORDER).strokeWidth(1)
          Text('☯').fontSize(34).fontColor(COLORS.IMPERIAL_RED)
        }
        Column({ space: 6 }) {
          Text('天道玄机').fontSize(38).fontColor(COLORS.INK_BLACK)
            .fontWeight(FontWeight.Bold).lineHeight(44)
          Row({ space: 12 }) {
            Text('梅香透骨').fontSize(11).fontColor(COLORS.IMPERIAL_RED)
              .fontWeight(FontWeight.Bold).opacity(0.75)
            Divider().vertical(true).width(1).height(10).color(RED.BORDER)
            Text('格物致知').fontSize(11).fontColor(COLORS.IMPERIAL_RED)
              .fontWeight(FontWeight.Bold).opacity(0.75)
          }
        }.alignItems(HorizontalAlign.Start)
        Blank().layoutWeight(1)
        Column({ space: 4 }) {
          Text(this.today ? '岁次 ' + this.today.yearStemBranch + '年' : '')
            .fontSize(13).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
          Text(this.today ? this.today.lunarText : '')
            .fontSize(9).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold).opacity(0.6)
        }.alignItems(HorizontalAlign.End)
      }.width('100%')
    }
    .width('100%').padding({ left: 24, right: 24, top: 56, bottom: 20 })
  }

  @Builder TodayCard() {
    if (this.today) {
      Row({ space: 16 }) {
        Column({ space: 6 }) {
          Text('今日 · ' + this.today.dateText).fontSize(11).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
          Text('农历' + this.today.lunarText + ' · ' + this.today.solarTerm + '后')
            .fontSize(10).fontColor(INK.BODY)
          Row({ space: 10 }) {
            Text('干支日 ' + this.today.dayStemBranch)
              .fontSize(11).fontColor(COLORS.IMPERIAL_RED).fontWeight(FontWeight.Bold)
            Text(this.today.zodiac + '年').fontSize(9).fontColor(INK.PLACEHOLDER)
          }
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Divider().vertical(true).height(44).color(RED.BORDER).opacity(0.5)
        Column({ space: 2 }) {
          Text(this.today.hexSymbol).fontSize(38).fontColor(COLORS.IMPERIAL_RED)
          Text('今日卦 · ' + this.today.hexName)
            .fontSize(10).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
        }.alignItems(HorizontalAlign.Center)
      }
      .width('100%').padding(16)
      .backgroundColor(COLORS.WHITE + 'B3').border({ width: 1, color: RED.BORDER })
      .borderRadius(16)
      .shadow({ radius: 12, color: COLORS.INK_BLACK + '10', offsetY: 3 })
      .margin({ left: 24, right: 24, bottom: 20 })
    }
  }

  @Builder TabNavigation() {
    Scroll() {
      Row({ space: 6 }) {
        this.TabButton('bazi', '生辰八字')
        this.TabButton('iching', '周易起卦')
        this.TabButton('almanac', '黄历')
        this.TabButton('hourluck', '吉时')
        this.TabButton('more', '更多')
      }
    }
    .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring)
    .width('100%').padding({ left: 24, right: 24, bottom: 24 })
  }

  @Builder TabButton(tab: string, label: string) {
    Button(label).fontSize(13).fontWeight(FontWeight.Bold)
      .fontColor(this.isTabActive(tab) ? COLORS.WHITE : INK.SECONDARY)
      .backgroundColor(this.isTabActive(tab) ? COLORS.INK_BLACK : COLORS.WHITE + '80')
      .padding({ left: 16, right: 16, top: 11, bottom: 11 })
      .borderRadius(14)
      .animation({ duration: 200, curve: Curve.EaseOut })
      .onClick(() => { this.activeTab = tab })
  }

  isTabActive(tab: string): boolean {
    if (tab === 'more') {
      return this.isHiddenTab(this.activeTab)
    }
    return this.activeTab === tab
  }

  isHiddenTab(tab: string): boolean {
    return tab === 'solar' || tab === 'zodiac' || tab === 'compat' ||
      tab === 'cosmos' || tab === 'hehun' || tab === 'privacy' || tab === 'more'
  }

  @Builder FooterSection() {
    Column({ space: 14 }) {
      Divider().color(INK.BORDER)
      Row({ space: 16 }) {
        Text('梅花易数 MEIHUA').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Text('·').fontSize(8).fontColor(INK.PLACEHOLDER)
        Text('河图洛书 COSMOLOGY').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
        Text('·').fontSize(8).fontColor(INK.PLACEHOLDER)
        Text('纳甲排盘 NAJIA').fontSize(8).fontColor(INK.BODY).fontWeight(FontWeight.Bold)
      }.justifyContent(FlexAlign.Center)
      Text('© ' + (this.today ? this.today.dateText.split('年')[0] : '2026') +
        ' · 天道玄机 · 顺天应人 · HEAVENLY DECRYPT')
        .fontSize(8).fontColor(INK.SECONDARY).fontWeight(FontWeight.Bold)
      Text('内容仅供文化娱乐参考，不构成任何决策依据。')
        .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
    }
    .width('100%').padding({ left: 24, right: 24, top: 24, bottom: 32 })
    .alignItems(HorizontalAlign.Center)
  }
}
