{ config, lib, pkgs, inputs, ... }:

let
  cfg = config._custom.desktop.email;
  inherit (config._custom.globals)
    userName themeColorsLight themeColorsDark preferDark;
  hmConfig = config.home-manager.users.${userName};
  aliasfile = "${hmConfig.xdg.configHome}/neomutt/aliases";
  mailboxfile = "${hmConfig.xdg.configHome}/neomutt/mailboxes";
  syncthingdir = "${hmConfig.home.homeDirectory}/Sync";

  catppuccin-neomutt-light-theme-path = "${inputs.catppuccin-neomutt}/${
      if themeColorsLight.flavour == "latte" then
        "latte-neomuttrc"
      else
        "neomuttrc"
    }";
  catppuccin-neomutt-dark-theme-path = "${inputs.catppuccin-neomutt}/${
      if themeColorsDark.flavour == "latte" then
        "latte-neomuttrc"
      else
        "neomuttrc"
    }";
in {
  config = lib.mkIf cfg.enable {
    _custom.hm = {
      home.packages = with pkgs;
        [
          urlscan # extract urls from emails/txt files
        ];

      home.symlinks = {
        "${aliasfile}" = "${syncthingdir}/.config/neomutt/aliases";
        "${mailboxfile}" = "${syncthingdir}/.config/neomutt/mailboxes";
      };

      xdg.configFile = {
        "neomutt/neomuttrc-theme" = {
          source = if preferDark then
            catppuccin-neomutt-dark-theme-path
          else
            catppuccin-neomutt-light-theme-path;
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
            map = [ "index" "pager" ];
          }
          {
            action = "sidebar-prev";
            key = "[";
            map = [ "index" "pager" ];
          }
          {
            action = "sidebar-next";
            key = "]";
            map = [ "index" "pager" ];
          }
          {
            action = "sidebar-open";
            key = "\\Co";
            map = [ "index" "pager" ];
          }
        ];
        macros = [
          {
            action = "!systemctl --user start mbsync &^M";
            key = "<F5>";
            map = [ "index" ];
          }
          {
            action =
              "<change-folder>${hmConfig.accounts.email.accounts.Personal.maildir.absPath}/INBOX<enter>";
            key = "P";
            map = [ "index" ];
          }
          {
            action =
              "<change-folder>${hmConfig.accounts.email.accounts.BOC.maildir.absPath}/INBOX<enter>";
            key = "B";
            map = [ "index" ];
          }
          {
            action =
              "<change-folder>${hmConfig.accounts.email.accounts.SE.maildir.absPath}/INBOX<enter>";
            key = "S";
            map = [ "index" ];
          }
          {
            action = "<save-message>?<tab>";
            key = "s";
            map = [ "index" ];
          }
          {
            action = "<pipe-message>urlscan -dc<Enter>";
            key = "\\Cl";
            map = [ "index" "pager" ];
          }
          {
            action = "<pipe-entry>urlscan -dc<Enter>";
            key = "\\Cl";
            map = [ "attach" "compose" ];
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
          pager_index_lines =
            "10"; # shows 10 lines of index when pager is active
          pager_stop = "yes";
          quit = "yes"; # don't ask, just do!!
          reply_to = "yes"; # reply to Reply to: field
          reverse_name = "yes"; # reply as whomever it was to
          sort = "threads";
          sort_aux = "reverse-last-date-received";
          sort_re = "yes";
          text_flowed = "yes";
          timeout = "0";
          tmpdir = "${hmConfig.xdg.configHome}/neomutt/tmp";
          wait_key = "no"; # don't ask "press key to continue"

          imap_check_subscribed = "yes";
          mail_check_stats = "yes";

        };

        extraConfig = ''
          source ${aliasfile}
          source ${mailboxfile}

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
