const WireguardActiveCount = Variable(0, {
  poll: [
    1000,
    ["bash", "-c", "wireguard-status"],
    (out) => parseInt(JSON.parse(out).activeCount),
  ],
});

export const wireguard = () =>
  Widget.Label({
    visible: WireguardActiveCount.bind().as((activeCount) => activeCount > 0),
    class_names: ["wireguard"],
    label: WireguardActiveCount.bind().as((activeCount) => {
      if (activeCount > 0) {
        return "wireguard";
      }
      return "";
    }),
  });
