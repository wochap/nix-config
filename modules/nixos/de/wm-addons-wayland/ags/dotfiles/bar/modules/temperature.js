// temp in celsius
const temp = Variable(0, {
  poll: [
    5000,
    ["bash", "-c", "sensors | grep 'Tctl' | awk '{print $2}'"],
    (out) => Math.floor(parseFloat(out)),
  ],
});

export const temperature = Widget.Label({
  class_names: temp.bind().as((temp) => {
    return ["temperature", temp > 80 ? "critical" : ""];
  }),
  label: temp.bind().as((temp) => {
    if (temp > 80) {
      return ` ${temp}°C`;
    }
    return ` ${temp}°C`;
  }),
});
