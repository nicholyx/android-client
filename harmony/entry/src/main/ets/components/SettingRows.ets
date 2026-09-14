/*
 * Reusable settings/list rows: an uppercase section header, a tappable row with
 * an optional value and chevron, and a row with a trailing Toggle. These mirror
 * the list_item_setting_* layouts on Android so the Settings, Advanced,
 * Troubleshoot and Split-tunneling screens share one visual language.
 */

@Component
export struct SectionHeader {
  @Prop title: ResourceStr = '';

  build() {
    Text(this.title)
      .fontSize(13)
      .fontColor($r('app.color.nb_txt_light'))
      .textCase(TextCase.UpperCase)
      .letterSpacing(0.5)
      .width('100%')
      .padding({ left: 20, right: 20, top: 24, bottom: 8 })
  }
}

@Component
export struct NavRow {
  @Prop title: ResourceStr = '';
  @Prop subtitle: string = '';
  @Prop showChevron: boolean = true;
  @Prop danger: boolean = false;
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontColor(this.danger ? $r('app.color.nb_danger') : $r('app.color.nb_txt'))
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(13)
              .fontColor($r('app.color.nb_txt_light'))
              .margin({ top: 4 })
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.showChevron) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(16)
            .fontColor([$r('app.color.nb_txt_light')])
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.info_row_bg'))
    .onClick(() => this.onTap())
  }
}

@Component
export struct ToggleRow {
  @Prop title: ResourceStr = '';
  @Prop subtitle: string = '';
  @Link isOn: boolean;
  onToggle: (value: boolean) => void = () => {};

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.title)
            .fontSize(16)
            .fontColor($r('app.color.nb_txt'))
          if (this.subtitle.length > 0) {
            Text(this.subtitle)
              .fontSize(13)
              .fontColor($r('app.color.nb_txt_light'))
              .margin({ top: 4 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .selectedColor($r('app.color.nb_orange'))
          .onChange((value: boolean) => {
            this.isOn = value;
            this.onToggle(value);
          })
      }
      .width('100%')
      .constraintSize({ minHeight: 56 })
      .padding({ left: 20, right: 20, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor($r('app.color.info_row_bg'))
  }
}
