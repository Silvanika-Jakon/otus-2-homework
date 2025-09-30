#!/bin/bash

RAID_DEV="/dev/md0"

# === Ввод количества дисков ===
read -p "Сколько дисков добавить в RAID 0? " NUM_DISKS

if ! [[ "$NUM_DISKS" =~ ^[0-9]+$ ]] || [[ "$NUM_DISKS" -lt 2 ]]; then
    echo "Нужно минимум 2 диска для RAID 0!"
    exit 1
fi

# === Ввод имен дисков ===
DISKS=()
for ((i=1; i<=NUM_DISKS; i++)); do
    read -p "Введите путь к диску #$i (например /dev/sdb): " DISK
    if [[ ! -b "$DISK" ]]; then
        echo "Ошибка: $DISK не существует или не является блоковым устройством!"
        exit 1
    fi
    DISKS+=("$DISK")
done

# === Подтверждение ===
echo "Вы выбрали следующие диски: ${DISKS[*]}"
read -p "ВНИМАНИЕ! Все данные на этих дисках будут уничтожены. Продолжить? (yes/[no]): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Операция отменена."
    exit 0
fi

# === Создание RAID 0 ===
echo "Создаю RAID 0..."
mdadm --create --verbose $RAID_DEV --level=0 --raid-devices=${#DISKS[@]} "${DISKS[@]}"

# === Проверка статуса ===
echo "Текущий статус массива:"
cat /proc/mdstat
mdadm --detail $RAID_DEV
