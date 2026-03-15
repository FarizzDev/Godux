#!/usr/bin/env perl
# Usage:
#   perl parse_presets.pl list                          # List all presets as "name|platform"
#   perl parse_presets.pl platform <preset_name>        # Get platform of a preset
#   perl parse_presets.pl is_android <preset_name>      # Check if preset is Android (exit 0 = true)
#   perl parse_presets.pl has_android                   # Check if ANY preset is Android (exit 0 = true)
#   perl parse_presets.pl get <preset_name> <key>       # Get a specific option value
#   perl parse_presets.pl export_format <preset_name>   # Get export format: apk or aab
#   perl parse_presets.pl keystore <preset_name> <debug|release> # Get keystore path
#   perl parse_presets.pl all_android                   # List all Android preset names
#
# Exit codes:
#   0 = success / true
#   1 = not found / false
#   2 = usage error

use strict;
use warnings;
use utf8;
use Encode qw(decode);

my $PRESETS_FILE = $ENV{PRESETS_FILE} // "export_presets.cfg";
my $EXPORT_ALL_ID = "[ Export All Preset ]\x{2063}";

# --- Parse ---
sub parse_presets {
    my ($filepath) = @_;
    open(my $fh, "<:encoding(UTF-8)", $filepath)
        or do { print STDERR "Error: $filepath not found.\n"; exit 2; };

    my @presets;
    my $current = undef;
    my $in_options = 0;

    while (my $line = <$fh>) {
        $line =~ s/[\r\n]+$//;

        if ($line =~ /^\[preset\.\d+\]$/) {
            push @presets, $current if defined $current;
            $current = { name => "", platform => "", options => {} };
            $in_options = 0;
            next;
        }

        if ($line =~ /^\[preset\.\d+\.options\]$/) {
            $in_options = 1;
            next;
        }

        next if !$line || $line =~ /^\s*;/;

        if (defined $current && $line =~ /^([^=]+)=(.*)$/) {
            my ($key, $value) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;
            $value =~ s/^\s+|\s+$//g;
            $value =~ s/^"(.*)"$/$1/;

            if (!$in_options) {
                $current->{name}     = $value if $key eq "name";
                $current->{platform} = $value if $key eq "platform";
            } else {
                $current->{options}{$key} = $value;
            }
        }
    }

    push @presets, $current if defined $current;
    close($fh);
    return @presets;
}

sub find_preset {
    my ($name, @presets) = @_;
    for my $p (@presets) {
        return $p if $p->{name} eq $name;
    }
    return undef;
}

# --- Commands ---
sub cmd_list {
    my (@presets) = @_;
    for my $p (@presets) {
        print "$p->{name}|$p->{platform}\n" if $p->{name} && $p->{platform};
    }
}

sub cmd_platform {
    my ($name, @presets) = @_;
    my $p = find_preset($name, @presets);
    if (!$p) { print STDERR "Error: Preset '$name' not found.\n"; exit 1; }
    print "$p->{platform}\n";
}

sub cmd_is_android {
    my ($name, @presets) = @_;
    my $p = find_preset($name, @presets);
    exit(($p && $p->{platform} eq "Android") ? 0 : 1);
}

sub cmd_has_android {
    my (@presets) = @_;
    for my $p (@presets) {
        exit 0 if $p->{platform} eq "Android";
    }
    exit 1;
}

sub cmd_all_android {
    my (@presets) = @_;
    my $found = 0;
    for my $p (@presets) {
        if ($p->{platform} eq "Android") {
            print "$p->{name}\n";
            $found = 1;
        }
    }
    exit 1 unless $found;
}

sub cmd_get {
    my ($name, $key, @presets) = @_;
    my $p = find_preset($name, @presets);
    if (!$p) { print STDERR "Error: Preset '$name' not found.\n"; exit 1; }
    print(($p->{options}{$key} // "") . "\n");
}

sub cmd_export_format {
    my ($name, @presets) = @_;
    my $p = find_preset($name, @presets);
    if (!$p) { print STDERR "Error: Preset '$name' not found.\n"; exit 1; }
    my $fmt = $p->{options}{"gradle_build/export_format"}
           // $p->{options}{"custom_build/export_format"}
           // "0";
    $fmt =~ s/^\s+|\s+$//g;
    print(($fmt eq "1" ? "aab" : "apk") . "\n");
}

sub cmd_keystore {
    my ($name, $type, @presets) = @_;
    unless ($type eq "debug" || $type eq "release") {
        print STDERR "Error: keystore type must be 'debug' or 'release'\n";
        exit 2;
    }
    my $p = find_preset($name, @presets);
    if (!$p) { print STDERR "Error: Preset '$name' not found.\n"; exit 1; }
    if ($p->{platform} ne "Android") { print "\n"; exit 0; }
    my $default = $type eq "debug" ? "debug.keystore" : "release.keystore";
    my $path = $p->{options}{"keystore/$type"} // "";
    $path =~ s/^res:\/\///;
    print(($path ? $path : $default) . "\n");
}

# --- Main ---
if (@ARGV < 1) {
    print "Usage: see script header\n";
    exit 2;
}

my @args = map { decode('UTF-8', $_) } @ARGV;
my $cmd = $args[0];
my $preset_arg = $args[1] // "";

my @presets = parse_presets($PRESETS_FILE);

if ($preset_arg eq $EXPORT_ALL_ID) {
    print "\n";
    exit 0;
}

if    ($cmd eq "list")                              { cmd_list(@presets) }
elsif ($cmd eq "platform"       && @args == 2)     { cmd_platform($args[1], @presets) }
elsif ($cmd eq "is_android"     && @args == 2)     { cmd_is_android($args[1], @presets) }
elsif ($cmd eq "has_android")                      { cmd_has_android(@presets) }
elsif ($cmd eq "all_android")                      { cmd_all_android(@presets) }
elsif ($cmd eq "get"            && @args == 3)     { cmd_get($args[1], $args[2], @presets) }
elsif ($cmd eq "export_format"  && @args == 2)     { cmd_export_format($args[1], @presets) }
elsif ($cmd eq "keystore"       && @args == 3)     { cmd_keystore($args[1], $args[2], @presets) }
else  { print "Usage: see script header\n"; exit 2 }
