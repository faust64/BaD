run-zero:
	./bench_a_disk -i /dev/zero -l ./logs-zero

graph-zero:
	ROW=1; grep -A1 avg-cpu: logs-zero/iostat.dat | grep '^[ \t]*[0-9]' | \
	    while read user nice system iowait steal idle; \
		do \
		    echo $$ROW $$user $$nice $$system $$iowait $$steal $$idle; \
		    ROW=`expr $$ROW + 1`; \
		done >logs-zero/cpu-usage.dat
	awk '{if (NF > 12) { print $$0; } }' logs-zero/iostat.dat | grep -v ^Device: | \
	    while read devname rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
		do \
		    echo $$devname $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
		done >logs-zero/blocks-usage.dat
	awk '{print $$1}' logs-zero/blocks-usage.dat | sort -u | \
	    while read devname; \
		do \
		    ROW=1; grep "^$$devname[ \t]" logs-zero/blocks-usage.dat | \
			while read name rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
			    do \
				echo $$ROW $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
				ROW=`expr $$ROW + 1`; \
			    done >logs-zero/blocks-$$devname-usage.dat; \
		done
	awk '/request=/' logs-zero/ioping | \
	    sed 's|.*request=\([0-9]*\) time=\([0-9\.]*\) \(..\)[ ]*\(.*\)$$|\1 \2 \3 \4|' | \
	    while read req time unit oth; \
		do \
		    val= ; \
		    if test "$$unit" = ms; then \
			if echo $$time | grep '\.' >/dev/null; then \
			    val=`echo $${time}0 | sed 's|\.\([0-9][0-9]0\)|\1|'`; \
			else \
			    val=$${time}000; \
			fi; \
		    elif test "$$unit" = us; then \
			val=$$time; \
		    fi; \
		    if test -z "$$val"; then \
			echo "unsupported unit $$unit, discarding data $$req ($$time)" >&2; \
			continue; \
		    fi; \
		    echo $$req $$val; \
		done >logs-zero/ioping.dat
	ls logs-zero/dd-read-block-bs*-* | sed 's|.*read-block-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-zero/dd-read-block-bs$$blocksize-* >logs-zero/dd-read-block-bs$$blocksize.dat; \
		done
	ls logs-zero/dd-write-bs*-*direct* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-zero/dd-write-bs$$blocksize-*direct* >logs-zero/dd-write-direct-bs$$blocksize.dat; \
		done
	ls logs-zero/dd-write-bs*-*fdatasync* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-zero/dd-write-bs$$blocksize-*fdatasync* >logs-zero/dd-write-fdatasync-bs$$blocksize.dat; \
		done
	./plots -l ./logs-zero

run-random:
	./bench_a_disk -l ./logs-random

graph-random:
	ROW=1; grep -A1 avg-cpu: logs-random/iostat.dat | grep '^[ \t]*[0-9]' | \
	    while read user nice system iowait steal idle; \
		do \
		    echo $$ROW $$user $$nice $$system $$iowait $$steal $$idle; \
		    ROW=`expr $$ROW + 1`; \
		done >logs-random/cpu-usage.dat
	awk '{if (NF > 12) { print $$0; } }' logs-random/iostat.dat | grep -v ^Device: | \
	    while read devname rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
		do \
		    echo $$devname $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
		done >logs-random/blocks-usage.dat
	awk '{print $$1}' logs-random/blocks-usage.dat | sort -u | \
	    while read devname; \
		do \
		    ROW=1; grep "^$$devname[ \t]" logs-random/blocks-usage.dat | \
			while read name rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
			    do \
				echo $$ROW $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
				ROW=`expr $$ROW + 1`; \
			    done >logs-random/blocks-$$devname-usage.dat; \
		done
	awk '/request=/' logs-random/ioping | \
	    sed 's|.*request=\([0-9]*\) time=\([0-9\.]*\) \(..\)[ ]*\(.*\)$$|\1 \2 \3 \4|' | \
	    while read req time unit oth; \
		do \
		    val= ; \
		    if test "$$unit" = ms; then \
			if echo $$time | grep '\.' >/dev/null; then \
			    val=`echo $${time}0 | sed 's|\.\([0-9][0-9]0\)|\1|'`; \
			else \
			    val=$${time}000; \
			fi; \
		    elif test "$$unit" = us; then \
			val=$$time; \
		    fi; \
		    if test -z "$$val"; then \
			echo "unsupported unit $$unit, discarding data $$req ($$time)" >&2; \
			continue; \
		    fi; \
		    echo $$req $$val; \
		done >logs-random/ioping.dat
	ls logs-random/dd-read-block-bs*-* | sed 's|.*read-block-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-random/dd-read-block-bs$$blocksize-* >logs-random/dd-read-block-bs$$blocksize.dat; \
		done
	ls logs-random/dd-write-bs*-*direct* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-random/dd-write-bs$$blocksize-*direct* >logs-random/dd-write-direct-bs$$blocksize.dat; \
		done
	ls logs-random/dd-write-bs*-*fdatasync* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$8;c=c+1;}' logs-random/dd-write-bs$$blocksize-*fdatasync* >logs-random/dd-write-fdatasync-bs$$blocksize.dat; \
		done
	./plots -l ./logs-random

reset:
	rm -fr logs-zero logs-random

setup:
	if ! test -d smallfile; then \
	    git clone https://github.com/bengland2/smallfile; \
	fi
	if ! test -d diskperf_utils; then \
	    mkdir diskperf_utils; \
	    for file in iograph.py mon_iostat.py test_diskread.py; \
	    do \
		curl -o diskperf_utils/$$file http://violin.qwer.tk/~dusty/misc/diskperf_utils/$$file; \
		chmod +x diskperf_utils/$$file; \
	    done; \
	fi
	./bench_a_disk -s
	./plots -s

random:	run-random graph-random

zero:	run-zero graph-zero

both:	reset random zero
