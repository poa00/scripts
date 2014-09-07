#!/usr/bin/env perl

$path = $ARGV[0];
$webpath = $ARGV[1];
$indexname = $ARGV[2];

if (int(@ARGV) != 3) {
    print STDERR "Usage: search-index path web-path indexname\n\n";
    print STDERR "Where 'path' is the file system path to your\n";
    print STDERR "DocumentRoot or the subdirectory you want to index,\n";
    print STDERR "'web-path' is just \"\" (if you want to index the entire\n";
    print STDERR "server) or the web path to the subdirectory you are\n";
    print STDERR "indexing (such as /subdirname), and indexname is\n";
    print STDERR "typically searchindex.txt. You will need to change\n";
    print STDERR "the settings in search.pl to match.\n";
    exit 1;
}

$nextFd = 0;

open(OUT, ">$indexname");

&update($path, $webpath);

sub update {
    my($path, $webpath) = @_;
    my($dd) = $nextFd++;
    print "Updating in $path\n";
    if (!opendir($dd, $path)) {
        print STDERR "Warning: can't open $path\n";
        return;
    }
    while ($entry = readdir($dd)) {
        if ($entry =~ /^\.$/) {
            next;
        }
        if ($entry =~ /^\.\.$/) {
            next;
        }
        if (-d "$path/$entry") {
            &update("$path/$entry", "$webpath/$entry");
            next;
        }
        if (($entry !~ /.html$/i) && ($entry !~ /.htm$/i)) {
            next;
        }
        my($fd) = $nextFd++;
        if (!open($fd, "$path/$entry")) {
            print STDERR "Warning: can't open $path/$entry\n";
            next;
        }
        my(%words) = ( );
        my($line);
        while ($line = <$fd>) {
            # Support for turning off the search engine
            # indexer for parts of a page. These markers
            # must have a line to themselves. 3/13/00
            if ($line =~ /<\!\-\- SEARCH-ENGINE-OFF -->/) {
                while ($line = <$fd>) {
                    if ($line =~ /<\!\-\- SEARCH-ENGINE-ON -->/) {
                        last;
                    }
                }
                next;
            }
            # Simple HTML flusher
            $line =~ s/\<.*?\>//g;
            # Case insensitive
            $line =~ tr/A-Z/a-z/;
            # If it's not a letter, it's whitespace
            $line =~ s/[^a-z]/ /g;
            my(@words) = split(/\s+/, $line);
            my($p);
            for $p (@words) {
                if (length($p)) {
                    $words{$p}++;
                }
            }
        }
        print OUT "$webpath/$entry ";
        my($first) = 1;
        while (($key, $val) = each(%words)) {
            print OUT "$val:$key";
            if ($first) {
                $first = 0;
            } else {
                print OUT " ";
            }
        }
        print OUT "\n";
        close($fd);
    }
    closedir($dd);
}
close(OUT);

