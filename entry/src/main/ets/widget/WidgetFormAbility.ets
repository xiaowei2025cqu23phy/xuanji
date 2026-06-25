import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit'
import { Want } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

export default class WidgetFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    hilog.info(0x0000, 'TiandaoWidget', 'Form added')
    return formBindingData.createFormBindingData({
      title: '天道玄机',
      subtitle: 'Heavenly Decrypt'
    })
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(0x0000, 'TiandaoWidget', 'Form cast to normal: ' + formId)
  }

  onUpdateForm(formId: string): void {
    hilog.info(0x0000, 'TiandaoWidget', 'Form updated: ' + formId)
    const now = new Date()
    const formData = formBindingData.createFormBindingData({
      currentDate: now.getFullYear() + '年' + (now.getMonth() + 1) + '月' + now.getDate() + '日',
      title: '天道玄机',
      subtitle: 'Heavenly Decrypt'
    })
    formProvider.updateForm(formId, formData)
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    hilog.info(0x0000, 'TiandaoWidget', 'Form visibility changed')
  }

  onFormEvent(formId: string, message: string): void {
    hilog.info(0x0000, 'TiandaoWidget', 'Form event: ' + formId)
  }

  onRemoveForm(formId: string): void {
    hilog.info(0x0000, 'TiandaoWidget', 'Form removed: ' + formId)
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY
  }
}
