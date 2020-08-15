# update.awk: update parameter values in a subset file from a superset.
# leaves comments and endemic paramters unchanged, preserves key order of subset.
# usage: awk -f update.awk recent-dump.param canonical.param

BEGIN { FS="," }
ARGIND==1 { newvalues[$1]=$0 }
ARGIND==2 { if($1 in newvalues) {print newvalues[$1]} else {print} }