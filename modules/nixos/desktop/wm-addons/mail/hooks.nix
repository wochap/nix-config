{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config._custom.desktop.mail;

  notmuch = "${pkgs.notmuch}/bin/notmuch";
  jq = "${pkgs.jq}/bin/jq";

  escape = lib.replaceStrings [ "'" ] [ "'\\''" ];

  # same scoping as neomutt.nix's virtual folders: lieer (gmail) keeps
  # everything under <account>/mail, other accounts under <account>/INBOX
  accountFolder = name: acc: if acc.sync == "lieer" then "${name}/mail" else "${name}/INBOX";

  # One guarded block per entry: for every new message in the account's mail
  # folder matching the from glob, run the command once with
  # id/From/Subject/Date as $1..$4 and the full message text on stdin.
  # `|| true` keeps a failing user command from failing `notmuch new` (and
  # with it the sync unit that invoked it).
  # NOTE: `search --output=messages` emits ids already prefixed with "id:",
  # so MAIL_ID is used as-is in queries.
  arriveBlock = name: acc: h: ''
    # mail arrive hook (account:${name} from:${h.from})
    while IFS= read -r MAIL_ID; do
      [ -n "$MAIL_ID" ] || continue
      # json shape: [thread] > [message, replies] > message object
      meta="$(${notmuch} show --format=json "$MAIL_ID" \
        | ${jq} -r '.[0][0][0] | [.headers.From // "", .headers.Subject // "", .headers.Date // ""] | @tsv')"
      IFS=$'\t' read -r MAIL_FROM MAIL_SUBJECT MAIL_DATE <<< "$meta"
      export MAIL_ID MAIL_FROM MAIL_SUBJECT MAIL_DATE
      ${notmuch} show --format=text "$MAIL_ID" | {
        ${h.command} "$MAIL_ID" "$MAIL_FROM" "$MAIL_SUBJECT" "$MAIL_DATE"
      } || true
    done < <(${notmuch} search --output=messages 'tag:new and from:${escape h.from} and folder:${accountFolder name acc}')
  '';

  postNewHook = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      name: acc: lib.concatMapStringsSep "\n" (arriveBlock name acc) acc.hooks.arrive
    ) cfg.accounts
  );
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (acc: acc.sync != "none" || acc.hooks.arrive == [ ]) (
          lib.attrValues cfg.accounts
        );
        message = "_custom.desktop.mail.accounts.<name>.hooks.arrive requires sync = \"lieer\" or \"mbsync\" — mail of sync = \"none\" accounts is never imported, so hooks could never fire.";
      }
    ];

    _custom.hm.programs.notmuch.hooks.postNew = lib.mkIf (postNewHook != "") postNewHook;
  };
}
