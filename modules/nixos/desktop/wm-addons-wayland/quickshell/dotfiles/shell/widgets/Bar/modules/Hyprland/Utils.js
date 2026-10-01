const ignoredInMapAppId = [
  "chrome-music.youtube.com__-Default",
  "chrome-www.figma.com__-Default",
  "chrome-chat.openai.com__-Default",
  "chrome-openwebui.wochap.local__-Default",
  "msedge-www.bing.com__chat-Default",
];

const ignoredInWorkspaces = [
  "showmethekey-gtk",
  { class: "kb-hud", title: /.*overlay$/ },
];

const isIgnoredInWorkspaces = (appId, title) =>
  ignoredInWorkspaces.some((ignored) =>
    typeof ignored === "string"
      ? ignored === appId
      : ignored.class === appId && ignored.title.test(title ?? ""),
  );

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
  if (
    /^chrome-.*__-Default$/.test(appId) &&
    !ignoredInMapAppId.includes(appId)
  ) {
    return "google-chrome";
  }
  if (/^msedge-.*-Default$/.test(appId) && !ignoredInMapAppId.includes(appId)) {
    return "microsoft-edge";
  }
  return appId;
};

// Hyprland stableId is a hex counter assigned at window creation.
const openOrderRank = (client) => {
  const rank = parseInt(client?.stableId ?? "", 16);
  return Number.isNaN(rank) ? Infinity : rank;
};

const compareOpenOrder = (a, b) => {
  const rankA = openOrderRank(a);
  const rankB = openOrderRank(b);
  if (rankA !== rankB) {
    return rankA < rankB ? -1 : 1;
  }
  const addressA = a?.address ?? "";
  const addressB = b?.address ?? "";
  return addressA < addressB ? -1 : addressA > addressB ? 1 : 0;
};
