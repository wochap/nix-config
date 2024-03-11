const date = Variable("", {
  poll: [1000, `date +"%a %d %b %H:%M"`],
});
export const clock = Widget.Label({
  class_name: "clock",
  label: date.bind(),
});
