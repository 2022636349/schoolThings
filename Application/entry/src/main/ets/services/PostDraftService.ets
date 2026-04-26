import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { distributedKVStore, preferences } from '@kit.ArkData';
import { Session } from '../common/Session';
import { MediaItem } from './PostService';

const STORE_NAME = 'post_draft';
const DISTRIBUTED_STORE_ID = 'post_draft_sync';
const BUNDLE_NAME = 'com.school.findThings';
const KEY_DRAFT_PREFIX = 'draft_';
const KEY_DELETED_PREFIX = 'deleted_at_';
const SYNC_PERMISSIONS: Permissions[] = ['ohos.permission.DISTRIBUTED_DATASYNC'];

export interface PostDraftData {
  title: string;
  description: string;
  category: string;
  lostTime: number;
  location: string;
  contact: string;
  type: string;
  imageUrl: string;
  mediaList: MediaItem[];
  updatedAt: number;
}

interface LocalDraftState {
  draft: PostDraftData | null;
  deletedAt: number;
}

interface DistributedDraftRecord {
  userId: string;
  updatedAt: number;
  deleted: boolean;
  draft: PostDraftData | null;
}

export interface DraftRemoteChange {
  userId: string;
  updatedAt: number;
  deleted: boolean;
  draft: PostDraftData | null;
}

export type DraftRemoteListener = (change: DraftRemoteChange) => void;

export class PostDraftService {
  private static kvStore: distributedKVStore.SingleKVStore | null = null;
  private static kvStoreOpening: Promise<distributedKVStore.SingleKVStore | null> | null = null;
  private static permissionGranted: boolean = false;
  private static storeListenerInstalled: boolean = false;
  private static remoteListeners: DraftRemoteListener[] = [];

  static save(context: common.UIAbilityContext, draft: PostDraftData): void {
    const userId = PostDraftService.getUserId(context);
    PostDraftService.saveLocal(context, userId, draft);
    PostDraftService.saveRemote(context, userId, draft);
  }

  static load(context: common.UIAbilityContext): PostDraftData | null {
    const userId = PostDraftService.getUserId(context);
    return PostDraftService.getLocalState(context, userId).draft;
  }

  static async loadLatest(context: common.UIAbilityContext): Promise<PostDraftData | null> {
    const userId = PostDraftService.getUserId(context);
    const localState = PostDraftService.getLocalState(context, userId);
    const remoteRecord = await PostDraftService.loadRemoteRecord(context, userId);
    const localUpdatedAt = localState.draft ? localState.draft.updatedAt : 0;

    if (!remoteRecord) {
      if (localState.draft && localUpdatedAt >= localState.deletedAt) {
        await PostDraftService.saveRemoteRecord(context, userId, localState.draft);
        return localState.draft;
      }
      if (localState.deletedAt > 0) {
        await PostDraftService.clearRemoteRecord(context, userId, localState.deletedAt);
      }
      return null;
    }

    if (remoteRecord.deleted) {
      if (remoteRecord.updatedAt >= localUpdatedAt && remoteRecord.updatedAt >= localState.deletedAt) {
        PostDraftService.clearLocal(context, userId, remoteRecord.updatedAt);
        return null;
      }
      if (localState.draft && localUpdatedAt > remoteRecord.updatedAt) {
        await PostDraftService.saveRemoteRecord(context, userId, localState.draft);
        return localState.draft;
      }
      return null;
    }

    if (!remoteRecord.draft) {
      return localState.draft;
    }

    const remoteDraft = remoteRecord.draft;
    const localStateTime = Math.max(localUpdatedAt, localState.deletedAt);
    if (remoteDraft.updatedAt > localStateTime) {
      PostDraftService.saveLocal(context, userId, remoteDraft);
      return remoteDraft;
    }

    if (localState.deletedAt > remoteDraft.updatedAt) {
      await PostDraftService.clearRemoteRecord(context, userId, localState.deletedAt);
      return null;
    }

    if (localState.draft && localUpdatedAt > remoteDraft.updatedAt) {
      await PostDraftService.saveRemoteRecord(context, userId, localState.draft);
      return localState.draft;
    }

    return localState.draft || remoteDraft;
  }

  static clear(context: common.UIAbilityContext): void {
    const userId = PostDraftService.getUserId(context);
    const deletedAt = Date.now();
    PostDraftService.clearLocal(context, userId, deletedAt);
    PostDraftService.clearRemote(context, userId, deletedAt);
  }

  static subscribeRemote(context: common.UIAbilityContext, listener: DraftRemoteListener): void {
    if (PostDraftService.remoteListeners.indexOf(listener) === -1) {
      PostDraftService.remoteListeners.push(listener);
    }
    PostDraftService.getDistributedStore(context).then((store) => {
      if (store) {
        PostDraftService.installStoreListener(store);
      }
    });
  }

  static unsubscribeRemote(listener: DraftRemoteListener): void {
    const idx = PostDraftService.remoteListeners.indexOf(listener);
    if (idx >= 0) {
      PostDraftService.remoteListeners.splice(idx, 1);
    }
  }

  static async syncNow(context: common.UIAbilityContext): Promise<void> {
    const store = await PostDraftService.getDistributedStore(context);
    if (!store) return;
    try {
      const userId = PostDraftService.getUserId(context);
      const value = await store.get(PostDraftService.getDraftKey(userId));
      if (typeof value !== 'string' || value.length === 0) {
        return;
      }
      const record = JSON.parse(value) as DistributedDraftRecord;
      PostDraftService.dispatchRemote(record);
    } catch (e) {
      console.warn('[PostDraftService] syncNow failed:', JSON.stringify(e));
    }
  }

  private static getUserId(context: common.UIAbilityContext): string {
    try {
      const userId = Session.getUserId(context);
      return userId && userId.length > 0 ? userId : 'guest';
    } catch (e) {
      return 'guest';
    }
  }

  private static getDraftKey(userId: string): string {
    return KEY_DRAFT_PREFIX + userId;
  }

  private static getDeletedKey(userId: string): string {
    return KEY_DELETED_PREFIX + userId;
  }

  private static getLocalState(context: common.UIAbilityContext, userId: string): LocalDraftState {
    try {
      const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      const raw = store.getSync(PostDraftService.getDraftKey(userId), '') as string;
      const deletedAt = store.getSync(PostDraftService.getDeletedKey(userId), 0) as number;
      if (!raw || raw.length === 0) {
        return { draft: null, deletedAt: deletedAt };
      }
      const draft = PostDraftService.normalizeDraft(JSON.parse(raw) as PostDraftData);
      return { draft: draft, deletedAt: deletedAt };
    } catch (e) {
      console.error('[PostDraftService] getLocalState failed:', JSON.stringify(e));
      return { draft: null, deletedAt: 0 };
    }
  }

  private static saveLocal(context: common.UIAbilityContext, userId: string, draft: PostDraftData): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      store.putSync(PostDraftService.getDraftKey(userId), JSON.stringify(draft));
      store.putSync(PostDraftService.getDeletedKey(userId), 0);
      store.flush();
    } catch (e) {
      console.error('[PostDraftService] saveLocal failed:', JSON.stringify(e));
    }
  }

  private static clearLocal(context: common.UIAbilityContext, userId: string, deletedAt: number): void {
    try {
      const store = preferences.getPreferencesSync(context, { name: STORE_NAME });
      store.deleteSync(PostDraftService.getDraftKey(userId));
      store.putSync(PostDraftService.getDeletedKey(userId), deletedAt);
      store.flush();
    } catch (e) {
      console.error('[PostDraftService] clearLocal failed:', JSON.stringify(e));
    }
  }

  private static saveRemote(context: common.UIAbilityContext, userId: string, draft: PostDraftData): void {
    PostDraftService.saveRemoteRecord(context, userId, draft).catch((e: Error) => {
      console.warn('[PostDraftService] saveRemote failed:', e.message);
    });
  }

  private static clearRemote(context: common.UIAbilityContext, userId: string, deletedAt: number): void {
    PostDraftService.clearRemoteRecord(context, userId, deletedAt).catch((e: Error) => {
      console.warn('[PostDraftService] clearRemote failed:', e.message);
    });
  }

  private static async saveRemoteRecord(
    context: common.UIAbilityContext,
    userId: string,
    draft: PostDraftData
  ): Promise<void> {
    const store = await PostDraftService.getDistributedStore(context);
    if (!store) return;
    const sanitized = PostDraftService.sanitizeDistributedDraft(draft);
    const record: DistributedDraftRecord = {
      userId: userId,
      updatedAt: draft.updatedAt,
      deleted: false,
      draft: sanitized
    };
    await store.put(PostDraftService.getDraftKey(userId), JSON.stringify(record));
  }

  private static async clearRemoteRecord(
    context: common.UIAbilityContext,
    userId: string,
    deletedAt: number
  ): Promise<void> {
    const store = await PostDraftService.getDistributedStore(context);
    if (!store) return;
    const record: DistributedDraftRecord = {
      userId: userId,
      updatedAt: deletedAt,
      deleted: true,
      draft: null
    };
    await store.put(PostDraftService.getDraftKey(userId), JSON.stringify(record));
  }

  private static async loadRemoteRecord(
    context: common.UIAbilityContext,
    userId: string
  ): Promise<DistributedDraftRecord | null> {
    try {
      const store = await PostDraftService.getDistributedStore(context);
      if (!store) return null;
      const value = await store.get(PostDraftService.getDraftKey(userId));
      if (typeof value !== 'string' || value.length === 0) {
        return null;
      }
      const parsed = JSON.parse(value) as DistributedDraftRecord;
      if (parsed.draft) {
        parsed.draft = PostDraftService.normalizeDraft(parsed.draft);
      }
      return parsed;
    } catch (e) {
      return null;
    }
  }

  private static async getDistributedStore(
    context: common.UIAbilityContext
  ): Promise<distributedKVStore.SingleKVStore | null> {
    if (PostDraftService.kvStore) {
      return PostDraftService.kvStore;
    }
    if (PostDraftService.kvStoreOpening) {
      return PostDraftService.kvStoreOpening;
    }

    PostDraftService.kvStoreOpening = PostDraftService.openDistributedStore(context);
    const store = await PostDraftService.kvStoreOpening;
    PostDraftService.kvStore = store;
    PostDraftService.kvStoreOpening = null;
    if (store) {
      PostDraftService.installStoreListener(store);
    }
    return store;
  }

  private static async openDistributedStore(
    context: common.UIAbilityContext
  ): Promise<distributedKVStore.SingleKVStore | null> {
    try {
      const granted = await PostDraftService.ensureSyncPermission(context);
      if (!granted) {
        console.warn('[PostDraftService] DISTRIBUTED_DATASYNC permission not granted');
        return null;
      }
      const config: distributedKVStore.KVManagerConfig = {
        bundleName: BUNDLE_NAME,
        context: context
      };
      const options: distributedKVStore.Options = {
        createIfMissing: true,
        encrypt: true,
        backup: false,
        autoSync: true,
        kvStoreType: distributedKVStore.KVStoreType.SINGLE_VERSION,
        securityLevel: distributedKVStore.SecurityLevel.S2
      };
      const manager = distributedKVStore.createKVManager(config);
      const store = await manager.getKVStore<distributedKVStore.SingleKVStore>(DISTRIBUTED_STORE_ID, options);
      return store;
    } catch (e) {
      console.warn('[PostDraftService] openDistributedStore failed:', JSON.stringify(e));
      return null;
    }
  }

  private static async ensureSyncPermission(context: common.UIAbilityContext): Promise<boolean> {
    if (PostDraftService.permissionGranted) {
      return true;
    }
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, SYNC_PERMISSIONS);
      const authResults = result.authResults || [];
      let granted = authResults.length > 0;
      for (const code of authResults) {
        if (code !== 0) {
          granted = false;
          break;
        }
      }
      PostDraftService.permissionGranted = granted;
      return granted;
    } catch (e) {
      console.warn('[PostDraftService] requestPermission failed:', JSON.stringify(e));
      return false;
    }
  }

  private static installStoreListener(store: distributedKVStore.SingleKVStore): void {
    if (PostDraftService.storeListenerInstalled) return;
    try {
      store.on(
        'dataChange',
        distributedKVStore.SubscribeType.SUBSCRIBE_TYPE_REMOTE,
        (data: distributedKVStore.ChangeNotification) => {
          PostDraftService.handleRemoteDataChange(data);
        }
      );
      PostDraftService.storeListenerInstalled = true;
    } catch (e) {
      console.warn('[PostDraftService] subscribe dataChange failed:', JSON.stringify(e));
    }
  }

  private static handleRemoteDataChange(data: distributedKVStore.ChangeNotification): void {
    try {
      const inserts = data.insertEntries || [];
      const updates = data.updateEntries || [];
      const merged: distributedKVStore.Entry[] = [];
      for (const e of inserts) merged.push(e);
      for (const e of updates) merged.push(e);

      for (const entry of merged) {
        if (!entry.key || entry.key.indexOf(KEY_DRAFT_PREFIX) !== 0) {
          continue;
        }
        const valueWrap = entry.value;
        if (!valueWrap || typeof valueWrap.value !== 'string') {
          continue;
        }
        const text = valueWrap.value as string;
        if (!text || text.length === 0) {
          continue;
        }
        let record: DistributedDraftRecord | null = null;
        try {
          record = JSON.parse(text) as DistributedDraftRecord;
        } catch (e) {
          continue;
        }
        if (!record) continue;
        if (record.draft) {
          record.draft = PostDraftService.normalizeDraft(record.draft);
        }
        PostDraftService.dispatchRemote(record);
      }
    } catch (e) {
      console.warn('[PostDraftService] handleRemoteDataChange error:', JSON.stringify(e));
    }
  }

  private static dispatchRemote(record: DistributedDraftRecord): void {
    const change: DraftRemoteChange = {
      userId: record.userId,
      updatedAt: record.updatedAt,
      deleted: record.deleted,
      draft: record.draft
    };
    const listeners = PostDraftService.remoteListeners.slice();
    for (const cb of listeners) {
      try {
        cb(change);
      } catch (e) {
        console.warn('[PostDraftService] listener threw:', JSON.stringify(e));
      }
    }
  }

  private static normalizeDraft(draft: PostDraftData): PostDraftData {
    const mediaList: MediaItem[] = [];
    const incomingMedia = draft.mediaList || [];
    for (const media of incomingMedia) {
      if (media && typeof media.url === 'string') {
        mediaList.push({ type: media.type === 'video' ? 'video' : 'image', url: media.url });
      }
    }
    return {
      title: draft.title || '',
      description: draft.description || '',
      category: draft.category || '',
      lostTime: draft.lostTime || 0,
      location: draft.location || '',
      contact: draft.contact || '',
      type: draft.type || 'found',
      imageUrl: draft.imageUrl || '',
      mediaList: mediaList,
      updatedAt: draft.updatedAt || 0
    };
  }

  private static sanitizeDistributedDraft(draft: PostDraftData): PostDraftData {
    const normalized = PostDraftService.normalizeDraft(draft);
    const remoteMedia: MediaItem[] = [];
    for (const media of normalized.mediaList) {
      if (media.url.indexOf('http://') === 0 || media.url.indexOf('https://') === 0) {
        remoteMedia.push({ type: media.type, url: media.url });
      }
    }
    const imageUrl = (normalized.imageUrl.indexOf('http://') === 0 || normalized.imageUrl.indexOf('https://') === 0)
      ? normalized.imageUrl
      : (remoteMedia.length > 0 ? remoteMedia[0].url : '');
    return {
      title: normalized.title,
      description: normalized.description,
      category: normalized.category,
      lostTime: normalized.lostTime,
      location: normalized.location,
      contact: normalized.contact,
      type: normalized.type,
      imageUrl: imageUrl,
      mediaList: remoteMedia,
      updatedAt: normalized.updatedAt
    };
  }
}
