import { Routes, NavRouter } from '../common/NavRouter';
import { Keys } from '../common/Constants';
import { EngineManager } from '../engine/EngineManager';

import { HomePage } from './HomePage';
import { PeersPage } from './PeersPage';
import { NetworksPage } from './NetworksPage';
import { SshSessionsPage } from './SshSessionsPage';
import { SettingsPage } from './SettingsPage';

import { PeerDetailPage } from './PeerDetailPage';
import { AdvancedPage } from './AdvancedPage';
import { SplitTunnelingPage } from './SplitTunnelingPage';
import { TroubleshootPage } from './TroubleshootPage';
import { AboutPage } from './AboutPage';
import { ProfilesPage } from './ProfilesPage';
import { FirstInstallPage } from './FirstInstallPage';
import { SshTerminalPage } from './SshTerminalPage';

interface TabSpec {
  title: Resource;
  symbol: Resource;
  activeSymbol: Resource;
}

/*
 * Application shell. Replaces the Android MainActivity: a single Navigation
 * hosts the five top-level tabs (Home, Peers, Resources, SSH, Settings) through
 * a Tabs component with a custom bottom bar, and pushes the sub-screens onto the
 * NavPathStack via the PageMap route table. First-run onboarding overlays the
 * whole shell until the user commits to a server.
 */
@Entry
@Component
struct Index {
  @Provide('navStack') navStack: NavPathStack = new NavPathStack();
  @StorageProp(Keys.FIRST_LAUNCH) firstLaunch: boolean = true;
  @State currentIndex: number = 0;

  private tabs: TabSpec[] = [
    { title: $r('app.string.bottom_nav_home'), symbol: $r('sys.symbol.house'), activeSymbol: $r('sys.symbol.house_fill') },
    { title: $r('app.string.bottom_nav_peers'), symbol: $r('sys.symbol.person'), activeSymbol: $r('sys.symbol.person_fill') },
    { title: $r('app.string.bottom_nav_networks'), symbol: $r('sys.symbol.externaldrive'), activeSymbol: $r('sys.symbol.externaldrive') },
    { title: $r('app.string.bottom_nav_ssh'), symbol: $r('sys.symbol.list_bullet'), activeSymbol: $r('sys.symbol.list_bullet') },
    { title: $r('app.string.bottom_nav_settings'), symbol: $r('sys.symbol.gearshape'), activeSymbol: $r('sys.symbol.gearshape_fill') }
  ];

  aboutToAppear(): void {
    NavRouter.bind(this.navStack);
    EngineManager.getInstance().init();
  }

  @Builder
  TabBarBuilder(index: number) {
    Column({ space: 4 }) {
      SymbolGlyph(this.currentIndex === index ? this.tabs[index].activeSymbol : this.tabs[index].symbol)
        .fontSize(22)
        .fontColor([this.currentIndex === index
          ? $r('app.color.tab_selected')
          : $r('app.color.tab_icon_unselected')])
      Text(this.tabs[index].title)
        .fontSize(10)
        .fontColor(this.currentIndex === index
          ? $r('app.color.tab_selected')
          : $r('app.color.tab_unselected'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .id('tab_' + index)
  }

  @Builder
  PageMap(name: string) {
    if (name === Routes.PEER_DETAIL) {
      PeerDetailPage()
    } else if (name === Routes.ADVANCED) {
      AdvancedPage()
    } else if (name === Routes.SPLIT_TUNNELING) {
      SplitTunnelingPage()
    } else if (name === Routes.TROUBLESHOOT) {
      TroubleshootPage()
    } else if (name === Routes.ABOUT) {
      AboutPage()
    } else if (name === Routes.PROFILES) {
      ProfilesPage()
    } else if (name === Routes.SSH_TERMINAL) {
      SshTerminalPage()
    }
  }

  build() {
    Stack() {
      Navigation(this.navStack) {
        Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
          TabContent() {
            HomePage()
          }
          .tabBar(this.TabBarBuilder(0))

          TabContent() {
            PeersPage()
          }
          .tabBar(this.TabBarBuilder(1))

          TabContent() {
            NetworksPage()
          }
          .tabBar(this.TabBarBuilder(2))

          TabContent() {
            SshSessionsPage()
          }
          .tabBar(this.TabBarBuilder(3))

          TabContent() {
            SettingsPage()
          }
          .tabBar(this.TabBarBuilder(4))
        }
        .scrollable(false)
        .barHeight(60)
        .barBackgroundColor($r('app.color.nb_bottom_nav_bg'))
        .onChange((index: number) => {
          this.currentIndex = index;
        })
      }
      .hideTitleBar(true)
      .mode(NavigationMode.Stack)
      .navDestination(this.PageMap)
      .backgroundColor($r('app.color.nb_bg'))

      if (this.firstLaunch) {
        FirstInstallPage()
      }
    }
    .width('100%')
    .height('100%')
  }
}
