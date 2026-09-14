import { Profile } from '../model/Profile';
import { EngineManager } from '../engine/EngineManager';
import { Keys, Urls } from '../common/Constants';
import { promptAction } from '@kit.ArkUI';

/*
 * Profiles — the ArkUI equivalent of ProfilesFragment + ProfileEditorDialog.
 * A list of saved profiles with the active one badged, per-profile switch /
 * logout / remove actions, and an Add Profile sheet with the Cloud / Self-hosted
 * segmented control the desktop app uses.
 */
@Component
export struct ProfilesPage {
  @StorageLink(Keys.PROFILES) profiles: Profile[] = [];
  @StorageLink(Keys.ACTIVE_PROFILE_ID) activeProfileId: string = '';
  @State addSheet: boolean = false;
  @State newName: string = '';
  @State newIsCloud: boolean = true;
  @State newUrl: string = '';

  private resetForm(): void {
    this.newName = '';
    this.newIsCloud = true;
    this.newUrl = '';
  }

  private save(): void {
    const name: string = this.newName.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: 'Profile name cannot be empty' });
      return;
    }
    const url: string = this.newIsCloud ? Urls.CLOUD_MANAGEMENT : this.newUrl.trim();
    if (!this.newIsCloud && url.length === 0) {
      promptAction.showToast({ message: 'Please enter a valid URL' });
      return;
    }
    EngineManager.getInstance().addProfile(name, url, this.newIsCloud);
    this.addSheet = false;
    this.resetForm();
  }

  @Builder
  AddSheet() {
    Column() {
      Text($r('app.string.profiles_dialog_add_title'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.nb_txt'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding(16)

      Text($r('app.string.profiles_dialog_name_label'))
        .fontSize(13)
        .fontColor($r('app.color.nb_txt_light'))
        .width('90%')
      TextInput({ placeholder: 'e.g. Work', text: this.newName })
        .width('90%')
        .height(44)
        .backgroundColor($r('app.color.nb_gray_bg'))
        .fontColor($r('app.color.nb_txt'))
        .margin({ top: 6, bottom: 16 })
        .onChange((value: string) => {
          this.newName = value;
        })

      Text($r('app.string.profiles_dialog_server_label'))
        .fontSize(13)
        .fontColor($r('app.color.nb_txt_light'))
        .width('90%')
      Row() {
        Text($r('app.string.profiles_dialog_server_cloud'))
          .fontSize(14)
          .fontColor(this.newIsCloud ? $r('app.color.white') : $r('app.color.nb_txt'))
          .backgroundColor(this.newIsCloud ? $r('app.color.nb_orange') : Color.Transparent)
          .borderRadius(6)
          .padding({ top: 8, bottom: 8 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.newIsCloud = true;
          })
        Text($r('app.string.profiles_dialog_server_self_hosted'))
          .fontSize(14)
          .fontColor(!this.newIsCloud ? $r('app.color.white') : $r('app.color.nb_txt'))
          .backgroundColor(!this.newIsCloud ? $r('app.color.nb_orange') : Color.Transparent)
          .borderRadius(6)
          .padding({ top: 8, bottom: 8 })
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.newIsCloud = false;
          })
      }
      .width('90%')
      .padding(4)
      .backgroundColor($r('app.color.nb_segment_track'))
      .borderRadius(8)
      .margin({ top: 6 })

      if (!this.newIsCloud) {
        TextInput({ placeholder: 'https://netbird.selfhosted.com:443', text: this.newUrl })
          .width('90%')
          .height(44)
          .backgroundColor($r('app.color.nb_gray_bg'))
          .fontColor($r('app.color.nb_txt'))
          .margin({ top: 12 })
          .onChange((value: string) => {
            this.newUrl = value;
          })
      }

      Button($r('app.string.advanced_save'))
        .width('90%')
        .height(48)
        .backgroundColor($r('app.color.nb_orange'))
        .fontColor($r('app.color.white'))
        .margin({ top: 24, bottom: 24 })
        .onClick(() => this.save())
    }
    .width('100%')
    .backgroundColor($r('app.color.nb_sheet_bg'))
  }

  /* 本 SDK（5.0.1）的 NavDestination.title 不接受 Resource，用局部 @Builder
   * 渲染 $r 并显式给出 CustomTitle 必需的 height（此版 SDK 为必填字段）。 */
  @Builder
  DestTitle() {
    Text($r('app.string.menu_profiles'))
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor($r('app.color.nb_txt'))
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        List() {
          ForEach(this.profiles, (profile: Profile) => {
            ListItem() {
              Column() {
                Row() {
                  Text(profile.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.nb_txt'))
                    .layoutWeight(1)
                  if (profile.id === this.activeProfileId) {
                    Text($r('app.string.profiles_active'))
                      .fontSize(11)
                      .fontColor($r('app.color.nb_orange'))
                      .backgroundColor($r('app.color.nb_orange_15'))
                      .borderRadius(6)
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  }
                }
                .width('100%')

                Text(profile.isCloud ? 'NetBird Cloud' : profile.serverUrl)
                  .fontSize(13)
                  .fontColor($r('app.color.nb_txt_light'))
                  .width('100%')
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                if (profile.email.length > 0) {
                  Text(profile.email)
                    .fontSize(12)
                    .fontColor($r('app.color.nb_txt_light'))
                    .width('100%')
                    .margin({ top: 2 })
                }

                Row({ space: 16 }) {
                  if (profile.id !== this.activeProfileId) {
                    Text($r('app.string.profiles_switch'))
                      .fontSize(14)
                      .fontColor($r('app.color.nb_orange'))
                      .onClick(() => {
                        // 三处操作都带确认，对齐 Android ProfilesFragment.createDialog。
                        AlertDialog.show({
                          message: $r('app.string.profiles_switch_confirm'),
                          primaryButton: {
                            value: $r('app.string.action_cancel'),
                            action: () => {}
                          },
                          secondaryButton: {
                            value: $r('app.string.profiles_switch'),
                            action: () => EngineManager.getInstance().switchProfile(profile.id)
                          }
                        });
                      })
                  }
                  Text($r('app.string.profiles_logout'))
                    .fontSize(14)
                    .fontColor($r('app.color.nb_txt_light'))
                    .onClick(() => {
                      AlertDialog.show({
                        message: $r('app.string.profiles_logout_confirm'),
                        primaryButton: {
                          value: $r('app.string.action_cancel'),
                          action: () => {}
                        },
                        secondaryButton: {
                          value: $r('app.string.profiles_logout'),
                          action: () => EngineManager.getInstance().logoutProfile(profile.id)
                        }
                      });
                    })
                  if (profile.id !== 'default') {
                    Text($r('app.string.profiles_remove'))
                      .fontSize(14)
                      .fontColor($r('app.color.nb_danger'))
                      .onClick(() => {
                        AlertDialog.show({
                          message: $r('app.string.profiles_remove_confirm'),
                          primaryButton: {
                            value: $r('app.string.action_cancel'),
                            action: () => {}
                          },
                          secondaryButton: {
                            value: $r('app.string.action_delete'),
                            fontColor: $r('app.color.nb_danger'),
                            action: () => EngineManager.getInstance().removeProfile(profile.id)
                          }
                        });
                      })
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.End)
                .margin({ top: 12 })
              }
              .width('90%')
              .padding(16)
              .backgroundColor($r('app.color.profile_card_background'))
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.info_row_stroke') })
              .margin({ bottom: 12 })
            }
            .width('100%')
          }, (profile: Profile) => profile.id)

          ListItem() {
            Row().height(88)
          }
        }
        .width('100%')
        .height('100%')
        .padding({ top: 12 })
        .alignListItem(ListItemAlign.Center)

        Button($r('app.string.profiles_add'))
          .width(160)
          .height(48)
          .backgroundColor($r('app.color.nb_orange'))
          .fontColor($r('app.color.white'))
          .margin({ right: 20, bottom: 24 })
          .onClick(() => {
            this.resetForm();
            this.addSheet = true;
          })
      }
      .width('100%')
      .height('100%')
    }
    .title({ builder: this.DestTitle, height: TitleHeight.MainOnly })
    .backgroundColor($r('app.color.profile_background'))
    .bindSheet(this.addSheet, this.AddSheet(), {
      height: SheetSize.FIT_CONTENT,
      showClose: true,
      onDisappear: () => {
        this.addSheet = false;
      }
    })
  }
}
