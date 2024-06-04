export const generateScriptModule = ({ cmd, className, labelAttrs }) => {
  const Var = Variable(
    { text: "" },
    {
      listen: [
        cmd,
        (out) => {
          return JSON.parse(out);
        },
      ],
    },
  );
  // HACK: without using a function initial `visible` won't work
  return () =>
    Widget.Label({
      class_name: className,
      label: Var.bind().as((value) => value.text.replace(/\n/g, " ")),
      visible: Var.bind().as((value) => !!value.text),
      ...labelAttrs,
    });
};

const ignored = [
  "chrome-music.youtube.com__-Default",
  "chrome-www.figma.com__-Default",
  "chrome-chat.openai.com__-Default",
  "chrome-ollama.wochap.local__-Default",
];

export const mapAppId = (appId) => {
  if (/^kitty-/.test(appId)) {
    return "kitty";
  }
  if (/^foot-/.test(appId)) {
    return "foot";
  }
  if (/^footclient-/.test(appId)) {
    return "footclient";
  }
  if (/^alacritty-/.test(appId)) {
    return "Alacritty";
  }
  if (/^thunar-/.test(appId)) {
    return "thunar";
  }
  if (/^chrome-.*__-Default$/.test(appId) && !ignored.includes(appId)) {
    return "google-chrome";
  }
  if (/^msedge-.*-Default$/.test(appId) && !ignored.includes(appId)) {
    return "microsoft-edge";
  }
  return appId;
};
