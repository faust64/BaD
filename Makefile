run-zero:
	./bench_a_disk -c -i /dev/zero -l ./logs-zero

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
	./plots -l ./logs-zero

run-random:
	./bench_a_disk -c -l ./logs-random

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