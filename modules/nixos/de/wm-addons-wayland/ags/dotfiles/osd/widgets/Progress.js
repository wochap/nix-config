export const Progress = ({ width, height, vertical = false }) => {
  const fill = Widget.Box({
    class_name: "fill",
    hexpand: vertical,
    vexpand: !vertical,
    hpack: vertical ? "fill" : "start",
    vpack: vertical ? "end" : "fill",
  });
  const wrapper = Widget.Box({
    class_name: "progress",
    child: fill,
    hexpand: false,
    vexpand: false,
    css: `
      min-width: ${width}px;
      min-height: ${height}px;
    `,
  });
  const container = Widget.Box({
    class_name: "progress-container",
    child: wrapper,
  });

  return Object.assign(container, {
    setValue(value) {
      let overflow = false;
      if (value > 1) {
        value -= 1;
        overflow = true;
      }
      if (value < 0) {
        fill.class_name = `fill ${overflow ? "overflow" : ""} muted`;
        return;
      }
      fill.class_name = `fill ${overflow ? "overflow" : ""}`;
      const axis = vertical ? "height" : "width";
      const fill_size = (vertical ? height : width) * value;
      fill.css = `min-${axis}: ${fill_size}px;opacity: ${fill_size === 0 ? 0 : 1};`;
    },
  });
};
