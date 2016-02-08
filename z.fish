set -q _Z_DATA; or set -x _Z_DATA $HOME/.z
test -d $_Z_DATA; and echo "ERROR: z.fish's datafile ($_Z_DATA) is a directory."

function __z_echo_dir
    test -d (string replace -r '\|.*$' '' $argv); and echo $argv
end

function _z_add
    set -l datafile $_Z_DATA
    [ "$argv" = "$HOME" ]; and return

    set -l tempfile "$datafile.(random)"
    while read line
        __z_echo_dir $line
    end < "$datafile" | awk -v path="$argv" -v now=(date +%s) -F"|" '
        BEGIN {
            rank[path] = 1
            time[path] = now
        }
        $2 >= 1 {
            # drop ranks below 1
            if( $1 == path ) {
                rank[$1] = $2 + 1
                time[$1] = now
            } else {
                rank[$1] = $2
                time[$1] = $3
            }
            count += $2
        }
        END {
            if( count > 9000 ) {
                # aging
                for( x in rank ) print x "|" 0.99*rank[x] "|" time[x]
            } else for( x in rank ) print x "|" rank[x] "|" time[x]
        }
    ' ^/dev/null > "$tempfile"
    [ $status -o ! -f "$datafile" ]; and env mv -f "$tempfile" "$datafile"
    env rm -f "$tempfile"
end

function z
    set datafile $_Z_DATA

    set -l fnd
    set -l last
    for arg in $argv
        if test -z "$fnd"
            set fnd "$arg"
        else
            set fnd "$fnd $arg"
        end
        set last $arg
    end
    [ -z $last ]; and return

    test -f "$datafile"; or return

    set -l cd (
    while read line
        __z_echo_dir $line
    end < "$datafile" | awk -v t=(date +%s) -v list="$list" -v typ="$typ" -v q="$fnd" -F"|" '
        function frecent(rank, time) {
            # relate frequency and time
            dx = t - time
            if( dx < 3600 ) return rank * 4
            if( dx < 86400 ) return rank * 2
            if( dx < 604800 ) return rank / 2
            return rank / 4
        }
        function output(files, out, common) {
            # list or return the desired directory
            if( list ) {
                cmd = "sort -n >&2"
                for( x in files ) {
                    if( files[x] ) printf "%-10s %s\n", files[x], x | cmd
                }
                if( common ) {
                    printf "%-10s %s\n", "common:", common > "/dev/stderr"
                }
            } else {
                if( common ) out = common
                print out
            }
        }
        function common(matches) {
            # find the common root of a list of matches, if it exists
            for( x in matches ) {
                if( matches[x] && (!short || length(x) < length(short)) ) {
                    short = x
                }
            }
            if( short == "/" ) return
            # use a copy to escape special characters, as we want to return
            # the original. yeah, this escaping is awful.
            clean_short = short
            gsub(/\[\(\)\[\]\|\]/, "\\\\&", clean_short)
            for( x in matches ) if( matches[x] && x !~ clean_short ) return
            return short
        }
        BEGIN {
            gsub(" ", ".*", q)
            hi_rank = ihi_rank = -9999999999
        }
        {
            if( typ == "rank" ) {
                rank = $2
            } else if( typ == "recent" ) {
                rank = $3 - t
            } else rank = frecent($2, $3)
            if( $1 ~ q ) {
                matches[$1] = rank
            } else if( tolower($1) ~ tolower(q) ) imatches[$1] = rank
            if( matches[$1] && matches[$1] > hi_rank ) {
                best_match = $1
                hi_rank = matches[$1]
            } else if( imatches[$1] && imatches[$1] > ihi_rank ) {
                ibest_match = $1
                ihi_rank = imatches[$1]
            }
        }
        END {
            # prefer case sensitive
            if( best_match ) {
                output(matches, best_match, common(matches))
            } else if( ibest_match ) {
                output(imatches, ibest_match, common(imatches))
            }
        }
    ')
    test $status -gt 0; and return
    test "$cd"; or return
    cd $cd
end

function __z_precmd --on-event fish_preexec
    _z_add $PWD
end
