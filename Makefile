graph:
	@@if test -z "$$LOG_PATH"; then \
	    LOG_PATH=./logs-zero; \
	fi; \
	ROW=1; grep -A1 avg-cpu: "$$LOG_PATH"/iostat.dat | grep '^[ \t]*[0-9]' | \
	    while read user nice system iowait steal idle; \
		do \
		    echo $$ROW $$user $$nice $$system $$iowait $$steal $$idle; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/cpu-usage.dat; \
	awk '{if (NF > 12) { print $$0; } }' "$$LOG_PATH"/iostat.dat | grep -v ^Device: | \
	    while read devname rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
		do \
		    echo $$devname $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
		done >"$$LOG_PATH"/blocks-usage.dat; \
	awk '{print $$1}' "$$LOG_PATH"/blocks-usage.dat | sort -u | \
	    while read devname; \
		do \
		    ROW=1; grep "^$$devname[ \t]" "$$LOG_PATH"/blocks-usage.dat | \
			while read name rrqm wrqm rs ws rmbs wmbs avgrqsz avgqusz await rawait wawait svctm util; \
			    do \
				echo $$ROW $$rrqm $$wrqm $$rs $$ws $$rmbs $$wmbs $$avgrqsz $$avgqusz $$await $$rawait $$wawait $$svctm $$util; \
				ROW=`expr $$ROW + 1`; \
			    done >"$$LOG_PATH"/blocks-$$devname-usage.dat; \
		done; \
	awk '/request=/' "$$LOG_PATH"/ioping | \
	    sed 's|.*request=\([0-9]*\) time=\([0-9\.]*\) \([^s]*[s]\)[ ]*\(.*\)$$|\1 \2 \3 \4|' | \
	    while read req time unit oth; \
		do \
		    val= ; \
		    if test "$$unit" = ms; then \
			if echo $$time | grep '\.' >/dev/null; then \
			    val=`echo $${time}0 | sed 's|\.\([0-9][0-9]0\)|\1|'`; \
			else \
			    val=$${time}000; \
			fi; \
		    elif test "$$unit" = s; then \
			if echo $$time | grep '\.' >/dev/null; then \
			    val=`echo $${time}0000 | sed 's|\.\([0-9][0-9]0000\)|\1|'`; \
			else \
			    val=$${time}000000; \
			fi; \
		    elif test "$$unit" = us; then \
			val=$$time; \
		    fi; \
		    if test -z "$$val"; then \
			echo "unsupported unit $$unit, discarding data $$req ($$time)" >&2; \
			continue; \
		    fi; \
		    echo $$req $$val; \
		done >"$$LOG_PATH"/ioping.dat; \
	ls "$$LOG_PATH"/dd-read-block-bs*-* | sed 's|.*read-block-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$0 ;c=c+1;}' "$$LOG_PATH"/dd-read-block-bs$$blocksize-* | \
			while read counter line; \
			do \
			    eval `echo "$$line" | sed 's|.* s, \([0-9\.]*\) \([KGBM]\)[B]*/s.*|speed=\1 unit=\2|'`; \
			    if test "$$unit" = G; then \
				speed="`printf "%.03f\n" "$$speed" | sed 's|\.||'`"; \
			    elif test "$$unit" = K; then \
				speed="0.`printf "%03.0f" "$$speed"`"; \
			    elif test "$$unit" = B; then \
				speed="0.`printf "%06.0f" "$$speed"`"; \
			    fi; \
			     echo "$$counter $$speed"; \
			done >"$$LOG_PATH"/dd-read-block-bs$$blocksize.dat; \
		done; \
	ls "$$LOG_PATH"/dd-write-bs*-*direct* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$0 ;c=c+1;}' "$$LOG_PATH"/dd-write-bs$$blocksize-*direct* | \
			while read counter line; \
			do \
			    eval `echo "$$line" | sed 's|.* s, \([0-9\.]*\) \([KGBM]\)[B]*/s.*|speed=\1 unit=\2|'`; \
			    if test "$$unit" = G; then \
				speed="`printf "%.03f\n" "$$speed" | sed 's|\.||'`"; \
			    elif test "$$unit" = K; then \
				speed="0.`printf "%03.0f" "$$speed"`"; \
			    elif test "$$unit" = B; then \
				speed="0.`printf "%06.0f" "$$speed"`"; \
			    fi; \
			     echo "$$counter $$speed"; \
			done >"$$LOG_PATH"/dd-write-direct-bs$$blocksize.dat; \
		done; \
	ls "$$LOG_PATH"/dd-write-bs*-*fdatasync* | sed 's|.*write-bs\([^-]*\)-.*|\1|' | sort -u | \
	    while read blocksize; \
		do \
		    awk 'BEGIN{c=1}/copied/{print c " " $$0 ;c=c+1;}' "$$LOG_PATH"/dd-write-bs$$blocksize-*fdatasync* | \
			while read counter line; \
			do \
			    eval `echo "$$line" | sed 's|.* s, \([0-9\.]*\) \([KGBM]\)[B]*/s.*|speed=\1 unit=\2|'`; \
			    if test "$$unit" = G; then \
				speed="`printf "%.03f\n" "$$speed" | sed 's|\.||'`"; \
			    elif test "$$unit" = K; then \
				speed="0.`printf "%03.0f" "$$speed"`"; \
			    elif test "$$unit" = B; then \
				speed="0.`printf "%06.0f" "$$speed"`"; \
			    fi; \
			     echo "$$counter $$speed"; \
			done >"$$LOG_PATH"/dd-write-fdatasync-bs$$blocksize.dat; \
		done; \
	if grep 'iops[ ]*:' "$$LOG_PATH"/fio-randrw* >/dev/null 2>&1; then \
	    ROW=1; grep -A2 'read: IOPS' "$$LOG_PATH"/fio-randrw* | awk '/iops[ ]*:/' | sed 's|.*min=[ ]*\([0-9\.]*\), max=[ ]*\([0-9\.]*\), avg=[ ]*\([0-9\.]*\),.*|\1 \2 \3|' | \
		while read min max avg; \
		    do \
			echo $$ROW $$min $$max $$avg; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-read-randrw-iops.dat; \
	    ROW=1; grep -A2 'write: IOPS' "$$LOG_PATH"/fio-randrw* | awk '/iops[ ]*:/' | sed 's|.*min=[ ]*\([0-9\.]*\), max=[ ]*\([0-9\.]*\), avg=[ ]*\([0-9\.]*\),.*|\1 \2 \3|' | \
		while read min max avg; \
		    do \
			echo $$ROW $$min $$max $$avg; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-write-randrw-iops.dat; \
	    ROW=1; grep -A2 'write: IOPS' "$$LOG_PATH"/fio-randwrite* | awk '/iops[ ]*:/' | sed 's|.*min=[ ]*\([0-9\.]*\), max=[ ]*\([0-9\.]*\), avg=[ ]*\([0-9\.]*\),.*|\1 \2 \3|' | \
		while read min max avg; \
		    do \
			echo $$ROW $$min $$max $$avg; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-write-randwrite-iops.dat; \
	    rm -f "$$LOG_PATH"/fio-custom-iops-*.dat; \
	    ROW=1; cat "$$LOG_PATH"/fio-4threads* | awk '/iops[ ]*:/' | sed 's|.*min=[ ]*\([0-9\.]*\), max=[ ]*\([0-9\.]*\), avg=[ ]*\([0-9\.]*\),.*|\1 \2 \3|' | \
		while read min max avg; \
		    do \
			mod=`expr $$ROW % 5`; PFX=; \
			if test "$$mod" = 1; then PFX=bgwriter; \
			elif test "$$mod" = 2; then PFX=queryA; \
			elif test "$$mod" = 3; then PFX=queryB; \
			elif test "$$mod" = 4; then PFX=bgupdread; \
			else PFX=bgupdwrite; fi; \
			eval cpt=\$$\{$${PFX}count\}; \
			test -z "$$cpt" && cpt=1; \
			echo "$$cpt $$min $$max $$avg" >>"$$LOG_PATH"/fio-custom-iops-$$PFX.dat; \
			eval $${PFX}count=`expr $$cpt + 1`; \
			ROW=`expr $$ROW + 1`; \
		    done; \
	else \
	    ROW=1; awk '/read[ ]*:.*iops=/' "$$LOG_PATH"/fio-randrw* | sed 's|.*iops=[ ]*\([0-9\.]*\),.*|\1|' | \
		while read iops; \
		    do \
			echo $$ROW $$iops; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-read-randrw-iops.dat; \
	    ROW=1; awk '/write[ ]*:.*iops=/' "$$LOG_PATH"/fio-randrw* | sed 's|.*iops=[ ]*\([0-9\.]*\),.*|\1|' | \
		while read iops; \
		    do \
			echo $$ROW $$iops; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-write-randrw-iops.dat; \
	    ROW=1; awk '/write[ ]*:.*iops=/' "$$LOG_PATH"/fio-randwrite* | sed 's|.*iops=[ ]*\([0-9\.]*\),.*|\1|' | \
		while read iops; \
		    do \
			echo $$ROW $$iops; \
			ROW=`expr $$ROW + 1`; \
		    done >"$$LOG_PATH"/fio-write-randwrite-iops.dat; \
	    rm -f "$$LOG_PATH"/fio-custom-iops-*.dat; \
	    ROW=1; awk '/iops=/' "$$LOG_PATH"/fio-4threads* | sed 's|.*iops=[ ]*\([0-9\.]*\),.*|\1|' | \
		while read iops; \
		    do \
			mod=`expr $$ROW % 5`; PFX=; \
			if test "$$mod" = 1; then PFX=bgwriter; \
			elif test "$$mod" = 2; then PFX=queryA; \
			elif test "$$mod" = 3; then PFX=queryB; \
			elif test "$$mod" = 4; then PFX=bgupdread; \
			else PFX=bgupdwrite; fi; \
			eval cpt=\$$\{$${PFX}count\}; \
			test -z "$$cpt" && cpt=1; \
			echo "$$cpt $$iops" >>"$$LOG_PATH"/fio-custom-iops-$$PFX.dat; \
			eval $${PFX}count=`expr $$cpt + 1`; \
			ROW=`expr $$ROW + 1`; \
		    done; \
	fi; \
	ROW=1; cat "$$LOG_PATH"/fio-randrw* | awk '/READ:/' | sed -e 's|.*bw=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' -e 's|.*aggrb=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' | \
	    while read throughput unit; \
		do \
		    if test "$$unit" = K; then throughput=`printf "%.03f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = M; then throughput=`printf "%06f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = G; then throughput=`printf "%09f" $$throughput | sed 's|\.||'`; \
		    fi; \
		    throughput=`expr $$throughput / 1000000`; \
		    echo $$ROW $$throughput; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/fio-read-randrw-throughput.dat; \
	ROW=1; cat "$$LOG_PATH"/fio-randrw* | awk '/WRITE:/' | sed -e 's|.*bw=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' -e 's|.*aggrb=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' | \
	    while read throughput unit; \
		do \
		    if test "$$unit" = K; then throughput=`printf "%.03f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = M; then throughput=`printf "%06f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = G; then throughput=`printf "%09f" $$throughput | sed 's|\.||'`; \
		    fi; \
		    throughput=`expr $$throughput / 1000000`; \
		    echo $$ROW $$throughput; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/fio-write-randrw-throughput.dat; \
	ROW=1; cat "$$LOG_PATH"/fio-randwrite* | awk '/WRITE:/' | sed -e 's|.*bw=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' -e 's|.*aggrb=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' | \
	    while read throughput unit; \
		do \
		    if test "$$unit" = K; then throughput=`printf "%.03f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = M; then throughput=`printf "%06f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = G; then throughput=`printf "%09f" $$throughput | sed 's|\.||'`; \
		    fi; \
		    throughput=`expr $$throughput / 1000000`; \
		    echo $$ROW $$throughput; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/fio-write-randwrite-throughput.dat; \
	ROW=1; cat "$$LOG_PATH"/fio-4threads* | awk '/READ:/' | sed -e 's|.*bw=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' -e 's|.*aggrb=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' | \
	    while read throughput unit; \
		do \
		    if test "$$unit" = K; then throughput=`printf "%.03f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = M; then throughput=`printf "%06f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = G; then throughput=`printf "%09f" $$throughput | sed 's|\.||'`; \
		    fi; \
		    throughput=`expr $$throughput / 1000000`; \
		    echo $$ROW $$throughput; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/fio-read-4threads-throughput.dat; \
	ROW=1; cat "$$LOG_PATH"/fio-4threads* | awk '/WRITE:/' | sed -e 's|.*bw=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' -e 's|.*aggrb=\([0-9\.]*\)\([KMG]*\)[i]*B/s.*|\1 \2|' | \
	    while read throughput unit; \
		do \
		    if test "$$unit" = K; then throughput=`printf "%.03f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = M; then throughput=`printf "%06f" $$throughput | sed 's|\.||'`; \
		    elif test "$$unit" = G; then throughput=`printf "%09f" $$throughput | sed 's|\.||'`; \
		    fi; \
		    throughput=`expr $$throughput / 1000000`; \
		    echo $$ROW $$throughput; \
		    ROW=`expr $$ROW + 1`; \
		done >"$$LOG_PATH"/fio-write-4threads-throughput.dat; \
	./plots -l "$$LOG_PATH"

run-random:
	./bench_a_disk -l ./logs-random

run-zero:
	./bench_a_disk -i /dev/zero -l ./logs-zero

run:	run-random

reset:
	rm -fr logs-zero logs-random

setup:
	@@if ! test -d smallfile; then \
	    git clone https://github.com/bengland2/smallfile; \
	fi
	@@if ! test -d diskperf_utils; then \
	    mkdir diskperf_utils; \
	    for file in iograph.py mon_iostat.py test_diskread.py; \
	    do \
		curl -o diskperf_utils/$$file http://violin.qwer.tk/~dusty/misc/diskperf_utils/$$file; \
		chmod +x diskperf_utils/$$file; \
	    done; \
	fi
	@@./bench_a_disk -s
	@@./plots -s

random:	run-random
	LOG_PATH=./logs-random make graph

zero:	run-zero
	LOG_PATH=./logs-zero make graph

all:	reset random

both:	reset random zero
