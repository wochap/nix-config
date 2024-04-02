const Systemtray = await Service.import("systemtray");

export const systray = Widget.Box({
  class_name: "systray",
  children: Systemtray.bind("items").as((items) =>
    items.map((item) =>
      Widget.Button({
        child: Widget.Icon({
          icon: item.bind("icon").as((value) => {
            if (value === "video-display") {
              return "kde-windows";
            }
            if (value === "smartcode-stremio-tray") {
              return "smartcode-stremio";
            }
            return value;
          }),
          size: 16,
        }),
        tooltipMarkup: item.bind("tooltip_markup"),
        onPrimaryClick: (_, event) => item.activate(event),
        onSecondaryClick: (_, event) => item.openMenu(event),
      }),
    ),
  ),
});
