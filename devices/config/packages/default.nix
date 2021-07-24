{ pkgs }:

{
  ptsh = pkgs.callPackage ./ptsh {};
  bigsur-cursors = pkgs.callPackage ./bigsur-cursors {};
  horizon-icons = pkgs.callPackage ./horizon-icons {};
  horizon-theme = pkgs.callPackage ./horizon-theme {};
  lightdm-webkit2-greeter = pkgs.callPackage ./lightdm-webkit2-greeter {};
  sddm-sugar-dark-greeter = pkgs.callPackage ./sddm-sugar-dark-greeter {};
  sddm-whitesur-greeter = pkgs.callPackage ./sddm-whitesur-greeter {};
  stremio = pkgs.callPackage ./stremio {};
  whitesur-dark-icons = pkgs.callPackage ./whitesur-dark-icons {};
  whitesur-dark-theme = pkgs.callPackage ./whitesur-dark-theme {};
  zscroll = pkgs.callPackage ./zscroll {};
  http-url-handler = pkgs.makeDesktopItem {
    name = "http-url-handler";
    desktopName = "HTTP URL handler";
    comment = "Open an HTTP/HTTPS URL with a particular browser";
    exec = "/etc/scripts/open_url.sh %u";
    type = "Application";
    terminal = "false";
    extraEntries = ''
      TryExec=/etc/scripts/open_url.sh
      X-MultipleArgs=false
      NoDisplay=true
      MimeType=x-scheme-handler/http;x-scheme-handler/https
    '';
  };
}
