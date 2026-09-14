import { bundleManager, common } from '@kit.AbilityKit';
import { i18n } from '@kit.LocalizationKit';
import { promptAction } from '@kit.ArkUI';
import { SectionHeader, NavRow } from '../components/SettingRows';
import { Keys } from '../common/Constants';
import { EngineManager } from '../engine/EngineManager';
import { Urls } from '../common/Constants';
import { UrlOpener } from '../common/UrlOpener';
import { Routes, AppNav } from '../common/NavRouter';
import { Profile } from '../model/Profile';

interface LanguageOption {
  label: string;
  code: string;
}

/*
 * Settings screen — the ArkUI equivalent of SettingsFragment. Grouped rows for
 * Connection (Profiles, Management Server), Settings (Advanced, Split tunneling,
 * Display Language) and Information (Troubleshoot, About, Documentation), with
 * the app version pinned at the bottom.
 */
@Component
export struct SettingsPage {
  @StorageLink(Keys.ACTIVE_PROFILE_ID) activeProfileId: string = '';
  @StorageLink(Keys.PROFILES) profiles: Profile[] = [];
  @State languageSheet: boolean = false;
  @State currentLanguage: string = 'System default';

  private languages: LanguageOption[] = [
    { label: 'System default', code: '' },
    { label: 'English', code: 'en' },
    { label: '简体中文', code: 'zh-Hans' },
    { label: 'Deutsch', code: 'de' },
    { label: 'Español', code: 'es' },
    { label: 'Français', code: 'fr' },
    { label: '日本語', code: 'ja' }
  ];

  private activeProfileName(): string {
    const active: Profile | null = EngineManager.getInstance().activeProfile();
    return active !== null ? active.name : '';
  }

  @Builder
  LanguageSheet() {
    Column() {
      Text($r('app.string.settings_language'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(16)
      ForEach(this.languages, (lang: LanguageOption) => {
        Row() {
          Text(lang.label)
            .fontSize(15)
            .fontColor($r('app.color.nb_txt'))
            .layoutWeight(1)
          if (this.currentLanguage === lang.label) {
            SymbolGlyph($r('sys.symbol.checkmark'))
              .fontSize(18)
              .fontColor([$r('app.color.nb_orange')])
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 14, bottom: 14 })
        .onClick(() => {
          this.applyLanguage(lang);
          this.languageSheet = false;
        })
      }, (lang: LanguageOption) => lang.code)
    }
    .width('100%')
    .padding({ bottom: 20 })
    .backgroundColor($r('app.color.nb_sheet_bg'))
  }

  private applyLanguage(lang: LanguageOption): void {
    this.currentLanguage = lang.label;
    try {
      i18n.System.setAppPreferredLanguage(lang.code);
            const langPrefix: string =
        getContext(this).resourceManager.getStringSync($r('app.string.settings_language_set').id);
      promptAction.showToast({ message: `${langPrefix} ${lang.label}` });
    } catch (err) {
      console.error(`[NetBird] setAppPreferredLanguage failed: ${JSON.stringify(err)}`);
    }
  }

  private versionLabel(): string {
    try {
      const info: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const prefix: string =
        getContext(this).resourceManager.getStringSync($r('app.string.about_version').id);
      return `${prefix}${info.versionName}`;
    } catch (err) {
      console.error(`[NetBird] read version failed: ${JSON.stringify(err)}`);
      return '';
    }
  }

  build() {
    Scroll() {
      Column() {
        SectionHeader({ title: $r('app.string.settings_section_connection') })
        NavRow({
          title: $r('app.string.menu_profiles'),
          subtitle: this.activeProfileName(),
          onTap: () => AppNav.push(Routes.PROFILES)
        })
        // Android 的 Change Server 打开服务器选择；harmony 侧该能力由
        // Profiles / FirstInstall 承担，真实管理面切换随登录体系（#12）落地。
        NavRow({
          title: $r('app.string.menu_change_server'),
          onTap: () => AppNav.push(Routes.PROFILES)
        })

        SectionHeader({ title: $r('app.string.settings_section_settings') })
        NavRow({ title: $r('app.string.menu_advanced'), onTap: () => AppNav.push(Routes.ADVANCED) })
        NavRow({
          title: $r('app.string.menu_split_tunneling'),
          onTap: () => AppNav.push(Routes.SPLIT_TUNNELING)
        })
        NavRow({
          title: $r('app.string.settings_language'),
          subtitle: this.currentLanguage,
          onTap: () => {
            this.languageSheet = true;
          }
        })

        SectionHeader({ title: $r('app.string.settings_section_information') })
        NavRow({ title: $r('app.string.menu_troubleshoot'), onTap: () => AppNav.push(Routes.TROUBLESHOOT) })
        NavRow({ title: $r('app.string.menu_about'), onTap: () => AppNav.push(Routes.ABOUT) })
        NavRow({
          title: $r('app.string.settings_documentation'),
          onTap: () => UrlOpener.open(getContext(this) as common.UIAbilityContext, Urls.DOCS)
        })

        Text(this.versionLabel())
          .fontSize(13)
          .fontColor($r('app.color.nb_txt_light'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 32, bottom: 24 })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.nb_bg'))
    .scrollBar(BarState.Off)
    .bindSheet(this.languageSheet, this.LanguageSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: true,
      onDisappear: () => {
        this.languageSheet = false;
      }
    })
  }
}
