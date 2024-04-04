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

export const mapAppId = (appId) => {
  if (/^kitty-/.test(appId)) {
    return "kitty";
  }
  if (/^thunar-/.test(appId) || appId === "xdg-desktop-portal-gtk") {
    return "thunar";
  }
  if (/^chrome-.*__-Default$/.test(appId)) {
    return "google-chrome";
  }
  if (/^msedge-.*-Default$/.test(appId)) {
    return "microsoft-edge";
  }
  if (appId === "Slack") {
    return "slack";
  }
  if (appId === "com.stremio.stremio") {
    return "stremio";
  }
  if (appId === "imv") {
    return "eog";
  }
  if (appId === "MongoDB") {
    return "mongodb-compass";
  }
  if (appId === "code-url-handler") {
    return "vscode";
  }
  return appId
};
