const Audio = await Service.import("audio");

export const audio = Widget.Button({
  class_name: "audio",
  on_clicked: () => {
    Audio.speaker.is_muted = !Audio.speaker.is_muted;
  },
  // HACK: `Audio.bind("speaker")` doesn't work
  setup(self) {
    self.hook(Audio.speaker, () => {
      const vol = Audio.speaker.volume * 100;
      self.tooltip_text = `Volume ${Math.floor(vol)}%`;
      self.class_name = `audio ${Audio.speaker.stream?.isMuted ? "muted" : ""}`;
    });
  },
  child: Widget.Label({
    vpack: "fill",
    vexpand: true,
    setup(self) {
      self.hook(Audio.speaker, () => {
        const vol = Audio.speaker.volume * 100;
        const icon = [
          [101, ""],
          [67, ""],
          [34, ""],
          [1, ""],
          [0, ""],
        ].find(([threshold]) => threshold <= vol)?.[1];
        self.label = `${Audio.speaker.stream?.isMuted ? "" : icon} ${Math.ceil(vol)}%`;
      });
    },
  }),
});
