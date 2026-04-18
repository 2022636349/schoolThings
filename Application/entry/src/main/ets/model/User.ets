// entry/src/main/ets/model/User.ets
import { cloudDatabase } from '@kit.CloudFoundationKit';

export class UserInfo extends cloudDatabase.DatabaseObject {
  public ID: string;
  public Name: string;
  public Phone: string;
  public Password: string;
  public Published: number;
  public Claimed: number;
  public Avatar: string | null;
  public pushToken: string | null;
  public heartValue: number;    // 热心值
  public fraudCount: number;    // 冒领值

  public naturalbase_ClassName(): string {
    return 'UserInfo';
  }

  constructor() {
    super();
    this.ID = '';
    this.Name = '';
    this.Phone = '';
    this.Password = '';
    this.Published = 0;
    this.Claimed = 0;
    this.Avatar = null;
    this.pushToken = null;
    this.heartValue = 0;
    this.fraudCount = 0;
  }
}
