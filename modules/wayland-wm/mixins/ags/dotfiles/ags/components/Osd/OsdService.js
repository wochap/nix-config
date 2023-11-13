import Service from "resource:///com/github/Aylur/ags/service/service.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";

class OsdService extends Service {
  static {
    Service.register(this, {
      popup: ["double"],
    });
  }

  _delay = 1000;
  _count = 0;

  popup(value) {
    this.emit("popup", value);
    this._count++;

    Utils.timeout(this._delay, () => {
      this._count--;

      if (this._count === 0) {
        this.emit("popup", -1);
      }
    });
  }
}

const osdService = new OsdService();

export default osdService;