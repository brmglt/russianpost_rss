#!/usr/bin/env bash
if [ "x$QUERY_STRING" = "x" ]; then
	track_id=$1
	out=/var/www/russianpost/russianpost.xml
	url=http://localhost/russianpost/russianpost.xml
else
	echo $'Content-Type: application/xml;charset=utf-8\r\n'
	track_id=`echo $QUERY_STRING | sed 's/[^a-zA-Z0-9]//g'`
	out="&1"
	url=http://$SERVER_NAME
	[ "x$SERVER_PORT" != "x80" ] && url=$url:${SERVER_PORT}
	url=$url$REQUEST_URI
fi
export http_proxy=http://127.0.0.1:8118
mywget() { wget --save-cookies=russianpost.cookie --load-cookies=russianpost.cookie -q -O - "$@"; }
not_all_digits()
{
	((`ls captcha-digits | wc -w` < 5))
}
log()
{
	if [ "x$QUERY_STRING" = "x" ]; then
		echo $*
	else
		echo DEBUG: $* >&2
	fi
}
wait_jobs()
{
	log "Waiting for `jobs -p | wc -l` jobs..."
	wait `jobs -p`
}
while true; do
	rm captcha-digits/*
	while not_all_digits; do
		key=`mywget http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo | grep -oP '(?<=value=")([^"]*)'`
		start=1
		log key: $key
		captcha=
		while [ "x$captcha" = "x" ]; do
			[ "x$start" = "x" ] || start=
			html=`mywget http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo --post-data="key=$key"`
			captcha=$(echo $html | grep -oP "(?<=src=')[^']*")
			CaptchaId=`echo $html | grep -oP "(?<=id='CaptchaId' value=')([^']*)"`
			log captcha link: $captcha, CaptchaId: $CaptchaId
		done

		rm captcha-digits/*
		for((p=0; p<10; p++)) do 
			{
				log $p worker started, pid=$$...
				while not_all_digits; do
					log There are just `ls captcha-digits | wc -w` digits available, try once more...
					png=captcha/Captcha-$(echo $captcha|grep -oP '(?<==)\d+')-$p.png
					for((i=0; i<3; i++)) do 
						mywget $captcha > $png
						mime=`file -ib $png`
						log mime: $mime
						#display $png&
						[ "x$mime" = "ximage/png" ] && { img=($(pngtopnm $png | pnmtoplainpnm)); break; }
					done
					[ "x$mime" != "ximage/png" ] && break
					xmin=
					ymaxmax=0
					yminmin=1000
					for((i=0; i<${img[1]}; i++)) do 
						ymin=
						ymax=
						for((j=0; j<${img[2]}; j++)) do 
							digit=$((img[$((j*img[1]*3+i*3+4))]/26)); 
							[ "x$ymin" = "x" -a "x$digit" != "x9" ] && ymin=$j
							[ "x$ymin" != "x" -a "x$digit" = "x9" -a "x$old" != "x9" ] && ymax=$j
							[ "x$ymin" != "x" ] && (( $ymin < $yminmin )) && yminmin=$ymin
							[ "x$ymax" != "x" ] && (( $ymax > $ymaxmax )) && ymaxmax=$ymax
							#[ "x$digit" = "x9" ] && printf ' ' || printf '%s' $digit;  
							old=$digit
						done; 
						#echo; 
						[ "x$xmin" = "x" -a "x$ymin" != "x" ] && xmin=$i
						if [ "x$xmin" != "x" -a "x$ymin" = "x" ]; then 
							xmax=$i; 
							#echo "xmin: $xmin xmax: $xmax yminmin: $yminmin ymaxmax: $ymaxmax"; 
							width=$((xmax-xmin))
							height=$((ymaxmax-yminmin))
							num=$(((xmax+xmin)/2/14))
							digit_png="captcha-digits/$num.png"
							[ ! -f $digit_png ] && ((width<15)) && convert $png -crop "${width}x$height+$xmin+$yminmin" -resize 12x16+0+0 $digit_png
							xmin=; 
							ymaxmax=0
							yminmin=1000
						fi
					done 
					#rm $png
				done
			}&
		done
		wait_jobs
	done
	code=
	for((i=0; i<5; i++)) do 
		min=10000
		for((j=0; j<10; j++)) do 
			d=`./png_compare.sh captcha-digits/$i.png captcha-digits-standart/$j.png`
			((d < min)) && min=$d num=$j
		done
		log "digit #$num min $min"
		code=$code$num
	done
	log code is $code
	datepart=`date +'CMONTH=%m&CDAY=%d&CYEAR=%Y'`
	#echo mywget http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo --post-data="BarCode=$1&InputedCaptchaCode=$code&CaptchaId=$CaptchaId&searchsign=1&$datepart&PATHCUR=rp/servise/ru/home/postuslug/trackingpo"
	html_tmp=`tempfile`
	#echo html_tmp: $html_tmp
	mywget http://www.russianpost.ru/resp_engine.aspx?Path=rp/servise/ru/home/postuslug/trackingpo --post-data="BarCode=$track_id&InputedCaptchaCode=$code&CaptchaId=$CaptchaId&searchsign=1&$datepart&PATHCUR=rp/servise/ru/home/postuslug/trackingpo" > $html_tmp
	err=`grep -oP '(?<=CaptchaErrorCodeContainer">)[^<]+' $html_tmp` && echo "Site error: $err"  || { grep -q 'Результат поиска' $html_tmp && break; }
	log html_tmp: $html_tmp
done 
eval "xsltproc --stringparam url '$url' --stringparam item_root '${url%/*}' --encoding utf-8 --html russianpost.xsl '$html_tmp' >$out 2>/dev/null"
