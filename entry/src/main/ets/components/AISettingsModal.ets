import { COLORS } from '../common/constants'
import { AIConfig, AI_PROVIDERS, DEFAULT_AI_CONFIG, AIProvider, ProviderInfo } from '../services/aiService'

@CustomDialog
export struct AISettingsModal {
  controller: CustomDialogController
  @State localConfig: AIConfig = DEFAULT_AI_CONFIG
  onSave?: (config: AIConfig) => void

  aboutToAppear() {
    // Config is passed via controller options
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('AI服务配置 (AI Settings)')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.INK_BLACK)
          .layoutWeight(1)

        Text('✕')
          .fontSize(18)
          .fontColor(COLORS.INK_BLACK + '66')
          .onClick(() => { this.controller.close() })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 16 })
      .border({ width: { bottom: 1 }, color: COLORS.INK_BLACK + '0D' })

      // Body
      Scroll() {
        Column({ space: 20 }) {
          // Provider selection
          Column({ space: 8 }) {
            Text('模型服务商 (Provider)')
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '99')
              .fontWeight(FontWeight.Bold)

            Grid() {
              ForEach(AI_PROVIDERS, (p: ProviderInfo) => {
                GridItem() {
                  Column({ space: 4 }) {
                    Text(p.label.split(' ')[0])
                      .fontSize(11)
                      .fontWeight(FontWeight.Bold)
                    Text(p.id)
                      .fontSize(8)
                      .opacity(0.6)
                  }
                  .width('100%')
                  .padding(10)
                  .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
                  .backgroundColor(this.localConfig.provider === p.id ? COLORS.INK_BLACK : COLORS.WHITE)
                  .onClick(() => {
                    this.localConfig.provider = p.id as AIProvider
                    this.localConfig.model = p.defaultModel
                    this.localConfig.baseUrl = p.baseUrl
                  })
                }
              }, (p: ProviderInfo) => p.id)
            }
            .columnsTemplate('1fr 1fr 1fr')
            .rowsTemplate('1fr 1fr')
            .width('100%')
          }

          // API Key
          Column({ space: 4 }) {
            Text('API 密钥 (API Key)')
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '99')
              .fontWeight(FontWeight.Bold)

            TextInput({ placeholder: '输入您的 API Key...', text: this.localConfig.apiKey })
              .onChange((v: string) => { this.localConfig.apiKey = v })
              .type(InputType.Password)
              .fontSize(11)
              .padding(10)
              .backgroundColor(COLORS.INK_BLACK + '05')
              .border({ width: 1, color: COLORS.INK_BLACK + '1A' })

            Text('提示：密钥仅保存在本地，不会上传至服务器。')
              .fontSize(8)
              .fontColor(COLORS.INK_BLACK + '4D')
              .fontStyle(FontStyle.Italic)
          }

          // Model Name
          Column({ space: 4 }) {
            Text('模型名称 (Model Name)')
              .fontSize(10)
              .fontColor(COLORS.INK_BLACK + '99')
              .fontWeight(FontWeight.Bold)

            TextInput({ placeholder: '例如: gpt-4o, deepseek-chat...', text: this.localConfig.model })
              .onChange((v: string) => { this.localConfig.model = v })
              .fontSize(11)
              .padding(10)
              .backgroundColor(COLORS.INK_BLACK + '05')
              .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
          }

          // Base URL (for custom provider)
          if (this.localConfig.provider === 'custom') {
            Column({ space: 4 }) {
              Text('接口地址 (Base URL)')
                .fontSize(10)
                .fontColor(COLORS.INK_BLACK + '99')
                .fontWeight(FontWeight.Bold)

              TextInput({ placeholder: 'https://api.your-provider.com/v1', text: this.localConfig.baseUrl || '' })
                .onChange((v: string) => { this.localConfig.baseUrl = v })
                .fontSize(11)
                .padding(10)
                .backgroundColor(COLORS.INK_BLACK + '05')
                .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
            }
          }
        }
        .width('100%')
        .padding(20)
      }
      .layoutWeight(1)

      // Footer
      Row({ space: 12 }) {
        Button('取消')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.INK_BLACK + '99')
          .backgroundColor(COLORS.INK_BLACK + '05')
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => { this.controller.close() })

        Button('保存配置')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.INK_BLACK)
          .layoutWeight(1)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            if (this.onSave) {
              this.onSave(this.localConfig)
            }
            this.controller.close()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
      .border({ width: { top: 1 }, color: COLORS.INK_BLACK + '0D' })
      .backgroundColor(COLORS.INK_BLACK + '03')
    }
    .width('90%')
    .backgroundColor(COLORS.WHITE)
    .border({ width: 1, color: COLORS.INK_BLACK + '1A' })
    .shadow({ radius: 24, color: COLORS.INK_BLACK + '99' })
  }
}
