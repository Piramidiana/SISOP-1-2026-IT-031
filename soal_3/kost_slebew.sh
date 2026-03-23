#!/bin/bash

DATA="$HOME/soal_3/data/penghuni.csv"
LOG="$HOME/soal_3/log/tagihan.log"
REKAP="$HOME/soal_3/rekap/laporan_bulanan.txt"
SAMPAH="$HOME/soal_3/sampah/history_hapus.csv"

tambah_penghuni() {
    echo "============================================"
    echo "            TAMBAH PENGHUNI"
    echo "============================================"
    read -p "Masukkan Nama: " nama
    read -p "Masukkan Kamar: " kamar
    read -p "Masukkan Harga Sewa: " harga
    read -p "Masukkan Tanggal Masuk (YYYY-MM-DD): " tanggal
    read -p "Masukkan Status Awal (Aktif/Menunggak): " status

    # Validasi kamar tidak boleh sama
    cek=$(awk -F',' -v k="$kamar" 'NR>1 && $2==k {print $2}' $DATA)
    if [ ! -z "$cek" ]; then
        echo "Kamar $kamar sudah terisi!"
        return
    fi

    # Validasi status
    if [ "$status" != "Aktif" ] && [ "$status" != "Menunggak" ]; then
        echo "Status harus Aktif atau Menunggak!"
        return
    fi

    # Validasi harga positif
    if [ "$harga" -le 0 ] 2>/dev/null; then
        echo "Harga sewa harus angka positif!"
        return
    fi

    echo "$nama,$kamar,$harga,$tanggal,$status" >> $DATA
    echo "[√] Penghuni \"$nama\" berhasil ditambahkan ke Kamar $kamar dengan status $status."
}

hapus_penghuni() {
    echo "============================================"
    echo "            HAPUS PENGHUNI"
    echo "============================================"
    read -p "Masukkan nama penghuni yang akan dihapus: " nama

    cek=$(awk -F',' -v n="$nama" 'NR>1 && $1==n {print $1}' $DATA)
    if [ -z "$cek" ]; then
        echo "Penghuni $nama tidak ditemukan!"
        return
    fi

    tanggal_hapus=$(date +%Y-%m-%d)
    awk -F',' -v n="$nama" -v t="$tanggal_hapus" 'NR>1 && $1==n {print $0","t}' $DATA >> $SAMPAH
    sed -i "/^$nama,/d" $DATA
    echo "[√] Data penghuni \"$nama\" berhasil diarsipkan ke sampah/history_hapus.csv dan dihapus dari sistem."
}

tampil_penghuni() {
    echo "============================================"
    echo "       DAFTAR PENGHUNI KOST SLEBEW         "
    echo "============================================"
    echo "No | Nama            | Kamar | Harga Sewa  | Status"
    echo "----------------------------------------------------"

    awk -F',' 'NR>1 {
        printf "%-3d| %-16s| %-6s| %-12s| %s\n", NR-1, $1, $2, $3, $5
    }' $DATA

    total=$(awk -F',' 'NR>1 {count++} END {print count+0}' $DATA)
    aktif=$(awk -F',' 'NR>1 && $5=="Aktif" {count++} END {print count+0}' $DATA)
    menunggak=$(awk -F',' 'NR>1 && $5=="Menunggak" {count++} END {print count+0}' $DATA)

    echo "----------------------------------------------------"
    echo "Total: $total penghuni | Aktif: $aktif | Menunggak: $menunggak"
    echo "============================================"
}

update_laporan() {
    echo "============================================"
    echo "         UPDATE STATUS PENGHUNI            "
    echo "============================================"
    read -p "Masukkan nama penghuni: " nama
    read -p "Status baru (Aktif/Menunggak): " status_baru

    cek=$(awk -F',' -v n="$nama" 'NR>1 && $1==n {print $1}' $DATA)
    if [ -z "$cek" ]; then
        echo "Penghuni $nama tidak ditemukan!"
        return
    fi

    sed -i "s/^$nama,\(.*\),\(.*\)$/$nama,\1,$status_baru/" $DATA
    echo "[√] Status $nama berhasil diupdate ke $status_baru"

    echo ""
    echo "============================================"
    echo "       LAPORAN KEUANGAN KOST SLEBEW        "
    echo "============================================"

    total_aktif=$(awk -F',' 'NR>1 && $5=="Aktif" {total+=$3} END {print total+0}' $DATA)
    total_menunggak=$(awk -F',' 'NR>1 && $5=="Menunggak" {total+=$3} END {print total+0}' $DATA)
    jumlah_kamar=$(awk -F',' 'NR>1 {count++} END {print count+0}' $DATA)

    echo "Total pemasukan (Aktif)  : Rp$total_aktif"
    echo "Total tunggakan          : Rp$total_menunggak"
    echo "Jumlah kamar terisi      : $jumlah_kamar"
    echo "--------------------------------------------"
    echo "Daftar penghuni menunggak:"
    menunggak=$(awk -F',' 'NR>1 && $5=="Menunggak" {print "  - "$1}' $DATA)
    if [ -z "$menunggak" ]; then
        echo "  Tidak ada tunggakan."
    else
        echo "$menunggak"
    fi
    echo "============================================"

    {
        echo "============================================"
        echo "       LAPORAN KEUANGAN KOST SLEBEW        "
        echo "============================================"
        echo "Total pemasukan (Aktif)  : Rp$total_aktif"
        echo "Total tunggakan          : Rp$total_menunggak"
        echo "Jumlah kamar terisi      : $jumlah_kamar"
        echo "============================================"
    } > $REKAP

    echo "[√] Laporan berhasil disimpan ke rekap/laporan_bulanan.txt"
}

kelola_cron() {
    while true
    do
        echo "================================"
        echo "        MENU KELOLA CRON        "
        echo "================================"
        echo "1. Lihat Cron Job Aktif"
        echo "2. Daftarkan Cron Job Pengingat"
        echo "3. Hapus Cron Job Pengingat"
        echo "4. Kembali"
        echo "================================"
        read -p "Pilih [1-4]: " opsi_cron

        case $opsi_cron in
            1)
                echo "Cron job aktif:"
                crontab -l 2>/dev/null || echo "Tidak ada cron job."
                ;;
            2)
                read -p "Masukkan Jam (0-23): " jam
                read -p "Masukkan Menit (0-59): " menit
                SCRIPT="$HOME/soal_3/kost_slebew.sh"
                crontab -l 2>/dev/null | grep -v "kost_slebew" > /tmp/crontab_tmp
                echo "$menit $jam * * * $SCRIPT --check-tagihan >> $LOG 2>&1" >> /tmp/crontab_tmp
                crontab /tmp/crontab_tmp
                echo "[√] Cron job pengingat tagihan didaftarkan (setiap hari jam $jam:$menit)."
                ;;
            3)
                crontab -l 2>/dev/null | grep -v "kost_slebew" > /tmp/crontab_tmp
                crontab /tmp/crontab_tmp
                echo "[√] Cron job pengingat tagihan berhasil dihapus."
                ;;
            4)
                break
                ;;
            *)
                echo "Pilihan tidak valid!"
                ;;
        esac
        echo ""
        read -p "Tekan [ENTER] untuk kembali ke menu cron..."
    done
}

# Handle argumen --check-tagihan untuk cron
if [ "$1" == "--check-tagihan" ]; then
    tanggal=$(date +%Y-%m-%d)
    echo "[$tanggal] Penghuni menunggak:" >> $LOG
    awk -F',' 'NR>1 && $5=="Menunggak" {print "  - "$1}' $DATA >> $LOG
    exit 0
fi

# Menu utama
while true
do
    clear
clear
clear
echo '  _  _____  ___ _____   ___ _    ___ ___ _____      __ '
echo ' | |/ / _ \/ __|_   _| / __| |  | __| _ ) __\ \    / / '
echo ' | | < (_) \__ \ | |   \__ \ |__| _|| _ \ _| \ \/\/ /  '
echo ' |_|\_\___/|___/ |_|   |___/____|___|___/___| \_/\_/   '
echo "================================================"
echo "         SISTEM MANAJEMEN KOST SLEBEW           "
echo "================================================"
echo " ID | OPTION"
    echo "--------------------------------------------"
    echo "  1 | Tambah Penghuni Baru"
    echo "  2 | Hapus Penghuni"
    echo "  3 | Tampilkan Daftar Penghuni"
    echo "  4 | Update Status & Cetak Laporan Keuangan"
    echo "  5 | Kelola Cron (Pengingat Tagihan)"
    echo "  6 | Exit Program"
    echo "================================================"
    read -p "Enter option [1-6]: " pilihan

    case $pilihan in
        1) tambah_penghuni ;;
        2) hapus_penghuni ;;
        3) tampil_penghuni ;;
        4) update_laporan ;;
        5) kelola_cron ;;
        6)
            echo "Sampai jumpa!"
            exit 0
            ;;
        *)
            echo "Pilihan tidak valid!"
            ;;
    esac

    echo ""
    read -p "Tekan [ENTER] untuk kembali ke menu..."
done
