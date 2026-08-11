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
    Column({ space: 14 }) {
      Divider().color(INK.HAIRLINE)

      // Header
      Row({ space: 8 }) {
        Text('🤖 AI 大师解析')
          .fontSize(13).fontWeight(FontWeight.Bold).fontColor(INK.CAPTION)
        Blank().layoutWeight(1)
        if (this.chatHistory.length > 0) {
          Button('🗑 清空').fontSize(9).fontColor(INK.PLACEHOLDER)
            .backgroundColor(INK.BG_FAINT).borderRadius(10)
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .onClick(() => { this.onClear() })
        }
      }.width('100%')

      // Category selector
      Scroll() {
        Row({ space: 6 }) {
          ForEach(QUESTION_CATEGORIES, (cat: CategoryInfo) => {
            Text(cat.icon + ' ' + cat.label.split(' ')[0])
              .fontSize(10).fontWeight(FontWeight.Bold)
              .fontColor(this.activeCategory === cat.id ? COLORS.WHITE : INK.SECONDARY)
              .backgroundColor(this.activeCategory === cat.id ? COLORS.IMPERIAL_RED : INK.BG_FAINT)
              .borderRadius(12).padding({ left: 12, right: 12, top: 7, bottom: 7 })
              .onClick(() => { this.onCategoryChange(cat.id) })
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

      // Chat messages area
      if (this.chatHistory.length > 0) {
        Scroll() {
          Column({ space: 10 }) {
            ForEach(this.chatHistory, (msg: ChatMessage, idx: number) => {
              Column() {
                Row() {
                  Text(msg.role === 'user' ? '🧑' : '🧘')
                    .fontSize(14).width(28)
                  Text(msg.content)
                    .fontSize(12).lineHeight(19)
                    .padding(14)
                    .backgroundColor(msg.role === 'user' ?
                      INK.BG_FAINT : COLORS.ACTIVE_CARD_BG)
                    .borderRadius({ topLeft: msg.role === 'user' ? 16 : 4, topRight: 16, bottomLeft: 16, bottomRight: 16 })
                    .constraintSize({ maxWidth: '78%' })
                }
                .width('100%')
                .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
              }
            })
            if (this.aiLoading) {
              Row({ space: 8 }) {
                LoadingProgress().width(16).height(16).color(COLORS.IMPERIAL_RED)
                Text('天道先生思考中...').fontSize(11).fontColor(INK.PLACEHOLDER)
              }.width('100%').justifyContent(FlexAlign.Start).padding({ left: 36, top: 4 })
            }
          }.width('100%')
        }
        .height(280)
        .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto)
      } else if (this.aiLoading) {
        Row({ space: 10 }) {
          LoadingProgress().width(18).height(18).color(COLORS.IMPERIAL_RED)
          Text('天道先生思考中...').fontSize(12).fontColor(INK.PLACEHOLDER)
        }.width('100%').justifyContent(FlexAlign.Center).padding(20)
      }

      // Input area
      Row({ space: 8 }) {
        TextInput({ placeholder: '💬 输入追问...', text: this.followUp })
          .onChange((value: string) => { this.followUp = value })
          .layoutWeight(1)
          .fontSize(12).padding({ left: 14, right: 14, top: 11, bottom: 11 })
          .backgroundColor(COLORS.WHITE + '66')
          .border({ width: 1.5, color: INK.FAINT }).borderRadius(14)

        Button('发送').fontSize(12).fontWeight(FontWeight.Bold)
          .fontColor(COLORS.WHITE).backgroundColor(COLORS.IMPERIAL_RED)
          .borderRadius(14).padding({ left: 20, right: 20, top: 11, bottom: 11 })
          .shadow({ radius: 6, color: COLORS.IMPERIAL_RED + '25', offsetY: 2 })
          .enabled(!this.aiLoading)
          .onClick(() => {
            const text = this.followUp.trim()
            if (text.length > 0) {
              this.onSend(text)
              this.followUp = ''
            }
          })
      }.width('100%')
    }.width('100%')
  }
}
