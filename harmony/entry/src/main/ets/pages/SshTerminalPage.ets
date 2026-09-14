import { SshSession, SshState } from '../model/SshSession';
import { EngineManager } from '../engine/EngineManager';
import { Keys } from '../common/Constants';
import { SshTarget } from './PeerDetailPage';

/*
 * SSH terminal — the ArkUI equivalent of SSHTerminalFragment. The Android build
 * embeds xterm.js in a WebView; here the session's output buffer is rendered
 * natively in a monospace scrolling view with a command line and a row of keys
 * the soft keyboard lacks (arrows, Ctrl-C, tab, pipe). A real integration swaps
 * the buffer source for the native engine's PTY stream; the Web/xterm approach
 * can also be restored with the Web component loading the ported assets.
 */
@Component
export struct SshTerminalPage {
  @StorageLink(Keys.SSH_SESSIONS) sessions: SshSession[] = [];
  @State target: SshTarget = new SshTarget('', 22, '');
  @State input: string = '';
  @State localOutput: string = '';
  private scroller: Scroller = new Scroller();

  private session(): SshSession | null {
    for (let i = 0; i < this.sessions.length; i++) {
      const s: SshSession = this.sessions[i];
      if (s.host === this.target.host && s.user === this.target.user) {
        return s;
      }
    }
    return null;
  }

  private prompt(): string {
    return `${this.target.user}@${this.target.host}:~$ `;
  }

  private send(text: string): void {
    this.localOutput += `${this.prompt()}${text}\n`;
    if (text.trim().length > 0) {
      this.localOutput += `${text}: command acknowledged\n`;
    }
    this.input = '';
    this.scroller.scrollEdge(Edge.Bottom);
  }

  @Builder
  KeyCap(label: string, insert: string) {
    Text(label)
      .fontSize(13)
      .fontColor($r('app.color.nb_txt'))
      .backgroundColor('#2A2D33')
      .borderRadius(6)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .onClick(() => {
        this.input += insert;
      })
  }

  build() {
    NavDestination() {
      Column() {
        // Terminal output
        Scroll(this.scroller) {
          Column() {
            Text(this.session() !== null && this.session()!.output.length > 0
              ? this.session()!.output
              : this.localOutput + this.prompt())
              .fontSize(13)
              .fontFamily('monospace')
              .fontColor('#D6DEE8')
              .width('100%')
              .textAlign(TextAlign.Start)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#14161A')
        .padding(12)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)

        // Quick keys the soft keyboard lacks
        Row({ space: 8 }) {
          this.KeyCap('↑', '\u001B[A')
          this.KeyCap('↓', '\u001B[B')
          this.KeyCap('Tab', '\t')
          this.KeyCap('Ctrl-C', '\u0003')
          this.KeyCap('|', '|')
          this.KeyCap('~', '~')
          this.KeyCap('/', '/')
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor('#1B1E23')

        // Command line
        Row() {
          TextInput({ text: this.input, placeholder: "command" })
            .layoutWeight(1)
            .height(44)
            .backgroundColor('#22262C')
            .fontColor('#D6DEE8')
            .fontFamily('monospace')
            .placeholderColor('#5A616B')
            .onChange((v: string) => {
              this.input = v;
            })
            .onSubmit(() => this.send(this.input))
          Button('↵')
            .width(48)
            .height(44)
            .backgroundColor($r('app.color.nb_orange'))
            .fontColor($r('app.color.white'))
            .margin({ left: 8 })
            .onClick(() => this.send(this.input))
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 10 })
        .backgroundColor('#1B1E23')
      }
      .width('100%')
      .height('100%')
    }
    .title(this.target.host.length > 0 ? `${this.target.user}@${this.target.host}` : 'SSH Terminal')
    .backgroundColor('#14161A')
    .onReady((ctx: NavDestinationContext) => {
      const param = ctx.pathInfo.param as Object | undefined;
      if (param instanceof SshTarget) {
        this.target = param;
      }
    })
  }
}
