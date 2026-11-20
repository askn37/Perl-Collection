# Perl-Collection

Perl用の雑多なスクリプト。なんならOSだって書ける。

> いずれも Artistic License 2.0 と MIT License を選択可

## Binary category

- gencrc.pl

  [euboot](https://github.com/askn37/euboot)等に添付している CRC計算／逆計算生成ツール。
  原理と目的は Qiita掲載の記事 [任意の CRC値を導出する](https://qiita.com/askn37/items/6b0380d2d4657229172d)を参照のこと。

<details>
<summary>実行例</summary>

```
$ gencrc.pl -u -c6 -i build/euboot_LF2_SF6.tmp -o hex/euboot_LF2_SF6.hex
Input-file: build/euboot_LF2_SF6.tmp
Input-size: 2390
CRC-type: "CRC-32/XOR" model:0xCBF43926 magic:0xDEBB20E3
[Unwind-CRC calculation mode (Xout)]
Page-size: 512
Page-length:  5
Page-capacity: $000A00 2.50KiB
Entire-CRC32: 08B4647A (LE) (Oops)
Code-CRC32: C1C2091C (LE)
Trim-CRC32: F5DD753A (LE)
Fixed-CRC32: CBE083D9 (LE)
Position: $000956
Output-file: hex/euboot_LF2_SF6.hex
Output-size: 2394
```

</details>

## Develop category

- xc8toDev.pl

  Microchip DFPパッケージ（AVR用）で、`xc8/avr`はあるのに `gcc/dev`がない場合に、`device-specs`ファイルを変換して補完する。
  いまのところ `AVR-Sx_DFP`パッケージでだけ必要になる。

## Text category

- hexview.pl

  Intel HEX Format ファイルを食わせて、色付けと ASCIIダンプを行う。 

- SpaceRemover.pl

  指定の（ディレクトリ以下の全ての）テキストファイルを対象に、Tab の Space変換と、行末の Space除去を行う。
  変換対象ファイルの拡張子は、スクリプト冒頭のフィルタで選別している。
バックアップは取らないので注意。

  先祖は 1980年代に書いた、結構な年代物。

## USB category

- lsusb.pl

  usbutilsの lsusbと同種の表示を行う。Windwosでも macosでも使える。一方で Linuxには不適。原典の libusbや、macos の usbdiagnoseが読みにくい／妙に使いにくいので自作したもの。VIDデータベース等は持たないので、情報量は原典より簡素。

<details>
<summary>実行例</summary>

```
$ lsusb.pl                
Bus 000 Device 001: ID 2109:2824 USB2.0 Hub             
Bus 000 Device 002: ID 2109:0824 USB3.1 Hub             
Bus 000 Device 004: ID 2109:2817 USB2.0 Hub             
Bus 000 Device 006: ID 0bda:9210 RTL9210B-CG
Bus 000 Device 005: ID 2109:0817 USB3.0 Hub             
Bus 000 Device 007: ID 2109:8817 USB Billboard Device   
Bus 000 Device 008: ID 174c:55aa ASM225
Bus 002 Device 024: ID 03eb:2145 mEDBG CMSIS-DAP
Bus 000 Device 003: ID 1ea7:0064 2.4G Mouse
```

```
$ lsusb.pl -v -d 1ea7:0064
Bus 000 Device 003: ID 1ea7:0064 2.4G Mouse
  Negotiated speed: Full Speed (12Mbps)
  Device Descriptor: 
    bLength                   18 (0x12)
    bDescriptorType            1 Device 
    bcdUSB                  1.10 (0x0110)
    bDeviceClass               0 Composite
    bDeviceSubClass            0
    bDeviceProtocol            0
    bMaxPacketSize0            8
    idVendor              0x1ea7
    idProduct             0x0064
    bcdDevice               2.00 (0x0200)
    iManufacturer              0 [0] 
    iProduct                   1 [20] 2.4G Mouse
    iSerialNumber              0 [0] 
    bNumConfigurations         1
  Configuration Descriptor: #1
    bLength                    9
    bDescriptorType            2 Configuration 
    wTotalLength              34 (0x22)
    bNumInterfaces             1
    bConfigurationValue        1
    iConfiguration             0 [0] 
    bmAttributes            0xa0 (0b10100000)
                             b:7 BUS_POWERED
                             b:5 REMOTE_WAKEUP
    iMaxPower                 50 (0x32) 100 mA
    Interface Descriptor: #0,0
      bLength                    9
      bDescriptorType            4 Interface 
      bInterfaceNumber           0
      bAlternateSetting          0
      bNumEndpoints              1
      bInterfaceClass            3 Human Interface Device
      bInterfaceSubClass         1 Boot Interface
      bInterfaceProtocol         2 Mouse
      iInterface                 0 [0] 
      HID Class Descriptor: 9
        [0000] 09 21 10 01 00 01 22 69  00
        bLength                    9
        bDescriptorType           33 (0x21) HID Class 
        bcdUSB                  1.10 (0x0110)
        bCountryCode               0
        bNumDescriptors            1
        bDescriptorType0          34 (0x22) HID Report 
        wDescriptorLength0       105 (0x69)
        Raw Descriptor: 105 - HID Report 
          [0000] 06 B5 FF 09 01 A1 01 85  B5 09 02 15 00 26 FF 00 
          [0010] 75 08 95 07 81 02 09 02  15 00 26 FF 00 75 08 95 
          [0020] 07 91 02 C0 05 01 09 02  A1 01 85 02 09 01 A1 00 
          [0030] 05 09 19 01 29 08 15 00  25 01 95 08 75 01 81 02 
          [0040] 05 01 09 30 09 31 16 01  F8 26 FF 07 75 0C 95 02 
          [0050] 81 06 09 38 15 81 25 7F  75 08 95 01 81 06 05 0C 
          [0060] 0A 38 02 95 01 81 06 C0  C0
          06 B5 FF       Usage Page (-75)
          09 01          Usage (1)
          A1 01          Collection (1)
          85 B5            Report ID (-75)
          09 02            Usage (2)
          15 00            Logical Minimum (0)
          26 FF 00         Logical Maximum (255)
          75 08            Report Size (8)
          95 07            Report Count (7)
          81 02            Input (2)
          09 02            Usage (2)
          15 00            Logical Minimum (0)
          26 FF 00         Logical Maximum (255)
          75 08            Report Size (8)
          95 07            Report Count (7)
          91 02            Output (2)
          C0             End Collection (0)
          05 01          Usage Page (1)
          09 02          Usage (2)
          A1 01          Collection (1)
          85 02            Report ID (2)
          09 01            Usage (1)
          A1 00            Collection (0)
          05 09              Usage Page (9)
          19 01              Usage Minimum (1)
          29 08              Usage Maximum (8)
          15 00              Logical Minimum (0)
          25 01              Logical Maximum (1)
          95 08              Report Count (8)
          75 01              Report Size (1)
          81 02              Input (2)
          05 01              Usage Page (1)
          09 30              Usage (48)
          09 31              Usage (49)
          16 01 F8           Logical Minimum (-2047)
          26 FF 07           Logical Maximum (2047)
          75 0C              Report Size (12)
          95 02              Report Count (2)
          81 06              Input (6)
          09 38              Usage (56)
          15 81              Logical Minimum (-127)
          25 7F              Logical Maximum (127)
          75 08              Report Size (8)
          95 01              Report Count (1)
          81 06              Input (6)
          05 0C              Usage Page (12)
          0A 38 02           Usage (568)
          95 01              Report Count (1)
          81 06              Input (6)
          C0               End Collection (0)
          C0             End Collection (0)
      Endpoint Descriptor: 0x81
        bLength                    7
        bDescriptorType            5 Endpoint 
        bEndpointAddress        0x81
        bmAttributes            0x03 (0b00000011)
          Transfer Type    Interrupt
          Sync Type             None
          Usage Type            Data
        wMaxPacketSize             8
        bInterval                  2

```

```
$ lsusb.pl -v -d 174c:55aa
Bus 000 Device 008: ID 174c:55aa ASM225
  Negotiated speed: Super Speed (5Gbps)
  Device Descriptor: 
    bLength                   18 (0x12)
    bDescriptorType            1 Device 
    bcdUSB                  3.10 (0x0310)
    bDeviceClass               0 Composite
    bDeviceSubClass            0
    bDeviceProtocol            0
    bMaxPacketSize0            9 => 512
    idVendor              0x174c
    idProduct             0x55aa
    bcdDevice               1.00 (0x0100)
    iManufacturer              2 [8] ASMT
    iProduct                   3 [12] ASM225
    iSerialNumber              1 [24] 000000000001
    bNumConfigurations         1
  BOS: Binary Device Object Store Descriptor: 22
    bLength                    5
    bDescriptorType           15 (0x0f) BOS: Binary Device Object Store 
    wTotalLength              22 (0x16)
    bNumDeviceCaps             2
    BOS USB 2.0 Extension: 7
      [0000] 07 10 02 1E F4 00 00
    BOS SuperSpeed USB capabilities: 10
      [0000] 0A 10 03 00 0E 00 01 0A  FF 07
  Configuration Descriptor: #1
    bLength                    9
    bDescriptorType            2 Configuration 
    wTotalLength              44 (0x2c)
    bNumInterfaces             1
    bConfigurationValue        1
    iConfiguration             0 [0] 
    bmAttributes            0xc0 (0b11000000)
                             b:7 BUS_POWERED
                             b:6 SELF_POWERED
    iMaxPower                  0 (0x00) 0 mA
    Interface Descriptor: #0,0
      bLength                    9
      bDescriptorType            4 Interface 
      bInterfaceNumber           0
      bAlternateSetting          0
      bNumEndpoints              2
      bInterfaceClass            8 Mass Storage
      bInterfaceSubClass         6 SCSI Command
      bInterfaceProtocol        80 (0x50) Bulk-Only Transport
      iInterface                 0 [0] 
      Endpoint Descriptor: 0x81
        bLength                    7
        bDescriptorType            5 Endpoint 
        bEndpointAddress        0x81
        bmAttributes            0x02 (0b00000010)
          Transfer Type         Bulk
          Sync Type             None
          Usage Type            Data
        wMaxPacketSize          1024 (0x400)
        bInterval                  0
        SuperSpeed Endpoint Companion Descriptor: 6
          bLength                    6
          bDescriptorType           48 (0x30) SuperSpeed Endpoint Companion 
          bMaxBurst                 15 (0x0f)
          bmAttributes      0x00000000
          wBytesPerInterval          0
      Endpoint Descriptor: 0x02
        bLength                    7
        bDescriptorType            5 Endpoint 
        bEndpointAddress        0x02
        bmAttributes            0x02 (0b00000010)
          Transfer Type         Bulk
          Sync Type             None
          Usage Type            Data
        wMaxPacketSize          1024 (0x400)
        bInterval                  0
        SuperSpeed Endpoint Companion Descriptor: 6
          bLength                    6
          bDescriptorType           48 (0x30) SuperSpeed Endpoint Companion 
          bMaxBurst                 15 (0x0f)
          bmAttributes      0x00000000
          wBytesPerInterval          0

```

  > 文字列記述子の詳細項で、文字列は ASCII表示であるが `[N]`は UTF-16LE換算での文字数になる。

</details>

## Copyright and Contact

Twitter(X): [@askn37](https://twitter.com/askn37) \
BlueSky Social: [@multix.jp](https://bsky.app/profile/multix.jp) \
GitHub: [https://github.com/askn37/](https://github.com/askn37/) \
Product: [https://askn37.github.io/](https://askn37.github.io/)

Copyright (c) askn (K.Sato) multix.jp \
Released under the Artistic License 2.0 \
https://opensource.org/license/Artistic-2.0
