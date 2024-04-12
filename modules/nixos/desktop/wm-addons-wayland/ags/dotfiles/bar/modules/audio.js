const Audio = await Service.import("audio");

export const audio = Widget.Button({
  class_name: "audio",
  on_clicked: () => {
    Audio.speaker.is_muted = !Audio.speaker.is_muted;
  },
  // HACK: `Audio.bind("speaker")` doesn't work
  setup(self) {
    self.hook(Audio.speaker, () => {
      self.class_name = `audio ${Audio.speaker.stream?.isMuted ? "muted" : ""}`;
    });
  },
  child: Widget.Label({
    useMarkup: true,
    setup(self) {
      self.hook(Audio.speaker, () => {
        const vol = Audio.speaker.volume * 100;
        const icons = [
          [66, ""],
          [33, ""],
          [1, ""],
          [0, ""],
        ];
        const icon = icons.find(([threshold, _]) => vol >= threshold)[1];
        self.label = `<span rise='-1000'>${Audio.speaker.stream?.isMuted ? "" : icon}</span> ${Math.ceil(vol)}%`;
      });
    },
  }),
});
