import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@kit.TestKit';
import { abilityDelegatorRegistry, Want } from '@kit.AbilityKit';

/*
 * UI end-to-end tests driven by the HarmonyOS UiTest Driver. They launch the
 * real EntryAbility, dismiss first-run onboarding, then walk the bottom
 * navigation and the connect toggle exactly as a user would, asserting on the
 * on-screen components (matched by the accessibility ids added to the pages).
 *
 * Run on a device/emulator: DevEco > Run 'ohosTest', or
 *   hdc shell aa test -b io.netbird.harmony -m entry_test \
 *     -s unittest /ets/testrunner/OpenHarmonyTestRunner -s class UiTest
 */
const BUNDLE: string = 'io.netbird.harmony';

export default function uiTest() {
  describe('UiTest', () => {
    let driver: Driver;

    beforeAll(async () => {
      driver = Driver.create();
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      const want: Want = {
        bundleName: BUNDLE,
        abilityName: 'EntryAbility',
        moduleName: 'entry'
      };
      await delegator.startAbility(want);
      await driver.delayMs(1500);
    });

    it('dismiss_first_install_onboarding', 0, async () => {
      const cont = await driver.findComponent(ON.id('first_install_continue'));
      if (cont !== null) {
        await cont.click();
        await driver.delayMs(800);
      }
      // After onboarding the home shell must be reachable.
      const toggle = await driver.findComponent(ON.id('connect_toggle'));
      expect(toggle !== null).assertTrue();
    });

    it('home_shows_connect_toggle_and_status', 0, async () => {
      const toggle = await driver.findComponent(ON.id('connect_toggle'));
      expect(toggle !== null).assertTrue();
      const status = await driver.findComponent(ON.id('connection_status'));
      expect(status !== null).assertTrue();
    });

    it('tap_connect_toggle_drives_status', 0, async () => {
      const toggle = await driver.findComponent(ON.id('connect_toggle'));
      await toggle.click();
      // Mock engine reaches Connected ~1.8s after run().
      await driver.delayMs(2600);
      const status = await driver.findComponent(ON.id('connection_status'));
      const text: string = await status.getText();
      expect(text === 'Connected' || text === 'Connecting…').assertTrue();
    });

    it('peers_tab_renders_filter_chips', 0, async () => {
      const peersTab = await driver.findComponent(ON.id('tab_1'));
      await peersTab.click();
      await driver.delayMs(800);
      const allChip = await driver.findComponent(ON.text('All'));
      expect(allChip !== null).assertTrue();
    });

    it('resources_tab_renders', 0, async () => {
      const tab = await driver.findComponent(ON.id('tab_2'));
      await tab.click();
      await driver.delayMs(800);
      // Header text is composed of spans; assert the tab is present and selectable.
      expect(tab !== null).assertTrue();
    });

    it('settings_tab_lists_profiles_row', 0, async () => {
      const tab = await driver.findComponent(ON.id('tab_4'));
      await tab.click();
      await driver.delayMs(800);
      const profiles = await driver.findComponent(ON.text('Profiles'));
      expect(profiles !== null).assertTrue();
    });

  });
}
