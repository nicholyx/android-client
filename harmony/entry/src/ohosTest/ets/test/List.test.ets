import engineTest from './Engine.test';
import uiTest from './Ui.test';

export default function testsuite() {
  engineTest();
  uiTest();
}
