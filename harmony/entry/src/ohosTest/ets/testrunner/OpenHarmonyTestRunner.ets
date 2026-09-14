import { hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityDelegatorRegistry, TestRunner } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'testTag';

function onAbilityCreateCallback(): void {
  hilog.info(DOMAIN, TAG, '%{public}s', 'onAbilityCreateCallback');
}

function addAbilityMonitorCallback(err: BusinessError): void {
  hilog.info(DOMAIN, TAG, 'addAbilityMonitorCallback : %{public}s', JSON.stringify(err) ?? '');
}

/*
 * The HarmonyOS test runner. Registers a monitor for TestAbility and starts it
 * under the delegator so Hypium can drive the instrumented suites. Kept to the
 * essential start-up path (no rawfile/mock dependency) so it cannot fail on a
 * missing optional resource.
 */
export default class OpenHarmonyTestRunner implements TestRunner {
  constructor() {
  }

  onPrepare(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'OpenHarmonyTestRunner OnPrepare');
  }

  async onRun(): Promise<void> {
    hilog.info(DOMAIN, TAG, '%{public}s', 'OpenHarmonyTestRunner onRun');
    const args: AbilityDelegatorRegistry.AbilityDelegatorArgs = AbilityDelegatorRegistry.getArguments();
    const delegator: AbilityDelegatorRegistry.AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    const moduleName: string = args.parameters['-m'];
    const testAbilityName: string = 'TestAbility';

    const monitor: AbilityDelegatorRegistry.AbilityMonitor = {
      abilityName: testAbilityName,
      onAbilityCreate: onAbilityCreateCallback,
      moduleName: moduleName
    };
    delegator.addAbilityMonitor(monitor, addAbilityMonitorCallback);

    const want: Want = {
      bundleName: args.bundleName,
      abilityName: testAbilityName,
      moduleName: moduleName
    };
    delegator.startAbility(want, (err: BusinessError) => {
      hilog.info(DOMAIN, TAG, 'startAbility result : %{public}s', JSON.stringify(err) ?? 'ok');
    });
    hilog.info(DOMAIN, TAG, '%{public}s', 'OpenHarmonyTestRunner onRun end');
  }
}
