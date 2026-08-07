import { COLORS, INK, OP, applyTheme } from '../common/constants'
import {
  AIConfig, AI_PROVIDERS, DEFAULT_AI_CONFIG, AIProvider, ProviderInfo, saveDarkMode,
  loadLateZiHuanRi, saveLateZiHuanRi
} from '../services/aiService'
import { exportReadingsToClipboard } from '../services/exportService'

@CustomDialog
export struct AISettingsModal {
  controller: CustomDialogController
  @StorageLink('uiDark') isDark: boolean = false
  @State localConfig: AIConfig = DEFAULT_AI_CONFIG
  @State lateZiHuanRi: boolean = false
  onSave?: (config: AIConfig) => void

  async aboutToAppear() {
    this.lateZiHuanRi = await loadLateZiHuanRi()
  }

  async exportRecords(): Promise<void> {
    try {
      await exportReadingsToClipboard()
      this.getUIContext().getPromptAction().showToast({ message: '记录已导出到剪贴板' })
    } catch (e) {
      this.getUIContext().getPromptAction().showToast({ message: '导出失败' })
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Column({ space: 4 }) {
          Text('AI服务配置 (AI Settings)')
            .fontSize(14).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
          Text('连接大模型，解锁深度命理解析').fontSize(9).fontColor(INK.PLACEHOLDER)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        Text('✕').fontSize(18).fontColor(INK.SECONDARY)
          .onClick(() => { this.controller.close() })
      }
      .width('100%').padding({ left: 20, right: 20, top: 20, bottom: 16 })
      .border({ width: { bottom: 1 }, color: INK.HAIRLINE })

      // Body
      Scroll() {
        Column({ space: 20 }) {
          // Provider selection
          Column({ space: 8 }) {
            Text('模型服务商 (Provider)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            Grid() {
              ForEach(AI_PROVIDERS, (p: ProviderInfo) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Text(p.label.split(' ')[0]).fontSize(11).fontWeight(FontWeight.Bold)
                      .fontColor(this.localConfig.provider === p.id ? COLORS.WHITE : COLORS.INK_BLACK)
                    Text(p.id).fontSize(8).opacity(0.6)
                      .fontColor(this.localConfig.provider === p.id ? COLORS.WHITE : INK.PLACEHOLDER)
                  }
                  .width('100%').padding(10)
                  .border({ width: 1, color: INK.FAINT })
                  .borderRadius(10)
                  .backgroundColor(this.localConfig.provider === p.id ? COLORS.INK_BLACK : COLORS.WHITE)
                  .onClick(() => {
                    this.localConfig.provider = p.id as AIProvider
                    this.localConfig.model = p.defaultModel
                    this.localConfig.baseUrl = p.baseUrl
                  })
                }
              }, (p: ProviderInfo) => p.id)
            }
            .columnsTemplate('1fr 1fr 1fr').rowsTemplate('1fr 1fr').width('100%')
          }

          // API Key
          Column({ space: 4 }) {
            Text('API 密钥 (API Key)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            TextInput({ placeholder: '输入您的 API Key...', text: this.localConfig.apiKey })
              .onChange((v: string) => { this.localConfig.apiKey = v })
              .type(InputType.Password).fontSize(11).padding(10)
              .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.FAINT }).borderRadius(10)
            Text('密钥仅保存在本地设备，不会上传至任何服务器。')
              .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
          }

          // Model Name
          Column({ space: 4 }) {
            Text('模型名称 (Model Name)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            TextInput({ placeholder: '例如: gpt-4o, deepseek-chat...', text: this.localConfig.model })
              .onChange((v: string) => { this.localConfig.model = v })
              .fontSize(11).padding(10)
              .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.FAINT }).borderRadius(10)
          }

          // Base URL (custom provider only)
          if (this.localConfig.provider === 'custom') {
            Column({ space: 4 }) {
              Text('接口地址 (Base URL)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
              TextInput({ placeholder: 'https://api.your-provider.com/v1', text: this.localConfig.baseUrl || '' })
                .onChange((v: string) => { this.localConfig.baseUrl = v })
                .fontSize(11).padding(10)
                .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.FAINT }).borderRadius(10)
            }
          }

          // Appearance
          Column({ space: 8 }) {
            Text('外观 (Appearance)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            Row({ space: 12 }) {
              Text('深色模式').fontSize(11).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold).layoutWeight(1)
              Text(this.isDark ? '开启' : '关闭').fontSize(9).fontColor(INK.PLACEHOLDER)
              Toggle({ type: ToggleType.Switch, isOn: this.isDark })
                .selectedColor(COLORS.IMPERIAL_RED)
                .onChange((v: boolean) => {
                  this.isDark = v
                  AppStorage.setOrCreate('uiDark', v)
                  applyTheme(v)
                  saveDarkMode(v)
                })
            }
            .width('100%').padding(10)
            .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE }).borderRadius(10)
          }

          // 命理偏好
          Column({ space: 8 }) {
            Text('命理偏好 (Preferences)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('晚子时换日').fontSize(11).fontColor(COLORS.INK_BLACK).fontWeight(FontWeight.Bold)
                Text('23:00–24:00 出生按次日日柱排（子初换日派）').fontSize(8).fontColor(INK.PLACEHOLDER)
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.lateZiHuanRi })
                .selectedColor(COLORS.IMPERIAL_RED)
                .onChange((v: boolean) => {
                  this.lateZiHuanRi = v
                  saveLateZiHuanRi(v)
                })
            }
            .width('100%').padding(10)
            .backgroundColor(INK.BG_FAINT).border({ width: 1, color: INK.HAIRLINE }).borderRadius(10)
          }

          // Data management
          Column({ space: 8 }) {
            Text('数据管理 (Data)').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            Row({ space: 12 }) {
              Button('导出我的记录').fontSize(11).fontWeight(FontWeight.Bold)
                .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).layoutWeight(1)
                .padding({ top: 10, bottom: 10 }).borderRadius(10)
                .onClick(() => { this.exportRecords() })
            }
            .width('100%')
            Text('八字与卦象记录以 JSON 备份到剪贴板，可粘贴保存。')
              .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic)
          }

          // Privacy note
          Column({ space: 4 }) {
            Text('隐私与免责').fontSize(10).fontColor(INK.LABEL).fontWeight(FontWeight.Bold)
            Text('排盘数据仅在您主动发起 AI 解析时发送至所选服务商；所有命理内容仅供文化娱乐参考，不构成医疗、投资、法律或任何决策依据。')
              .fontSize(8).fontColor(INK.PLACEHOLDER).lineHeight(14)
          }
        }
        .width('100%').padding(20)
      }
      .layoutWeight(1)

      // Footer
      Row({ space: 12 }) {
        Button('取消').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(INK.LABEL).backgroundColor(INK.BG_FAINT).layoutWeight(1)
          .padding({ top: 12, bottom: 12 }).borderRadius(12)
          .onClick(() => { this.controller.close() })
        Button('保存配置').fontSize(11).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.INK_BLACK).layoutWeight(1)
          .padding({ top: 12, bottom: 12 }).borderRadius(12)
          .onClick(() => {
            if (this.onSave) { this.onSave(this.localConfig) }
            this.controller.close()
          })
      }
      .width('100%').padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .border({ width: { top: 1 }, color: INK.HAIRLINE })
      .backgroundColor(INK.BG_FAINT)
    }
    .width('90%')
    .backgroundColor(COLORS.WHITE)
    .border({ width: 1, color: INK.FAINT })
    .borderRadius(20)
    .shadow({ radius: 24, color: COLORS.INK_BLACK + OP.MEDIUM })
  }
}
