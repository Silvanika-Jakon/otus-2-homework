# Домашнее задание: работа с mdadm
## Задание  
• Добавить в виртуальную машину несколько дисков  
• Собрать RAID-0/1/5/10 на выбор  
• Сломать и починить RAID  
• Создать GPT таблицу, пять разделов и смонтировать их в системе.  

Выполнение:
1. Добавила в виртуальную машину 5 дисков.
```
lsblk
NAME         MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS  
sda            8:0    0  10G  0 disk  
├─sda1         8:1    0   1M  0 part  
├─sda2         8:2    0   1G  0 part /boot  
└─sda3         8:3    0   9G  0 part  
  └─vg0-root 252:0    0   9G  0 lvm  /  
sdb            8:16   0   1G  0 disk  
sdc            8:32   0   1G  0 disk  
sdd            8:48   0   1G  0 disk  
sde            8:64   0   1G  0 disk  
sdf            8:80   0   1G  0 disk  
```
2. Занулила суперблоки
```
root@efilimonova:~# mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sdf
```

3. Создала RAID-6.
```
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
```

4. Проверила рейд.
```
root@efilimonova:~# cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md0 : active raid6 sdf[4] sde[3] sdd[2] sdc[1] sdb[0]
      3139584 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]
unused devices: <none>

/dev/md0:
           Version : 1.2
     Creation Time : Wed Oct  1 01:08:36 2025
        Raid Level : raid6
        Array Size : 3139584 (2.99 GiB 3.21 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Wed Oct  1 01:08:44 2025
             State : clean
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : efilimonova:0  (local to host efilimonova)
              UUID : 85746f8a:325470b1:234935f1:8062f29d
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8       80        4      active sync   /dev/sdf
```

5. Зафейлила два диска в RAID-6.
```
mdadm /dev/md0 --fail /dev/sde
mdadm /dev/md0 --fail /dev/sdf

Состояние рейда degraded, но он еще жив.
root@efilimonova:~# mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Wed Oct  1 01:08:36 2025
        Raid Level : raid6
        Array Size : 3139584 (2.99 GiB 3.21 GB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Wed Oct  1 01:14:29 2025
             State : clean, degraded
    Active Devices : 3
   Working Devices : 3
    Failed Devices : 2
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : efilimonova:0  (local to host efilimonova)
              UUID : 85746f8a:325470b1:234935f1:8062f29d
            Events : 21

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       -       0        0        3      removed
       -       0        0        4      removed

       3       8       64        -      faulty   /dev/sde
       4       8       80        -      faulty   /dev/sdf
```

6. Удалила "сломанные" диски из рейда.
```
mdadm /dev/md0 --remove /dev/sde
mdadm /dev/md0 --remove /dev/sdf
```

7. Передобавила диски в рейд:
```
mdadm /dev/md0 --add /dev/sde
mdadm /dev/md0 --add /dev/sdf
```

8. RAID пересобрался. Видно было статус rebuilding:
```
    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       5       8       64        3      spare rebuilding   /dev/sde
       6       8       80        4      spare rebuilding   /dev/sdf
```

9. Создала GPT раздел на md0.
```
parted -s /dev/md0 mklabel gpt
```

10. Создала партиции.
```
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
```

11. Создала файловые системы. 
```
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
```

12. Создала папки и смонтировала партиции.
```
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done

ls -al /raid
total 28
drwxr-xr-x  7 root root 4096 Oct  1 01:26 .
drwxr-xr-x 23 root root 4096 Oct  1 01:26 ..
drwxr-xr-x  3 root root 4096 Oct  1 01:26 part1
drwxr-xr-x  3 root root 4096 Oct  1 01:26 part2
drwxr-xr-x  3 root root 4096 Oct  1 01:26 part3
drwxr-xr-x  3 root root 4096 Oct  1 01:26 part4
drwxr-xr-x  3 root root 4096 Oct  1 01:26 part5
```


