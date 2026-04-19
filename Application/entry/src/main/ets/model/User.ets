// 用户基础信息（对应后端 User 表）
// 保留旧字段名 ID/Name/Avatar/… 以便现有页面最少改动，按后端 JSON 映射时在 service 里做转换。

export class UserInfo {
  public ID: string = '';            // userId 的字符串形式（对应后端 user.id）
  public studentNo: string = '';     // 学号
  public Name: string = '';          // 昵称
  public Phone: string = '';         // 手机号（可能为掩码）
  public Password: string = '';      // 前端一般不会持有，保留兼容
  public Published: number = 0;      // 发布数
  public Claimed: number = 0;        // 认领数
  public Avatar: string | null = null;
  public pushToken: string | null = null;
  public heartValue: number = 0;     // 热心值
  public fraudCount: number = 0;     // 冒领值
}
