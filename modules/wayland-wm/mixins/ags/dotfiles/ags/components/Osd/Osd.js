import Widget from "resource:///com/github/Aylur/ags/widget.js";
import OsdService from "./OsdService.js";

const Osd = Widget.Window({
  name: "osd",
  className: "osd-window",
  layer: "overlay",
  anchor: ["right"],
  margin: [0, 7, 0, 0],
  child: Widget.Box({
    className: "osd",
    children: [
      Widget.Revealer({
        transitionDuration: 250,
        transition: "slide_left",
        connections: [
          [
            OsdService,
            (self, value) => (self.revealChild = value >= 0),
            "popup",
          ],
        ],
        child: Widget.Box({
          className: "osd-progress",
          properties: [
            ["height", 273],
            ["width", 28],
          ],
          connections: [
            [OsdService, (self, value) => self.setProgress(value), "popup"],
          ],
          children: [
            Widget.Box({
              className: "osd-progress-bar",
              hexpand: true,
              vexpand: false,
              halign: "fill",
              valign: "end",
            }),
          ],
          setup: (self) => {
            self.setStyle(`
              min-height: ${self._height}px;
              min-width: ${self._width}px;
            `);

            self.setProgress = (value) => {
              if (value < 0 || value > 200) return;

              const fill = self.children[0];

              if (value > 100) {
                const minHeight = (self._height * (value - 100)) / 100;
                fill.setStyle(`min-height: ${minHeight}px;`);
                fill.toggleClassName("overflowed", true);
                return;
              }

              const minHeight = (self._height * value) / 100;
              fill.setStyle(`min-height: ${minHeight}px;`);
              fill.toggleClassName("overflowed", false);
            };
          },
        }),
      }),
    ],
  }),
});

export default Osd;
