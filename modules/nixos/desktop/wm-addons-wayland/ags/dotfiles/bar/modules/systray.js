const Systemtray = await Service.import("systemtray");

export const systray = () =>
  Widget.Box({
    class_name: "systray",
    children: Systemtray.bind("items").as((items) =>
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
