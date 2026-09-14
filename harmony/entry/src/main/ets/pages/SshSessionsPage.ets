import { SshSession, SshState } from '../model/SshSession';
import { EngineManager } from '../engine/EngineManager';
import { Keys } from '../common/Constants';
import { StatusDot } from '../components/StatusDot';
import { PeerStatus } from '../model/Status';
import { Routes, NavRouter } from '../common/NavRouter';
import { SshTarget } from './PeerDetailPage';
import { promptAction } from '@kit.ArkUI';

/*
 * SSH sessions — the ArkUI equivalent of SshSessionsFragment. A list of open
 * sessions with their state and a delete action, plus a "+" that opens the new
 * connection form (host, port, user, password). Tapping a session opens the
 * terminal.
 */
@Component
export struct SshSessionsPage {
  @StorageLink(Keys.SSH_SESSIONS) sessions: SshSession[] = [];
  @State newSheet: boolean = false;
  @State host: string = '';
  @State port: string = '22';
  @State user: string = '';
  @State password: string = '';

  private resetForm(): void {
    this.host = '';
    this.port = '22';
    this.user = '';
    this.password = '';
  }

  private connect(): void {
    if (this.host.trim().length === 0) {
      promptAction.showToast({ message: 'Enter a host' });
      return;
    }
    if (this.user.trim().length === 0) {
      promptAction.showToast({ message: 'Enter a username' });
      return;
    }
    const portNum: number = Number.parseInt(this.port, 10);
    if (Number.isNaN(portNum) || portNum < 1 || portNum > 65535) {
      promptAction.showToast({ message: 'Enter a port between 1 and 65535' });
      return;
    }
    EngineManager.getInstance().addSshSession(this.host.trim(), portNum, this.user.trim(), this.password);
    this.newSheet = false;
    this.resetForm();
  }

  private stateDot(s: SshSession): PeerStatus {
    if (s.state === SshState.CONNECTED) {
      return PeerStatus.CONNECTED;
    }
    if (s.state === SshState.CONNECTING || s.state === SshState.PASSWORD_REQUIRED) {
      return PeerStatus.CONNECTING;
    }
    return PeerStatus.IDLE;
  }

  @Builder
  NewSheet() {
    Column() {
      Text($r('app.string.ssh_new_connection_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(16)

      TextInput({ placeholder: 'Host (IP or FQDN)', text: this.host })
        .width('90%').height(44).backgroundColor($r('app.color.nb_gray_bg'))
        .fontColor($r('app.color.nb_txt')).margin({ bottom: 12 })
        .onChange((v: string) => { this.host = v; })

      Row({ space: 12 }) {
        TextInput({ placeholder: 'Username', text: this.user })
          .layoutWeight(1).height(44).backgroundColor($r('app.color.nb_gray_bg'))
          .fontColor($r('app.color.nb_txt'))
          .onChange((v: string) => { this.user = v; })
        TextInput({ placeholder: '22', text: this.port })
          .width(90).height(44).backgroundColor($r('app.color.nb_gray_bg'))
          .fontColor($r('app.color.nb_txt')).type(InputType.Number)
          .onChange((v: string) => { this.port = v; })
      }
      .width('90%')
      .margin({ bottom: 12 })

      TextInput({ placeholder: 'Password', text: this.password })
        .width('90%').height(44).backgroundColor($r('app.color.nb_gray_bg'))
        .fontColor($r('app.color.nb_txt')).type(InputType.Password)
        .margin({ bottom: 20 })
        .onChange((v: string) => { this.password = v; })

      Button($r('app.string.ssh_dialog_connect'))
        .width('90%').height(48)
        .backgroundColor($r('app.color.nb_orange'))
        .fontColor($r('app.color.white'))
        .margin({ bottom: 24 })
        .onClick(() => this.connect())
    }
    .width('100%')
    .backgroundColor($r('app.color.nb_sheet_bg'))
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Text($r('app.string.ssh_sessions_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.nb_txt'))
          .width('100%')
          .padding({ left: 20, top: 16, bottom: 12 })

        if (this.sessions.length === 0) {
          Column() {
            Text($r('app.string.ssh_sessions_empty'))
              .fontSize(15)
              .fontColor($r('app.color.nb_txt_light'))
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.sessions, (session: SshSession) => {
              ListItem() {
                Row() {
                  StatusDot({ status: this.stateDot(session), size: 9 })
                  Column() {
                    Text(session.title)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.nb_txt'))
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(SshSession.stateLabel(session.state))
                      .fontSize(12)
                      .fontColor($r('app.color.nb_txt_light'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 12 })

                  SymbolGlyph($r('sys.symbol.trash'))
                    .fontSize(18)
                    .fontColor([$r('app.color.nb_danger')])
                    .padding(8)
                    .onClick(() => EngineManager.getInstance().removeSshSession(session.id))
                }
                .width('100%')
                .constraintSize({ minHeight: 60 })
                .padding({ left: 20, right: 16 })
                .alignItems(VerticalAlign.Center)
                .backgroundColor($r('app.color.info_row_bg'))
                .onClick(() => NavRouter.push(Routes.SSH_TERMINAL,
                  new SshTarget(session.host, session.port, session.user)))
              }
            }, (session: SshSession) => session.id)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: $r('app.color.nb_gray_separator') })
        }
      }
      .width('100%')
      .height('100%')

      Button('+')
        .width(56)
        .height(56)
        .fontSize(28)
        .type(ButtonType.Circle)
        .backgroundColor($r('app.color.nb_orange'))
        .fontColor($r('app.color.white'))
        .margin({ right: 20, bottom: 24 })
        .onClick(() => {
          this.resetForm();
          this.newSheet = true;
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg_peers'))
    .bindSheet(this.newSheet, this.NewSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: true,
      onDisappear: () => {
        this.newSheet = false;
      }
    })
  }
}
