import { COLORS, INK, RED } from '../common/constants'

@Component
export struct PrivacySection {
  @StorageLink('uiDark') isDark: boolean = false

  build() {
    Column({ space: 16 }) {
      Row({ space: 8 }) {
        Circle({ width: 6, height: 6 }).fill(COLORS.IMPERIAL_RED)
        Text('隐私与免责').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK)
        Text('PRIVACY').fontSize(8).fontColor(INK.PLACEHOLDER).fontWeight(FontWeight.Bold)
      }.width('100%')

      this.Block('一、信息收集', '本应用仅在你主动输入时收集出生日期、时辰、经度、性别、卦象记录等排盘数据；这些数据默认仅保存在本机。')
      this.Block('二、AI 解析与第三方', '仅当你主动发起 AI 解析并已配置 API Key 时，相关排盘摘要会发送至你选择的第三方模型服务商（如 Google、OpenAI、DeepSeek 等）。API Key 以系统安全加密方式存储于本机，不会上传至任何服务器。')
      this.Block('三、数据存储与导出', '排盘记录保存在系统偏好存储中；你可通过「设置 → 导出我的记录」将记录以 JSON 备份到剪贴板，请妥善保管包含个人出生信息的备份。卸载应用将清除全部本地记录。')
      this.Block('四、权限说明', '本应用仅申请网络权限（INTERNET），用于 AI 解析；不申请通讯录、定位、相机等敏感权限。')
      this.Block('五、免责声明', '本应用所有命理、黄历、卦象内容均基于传统易学规则离线或 AI 生成，仅供文化娱乐与研究参考，不构成医疗、投资、法律、婚恋或其他任何现实决策依据。请理性看待，切勿迷信。')
      this.Block('六、联系方式', '如对隐私政策有任何疑问，可通过应用商店页面联系开发者。')

      Text('完整隐私政策以上架 AppGallery Connect 时登记的版本为准。')
        .fontSize(8).fontColor(INK.PLACEHOLDER).fontStyle(FontStyle.Italic).width('100%')
    }
    .width('100%').padding(4).backgroundColor(this.isDark ? COLORS.PAPER : COLORS.PAPER)
  }

  @Builder Block(title: string, body: string) {
    Column({ space: 6 }) {
      Text(title).fontSize(12).fontWeight(FontWeight.Bold).fontColor(COLORS.INK_BLACK).width('100%')
      Text(body).fontSize(10).fontColor(INK.BODY).lineHeight(17).width('100%')
    }
    .width('100%').padding(14).backgroundColor(COLORS.WHITE + '80')
    .border({ width: 1, color: INK.HAIRLINE }).borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }
}
