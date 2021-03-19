#!/usr/bin/env bash

# source: https://gist.github.com/joshisa/297b0bc1ec0dcdda0d1625029711fa24

# Inspired by: https://gist.github.com/joshisa/297b0bc1ec0dcdda0d1625029711fa24
# Referenced and tweaked from http://stackoverflow.com/questions/6174220/parse-url-in-shell-script#6174447
url="$1"

protocol=$(echo "$1" | grep "://" | sed -e's,^\(.*://\).*,\1,g')
# Remove the protocol
url_no_protocol=$(echo "${1/$protocol/}")
# Use tr: Make the protocol lower-case for easy string compare
protocol=$(echo "$protocol" | tr '[:upper:]' '[:lower:]')

# Extract the user and password (if any)
# cut 1: Remove the path part to prevent @ in the querystring from breaking the next cut
# rev: Reverse string so cut -f1 takes the (reversed) rightmost field, and -f2- is what we want
# cut 2: Remove the host:port
# rev: Undo the first rev above
userpass=$(echo "$url_no_protocol" | grep "@" | cut -d"/" -f1 | rev | cut -d"@" -f2- | rev)
pass=$(echo "$userpass" | grep ":" | cut -d":" -f2)
if [ -n "$pass" ]; then
  user=$(echo "$userpass" | grep ":" | cut -d":" -f1)
else
  user="$userpass"
fi

# Extract the host
hostport=$(echo "${url_no_protocol/$userpass@/}" | cut -d"/" -f1)
host=$(echo "$hostport" | cut -d":" -f1)
port=$(echo "$hostport" | grep ":" | cut -d":" -f2)
path=$(echo "$url_no_protocol" | grep "/" | cut -d"/" -f2-)

# echo "url: $url"
# echo "  protocol: $protocol"
# echo "  userpass: $userpass"
# echo "  user: $user"
# echo "  pass: $pass"
# echo "  host: $host"
# echo "  port: $port"
# echo "  path: $path"

if [[
    $host =~ ^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$ ||
    $port ||
    $host == *"localhost"* ||
    $host == *"figma"*
  ]];
then
  google-chrome-stable $url
else
  if [[
    $host == *"TNB3000"*
  ]];
  then
    # requires `Open external links in a container` addon
    # firefox "ext+container:name=Work&url=$url"
    firefox $url
  else
    firefox $url
  fi
fi
