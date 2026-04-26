export class UserInfo {
  public ID: string = '';            
  public studentNo: string = '';     
  public Name: string = '';          
  public Phone: string = '';         
  public Password: string = '';      
  public Published: number = 0;      
  public Claimed: number = 0;        
  public Avatar: string | null = null;
  public pushToken: string | null = null;
  public heartValue: number = 0;     
  public fraudCount: number = 0;     
}
