import pasteboard from '@ohos.pasteboard'
import { systemShare } from '@kit.ShareKit'
import { common } from '@kit.AbilityKit'
import { exportAllReadings } from './readingStore'
import { hilog } from '@kit.PerformanceAnalysisKit'

const TAG = 'ExportService'

// ============================================================
// Export readings as text to clipboard (for backup / sharing)
// ============================================================
export async function exportReadingsToClipboard(): Promise<string> {
  try {
    const json = await exportAllReadings()
    const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, json)
    await pasteboard.getSystemPasteboard().setData(data)
    hilog.info(0x0000, TAG, 'Readings exported to clipboard successfully')
    return json
  } catch (e) {
    hilog.error(0x0000, TAG, 'exportReadingsToClipboard failed: %{public}s', (e as Object).toString())
    throw new Error('导出失败')
  }
}

// ============================================================
// Share text via system share panel (ShareKit)
// ============================================================
export async function shareText(text: string, context: Context): Promise<void> {
  const record: systemShare.SharedRecord = {
    utd: 'general.plain-text',
    title: '天道玄机',
    content: text
  }
  const data = new systemShare.SharedData(record)
  const controller = new systemShare.ShareController(data)
  await controller.show(context as common.UIAbilityContext, {
    previewMode: systemShare.SharePreviewMode.DETAIL
  })
}

// ============================================================
// Generate a readable text summary of bazi result for sharing
// ============================================================
export function formatBaziShareText(
  date: string, time: string, gender: string,
  yearStem: string, yearBranch: string,
  monthStem: string, monthBranch: string,
  dayStem: string, dayBranch: string,
  hourStem: string, hourBranch: string,
  dayMaster: string, dayMasterAnalysis: string,
  structureName: string, structureDesc: string
): string {
  let text = '【天道玄机 · 八字排盘】\n'
  text += '生辰：' + date + ' ' + time + '（' + (gender === 'male' ? '男' : '女') + '）\n'
  text += '四柱：' + yearStem + yearBranch + ' ' + monthStem + monthBranch + ' ' +
    dayStem + dayBranch + ' ' + hourStem + hourBranch + '\n'
  text += '日主：' + dayMaster + '\n'
  if (dayMasterAnalysis.length > 0) {
    text += '日主解析：' + dayMasterAnalysis + '\n'
  }
  if (structureName.length > 0) {
    text += '格局：' + structureName + '\n'
    if (structureDesc.length > 0) {
      text += '格局解析：' + structureDesc + '\n'
    }
  }
  text += '\n—— 天道玄机 · 仅供文化娱乐参考'
  return text
}

// ============================================================
// Generate a readable text summary of iching result for sharing
// ============================================================
export function formatIChingShareText(
  hexSymbol: string, hexName: string, hexNumber: number,
  judgement: string, meaning: string,
  changedSymbol: string, changedName: string,
  tiName: string, tiElement: string,
  yongName: string, yongElement: string,
  tiYongRelation: string,
  movingCount: number
): string {
  let text = '【天道玄机 · 周易起卦】\n'
  text += '本卦：' + hexSymbol + ' ' + hexName + '（第' + hexNumber + '卦）\n'
  text += '卦辞：' + judgement + '\n'
  text += '释义：' + meaning + '\n'
  if (changedName.length > 0) {
    text += '变卦：' + changedSymbol + ' ' + changedName + '\n'
  }
  text += '体用：' + tiName + '(' + tiElement + ') 为体，' +
    yongName + '(' + yongElement + ') 为用 · ' + tiYongRelation + '\n'
  text += '动爻：' + movingCount + '个\n'
  text += '\n—— 天道玄机 · 仅供文化娱乐参考'
  return text
}
