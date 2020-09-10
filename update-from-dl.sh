# update-from-dl.sh: update individual parameter files from a monolithic download

for p in ???*.param;
  do
    awk -f `dirname $0`/update.awk dl.param $p > $p.dl &&
	mv $p.dl $p &&
	unix2dos $p
  done && 
 mv dl.param dl.param-old