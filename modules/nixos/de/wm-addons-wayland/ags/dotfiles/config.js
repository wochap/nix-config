const audio = await Service.import("audio");
const battery = await Service.import("battery");
const systemtray = await Service.import("systemtray");
const bluetooth = await Service.import("bluetooth");

const spacing = 7;

const appIds = ["kitty", "slack", "thunar-scratch", "thunar"];
const activeAppId = "slack";
const taskbar = Widget.Box({
  class_name: "taskbar",
  spacing,
  children: appIds.map((appId) =>
    Widget.Box({
      tooltip_text: appId,
      class_name: activeAppId === appId ? "focused" : "",
      child: Widget.Icon({
        icon: appId,
        size: 20,
      }),
    }),
  ),
});

const systray = Widget.Box({
  class_name: "systray",
  children: systemtray.bind("items").as((items) =>
    items.map((item) =>
      Widget.Button({
        child: Widget.Icon({
          icon: item.bind("icon"),
          size: 16,
        }),
        tooltipMarkup: item.bind("tooltip_markup"),
        onPrimaryClick: (_, event) => item.activate(event),
        onSecondaryClick: (_, event) => item.openMenu(event),
      }),
    ),
  ),
});

const date = Variable("", {
  poll: [1000, `date +"%a %d %b %H:%M"`],
});
const clock = Widget.Label({
  class_name: "clock",
  label: date.bind(),
});

const myLabel = Widget.Label({
  label: "some example content",
});

// function Left() {
//   return Widget.Box({
//     spacing: 8,
//     children: [Workspaces(), ClientTitle()],
//   });
// }
//
// function Center() {
//   return Widget.Box({
//     spacing: 8,
//     children: [Media(), Notification()],
//   });
// }
//
// function Right() {
//   return Widget.Box({
//     hpack: "end",
//     spacing: 8,
//     children: [Volume(), BatteryLabel(), Clock(), SysTray()],
//   });
// }

const bar = Widget.Window({
  name: "bar",
  class_name: "bar-container",
  exclusivity: "exclusive",
  layer: "bottom",
  anchor: ["top", "left", "right"],
  child: Widget.CenterBox({
    class_name: "bar",
    startWidget: Widget.Box({
      children: [myLabel],
    }),
    centerWidget: Widget.Box({
      hpack: "center",
      children: [taskbar],
    }),
    endWidget: Widget.Box({
      spacing,
      hpack: "end",
      children: [systray, clock],
    }),
  }),
});

App.config({
  style: "./style.css",
  windows: [bar],
});
