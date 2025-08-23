const ignored = [
  "chrome-music.youtube.com__-Default",
  "chrome-www.figma.com__-Default",
  "chrome-chat.openai.com__-Default",
  "chrome-ollama.wochap.local__-Default",
  "chrome-openwebui.wochap.local__-Default",
  "msedge-www.bing.com__chat-Default",
];

const mapAppId = (appId) => {
  if (/^kitty-/.test(appId)) {
    return "kitty";
  }
  if (/^foot-/.test(appId)) {
    return "foot";
  }
  if (/^footclient-/.test(appId)) {
    return "footclient";
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
