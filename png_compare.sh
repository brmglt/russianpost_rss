#!/usr/bin/env bash
img1=($(pngtopnm $1 | pnmtoplainpnm))
img2=($(pngtopnm $2 | pnmtoplainpnm))
min_sum=100000
for((k=-2; k<3; k++)) do 
	for((l=-2;l<3; l++)) do 
sum=0
		for((i=0; i<${img1[1]}; i++)) do 
			for((j=0; j<${img1[2]}; j++)) do 
				x=$((i+k)) y=$((j+l))
				((x<0 || y<0 || x>=img1[1] || y>= img1[2] || x>=img2[1] || y>= img2[2])) && continue
				digit1=$((img1[$((y*img1[1]*3+x*3+4))]/26)); 
				digit2=$((img2[$((y*img2[1]*3+x*3+4))]/26)); 
				d=$((digit2-digit1))
				((d>0)) && sum=$((sum+d)) || sum=$((sum-d))
			done
		done
		#echo k: $k l: $l sum: $sum
		((sum < min_sum)) && min_sum=$sum
	done
done
echo $min_sum
