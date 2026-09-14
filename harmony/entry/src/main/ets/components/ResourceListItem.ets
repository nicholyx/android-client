import { Resource as NetResource } from '../model/Resource';
import { StatusDot } from './StatusDot';

/*
 * One row of the Resources (networks) list, mirroring list_item_resource.xml:
 * status dot, name, the route/domain address beneath it, an "exit node" badge
 * when the route covers all traffic, and a trailing switch bound to whether the
 * route is selected for routing.
 */
@Component
export struct ResourceListItem {
  @ObjectLink resource: NetResource;
  onToggle: (resource: NetResource, selected: boolean) => void = () => {};

  build() {
    Row() {
      StatusDot({ status: this.resource.status, dotSize: 9 })

      Column() {
        Row() {
          Text(this.resource.name)
            .fontSize(15)
            .fontColor($r('app.color.nb_txt'))
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.resource.isExitNode()) {
            Text($r('app.string.networks_desc_exit_node'))
              .fontSize(10)
              .fontColor($r('app.color.nb_orange'))
              .backgroundColor($r('app.color.nb_orange_15'))
              .borderRadius(6)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .margin({ left: 8 })
          }
        }
        .alignItems(VerticalAlign.Center)

        Text(this.resource.address)
          .fontSize(12)
          .fontColor($r('app.color.nb_txt_light'))
          .fontFamily('monospace')
          .margin({ top: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 12 })

      if (!this.resource.isExitNode()) {
        Toggle({ type: ToggleType.Switch, isOn: this.resource.isSelected })
          .selectedColor($r('app.color.nb_orange'))
          .onChange((value: boolean) => this.onToggle(this.resource, value))
      } else {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.nb_txt_light')])
      }
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.info_row_bg'))
  }
}
