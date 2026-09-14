import { EngineManager } from '../engine/EngineManager';
import { SplitTunnelConfig, SplitTunnelEntry } from '../model/Settings';
import { SplitTunnelMode, Keys } from '../common/Constants';

interface ModeOption {
  mode: SplitTunnelMode;
  title: Resource;
  description: Resource;
}

/*
 * Split tunneling — the ArkUI equivalent of SplitTunnelingFragment. A mode
 * selector (Off / Include / Exclude) above a searchable list of apps whose
 * routing follows the selected mode. HarmonyOS does not expose the full
 * installed-app list the way Android's launcher-intent query does, so entries
 * come from the stored config.
 */
@Component
export struct SplitTunnelingPage {
  @StorageLink(Keys.SPLIT_TUNNELING) config: SplitTunnelConfig = new SplitTunnelConfig();
  @State query: string = '';

  private modes: ModeOption[] = [
    { mode: SplitTunnelMode.OFF, title: $r('app.string.split_tunneling_mode_off'), description: $r('app.string.split_tunneling_mode_off_description') },
    { mode: SplitTunnelMode.INCLUDE, title: $r('app.string.split_tunneling_mode_include'), description: $r('app.string.split_tunneling_mode_include_description') },
    { mode: SplitTunnelMode.EXCLUDE, title: $r('app.string.split_tunneling_mode_exclude'), description: $r('app.string.split_tunneling_mode_exclude_description') }
  ];

  private filtered(): SplitTunnelEntry[] {
    const q: string = this.query.trim().toLowerCase();
    if (q.length === 0) {
      return this.config.entries;
    }
    return this.config.entries.filter((e: SplitTunnelEntry): boolean =>
      e.label.toLowerCase().includes(q) || e.bundleName.toLowerCase().includes(q));
  }

  private setMode(mode: SplitTunnelMode): void {
    this.config.mode = mode;
    EngineManager.getInstance().saveSplitTunneling(this.config);
  }

  private toggle(entry: SplitTunnelEntry, value: boolean): void {
    entry.selected = value;
    EngineManager.getInstance().saveSplitTunneling(this.config);
  }

  /* 本 SDK（5.0.1）的 NavDestination.title 不接受 Resource，用局部 @Builder
   * 渲染 $r 并显式给出 CustomTitle 必需的 height（此版 SDK 为必填字段）。 */
  @Builder
  DestTitle() {
    Text($r('app.string.menu_split_tunneling'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.split_tunneling_mode_title'))
          .fontSize(13)
          .fontColor($r('app.color.nb_txt_light'))
          .textCase(TextCase.UpperCase)
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 8 })

        Column({ space: 10 }) {
          ForEach(this.modes, (option: ModeOption) => {
            Row() {
              Radio({ value: option.mode, group: 'split-mode' })
                .checked(this.config.mode === option.mode)
                .radioStyle({ checkedBackgroundColor: $r('app.color.nb_orange') })
                .onChange((checked: boolean) => {
                  if (checked) {
                    this.setMode(option.mode);
                  }
                })
              Column() {
                Text(option.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.nb_txt'))
                Text(option.description)
                  .fontSize(12)
                  .fontColor($r('app.color.nb_txt_light'))
                  .margin({ top: 2 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 8 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor($r('app.color.info_row_bg'))
            .borderRadius(10)
            .border({ width: 1, color: this.config.mode === option.mode
              ? $r('app.color.nb_orange') : $r('app.color.info_row_stroke') })
            .onClick(() => this.setMode(option.mode))
          }, (option: ModeOption) => option.mode)
        }
        .width('90%')

        if (this.config.mode !== SplitTunnelMode.OFF) {
          Row() {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(16)
              .fontColor([$r('app.color.nb_txt_light')])
              .margin({ right: 8 })
            TextInput({ placeholder: 'Search apps', text: this.query })
              .placeholderColor($r('app.color.nb_txt_light'))
              .backgroundColor(Color.Transparent)
              .fontColor($r('app.color.nb_txt'))
              .layoutWeight(1)
              .height(40)
              .onChange((value: string) => {
                this.query = value;
              })
          }
          .width('90%')
          .padding({ left: 12, right: 12 })
          .backgroundColor($r('app.color.info_row_bg'))
          .borderRadius(10)
          .border({ width: 1, color: $r('app.color.info_row_stroke') })
          .margin({ top: 16 })

          List() {
            ForEach(this.filtered(), (entry: SplitTunnelEntry) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(entry.label)
                      .fontSize(15)
                      .fontColor($r('app.color.nb_txt'))
                    Text(entry.bundleName)
                      .fontSize(12)
                      .fontColor($r('app.color.nb_txt_light'))
                      .margin({ top: 2 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Toggle({ type: ToggleType.Switch, isOn: entry.selected })
                    .selectedColor($r('app.color.nb_orange'))
                    .onChange((value: boolean) => this.toggle(entry, value))
                }
                .width('100%')
                .constraintSize({ minHeight: 56 })
                .padding({ left: 20, right: 20 })
                .alignItems(VerticalAlign.Center)
              }
            }, (entry: SplitTunnelEntry) => entry.bundleName)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: $r('app.color.nb_gray_separator') })
          .margin({ top: 8 })
        } else {
          Text($r('app.string.split_tunneling_mode_off_description'))
            .fontSize(14)
            .fontColor($r('app.color.nb_txt_light'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ top: 24 })
        }
      }
      .width('100%')
      .height('100%')
    }
    .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
    .backgroundColor($r('app.color.nb_bg'))
  }
}
