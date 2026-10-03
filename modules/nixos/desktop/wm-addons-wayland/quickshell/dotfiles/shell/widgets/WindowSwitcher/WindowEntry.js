.pragma library

// Window entry shape shared by the window switcher and harpoon backends:
//   { id, title, icon, appClass, workspace, special, specialName, urgent,
//     captureSource, key? }

// Special workspaces are labelled "S"; their full name goes into the tag.
const workspaceInfo = (client) => {
  const workspace = client?.workspace ?? {};
  const name = String(workspace.name ?? "");
  const special = Number(workspace.id ?? 0) < 0 || name.startsWith("special:");
  return {
    workspace: special ? "S" : String(workspace.id ?? ""),
    special: special,
    specialName: special ? name : ""
  };
};

const make = (id, toplevel, client, icon, extra) => Object.assign({
  id: id,
  title: toplevel?.title ?? client?.title ?? "",
  icon: icon,
  appClass: client?.class ?? "",
  urgent: toplevel?.urgent ?? false,
  captureSource: toplevel?.wayland ?? null
}, workspaceInfo(client), extra ?? {});
