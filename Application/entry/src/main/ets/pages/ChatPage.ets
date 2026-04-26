import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { AuthService } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { UserService } from '../services/UserService';
import { UploadService } from '../services/UploadService';
import { ChatMessage } from '../model/ChatMessage';
import { ChatSession } from '../model/ChatSession';
import { MeteorOverlay } from '../components/MeteorOverlay';
import { formatTime } from '../services/ItemService';

interface ChatParams {
  sessionId: string;
  itemId: number;
  itemText: string;
  itemType: string;
  ownerId: string;
  otherUserId: string;
  otherUserName: string;
  otherUserAvatar: string;
  isInitiator: string;
}

interface Path {
  type: string;
  url: string;
}

interface ChatItemCardPayload {
  itemId: number;
  title: string;
  type: string;
  publisherName: string;
}

@Entry
@Component
export struct ChatPage {
  @Prop @Watch('onParamsJsonChange') paramsJson: string = '';
  @State sessionId: string = '';
  @State itemId: number = 0;
  @State itemText: string = '';
  @State itemType: string = '';
  @State ownerId: string = '';
  @State otherUserId: string = '';
  @State otherUserName: string = '';
  @State otherUserAvatar: string = '';
  @State isInitiator: boolean = false;

  @State fullItemText: string = '';
  @State fullItemType: string = '';
  @State fullMediaListJson: string = '[]';
  @State fullPublishTime: string = '';
  @State fullPublisherName: string = '';
  @State fullPublisherAvatar: string = '';

  @State currentUserId: string = '';
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isSending: boolean = false;
  @State isConfirming: boolean = false;
  @State iHaveConfirmed: boolean = false;
  @State isClaimed: boolean = false;
  @State topHeight: number = 0;
  @State bottomHeight: number = 0;

  private scroller: Scroller = new Scroller();
  private pollTimer: number = -1;
  private lastMsgId: number = 0;
  private idlePollCount: number = 0;

  onParamsJsonChange(): void {
    if (this.paramsJson) {
      this.applyParams(this.paramsJson);
    }
  }

  private applyParams(json: string): void {
    try {
      const p = JSON.parse(json) as ChatParams;
      this.sessionId = p.sessionId;
      this.itemId = p.itemId;
      this.itemText = p.itemText || '';
      this.itemType = p.itemType || '';
      this.ownerId = p.ownerId;
      this.otherUserId = p.otherUserId;
      this.otherUserName = p.otherUserName;
      this.otherUserAvatar = p.otherUserAvatar;
      this.isInitiator = p.isInitiator === 'true';
      this.messages = [];
      this.lastMsgId = 0;
      this.idlePollCount = 0;
      this.iHaveConfirmed = false;
      this.isClaimed = false;
      this.fullItemText = '';
      this.fullItemType = '';
      if (this.itemId > 0) { this.loadItemDetails(); }
      if (this.pollTimer !== -1) { clearInterval(this.pollTimer); }
      this.loadData(true);
      this.startPolling();
    } catch (e) {
      console.error('[ChatPage] applyParams failed:', e);
    }
  }

  goBack(): void {
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      const prev = AppStorage.get<string>('tabletPrevRightType') || 'none';
      const prevParams = AppStorage.get<string>('tabletPrevRightParams') || '';
      AppStorage.setOrCreate('tabletRightParams', prevParams);
      AppStorage.setOrCreate('tabletRightType', prev);
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
    } else {
      router.back();
    }
  }

  aboutToAppear(): void {
    if (this.paramsJson) {
      this.applyParams(this.paramsJson);
    } else {
      const p = router.getParams() as ChatParams;
      if (p) {
        this.sessionId = p.sessionId;
        this.itemId = p.itemId;
        this.itemText = p.itemText || '';
        this.itemType = p.itemType || '';
        this.ownerId = p.ownerId;
        this.otherUserId = p.otherUserId;
        this.otherUserName = p.otherUserName;
        this.otherUserAvatar = p.otherUserAvatar;
        this.isInitiator = p.isInitiator === 'true';
      }
    }
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.bottomHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height);
    });
    if (this.itemId > 0) {
      this.loadItemDetails();
    }
    AuthService.getSession(getContext(this) as common.UIAbilityContext).then((session) => {
      if (session) {
        this.currentUserId = session.id;
      }
      if (!this.paramsJson) {
        this.loadData(true);
        this.startPolling();
      }
    });
  }

  aboutToDisappear(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
    this.markCurrentSessionRead();

    AppStorage.setOrCreate('messageListRefresh', Date.now());
  }

  private async markCurrentSessionRead(): Promise<void> {
    if (!this.sessionId) return;
    try {
      const maxMsgId = await ChatService.getMaxMsgId(this.sessionId);
      const store = preferences.getPreferencesSync(getContext(this), { name: 'message_state' });
      store.putSync('lastReadMsgId_' + this.sessionId, maxMsgId);
      store.putSync('lastReadTime', Date.now());
      store.flush();
    } catch (e) {
    }
    AppStorage.setOrCreate('messageListRefresh', Date.now());
  }

  async loadItemDetails(): Promise<void> {
    try {
      const item = await ChatService.getItemById(this.itemId);
      if (item) {
        this.fullItemText = item.text;
        this.fullItemType = item.type;
        try {
          const rawMedia = JSON.parse(item.resource || '[]') as Array<Path>;
          const resolvedMedia: Array<Path> = [];
          for (const m of rawMedia) {
            let url = m.url;
            if (url && !url.startsWith('http')) {
              url = await UploadService.getDownloadURL(url);
            }
            resolvedMedia.push({ type: m.type, url });
          }
          this.fullMediaListJson = JSON.stringify(resolvedMedia);
        } catch (e) {
          this.fullMediaListJson = '[]';
        }
        if (item.publishTime) {
          this.fullPublishTime = formatTime(new Date(item.publishTime));
        }
      }
      const publisherMap = await UserService.getPublisherInfoByIds([this.ownerId]);
      const info = publisherMap[this.ownerId];
      if (info) {
        this.fullPublisherName = info.name;
        this.fullPublisherAvatar = info.avatar;
      }
    } catch (e) {
      console.error('[ChatPage] loadItemDetails 失败:', e);
    }
  }

  private startPolling(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
    }
    this.pollTimer = setInterval(() => {
      this.loadData(false);
    }, this.idlePollCount >= 3 ? 5000 : 2000);
  }

  async loadData(forceFull: boolean = false): Promise<void> {
    try {
      const msgs = forceFull ? await ChatService.getMessages(this.sessionId) : await ChatService.getMessages(this.sessionId, this.lastMsgId);
      if (forceFull) {
        this.messages = msgs;
      } else if (msgs.length > 0) {
        this.messages = [...this.messages, ...msgs];
      }
      if (this.messages.length > 0) {
        this.lastMsgId = this.messages[this.messages.length - 1].msgId;
      }
      this.idlePollCount = msgs.length > 0 ? 0 : this.idlePollCount + 1;
      if (this.pollTimer === -1 || msgs.length > 0) {
        this.startPolling();
      }
      const session = await ChatService.getSession(this.sessionId);
      if (session) {
        if (this.isInitiator) {
          this.iHaveConfirmed = session.initiatorConfirmed === 1;
        } else {
          this.iHaveConfirmed = session.ownerConfirmed === 1;
        }
        if (session.initiatorConfirmed === 1 && session.ownerConfirmed === 1) {
          this.isClaimed = true;
          this.fullItemType = 'claimed';
          this.itemType = 'claimed';
        }
      }
      this.scroller.scrollEdge(Edge.Bottom);
    } catch (error) {
      console.error('[ChatPage] 加载数据失败:', error);
    }
  }

  async sendMessage(): Promise<void> {
    const content = this.inputText.trim();
    if (!content || this.isSending) return;
    this.isSending = true;
    this.inputText = '';
    try {
      await ChatService.sendMessage(this.sessionId, this.currentUserId, content);
      await this.loadData();
    } catch (error) {
      console.error('[ChatPage] 发送失败:', error);
      this.getUIContext().getPromptAction().showToast({ message: '发送失败，请重试' });
    } finally {
      this.isSending = false;
    }
  }

  async onConfirmClaim(): Promise<void> {
    if (this.isConfirming || this.iHaveConfirmed) return;
    this.isConfirming = true;
    try {
      const bothConfirmed = await ChatService.confirmClaimed(this.sessionId, this.currentUserId);
      this.iHaveConfirmed = true;
      if (bothConfirmed) {
        const session = await ChatService.getSession(this.sessionId);
        if (session) {
          await ChatService.markItemClaimed(session);
        }
        await ChatService.sendSystemMessage(this.sessionId, '双方已确认，认领流程已完成');
        this.isClaimed = true;
        this.fullItemType = 'claimed';
        this.itemType = 'claimed';
        this.getUIContext().getPromptAction().showToast({ message: '认领完成！双方已确认' });
      } else {
        await ChatService.sendSystemMessage(this.sessionId, '一方已确认认领，等待对方确认');
        this.getUIContext().getPromptAction().showToast({ message: '已确认，等待对方确认' });
      }
    } catch (error) {
      console.error('[ChatPage] 确认认领失败:', error);
      this.getUIContext().getPromptAction().showToast({ message: '操作失败，请重试' });
    } finally {
      this.isConfirming = false;
    }
  }

  effectiveType(): string {
    return this.fullItemType || this.itemType;
  }

  getTypeLabel(): string {
    const t = this.effectiveType();
    if (t === 'lost') return '寻物';
    if (t === 'found') return '招领';
    if (t === 'claimed') return '已认领';
    return '物品';
  }

  getTypeColor(): string {
    const t = this.effectiveType();
    if (t === 'lost') return '#E07B39';
    if (t === 'found') return '#4E8FDF';
    return '#4CAF50';
  }

  getTypeBgColor(): ResourceColor {
    const t = this.effectiveType();
    if (t === 'lost') return $r('app.color.badge_lost_bg');
    if (t === 'found') return $r('app.color.badge_find_bg');
    return $r('app.color.badge_claimed_bg');
  }

  formatMsgTime(date: Date | null): string {
    if (!date) return '';
    const d = new Date(date);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    return `${h}:${m}`;
  }

  build() {
    Stack() {
      Column() {

      Row() {
        Row() {
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(22).height(22).fillColor($r('app.color.icon_primary'))
        }
        .width(40).height(40).borderRadius(20)
        .backgroundColor($r('app.color.bg_secondary'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => { this.goBack() })

        Row({ space: 8 }) {
          if (this.otherUserAvatar) {
            Image(this.otherUserAvatar)
              .width(36).height(36).borderRadius(18)
              .objectFit(ImageFit.Cover).backgroundColor($r('app.color.bg_avatar_placeholder'))
          } else {
            Stack() {
              Circle().width(36).height(36).fill('#4E8FDF').opacity(0.12)
              Text(this.otherUserName?.charAt(0) || '?')
                .fontSize(15).fontWeight(FontWeight.Bold).fontColor('#4E8FDF')
            }.width(36).height(36).borderRadius(18)
          }
          Text(this.otherUserName || '对方')
            .fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)

        if (this.isClaimed) {
          Text('已认领')
            .fontSize(13).fontColor('#4CAF50')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14)
            .border({ width: 1, color: '#4CAF50' })
        } else if (this.iHaveConfirmed) {
          Text('已确认')
            .fontSize(13).fontColor('#4CAF50')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14)
            .border({ width: 1, color: '#4CAF50' })
        } else {
          Text(this.isConfirming ? '...' : '认领完成')
            .fontSize(13).fontColor('#4E8FDF')
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .borderRadius(14)
            .border({ width: 1, color: '#4E8FDF' })
            .onClick(() => { this.onConfirmClaim() })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topHeight + 10, bottom: 14 })
      .backgroundColor($r('app.color.bg_card'))
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.04)', offsetY: 2 })

      Row({ space: 10 }) {
        Text(this.getTypeLabel())
          .fontSize(11)
          .fontColor(this.getTypeColor())
          .backgroundColor(this.getTypeBgColor())
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
        Text(this.fullItemText || this.itemText || '加载中...')
          .fontSize(13).fontColor($r('app.color.text_tertiary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        Text('查看详情 >')
          .fontSize(12).fontColor('#4E8FDF')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor($r('app.color.bg_input_area'))
      .border({ width: { bottom: 1 }, color: $r('app.color.border') })
      .onClick(() => {
        const dp: Record<string, Object> = {};
        dp['itemId'] = this.itemId;
        dp['type'] = this.fullItemType || this.itemType;
        dp['text'] = this.fullItemText || this.itemText;
        dp['publishTime'] = this.fullPublishTime;
        dp['publishId'] = this.ownerId;
        dp['publisherName'] = this.fullPublisherName || this.otherUserName;
        dp['publisherAvatar'] = this.fullPublisherAvatar || (this.isInitiator ? this.otherUserAvatar : '');
        dp['mediaList'] = this.fullMediaListJson;
        if (AppStorage.get<boolean>('isTabletMode') === true) {
          AppStorage.setOrCreate('tabletPrevRightType', 'chat');
          AppStorage.setOrCreate('tabletPrevRightParams', this.paramsJson || JSON.stringify({
            sessionId: this.sessionId,
            itemId: this.itemId,
            itemText: this.itemText,
            itemType: this.itemType,
            ownerId: this.ownerId,
            otherUserId: this.otherUserId,
            otherUserName: this.otherUserName,
            otherUserAvatar: this.otherUserAvatar,
            isInitiator: this.isInitiator ? 'true' : 'false'
          }));
          AppStorage.setOrCreate('tabletRightType', 'detail');
          AppStorage.setOrCreate('tabletRightParams', JSON.stringify(dp));
        } else {
          router.pushUrl({ url: 'pages/DetailPage', params: dp });
        }
      })

      List({ space: 8, scroller: this.scroller }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            this.MessageBubble(msg)
          }
        }, (msg: ChatMessage): string => msg.msgId.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.bg_page'))

      Row({ space: 10 }) {
        TextInput({ text: this.inputText, placeholder: '输入消息...' })
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .placeholderColor($r('app.color.text_disabled'))
          .backgroundColor($r('app.color.bg_input'))
          .borderRadius(22)
          .padding({ left: 16, right: 16, top: 0, bottom: 0 })
          .onChange((val: string) => { this.inputText = val })
          .onSubmit(() => { this.sendMessage() })

        Button('发送')
          .height(44)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .backgroundColor(this.inputText.trim() ? '#4E8FDF' : '#C0D0E8')
          .borderRadius(22)
          .padding({ left: 18, right: 18 })
          .enabled(this.inputText.trim().length > 0 && !this.isSending)
          .onClick(() => { this.sendMessage() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: this.bottomHeight + 10 })
      .backgroundColor($r('app.color.bg_card'))
      .shadow({ radius: 6, color: 'rgba(0,0,0,0.05)', offsetY: -2 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      MeteorOverlay({ suppressInTablet: true })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }

  private parseItemCardText(content: string): string {
    try {
      const payload = JSON.parse(content) as ChatItemCardPayload;
      return `${payload.title} · ${payload.type === 'lost' ? '失物招领' : '寻物启事'} · ${payload.publisherName}`;
    } catch (e) {
      return content;
    }
  }

  @Builder
  MessageBubble(msg: ChatMessage) {
    Row({ space: 8 }) {
      if (msg.senderId !== this.currentUserId) {
        if (this.otherUserAvatar) {
          Image(this.otherUserAvatar)
            .width(36).height(36).borderRadius(18)
            .objectFit(ImageFit.Cover).backgroundColor($r('app.color.bg_avatar_placeholder'))
        } else {
          Stack() {
            Circle().width(36).height(36).fill('#4E8FDF').opacity(0.12)
            Text(this.otherUserName?.charAt(0) || '?')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor('#4E8FDF')
          }.width(36).height(36).borderRadius(18)
        }
      }

      Column({ space: 4 }) {
        if (msg.senderId !== this.currentUserId) {
          Text(this.otherUserName || '对方')
            .fontSize(12).fontColor($r('app.color.text_caption')).alignSelf(ItemAlign.Start)
        }
        if (msg.messageType === 'system') {
          Text(msg.content || '系统消息')
            .fontSize(13)
            .fontColor('#666666')
            .backgroundColor('#F3F4F6')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(14)
            .constraintSize({ maxWidth: 240 })
            .lineHeight(20)
        } else if (msg.messageType === 'item-card') {
          Column({ space: 6 }) {
            Text('物品卡片')
              .fontSize(11)
              .fontColor('#4E8FDF')
            Text(this.parseItemCardText(msg.content))
              .fontSize(14)
              .fontColor($r('app.color.text_tertiary'))
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .backgroundColor('#EBF3FF')
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .borderRadius(16)
          .constraintSize({ maxWidth: 240 })
        } else {
          Row() {
            Text(msg.content)
              .fontSize(15)
              .fontColor(msg.senderId === this.currentUserId ? '#FFFFFF' : $r('app.color.text_primary'))
              .backgroundColor(msg.senderId === this.currentUserId ? '#4E8FDF' : $r('app.color.bg_card'))
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .borderRadius(18)
              .constraintSize({ maxWidth: 240 })
              .lineHeight(22)
          }
        }
        Text(this.formatMsgTime(msg.sendTime))
          .fontSize(11).fontColor($r('app.color.text_disabled'))
          .alignSelf(msg.senderId === this.currentUserId ? ItemAlign.End : ItemAlign.Start)
      }
      .alignItems(msg.senderId === this.currentUserId ? HorizontalAlign.End : HorizontalAlign.Start)
      .layoutWeight(1)

      if (msg.senderId === this.currentUserId) {
        Row().width(36).height(36)
      }
    }
    .width('100%')
    .justifyContent(msg.senderId === this.currentUserId ? FlexAlign.End : FlexAlign.Start)
    .padding({ left: 4, right: 4, top: 2, bottom: 2 })
  }
}
