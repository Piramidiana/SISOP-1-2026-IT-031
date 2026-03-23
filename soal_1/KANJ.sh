#!/bin/bash

FILE=$1
SOAL=$2

if [ -z "$FILE" ] || [ -z "$SOAL" ]; then
    echo "Penggunaan: ./KANJ.sh passenger.csv a/b/c/d/e"
    exit 1
fi

case $SOAL in
    a)
        count_passenger=$(awk -F',' 'NR>1 {count++} END {print count}' $FILE)
        echo "Jumlah seluruh penumpang KANJ adalah ${count_passenger} orang"
        ;;
    b)
        carriage=$(awk -F',' 'NR>1 {gerbong[$4]=1} END {print length(gerbong)}' $FILE)
        echo "Jumlah gerbong penumpang KANJ adalah ${carriage}"
        ;;
    c)
        age=$(awk -F',' 'NR>1 {if($2+0>max+0) max=$2} END {print max}' $FILE)
        nama=$(awk -F',' -v m="$age" 'NR>1 && $2==m {print $1}' $FILE)
        echo "${nama} adalah penumpang kereta tertua dengan usia ${age} tahun"
        ;;
    d)
        average_age=$(awk -F',' 'NR>1 {total+=$2; count++} END {print int(total/count)}' $FILE)
        echo "Rata-rata usia penumpang adalah ${average_age} tahun"
        ;;
    e)
        business_passenger=$(awk -F',' 'NR>1 && $3=="Business" {count++} END {print count}' $FILE)
        echo "Jumlah penumpang business class ada ${business_passenger} orang"
        ;;
    *)
        echo "Soal tidak dikenali. Gunakan a, b, c, d, atau e."
        echo "Contoh penggunaan: ./KANJ.sh data.csv a"
        ;;
esac
