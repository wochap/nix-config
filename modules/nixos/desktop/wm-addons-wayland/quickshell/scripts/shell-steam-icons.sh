#!/usr/bin/env bash

# This script finds all Steam game icon paths and outputs them as a JSON object.
# The JSON object's keys are the Steam App IDs (the folder names), and the
# values are the full absolute paths to the icon files.

# We find all matching files and pipe the results to awk for formatting.
# The awk command constructs the main content of our JSON object.
json_content=$(find ~/.local/share/Steam/appcache/librarycache/ -type f -regextype posix-extended -regex '.*/[0-9]+/[a-f0-9]{40}\.(jpg|png)$' | awk -F'/' '{
    # For each line (filepath), print a comma followed by a "key":"value" pair.
    # The key is the second-to-last field (the app ID).
    # The value is the full line ($0). We add escaped quotes for JSON string compatibility.
    printf ",\"%s\":\"%s\"", $(NF-1), $0
}')

# After the command runs, we check if any icons were found.
if [ -z "$json_content" ]; then
    # If no icons were found, output an empty JSON object.
    echo "{}"
else
    # If icons were found, $json_content will look like: ,"key1":"value1","key2":"value2"
    # We remove the leading comma using bash's substring expansion (`${string:1}`)
    # and wrap the result in curly braces to form a valid JSON object.
    echo "{${json_content:1}}"
fi


