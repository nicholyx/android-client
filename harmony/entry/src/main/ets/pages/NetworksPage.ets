import { Resource as NetResource } from '../model/Resource';
import { PeerStatus } from '../model/Status';
import { EngineManager } from '../engine/EngineManager';
import { Keys } from '../common/Constants';
import { ResourceListItem } from '../components/ResourceListItem';

/*
 * Resources screen — the ArkUI equivalent of NetworksFragment. A connected-count
 * header, a search field, and the list of shared resources; the switch on each
 * row selects or deselects that route through the engine. Exit nodes are shown
 * in their own section and picked from the home screen instead.
 */
@Component
export struct NetworksPage {
  @StorageLink(Keys.RESOURCES) resources: NetResource[] = [];
  @State query: string = '';

  private nonExitNodes(): NetResource[] {
    const q: string = this.query.trim().toLowerCase();
    const result = this.resources.filter((r: NetResource): boolean => {
      if (r.isExitNode()) {
        return false;
      }
      if (q.length === 0) {
        return true;
      }
      return r.name.toLowerCase().includes(q) || r.address.toLowerCase().includes(q);
    });
    // 对齐 Android NetworksAdapter.sort：按名称排序
    result.sort((r1: NetResource, r2: NetResource): number => {
      const n1: string = r1.name.toLowerCase();
      const n2: string = r2.name.toLowerCase();
      if (n1 < n2) {
        return -1;
      }
      if (n1 > n2) {
        return 1;
      }
      return 0;
    });
    return result;
  }

  private connectedCount(): number {
    return this.resources.filter((r: NetResource): boolean =>
      !r.isExitNode() && r.status === PeerStatus.CONNECTED).length;
  }

  private totalCount(): number {
    return this.resources.filter((r: NetResource): boolean => !r.isExitNode()).length;
  }

  build() {
    Column() {
      Row() {
        Text() {
          Span(`${this.connectedCount()}`)
          Span($r('app.string.count_of'))
          Span(`${this.totalCount()}`)
          Span($r('app.string.resources_connected_suffix'))
        }
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })

      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(16)
          .fontColor([$r('app.color.nb_txt_light')])
          .margin({ right: 8 })
        TextInput({ placeholder: 'Search resources', text: this.query })
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
      .margin({ bottom: 8 })

      if (this.totalCount() === 0) {
        Column() {
          Text('No resources shared with this peer yet')
            .fontSize(15)
            .fontColor($r('app.color.nb_txt_light'))
            .textAlign(TextAlign.Center)
            .width('70%')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.nonExitNodes(), (resource: NetResource) => {
            ListItem() {
              ResourceListItem({
                resource: resource,
                onToggle: (r: NetResource, selected: boolean) => {
                  if (selected) {
                    EngineManager.getInstance().selectRoute(r.address);
                  } else {
                    EngineManager.getInstance().deselectRoute(r.address);
                  }
                }
              })
            }
          }, (resource: NetResource) => resource.address + resource.name)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: $r('app.color.nb_gray_separator') })
        .padding({ bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg_peers'))
  }
}
