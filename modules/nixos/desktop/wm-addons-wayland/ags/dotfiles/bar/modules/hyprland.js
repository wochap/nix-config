const Hyprland = await Service.import("hyprland");

export const hyprlandTitle = () =>
  Widget.Label({
    class_name: "dwltitle",
    label: Hyprland.active.client.bind("title"),
    visible: Hyprland.active.client.bind("address").as((addr) => !!addr),
  });
