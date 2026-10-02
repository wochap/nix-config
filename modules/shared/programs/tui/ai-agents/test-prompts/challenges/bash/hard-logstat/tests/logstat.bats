#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  script="$BATS_TEST_DIRNAME/../logstat.sh"
  cd "$BATS_TEST_TMPDIR" || exit 1
  cat >access.log <<'LOG'
# sample log
10.0.0.1 GET /index.html 200 512
10.0.0.2 GET /index.html 200 512

10.0.0.3 GET /about 200 100
10.0.0.1 GET /missing 404 0
   # indented comment
10.0.0.4 POST /api/login 500 -
10.0.0.2 GET /index.html 304 512
10.0.0.5 GET /about 200 0010
LOG
}

ls_run() {
  run --separate-stderr bash "$script" "$@"
}

@test "text output, default options" {
  ls_run access.log
  [ "$status" -eq 0 ]
  [ "$stderr" = "" ]
  expected=$'3 1536 /index.html\n2 110 /about\n1 0 /api/login\n1 0 /missing\nTOTAL 7 1646'
  [ "$output" = "$expected" ]
}

@test "ties are ordered by path in byte order" {
  printf '%s\n' '1 GET /b 200 1' '1 GET /B 200 1' '1 GET /a 200 1' '1 GET /_ 200 1' >ties.log
  ls_run ties.log
  [ "$status" -eq 0 ]
  [ "$output" = $'1 1 /B\n1 1 /_\n1 1 /a\n1 1 /b\nTOTAL 4 4' ]
}

@test "--top limits paths but not totals" {
  ls_run -n 2 access.log
  [ "$status" -eq 0 ]
  [ "$output" = $'3 1536 /index.html\n2 110 /about\nTOTAL 7 1646' ]
  ls_run --top 1 access.log
  [ "$output" = $'3 1536 /index.html\nTOTAL 7 1646' ]
}

@test "default top is 10" {
  for i in $(seq 1 15); do printf '1 GET /p%02d 200 1\n' "$i"; done >many.log
  ls_run many.log
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 11 ]
  [ "${lines[0]}" = "1 1 /p01" ]
  [ "${lines[9]}" = "1 1 /p10" ]
  [ "${lines[10]}" = "TOTAL 15 15" ]
}

@test "--status filters lines and totals" {
  ls_run -s 2xx access.log
  [ "$status" -eq 0 ]
  [ "$output" = $'2 110 /about\n2 1024 /index.html\nTOTAL 4 1134' ]
  ls_run --status 5xx access.log
  [ "$output" = $'1 0 /api/login\nTOTAL 1 0' ]
  ls_run -s 1xx access.log
  [ "$output" = "TOTAL 0 0" ]
}

@test "stdin when no file or -" {
  run --separate-stderr bash -c 'bash "$1" < access.log' _ "$script"
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "3 1536 /index.html" ]
  run --separate-stderr bash -c 'printf "1 GET /x 200 5\n" | bash "$1" access.log - -n 1' _ "$script"
  [ "$status" -eq 0 ]
  [ "$output" = $'3 1536 /index.html\nTOTAL 8 1651' ]
}

@test "multiple files, names with spaces, no trailing newline" {
  printf '1 GET /x 200 5\n1 GET /y 200 7' >"my log.txt"
  printf '1 GET /y 200 1' >"other one.log"
  ls_run "my log.txt" "other one.log"
  [ "$status" -eq 0 ]
  [ "$output" = $'2 8 /y\n1 5 /x\nTOTAL 3 13' ]
}

@test "-- ends options" {
  printf '1 GET /dash 200 3\n' >./-n
  ls_run -- -n
  [ "$status" -eq 0 ]
  [ "$output" = $'1 3 /dash\nTOTAL 1 3' ]
}

@test "malformed lines are skipped and reported" {
  cat >bad.log <<'LOG'
1 GET /ok 200 1
1 GET /short 200
1 GET /long 200 1 extra
1 GET /badstatus 20x 1
1 GET /badstatus2 600 1
1 GET /badbytes 200 -5
1 GET /badbytes2 200 1k
1 GET /ok 201 2
LOG
  ls_run bad.log
  [ "$status" -eq 0 ]
  [ "$output" = $'2 3 /ok\nTOTAL 2 3' ]
  [ "$stderr" = "logstat: skipped 6 malformed line(s)" ]
}

@test "special characters in paths are data" {
  touch a b c
  cat >weird.log <<'LOG'
1 GET * 200 1
1 GET /q?a='b' 200 2
1 GET /x]y[z 200 3
1 GET /$(echo_pwned) 200 4
1 GET /$HOME 200 5
1 GET /back\slash 200 6
1 GET /x]y[z 200 3
LOG
  ls_run weird.log
  [ "$status" -eq 0 ]
  expected="2 6 /x]y[z
1 1 *
1 4 /\$(echo_pwned)
1 5 /\$HOME
1 6 /back\\slash
1 2 /q?a='b'
TOTAL 7 24"
  [ "$output" = "$expected" ]
  [ ! -e echo_pwned ]
}

@test "json output" {
  ls_run -f json -n 2 access.log
  [ "$status" -eq 0 ]
  [ "$output" = '{"total":{"requests":7,"bytes":1646},"paths":[{"path":"/index.html","count":3,"bytes":1536},{"path":"/about","count":2,"bytes":110}]}' ]
}

@test "json escaping" {
  printf '%s\n' '1 GET /say"hi" 200 1' '1 GET /a\b 200 2' >j.log
  ls_run --format json j.log
  [ "$status" -eq 0 ]
  [ "$output" = '{"total":{"requests":2,"bytes":3},"paths":[{"path":"/a\\b","count":1,"bytes":2},{"path":"/say\"hi\"","count":1,"bytes":1}]}' ]
}

@test "json with no counted lines" {
  ls_run -f json -s 1xx access.log
  [ "$status" -eq 0 ]
  [ "$output" = '{"total":{"requests":0,"bytes":0},"paths":[]}' ]
}

@test "html output and escaping" {
  printf '%s\n' '1 GET /a?x=1&y=<2> 200 3' '1 GET /q="v"&&z 200 4' '1 GET /a?x=1&y=<2> 200 3' >h.log
  ls_run -f html h.log
  [ "$status" -eq 0 ]
  expected='<table>
<tr><th>path</th><th>count</th><th>bytes</th></tr>
<tr><td>/a?x=1&amp;y=&lt;2&gt;</td><td>2</td><td>6</td></tr>
<tr><td>/q=&quot;v&quot;&amp;&amp;z</td><td>1</td><td>4</td></tr>
</table>'
  [ "$output" = "$expected" ]
}

@test "usage errors exit 2" {
  for args in "-x" "-n" "-n 0" "-n -3" "-n abc" "-s 6xx" "-s 200" "-f xml" "--bogus"; do
    # shellcheck disable=SC2086
    ls_run $args access.log
    [ "$status" -eq 2 ] || { echo "args: $args status: $status"; false; }
    [ "$output" = "" ]
    [[ "$stderr" == *usage* ]]
  done
}

@test "unreadable file exits 1 before any output" {
  ls_run access.log "no such.log"
  [ "$status" -eq 1 ]
  [ "$output" = "" ]
  [ "$stderr" = "logstat: cannot read no such.log" ]
}
