{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.mail;
  inherit (config._custom.globals)
    userName
    themeColorsLight
    themeColorsDark
    preferDark
    ;
  hmConfig = config.home-manager.users.${userName};
  aliasfile = "${hmConfig.xdg.configHome}/neomutt/aliases";
  mailboxfile = "${hmConfig.xdg.configHome}/neomutt/mailboxes";
  syncthingdir = "${hmConfig.home.homeDirectory}/Sync";
  maildirBasePath = hmConfig.accounts.email.maildirBasePath;

  accountInboxAction =
    name: account:
    if account.sync == "lieer" then
      "<change-folder>notmuch://${maildirBasePath}?query=${lib.escapeURL "tag:inbox and folder:${name}"}<enter>"
    else
      "<change-folder>${maildirBasePath}/${name}/INBOX<enter>";

  vfolderLine =
    name: query: ''named-mailboxes "${name}" "notmuch://?query=${lib.escapeURL query}"'';
  accountVfolders =
    name: acc:
    if acc.sync == "lieer" then
      [
        (vfolderLine "${name}/inbox" "tag:inbox and folder:${name}")
        (vfolderLine "${name}/unread" "tag:unread and folder:${name}")
        (vfolderLine "${name}/flagged" "tag:flagged and folder:${name}")
        (vfolderLine "${name}/sent" "tag:sent and folder:${name}")
      ]
    else
      [
        (vfolderLine "${name}/inbox" "folder:${name}/INBOX")
        (vfolderLine "${name}/unread" "tag:unread and folder:${name}/INBOX")
      ];
  vfolders = lib.concatStringsSep "\n" (
    [ (vfolderLine "all/unread" "tag:unread") ]
    ++ lib.concatLists (lib.mapAttrsToList accountVfolders cfg.accounts)
  );

  notmuch-address =
    pkgs.writeScriptBin "notmuch-address" # sh
      ''
        #!/usr/bin/env bash
        ${pkgs.notmuch}/bin/notmuch address --output=sender --output=recipients --deduplicate=address --format=text "$@" |
          ${pkgs.gawk}/bin/awk -F'[<>]' 'NF >= 2 {
            addr = $2; name = $1;
            gsub(/^[ \t]+|[ \t]+$/, "", addr);
            gsub(/^[ \t]+|[ \t]+$/, "", name);
            print addr "\t" name
          }'
      '';

  catppuccin-neomutt-light-theme-path = "${inputs.catppuccin-neomutt}/${
    if themeColorsLight.flavour == "latte" then "latte-neomuttrc" else "neomuttrc"
  }";
  catppuccin-neomutt-dark-theme-path = "${inputs.catppuccin-neomutt}/${
    if themeColorsDark.flavour == "latte" then "latte-neomuttrc" else "neomuttrc"
  }";
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      accounts.email.accounts = lib.mapAttrs (name: acc: {
        neomutt = {
          enable = true;
          sendMailCommand = "${pkgs._custom.offlinemsmtp}/bin/offlinemsmtp -a ${acc.name}";
          showDefaultMailbox = acc.sync != "lieer";
          extraConfig = lib.concatStringsSep "\n" (
            [
              ''set folder="${maildirBasePath}"''
            ]
            ++ lib.optional (acc.pgpKey != "") ''set pgp_default_key = "${acc.pgpKey}"''
            ++ lib.optional (acc.pgpKey != "") ''set pgp_sign_as = "${acc.pgpKey}"''
            ++ lib.optional (acc.color != "") "color status ${acc.color} default"
          );
        };
      }) cfg.accounts;

      home.packages = with pkgs; [
        notmuch-address
        urlscan
        w3m
      ];

      home.symlinks = {
        "${aliasfile}" = "${syncthingdir}/.config/neomutt/aliases";
        "${mailboxfile}" = "${syncthingdir}/.config/neomutt/mailboxes";
      };

      xdg.configFile = {
        "neomutt/neomuttrc-theme" = {
          source =
            if preferDark then catppuccin-neomutt-dark-theme-path else catppuccin-neomutt-light-theme-path;
          force = true;
        };
        "neomutt/neomuttrc-light".source = catppuccin-neomutt-light-theme-path;
        "neomutt/neomuttrc-dark".source = catppuccin-neomutt-dark-theme-path;
      };

      programs.neomutt = {
        enable = true;
        vimKeys = true;
        binds = [
          {
            action = "complete-query";
            key = "<Tab>";
            map = [ "editor" ];
          }
          {
            action = "group-reply";
            key = "R";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "sidebar-prev";
            key = "[";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "sidebar-next";
            key = "]";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "sidebar-open";
            key = "\\Co";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "vfolder-from-query";
            key = "\\Cs";
            map = [ "index" ];
          }
          {
            action = "modify-labels";
            key = "f";
            map = [
              "index"
              "pager"
            ];
          }
        ];
        macros = [
          {
            action = "!email-sync &^M";
            key = "<F5>";
            map = [ "index" ];
          }
        ]
        ++ (lib.optional (cfg.accounts ? personal) {
          action = accountInboxAction "personal" cfg.accounts.personal;
          key = "P";
          map = [ "index" ];
        })
        ++ (lib.optional (cfg.accounts ? se) {
          action = accountInboxAction "se" cfg.accounts.se;
          key = "S";
          map = [ "index" ];
        })
        ++ [
          {
            action = "<save-message>?<tab>";
            key = "s";
            map = [ "index" ];
          }
          {
            action = "<modify-labels-then-hide>+trash<enter>";
            key = "D";
            map = [ "index" ];
          }
          {
            action = "<modify-labels-then-hide>-inbox<enter>";
            key = "A";
            map = [ "index" ];
          }
          {
            action = "<pipe-message>urlscan -dc<Enter>";
            key = "\\Cl";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "<pipe-entry>urlscan -dc<Enter>";
            key = "\\Cl";
            map = [
              "attach"
              "compose"
            ];
          }
        ];

        sidebar = {
          enable = true;
          width = 40;
          format = "%D%?F? [%F]?%* %?N?%N/?%S";
          shortPath = false;
        };

        settings = {
          abort_key = "<Esc>";
          alias_file = aliasfile;
          allow_ansi = "yes";
          beep = "no";
          beep_new = "no";
          confirmappend = "no";
          delete = "yes";
          edit_headers = "yes";
          fast_reply = "yes";
          fcc_attach = "yes";
          folder = "${hmConfig.home.homeDirectory}/Mail";
          forward_quote = "yes";
          include = "yes";
          mail_check = "0";
          mailcap_path = "${hmConfig.xdg.configHome}/neomutt/mailcap";
          mark_old = "no";
          markers = "no";
          move = "no";
          pager_context = "3";
          pager_index_lines = "10";
          pager_stop = "yes";
          quit = "yes";
          reply_to = "yes";
          reverse_name = "yes";
          query_command = ''"notmuch-address '%s'"'';
          sort = "threads";
          sort_aux = "reverse-last-date-received";
          sort_re = "yes";
          text_flowed = "yes";
          timeout = "0";
          tmpdir = "${hmConfig.xdg.configHome}/neomutt/tmp";
          wait_key = "no";
          mail_check_stats = "yes";
        };

        extraConfig = ''
          source ${aliasfile}
          source ${mailboxfile}

          # Global Notmuch virtual folders
          set nm_default_uri = "notmuch://${maildirBasePath}"
          ${vfolders}

          # Use return to open message because I'm not a savage
          unbind index <return>
          bind index <return> display-message

          # Use N to toggle new
          unbind index N
          bind index N toggle-new

          lists .*@lists.sr.ht

          # Theme formats
          set date_format = "%d %h %H:%M";
          set status_chars = " 󰁦";
          set status_format = "[ %D ] %?r?[ 󰇰 %m ] ?%?n?[ 󰇮 %n ] ?%?d?[ 󰩹 %d ] ?%?t?[  %t ] ?%?F?[  %F ] ?%?p?[  %p ]?%|─";
          set crypt_chars = "󰈡 ";
          set flag_chars = "󰩹󰩺 󰇰󰇮 ";
          set to_chars = " ";
          set pager_format = "[ %n ] [ %T %s ]%* [ 󰸗 %{!%Y %a %d %b %H:%M} ] %?X?[ 󰁦 %X ]? [  %P ]%|─";

          # Theme
          source ${hmConfig.xdg.configHome}/neomutt/neomuttrc-theme
          color index color0 default '~R'
        '';
      };
    };
  };
}
