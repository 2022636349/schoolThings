import { router } from '@kit.ArkUI';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { TopNavBar } from '../components/TopNavBar';
import { AuthService } from '../services/AuthService';
import { ChatService } from '../services/ChatService';
import { UserService } from '../services/UserService';
import { ChatSession } from '../model/ChatSession';

interface ChatItemCardPayload {
  itemId: number;
  title: string;
  type: string;
  publisherName: string;
}

const MSG_STATE_STORE = 'message_state';
const PER_SESSION_READ_PREFIX = 'lastReadMsgId_';
const HIDDEN_PREFIX = 'hidden_';

interface SessionRow {
  session: ChatSession;
  otherUserId: string;
  otherUserName: string;
  otherUserAvatar: string;
  itemType: string;
  itemText: string;
  timeLabel: string;
  unreadCount: number;
}

@Entry
@Component
export struct MessagePage {
  @State sessionRows: SessionRow[] = [];
  @State isLoading: boolean = true;
  @State isRefreshing: boolean = false;
  @State currentUserId: string = '';
  @State topHeight: number = 0;

  @StorageProp('messageListRefresh') @Watch('onMessageListRefresh') messageListRefreshTrigger: number = 0;

  onMessageListRefresh(): void {
    if (this.currentUserId) {
      this.isRefreshing = true;
      this.loadSessions(this.currentUserId).finally(() => { this.isRefreshing = false; });
    }
  }

  aboutToAppear(): void {
    window.getLastWindow(getContext(this)).then((win) => {
      this.topHeight = px2vp(win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
    });
    AuthService.getSession(getContext(this) as common.UIAbilityContext).then((session) => {
      if (session) {
        this.currentUserId = session.id;
        this.loadSessions(session.id);
      } else {
        this.isLoading = false;
      }
    });
  }

  async loadSessions(userId: string): Promise<void> {
    this.isLoading = true;
    try {
      const allSessions = await ChatService.getSessionsForUser(userId);
      if (allSessions.length === 0) {
        this.sessionRows = [];
        this.isLoading = false;
        return;
      }

      const store0 = preferences.getPreferencesSync(getContext(this), { name: MSG_STATE_STORE });
      const sessions = allSessions.filter((s: ChatSession): boolean => {
        const h = store0.getSync(HIDDEN_PREFIX + s.sessionId, 0) as number;
        if (!h) return true;
        const lt = s.lastTime ? s.lastTime.getTime() : 0;
        return lt > h;
      });
      if (sessions.length === 0) {
        this.sessionRows = [];
        this.isLoading = false;
        return;
      }

      const otherIds: string[] = [];
      for (const s of sessions) {
        const otherId = s.initiatorId === userId ? s.ownerId : s.initiatorId;
        if (otherIds.indexOf(otherId) === -1) {
          otherIds.push(otherId);
        }
      }
      const publisherMap = await UserService.getPublisherInfoByIds(otherIds);

      const itemMap: Record<string, string[]> = {};
      for (const s of sessions) {
        const key = s.itemId.toString();
        if (!itemMap[key]) {
          try {
            const item = await ChatService.getItemById(s.itemId);
            itemMap[key] = item ? [item.type, item.text] : ['', ''];
          } catch (e) {
            itemMap[key] = ['', ''];
          }
        }
      }

      const lastReadMsgIdMap: Record<string, number> = {};
      try {
        const store = preferences.getPreferencesSync(getContext(this), { name: MSG_STATE_STORE });
        for (const s of sessions) {
          const key = PER_SESSION_READ_PREFIX + s.sessionId;
          lastReadMsgIdMap[s.sessionId] = store.getSync(key, 0) as number;
        }
      } catch (e) {  }

      const unreadCountMap = await ChatService.getPerSessionUnreadCounts(userId, lastReadMsgIdMap);

      const rows: SessionRow[] = sessions.map((s: ChatSession): SessionRow => {
        const otherId = s.initiatorId === userId ? s.ownerId : s.initiatorId;
        const info = publisherMap[otherId];
        const itemData = itemMap[s.itemId.toString()] || ['', ''];
        return {
          session: s,
          otherUserId: otherId,
          otherUserName: info?.name || otherId,
          otherUserAvatar: info?.avatar || '',
          itemType: s.initiatorConfirmed === 1 && s.ownerConfirmed === 1 ? 'claimed' : (itemData[0] || ''),
          itemText: itemData[1] || '',
          timeLabel: s.lastTime ? this.formatTime(s.lastTime) : '',
          unreadCount: unreadCountMap[s.sessionId] || 0
        } as SessionRow;
      });
      this.sessionRows = rows;
    } catch (error) {
      console.error('[MessagePage] 加载会话失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  formatTime(date: Date): string {
    const d = new Date(date);
    const now = new Date();
    const diff = Math.floor((now.getTime() - d.getTime()) / 1000 / 60);
    if (diff < 1) return '刚刚';
    if (diff < 60) return `${diff}分钟前`;
    if (diff < 60 * 24) return `${Math.floor(diff / 60)}小时前`;
    if (diff < 60 * 24 * 7) return `${Math.floor(diff / 60 / 24)}天前`;
    return `${d.getMonth() + 1}/${d.getDate()}`;
  }

  getTypeLabel(type: string): string {
    if (type === 'lost') return '寻物';
    if (type === 'found') return '招领';
    if (type === 'claimed') return '已认领';
    return '';
  }

  getTypeColor(type: string): string {
    if (type === 'lost') return '#E07B39';
    if (type === 'found') return '#4E8FDF';
    return '#4CAF50';
  }

  getTypeBgColor(type: string): ResourceColor {
    if (type === 'lost') return $r('app.color.badge_lost_bg');
    if (type === 'found') return $r('app.color.badge_find_bg');
    return $r('app.color.badge_claimed_bg');
  }

  private formatLastMessage(lastMessage: string | null): string {
    if (!lastMessage) return '';
    if (lastMessage === '[图片]' || lastMessage === '[物品卡片]' || lastMessage === '[系统消息]') {
      return lastMessage;
    }
    if (lastMessage.startsWith('{')) {
      try {
        const payload = JSON.parse(lastMessage) as ChatItemCardPayload;
        return `[物品卡片] ${payload.title}`;
      } catch (e) {
        return lastMessage;
      }
    }
    return lastMessage;
  }

  async doRefresh(): Promise<void> {
    if (this.currentUserId) {
      await this.loadSessions(this.currentUserId);
    }
    this.isRefreshing = false;
  }

  async markSessionRead(sessionId: string): Promise<void> {
    try {
      const maxMsgId = await ChatService.getMaxMsgId(sessionId);
      const store = preferences.getPreferencesSync(getContext(this), { name: MSG_STATE_STORE });
      store.putSync(PER_SESSION_READ_PREFIX + sessionId, maxMsgId);
      store.putSync('lastReadTime', Date.now());
      store.flush();
    } catch (e) {  }

    const newRows: SessionRow[] = [];
    for (let i = 0; i < this.sessionRows.length; i++) {
      const r = this.sessionRows[i];
      if (r.session.sessionId === sessionId) {
        newRows.push({
          session: r.session,
          otherUserId: r.otherUserId,
          otherUserName: r.otherUserName,
          otherUserAvatar: r.otherUserAvatar,
          itemType: r.itemType,
          itemText: r.itemText,
          timeLabel: r.timeLabel,
          unreadCount: 0
        });
      } else {
        newRows.push(r);
      }
    }
    this.sessionRows = newRows;
  }

  async deleteSession(row: SessionRow): Promise<void> {
    const sid = row.session.sessionId;
    try {

      let hideTime = Date.now();
      if (row.session.lastTime) {
        const lt = row.session.lastTime.getTime();
        if (lt + 1000 > hideTime) hideTime = lt + 1000;
      }

      const maxMsgId = await ChatService.getMaxMsgId(sid);
      const store = preferences.getPreferencesSync(getContext(this), { name: MSG_STATE_STORE });
      store.putSync(HIDDEN_PREFIX + sid, hideTime);
      store.putSync(PER_SESSION_READ_PREFIX + sid, maxMsgId);
      store.flush();
      this.sessionRows = this.sessionRows.filter((r: SessionRow) => r.session.sessionId !== sid);
      this.getUIContext().getPromptAction().showToast({ message: '已删除', duration: 1500 });
    } catch (e) {
      console.error('[MessagePage] deleteSession failed:', e);
      this.getUIContext().getPromptAction().showToast({ message: '删除失败', duration: 1500 });
    }
  }

  @Builder
  deleteSwipeAction(row: SessionRow) {
    Row() {
      Text('删除')
        .fontSize(14).fontColor(Color.White).fontWeight(FontWeight.Medium)
    }
    .width(72).height('100%')
    .backgroundColor('#FF3B30')
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.deleteSession(row) })
  }

  openChat(row: SessionRow): void {
    const s = row.session;
    const isInitiator = s.initiatorId === this.currentUserId;

    this.markSessionRead(s.sessionId);
    const cp: Record<string, Object> = {};
    cp['sessionId'] = s.sessionId;
    cp['itemId'] = s.itemId;
    cp['itemText'] = row.itemText;
    cp['itemType'] = row.itemType;
    cp['ownerId'] = s.ownerId;
    cp['otherUserId'] = row.otherUserId;
    cp['otherUserName'] = row.otherUserName;
    cp['otherUserAvatar'] = row.otherUserAvatar;
    cp['isInitiator'] = isInitiator ? 'true' : 'false';
    if (AppStorage.get<boolean>('isTabletMode') === true) {
      AppStorage.setOrCreate('tabletPrevRightType', 'none');
      AppStorage.setOrCreate('tabletPrevRightParams', '');
      AppStorage.setOrCreate('tabletRightType', 'chat');
      AppStorage.setOrCreate('tabletRightParams', JSON.stringify(cp));
    } else {
      router.pushUrl({ url: 'pages/ChatPage', params: cp });
    }
  }

  build() {
    Column() {
      TopNavBar({ title: '消息' })
        .padding({ top: this.topHeight })

      Refresh({ refreshing: $$this.isRefreshing }) {
        List({ space: 0 }) {
          if (this.isLoading && this.sessionRows.length === 0) {
            ListItem() {
              Column() {
                LoadingProgress().width(40).height(40).color('#4E8FDF')
              }
              .width('100%').height(300).justifyContent(FlexAlign.Center)
            }
          } else if (this.sessionRows.length === 0) {
            ListItem() {
              Column({ space: 8 }) {
                Text('暂无消息').fontSize(16).fontColor($r('app.color.text_caption'))
              }
              .width('100%').height(300).justifyContent(FlexAlign.Center)
            }
          } else {
            ForEach(this.sessionRows, (row: SessionRow) => {
              ListItem() {
                Row({ space: 12 }) {

                  Stack() {
                    if (row.otherUserAvatar) {
                      Image(row.otherUserAvatar)
                        .width(48).height(48).borderRadius(24)
                        .objectFit(ImageFit.Cover).backgroundColor($r('app.color.bg_avatar_placeholder'))
                    } else {
                      Stack() {
                        Circle().width(48).height(48).fill('#4E8FDF').opacity(0.12)
                        Text(row.otherUserName?.charAt(0) || '?')
                          .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4E8FDF')
                      }.width(48).height(48).borderRadius(24)
                    }

                    if (row.unreadCount > 0) {
                      Text(row.unreadCount > 99 ? '99+' : row.unreadCount.toString())
                        .fontSize(10).fontColor(Color.White).fontWeight(FontWeight.Bold)
                        .backgroundColor('#FF3B30')
                        .borderRadius(10)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                        .constraintSize({ minWidth: 18, minHeight: 18 })
                        .textAlign(TextAlign.Center)
                        .position({ x: 32, y: -2 })
                    }
                  }
                  .width(48).height(48)

                  Column({ space: 5 }) {
                    Row({ space: 6 }) {
                      Text(row.otherUserName)
                        .fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                        .layoutWeight(1)
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(row.timeLabel)
                        .fontSize(11).fontColor($r('app.color.text_disabled'))
                    }.width('100%').alignItems(VerticalAlign.Center)

                    Row({ space: 6 }) {
                      if (row.itemType) {
                        Text(this.getTypeLabel(row.itemType))
                          .fontSize(10)
                          .fontColor(this.getTypeColor(row.itemType))
                          .backgroundColor(this.getTypeBgColor(row.itemType))
                          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                          .borderRadius(3)
                      }
                      Text(row.itemText || this.formatLastMessage(row.session.lastMessage) || '开始聊天')
                        .fontSize(12).fontColor($r('app.color.text_hint'))
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                    }.width('100%').alignItems(VerticalAlign.Center)

                    if (row.session.lastMessage) {
                      Text(this.formatLastMessage(row.session.lastMessage))
                        .fontSize(13).fontColor($r('app.color.text_tertiary'))
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 14, bottom: 14 })
                .backgroundColor($r('app.color.bg_card'))
                .onClick(() => { this.openChat(row) })
              }
              .swipeAction({ end: { builder: () => { this.deleteSwipeAction(row) } } })

              ListItem() {
                Divider().color($r('app.color.divider2')).margin({ left: 76 })
              }
            }, (row: SessionRow): string => row.session.sessionId)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.bg_page'))
      }
      .layoutWeight(1)
      .onRefreshing(() => { this.doRefresh() })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
