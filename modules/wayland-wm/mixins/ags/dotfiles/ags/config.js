import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import { Osd, OsdService } from "./components/Osd/index.js";

globalThis.OsdService = OsdService;

const tmp = "/tmp/ags/scss";
Utils.ensureDirectory(tmp);
Utils.exec(`sassc ${App.configDir}/main.scss ${tmp}/style.css`);
App.resetCss();
App.applyCss(`${tmp}/style.css`);

export default {
  cacheNotificationActions: false,
  closeWindowDelay: {},
  maxStreamVolume: 1,
  windows: [Osd],
};
