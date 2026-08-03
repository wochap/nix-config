{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config._custom.desktop.email;
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

  # lieer keeps a flat maildir (no INBOX folder), so the inbox becomes a
  # notmuch query; mbsync accounts still use their INBOX maildir folder
  accountInboxAction =
    account:
    if (cfg.accounts.${account.name} or null) == "lieer" then
      "<change-folder>notmuch://${maildirBasePath}?query=${lib.escapeURL "tag:inbox and folder:${account.name}"}<enter>"
    else
      "<change-folder>${account.maildir.absPath}/INBOX<enter>";

  # notmuch-based virtual folders
  vfolderLine =
    name: query: ''virtual-mailboxes "${name}" "notmuch://?query=${lib.escapeURL query}"'';
  accountVfolders =
    name: sync:
    if sync == "lieer" then
      # lieer keeps a flat maildir, everything is selected by tags
      [
        (vfolderLine "${name}/inbox" "tag:inbox and folder:${name}")
        (vfolderLine "${name}/unread" "tag:unread and folder:${name}")
        (vfolderLine "${name}/flagged" "tag:flagged and folder:${name}")
        (vfolderLine "${name}/sent" "tag:sent and folder:${name}")
      ]
    else
      # mbsync keeps real folders, so select by location; tags are only
      # reliable for unread (synced from maildir flags)
      [
        (vfolderLine "${name}/inbox" "folder:${name}/INBOX")
        (vfolderLine "${name}/unread" "tag:unread and folder:${name}/INBOX")
      ];
  vfolders = lib.concatStringsSep "\n" (
    [ (vfolderLine "all/unread" "tag:unread") ]
    ++ lib.concatLists (lib.mapAttrsToList accountVfolders cfg.accounts)
  );

  catppuccin-neomutt-light-theme-path = "${inputs.catppuccin-neomutt}/${
    if themeColorsLight.flavour == "latte" then "latte-neomuttrc" else "neomuttrc"
  }";
  catppuccin-neomutt-dark-theme-path = "${inputs.catppuccin-neomutt}/${
    if themeColorsDark.flavour == "latte" then "latte-neomuttrc" else "neomuttrc"
  }";

  # query_command backend: contact completion from the whole mail history
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
in
{
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs; [
        notmuch-address
        urlscan # extract urls from emails/txt files
        w3m # html rendering for notmuch.nvim
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
            # prompt for a notmuch query and open it as a virtual folder
            action = "vfolder-from-query";
            key = "\\Cs";
            map = [ "index" ];
          }
          {
            # edit notmuch tags (+tag -tag) on the current message
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
          {
            action = accountInboxAction hmConfig.accounts.email.accounts.Personal;
            key = "P";
            map = [ "index" ];
          }
          {
            action = accountInboxAction hmConfig.accounts.email.accounts.SE;
            key = "S";
            map = [ "index" ];
          }
          {
            action = "<save-message>?<tab>";
            key = "s";
            map = [ "index" ];
          }
          {
            # trash via notmuch tag, lieer pushes it to the gmail trash on sync
            action = "<modify-labels-then-hide>+trash<enter>";
            key = "D";
            map = [ "index" ];
          }
          {
            # archive: drop the inbox tag
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
          format = "%B%?F? [%F]?%* %?N?%N/?%S";
          shortPath = false;
        };

        settings = {
          abort_key = "<Esc>";
          alias_file = aliasfile;
          allow_ansi = "yes";
          beep = "no";
          beep_new = "no"; # bell on new mails
          confirmappend = "no"; # don't ask, just do!
          delete = "yes"; # don't ask, just do
          edit_headers = "yes"; # show headers when composing
          fast_reply = "yes"; # skip to compose when replying
          fcc_attach = "yes"; # save attachments with the body
          folder = "${hmConfig.home.homeDirectory}/Mail";
          forward_quote = "yes"; # include message in forwards
          include = "yes"; # include message in replies
          mail_check = "0"; # how often look for new mail
          mailcap_path = "${hmConfig.xdg.configHome}/neomutt/mailcap"; # MIMEs
          mark_old = "no"; # read/new is good enough for me
          markers = "no"; # show '+' at start of wrapped lines
          move = "no"; # gmail does that
          pager_context = "3";
          pager_index_lines = "10"; # shows 10 lines of index when pager is active
          pager_stop = "yes";
          quit = "yes"; # don't ask, just do!!
          reply_to = "yes"; # reply to Reply to: field
          reverse_name = "yes"; # reply as whomever it was to
          query_command = "notmuch-address %s"; # contact completion from the mail history
          sort = "threads";
          sort_aux = "reverse-last-date-received";
          sort_re = "yes";
          text_flowed = "yes";
          timeout = "0";
          tmpdir = "${hmConfig.xdg.configHome}/neomutt/tmp";
          wait_key = "no"; # don't ask "press key to continue"

          mail_check_stats = "yes";
        };

        extraConfig = ''
          source ${aliasfile}
          source ${mailboxfile}

          # Notmuch virtual folders
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
