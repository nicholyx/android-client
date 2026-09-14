import { common } from '@kit.AbilityKit';
import { i18n } from '@kit.LocalizationKit';
import { promptAction } from '@kit.ArkUI';
import { SectionHeader, NavRow } from '../components/SettingRows';
import { EngineManager } from '../engine/EngineManager';
import { Urls } from '../common/Constants';
import { UrlOpener } from '../common/UrlOpener';
import { Routes, NavRouter } from '../common/NavRouter';
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
  @StorageLink('nb_active_profile_id') activeProfileId: string = '';
  @StorageLink('nb_profiles') profiles: Profile[] = [];
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
      promptAction.showToast({ message: `Language set to ${lang.label}` });
    } catch (err) {
      console.error(`[NetBird] setAppPreferredLanguage failed: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Scroll() {
      Column() {
        SectionHeader({ title: $r('app.string.settings_section_connection') })
        NavRow({
          title: $r('app.string.menu_profiles'),
          subtitle: this.activeProfileName(),
          onTap: () => NavRouter.push(Routes.PROFILES)
        })

        SectionHeader({ title: $r('app.string.settings_section_settings') })
        NavRow({ title: $r('app.string.menu_advanced'), onTap: () => NavRouter.push(Routes.ADVANCED) })
        NavRow({
          title: $r('app.string.menu_split_tunneling'),
          onTap: () => NavRouter.push(Routes.SPLIT_TUNNELING)
        })
        NavRow({
          title: $r('app.string.settings_language'),
          subtitle: this.currentLanguage,
          onTap: () => {
            this.languageSheet = true;
          }
        })

        SectionHeader({ title: $r('app.string.settings_section_information') })
        NavRow({ title: $r('app.string.menu_troubleshoot'), onTap: () => NavRouter.push(Routes.TROUBLESHOOT) })
        NavRow({ title: $r('app.string.menu_about'), onTap: () => NavRouter.push(Routes.ABOUT) })
        NavRow({
          title: $r('app.string.settings_documentation'),
          onTap: () => UrlOpener.open(getContext(this) as common.UIAbilityContext, Urls.DOCS)
        })

        Text('Version: 1.0.0')
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
