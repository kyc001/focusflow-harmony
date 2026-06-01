import connection from '@ohos.net.connection';

type NetworkChangeHandler = (online: boolean, message: string) => void;

export class FocusNetworkService {
  private netConnection?: connection.NetConnection;
  private online: boolean = true;
  private message: string = '网络状态检测中';
  private handler?: NetworkChangeHandler;

  async start(handler: NetworkChangeHandler): Promise<void> {
    this.handler = handler;
    await this.refreshCurrentState();
    this.emit();
    if (this.netConnection !== undefined) {
      return;
    }
    try {
      this.netConnection = connection.createNetConnection(undefined, 5000);
      this.netConnection.on('netAvailable', () => {
        this.online = true;
        this.message = '网络可用，可以登录或同步';
        this.emit();
      });
      this.netConnection.on('netLost', () => {
        this.online = false;
        this.message = '网络已断开，同步入口已暂停';
        this.emit();
      });
      this.netConnection.on('netUnavailable', () => {
        this.online = false;
        this.message = '暂无可用网络，同步入口已暂停';
        this.emit();
      });
      this.netConnection.register((err: Error) => {
        if (err !== undefined) {
          this.online = true;
          this.message = '网络监听不可用，仍允许手动同步';
          this.emit();
        }
      });
    } catch (err) {
      this.online = true;
      this.message = '网络监听不可用，仍允许手动同步';
      this.emit();
    }
  }

  stop(): void {
    if (this.netConnection === undefined) {
      return;
    }
    try {
      this.netConnection.unregister(() => {
      });
    } catch (err) {
    }
    this.netConnection = undefined;
    this.handler = undefined;
  }

  isOnline(): boolean {
    return this.online;
  }

  statusText(): string {
    return this.message;
  }

  private async refreshCurrentState(): Promise<void> {
    try {
      this.online = await connection.hasDefaultNet();
      this.message = this.online ? '网络可用，可以登录或同步' : '暂无可用网络，同步入口已暂停';
    } catch (err) {
      this.online = true;
      this.message = '网络状态未知，仍允许手动同步';
    }
  }

  private emit(): void {
    if (this.handler !== undefined) {
      this.handler(this.online, this.message);
    }
  }
}

export const focusNetworkService: FocusNetworkService = new FocusNetworkService();
