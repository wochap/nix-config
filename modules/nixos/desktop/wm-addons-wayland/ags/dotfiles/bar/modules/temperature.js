// temp in celsius
const Temperature = Variable(0, {
  poll: [
    5000,
    ["bash", "-c", "sensors | grep 'Tctl' | awk '{print $2}'"],
    (out) => Math.floor(parseFloat(out)),
  ],
});

const thresholdVisible = 50;
const thresholdMedium = 55;
const thresholdCritical = 80;
export const temperature = () =>
  Widget.Label({
    visible: Temperature.bind().as((temp) => temp >= thresholdVisible),
    class_names: Temperature.bind().as((temp) => {
      return [
        "temperature",
        temp >= thresholdMedium ? "medium" : "",
        temp >= thresholdCritical ? "critical" : "",
      ];
    }),
    label: Temperature.bind().as((temp) => {
      if (temp > thresholdCritical) {
        return ` ${temp}°C`;
      }
      return ` ${temp}°C`;
    }),
  });
