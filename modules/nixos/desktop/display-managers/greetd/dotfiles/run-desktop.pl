#!/usr/bin/env perl

use v5.38;
use strict;
use warnings;

use Config::INI::Reader;
use Getopt::Long;

my $is_silent = 0;
GetOptions('silent|s' => \$is_silent)
    or die "Error in command line arguments.\n";

my $session = $ARGV[0];
if (not defined $session) {
    # Update usage message to include the new option
    die "Usage: $0 [--silent|-s] <session>\n";
}

say "Session: $session" unless $is_silent;

my @session_dirs = (
    "/run/current-system/sw/share/wayland-sessions",
    "/run/current-system/sw/share/xsessions",
    "@waylandSessionsPath@",
);

foreach my $dir (@session_dirs) {
    if (opendir(my $dh, $dir)) {
        while (my $file = readdir $dh) {
            if ($file eq "$session.desktop") {
                my $path = "$dir/$file";
                say "Found $path" unless $is_silent;

                my $ini = Config::INI::Reader->read_file($path);
                if (my $exec = $ini->{"Desktop Entry"}->{Exec}) {
                    say "Exec: $exec" unless $is_silent;
                    exec $exec or die "Failed to execute '$exec': $!";
                } else {
                    warn "Could not find 'Exec' entry in '$path'." unless $is_silent;
                }
            }
        }
        closedir $dh;
    } else {
        warn "Couldn't open directory '$dir': $!, skipping." unless $is_silent;
    }
}

warn "Error: Could not find a desktop entry for session '$session'.\n" unless $is_silent;
exit 1;
