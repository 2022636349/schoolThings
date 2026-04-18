import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

const WIDGET_STORE = 'widget_data';
const FORM_IDS_STORE = 'widget_form_ids';

export default class EntryFormAbility extends FormExtensionAbility {

  onAddForm(want: Want): formBindingData.FormBindingData {
    // 保存 formId 以便主应用主动推送更新
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string;
    if (formId) {
      this.saveFormId(formId);
    }
    const formData = this.getWidgetData();
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string): void {
    const formData = this.getWidgetData();
    const bindingData = formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, bindingData).catch((err: Error) => {
      console.error('[EntryFormAbility] updateForm failed:', err);
    });
  }

  onRemoveForm(formId: string): void {
    this.removeFormId(formId);
  }

  onFormEvent(formId: string, message: string): void {
    // 处理卡片事件（如需要）
    console.info('[EntryFormAbility] onFormEvent:', formId, message);
  }

  private getWidgetData(): Record<string, Object> {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: WIDGET_STORE });
      const unreadCount = store.getSync('unreadCount', 0) as number;
      const latestMessage = store.getSync('latestMessage', '') as string;
      const data: Record<string, Object> = {};
      data['unreadCount'] = unreadCount;
      data['latestMessage'] = latestMessage;
      return data;
    } catch (e) {
      console.error('[EntryFormAbility] getWidgetData failed:', e);
      const data: Record<string, Object> = {};
      data['unreadCount'] = 0;
      data['latestMessage'] = '';
      return data;
    }
  }

  private saveFormId(formId: string): void {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: FORM_IDS_STORE });
      store.putSync(formId, true);
      store.flush();
    } catch (e) {
      console.error('[EntryFormAbility] saveFormId failed:', e);
    }
  }

  private removeFormId(formId: string): void {
    try {
      const store = preferences.getPreferencesSync(this.context, { name: FORM_IDS_STORE });
      store.deleteSync(formId);
      store.flush();
    } catch (e) {
      console.error('[EntryFormAbility] removeFormId failed:', e);
    }
  }
}
