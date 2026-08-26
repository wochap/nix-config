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
  sinceClause = lib.optionalString (cfg.querySince != null) " and date:${cfg.querySince}..";

  accountInboxAction =
    name:
    # A raw notmuch URI makes status-line %D display the full query.
    "<change-vfolder>${name}/inbox<enter>";

  vfolderLine = name: query: ''named-mailboxes "${name}" "notmuch://?query=${lib.escapeURL query}"'';
  accountVfolders =
    name: acc:
    let
      # lieer (gmail) keeps everything under <account>/mail, other accounts under <account>/INBOX
      accountFolder = if acc.sync == "lieer" then "${name}/mail" else "${name}/INBOX";
      # extra virtual folders defined per-account (e.g. sender filters),
      # always scoped to the account's mail folder
      extraVfolders = map (
        vf: vfolderLine "${name}/${vf.name}" "${vf.query} and folder:${accountFolder}${sinceClause}"
      ) acc.virtualFolders;
    in
    (
      if acc.sync == "lieer" then
        [
          (vfolderLine "${name}/inbox" "tag:inbox and folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/unread" "tag:unread and folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/flagged" "tag:flagged and folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/sent" "tag:sent and folder:${accountFolder}${sinceClause}")
        ]
      else
        [
          (vfolderLine "${name}/inbox" "folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/unread" "tag:unread and folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/flagged" "tag:flagged and folder:${accountFolder}${sinceClause}")
          (vfolderLine "${name}/sent" "folder:${name}/Sent${sinceClause}")
        ]
    )
    ++ extraVfolders;
  vfolders = lib.concatStringsSep "\n" (
    [ (vfolderLine "all/unread" "tag:unread${sinceClause}") ]
    ++ lib.concatLists (lib.mapAttrsToList accountVfolders cfg.accounts)
  );

  query-addresses =
    pkgs.writeScriptBin "query-addresses" # sh
      ''
        #!/usr/bin/env bash
        query="$1"
        shift

        # Neomutt expects an empty line or status on the first line
        echo "Searching for '$query'..."

        ${lib.optionalString config._custom.desktop.contacts.enable ''
          # Khard emits a leading empty line in neomutt mode.
          ${pkgs.khard}/bin/khard email --parsable -- "$query" | ${pkgs.coreutils}/bin/tail -n +2
        ''}

        # Notmuch
        ${pkgs.notmuch}/bin/notmuch address --output=sender --output=recipients --deduplicate=address --format=text "$query" "$@" 2>/dev/null |
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
          sendMailCommand = "${pkgs._custom.offlinemsmtp}/bin/offlinemsmtp -a ${name}";
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
        query-addresses
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
          {
            action = "next-unread";
            key = "J";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "previous-unread";
            key = "K";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "view-attachments";
            key = "v";
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
        ++ (lib.mapAttrsToList (name: acc: {
          action = accountInboxAction name;
          key = acc.inboxKey;
          map = [ "index" ];
        }) (lib.filterAttrs (_: acc: acc.inboxKey != null) cfg.accounts))
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
          {
            action = "<view-attachments><search>text/html<Enter><pipe-entry>smart-open --gui --mime text/html -<Enter><exit>";
            key = "B";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "<view-attachments><search>text/html<Enter><pipe-entry>smart-open --tui --mime text/html -<Enter><exit>";
            key = "T";
            map = [
              "index"
              "pager"
            ];
          }
          {
            action = "<pipe-entry>smart-open --auto -<Enter>";
            key = "o";
            map = [ "attach" ];
          }
          {
            action = "<pipe-entry>smart-open --auto -<Enter>";
            key = "<Enter>";
            map = [ "attach" ];
          }
          {
            action = "<pipe-entry>smart-open --gui -<Enter>";
            key = "B";
            map = [ "attach" ];
          }
          {
            action = "<pipe-entry>smart-open --tui -<Enter>";
            key = "T";
            map = [ "attach" ];
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
          ascii_chars = "no";
          beep = "no";
          beep_new = "no";
          confirmappend = "no";
          delete = "ask-yes";
          edit_headers = "yes";
          fast_reply = "yes";
          fcc_attach = "yes";
          folder = "${hmConfig.home.homeDirectory}/Mail";
          forward_quote = "yes";
          include = "yes";
          index_format = ''"%4C %zs %<X?󰁦& >%zc%zt %<[y?%<[d?     %[%H:%M]&    %[%b %d]>&%[%Y-%m-%d]> %-20.20L (%<l?%4l&%4c>) %s%@subject-fallback@"'';
          mail_check = "0";
          mailcap_path = "${hmConfig.xdg.configHome}/neomutt/mailcap";
          mark_old = "no";
          markers = "no";
          move = "no";
          narrow_tree = "no";
          pager_context = "4";
          menu_scroll = "yes";
          menu_context = "4";
          pager_index_lines = "10";
          pager_stop = "yes";
          quit = "yes";
          reply_to = "yes";
          reverse_name = "yes";
          query_command = ''"query-addresses '%s'"'';
          sort = "threads";
          sort_aux = "reverse-last-date-received";
          sort_re = "yes";
          spool_file = "personal/inbox";
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

          ignore *
          unignore From: To: Cc: Reply-To: Date: Subject: List-Id:
          hdr_order From: To: Cc: Reply-To: Date: Subject: List-Id:

          lists .*@lists.sr.ht

          index-format-hook subject-fallback "~s ^$" "[no subject]"

          # Theme formats
          set sidebar_format="%D%?F?  %F?%* %?N?%N/?%S"
          set date_format = "%d %h %H:%M";
          set status_chars = " 󰁦";
          set status_format = "[ %D ] %?r?[ 󰇰 %m ] ?%?n?[ 󰇮 %n ] ?%?d?[ 󰩹 %d ] ?%?t?[  %t ] ?%?F?[  %F ] ?%?p?[  %p ]?%|─";
          set crypt_chars = "󰈡 ";
          set flag_chars = "󰩹󰩺 󰇰󰇮 ";
          set to_chars = " ";
          set pager_format = "[ %n ] [ %T %s ]%* [ 󰸗 %{!%Y %a %d %b %H:%M} ] %?X?[ 󰁦 %X ]? [  %P ]%|─";

          # Theme
          source ${hmConfig.xdg.configHome}/neomutt/neomuttrc-theme
          color tree color0 default
          color index color0 default '~R'
        '';
      };
    };
  };
}
