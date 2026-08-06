import { COLORS, INK, RED, OP } from '../../common/constants'
import { ChatMessage, QUESTION_CATEGORIES, CategoryInfo } from '../../services/aiService'

@Component
export struct AIChatPanel {
  @Link chatHistory: ChatMessage[]
  @Prop activeCategory: string
  @Prop aiLoading: boolean
  onCategoryChange: (categoryId: string) => void = (_id: string) => {}
  onSend: (text: string) => void = (_text: string) => {}
  onClear: () => void = () => {}
  @State followUp: string = ''

  build() {
    Column({ space: 16 }) {
      Divider().color(COLORS.INK_BLACK + OP.X_FAINT)

      Row({ space: 8 }) {
        Text('AI 大师解析')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(INK.CAPTION)
        Blank().layoutWeight(1)
        if (this.chatHistory.length > 0) {
          Button('清空')
            .fontSize(8).fontColor(INK.PLACEHOLDER).backgroundColor(INK.BG_FAINT)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .onClick(() => { this.onClear() })
        }
      }.width('100%')

      // Category selector
      Row({ space: 4 }) {
        ForEach(QUESTION_CATEGORIES, (cat: CategoryInfo) => {
          Text(cat.icon + ' ' + cat.label)
            .fontSize(9)
            .fontColor(this.activeCategory === cat.id ? COLORS.WHITE : INK.SECONDARY)
            .backgroundColor(this.activeCategory === cat.id ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(12)
            .onClick(() => { this.onCategoryChange(cat.id) })
        }, (cat: CategoryInfo) => cat.id)
      }
      .width('100%')

      // Chat history
      if (this.chatHistory.length > 0) {
        Scroll() {
          Column({ space: 12 }) {
            ForEach(this.chatHistory, (msg: ChatMessage, idx: number) => {
              Row() {
                Text(msg.content)
                  .fontSize(11)
                  .fontColor(INK.BODY)
                  .padding(12)
                  .backgroundColor(msg.role === 'user' ? INK.BG_LIGHT : RED.BG_MEDIUM)
                  .borderRadius(12)
                  .constraintSize({ maxWidth: '80%' })
              }
              .width('100%')
              .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
            }, (_msg: ChatMessage, idx: number) => idx.toString())
            if (this.aiLoading) {
              Row({ space: 8 }) {
                LoadingProgress().width(14).height(14).color(COLORS.IMPERIAL_RED)
                Text('天道先生思考中...').fontSize(10).fontColor(INK.PLACEHOLDER)
              }
              .width('100%').justifyContent(FlexAlign.Start).padding({ left: 4 })
            }
          }
          .width('100%')
        }
        .height(200)
      } else if (this.aiLoading) {
        Row({ space: 8 }) {
          LoadingProgress().width(14).height(14).color(COLORS.IMPERIAL_RED)
          Text('天道先生思考中...').fontSize(10).fontColor(INK.PLACEHOLDER)
        }.width('100%').justifyContent(FlexAlign.Center).padding(16)
      }

      // Input area
      Row({ space: 8 }) {
        TextInput({ placeholder: '输入追问...', text: this.followUp })
          .onChange((value: string) => { this.followUp = value })
          .layoutWeight(1)
          .fontSize(11)
          .padding(10)
          .backgroundColor(INK.BG_FAINT)
          .border({ width: 1, color: INK.HAIRLINE })
          .borderRadius(12)

        Button('发送')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.IMPERIAL_RED)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .borderRadius(12)
          .enabled(!this.aiLoading)
          .onClick(() => {
            const text = this.followUp.trim()
            if (text.length > 0) {
              this.onSend(text)
              this.followUp = ''
            }
          })
      }
      .width('100%')
    }
    .width('100%')
  }
}
