{ config, pkgs, lib, inputs, ... }:

with pkgs;
let
  userName = config._userName;
  hmConfig = config.home-manager.users.${userName};

  aliasfile = "${hmConfig.xdg.configHome}/neomutt/aliases";
  mailboxfile = "${hmConfig.xdg.configHome}/neomutt/mailboxes";
  bindir = "${hmConfig.home.homeDirectory}/bin";
  mutt-display-filter =
    pkgs.writeScriptBin "mdf" (builtins.readFile ./scripts/mutt-display-filter.py);

  syncthingdir = "${hmConfig.home.homeDirectory}/Sync";
in {
  config = {
    home-manager.users.${userName} = {
      home.symlinks."${aliasfile}" = "${syncthingdir}/.config/neomutt/aliases";
      home.symlinks."${mailboxfile}" =
        "${syncthingdir}/.config/neomutt/mailboxes";

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
            key = "\\Cp";
            map = [ "index" "pager" ];
          }
          {
            action = "sidebar-next";
            key = "\\Cn";
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
              "<change-folder>${hmConfig.accounts.email.accounts.Work.maildir.absPath}/INBOX<enter>";
            key = "W";
            map = [ "index" ];
          }
          {
            action = "<change-folder>?<change-dir><home>^K=<enter><tab>";
            key = "c";
            map = [ "index" ];
          }
          {
            action = "<save-message>?<tab>";
            key = "s";
            map = [ "index" ];
          }
        ];

        sidebar = {
          enable = true;
          width = 40;
          format = "%B%?F? [%F]?%* %?N?%N/?%S";
          shortPath = false;
        };

        settings = {
          alias_file = aliasfile;
          confirmappend = "no";
          edit_headers = "yes";
          fast_reply = "yes";
          folder = "${hmConfig.home.homeDirectory}/Mail";
          imap_check_subscribed = "yes";
          include = "yes";
          mail_check = "0";
          mail_check_stats = "yes";
          mailcap_path = "${hmConfig.xdg.configHome}/neomutt/mailcap";
          mark_old = "no";
          markers = "no";
          pager_context = "3";
          pager_index_lines = "10";
          pager_stop = "yes";
          sort_aux = "reverse-last-date-received";
          sort_re = "yes";
          tmpdir = "${hmConfig.home.homeDirectory}/tmp";
        };

        extraConfig = ''
          source ${inputs.dracula-mutt}/dracula.muttrc
          source ${aliasfile}
          source ${mailboxfile}
          set allow_ansi
          set display_filter="${mutt-display-filter}/bin/mdf"
          # Use return to open message because I'm not a savage
          unbind index <return>
          bind index <return> display-message
          # Use N to toggle new
          unbind index N
          bind index N toggle-new
          # Status Bar
          set status_chars  = " *%A"
          set status_format = "───[ Folder: %f (%l %s/%S)]───[%r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)?%?F? (%F flagged)?]───%>─%?p?( %p postponed)?───"
          lists .*@lists.sr.ht
        '';
      };
    };
  };
}
