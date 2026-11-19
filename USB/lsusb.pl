#!/usr/bin/env perl -w

use strict;
use warnings;
use version;
use utf8;
use feature ':5.10';
use File::Basename qw/basename/;
use USB::LibUSB;
# use YAML::XS;
# use Data::Dumper;
use Getopt::Std;
my %opts; getopts("hvVd:s:", \%opts) or exit($? || 1);

### Usage Display
sub usage {
  print <<__EOL__;
Usage: ${\(basename $0)} [options]...

  List USB devices

  -v Increase verbosity (show descriptors)
  -s [bus:][devnum]
      Show only devices with specified device and/or
      bus numbers (in decimal)
  -d vendor[:product]
      Show only devices with the specified vendor and
      product ID numbers (in hexadecimal)
  -V  Show version of program
  -h  Show usage and help

__EOL__
  exit($? || 1);
}
usage() if $opts{h};

### Version Display
if ($opts{V}) {
  my $vh = libusb_get_version();
  printf "%s -- libusb %d.%d.%d (%d) %s",
    basename($0),
    $vh->{major}, $vh->{minor}, $vh->{micro}, $vh->{nano}, $vh->{rc};
  say '';
  exit 0;
}

### Descriptor Description
my @speed_list = (
  "[unknown]",
  "Low Speed (1.5Mbps)",
  "Full Speed (12Mbps)",
  "High Speed (480Mbps)",
  "Super Speed (5Gbps)",
  "Super Speed (10Gbps)",
  "Super Speed (10Gbps x2)",
);
my %desc_name = (
  0x01=>"Device ",
  0x02=>"Configuration ",
  0x03=>"String ",
  0x04=>"Interface ",
  0x05=>"Endpoint ",
  0x07=>"Other Speed Configuration ",
  0x08=>"Interface Power ",
  0x09=>"OTG ",
  0x0B=>"Interface Association ",
  0x0F=>"BOS: Binary Device Object Store ",
  0x10=>"Device Capability ",
  0x21=>"HID Class ",
  0x22=>"HID Report ",
  0x23=>"HID Physical ",
  0x24=>"Function ",  # CS_Interface
  0x30=>"SuperSpeed Endpoint Companion ",
);
my %desc_list = (
  0x01=>[ # Device
    [bLength=>0],
    [bDescriptorType=>6],
    [bcdUSB=>2],
    [bDeviceClass=>0],
    [bDeviceSubClass=>0],
    [bDeviceProtocol=>0],
    [bMaxPacketSize0=>0],
    [idVendor=>1],
    [idProduct=>1],
    [bcdDevice=>2],
    [iManufacturer=>3],
    [iProduct=>3],
    [iSerialNumber=>3],
    [bNumConfigurations=>0],
  ],
  0x02=>[ # Configuration
    [bLength=>0],
    [bDescriptorType=>6],
    [wTotalLength=>0],
    [bNumInterfaces=>0],
    [bConfigurationValue=>0],
    [iConfiguration=>3],
    [bmAttributes=>5],
    [iMaxPower=>4],
  ],
  0x04=>[ # Interface
    [bLength=>0],
    [bDescriptorType=>6],
    [bInterfaceNumber=>0],
    [bAlternateSetting=>0],
    [bNumEndpoints=>0],
    [bInterfaceClass=>0],
    [bInterfaceSubClass=>0],
    [bInterfaceProtocol=>0],
    [iInterface=>3],
  ],
  0x05=>[ # Endpoint
    [bLength=>0],
    [bDescriptorType=>6],
    [bEndpointAddress=>8],
    [bmAttributes=>5],
    [wMaxPacketSize=>0],
    [bInterval=>0],
  ],
  0x0B=>[ # IAD
    [bLength=>0],
    [bDescriptorType=>6],
    [bFirstInterface=>0],
    [bInterfaceCount=>0],
    [bFunctionClass=>0],
    [bFunctionSubClass=>0],
    [bFunctionProtocol=>0],
    [iFunction=>3]
  ],
  0x0F=>[ # Binary Device Object Store
    [bLength=>0],
    [bDescriptorType=>6],
    [wTotalLength=>0],
    [bNumDeviceCaps=>0],
  ],
  0x30=>[ # SuperSpeed Endpoint Companion
    [bLength=>0],
    [bDescriptorType=>6],
    [bMaxBurst=>0],
    [bmAttributes=>5,4],
    [wBytesPerInterval=>0],
  ],
);
my %cdc_desc = (
  0x00=>[ # Header
    [bLength=>0],
    [bDescriptorType=>6],
    [bDescriptorSubtype=>7],
    [bcdCDC=>2,2],
  ],
  0x01=>[ # Call Management
    [bLength=>0],
    [bDescriptorType=>6],
    [bDescriptorSubtype=>7],
    [bmCapabilities=>5],
    [bDataInterface=>0],
  ],
  0x02=>[ # Abstract Control Management
    [bLength=>0],
    [bDescriptorType=>6],
    [bDescriptorSubtype=>7],
    [bmCapabilities=>5],
  ],
  0x06=>[ # Union
    [bLength=>0],
    [bDescriptorType=>6],
    [bDescriptorSubtype=>7],
    [bControlInterface=>0],
    [bSubordinateInterface0=>0],
    [bSubordinateInterface1=>0],
    [bSubordinateInterface2=>0],
  ],
);
my %cdc_name = (
  0x00=>"Header ",
  0x01=>"Call Management ",
  0x02=>"Abstract Control Management ",
  0x03=>"Direct Line Management ",
  0x04=>"Telephone Ringer ",
  0x05=>"Telephone Call and Line State Reporting Capabilities ",
  0x06=>"Union ",
  0x07=>"Country Selection ",
);
my %cap_desc = (
  0x02=>[ # usb_2_0_extension : 7
    [bLength=>0],
    [bDescriptorType=>6],
    [bDevCapabilityType=>0],
    [bmAttributes=>5,4],
  ],
  0x03=>[ # ss_usb_device_capability : 10
    [bLength=>0],
    [bDescriptorType=>6],
    [bDevCapabilityType=>0],
    [bmAttributes=>5,1],
    [wSpeedsSupported=>5,2],
    [bFunctionalitySupport=>0],
    [bU1ExitLat=>0],
    [wU2ExitLat=>0,2],
  ],
);
my %cap_name = (
  0x01=>"Wireless USB capabilities",
  0x02=>"USB 2.0 Extension",
  0x03=>"SuperSpeed USB capabilities",
  0x04=>"Container ID",
  0x05=>"Platform capability",
  0x06=>"Various PD capabilities",
  0x07=>"Battery supported",
  0x08=>"Consumer characteristics",
  0x09=>"Provider characteristics",
  0x0A=>"SuperSpeed Plus USB capabilities",
  0x0B=>"Precision Time Measurement capability",
  0x0C=>"Wireless USB 1.1 capabilities",
  0x0D=>"Billboard capability",
  0x0E=>"Authentication capability",
  0x0F=>"Billboard Ex capability",
  0x10=>"Configuration Summary",
  0x11=>"Firmware Status",
  0x12=>"TBD USB Audio 4.0",
  0x13=>"USB 3 Gen T Capability",
  0x14=>"TBD USB PD",
);
my %class_desc = (
  0x00=>{name=>"Composite"},
  0x01=>{name=>"USB Audio Class"},
  0x02=>{
    name=>"Communications Device Class",
    proc=>{
      0x01=>"AT Commands",
      0x02=>"AT Commands defined by PCCA-101",
      0x03=>"AT Commands defined by PCCA-101 & Annex O",
      0x04=>"AT Commands defined by GSM 07.07",
      0x05=>"AT Commands defined by 3GPP 27.007",
      0x06=>"AT Commands defined by TIA for CDMA",
      0x07=>"Ethernet Emulation Model",
      0xFE=>"External Protocol: Functional defne",
      0xFF=>"Vendor Specific",
    },
    0x01=>"Direct Line Control Model",
    0x02=>"Abstract Control Model",
    0x03=>"Telephone Control Model",
    0x04=>"Multi-Channel Control Model",
    0x05=>"CAPI Control Model",
    0x06=>"Ethernet Networking Control Model",
    0x07=>"ATM Networking Control Model",
    0x08=>"Wireless Handset Control Model",
    0x09=>"Device Management",
    0x0A=>"Mobile Direct Line Model",
    0x0B=>"OBEX",
    0x0C=>"Ethernet Emulation Model",
    0x0D=>"Network Control Model",
  },
  0x03=>{
    name=>"Human Interface Device",
    proc=>{
      0x01=>"Keyboard",
      0x02=>"Mouse",
    },
    0x01=>"Boot Interface",
  },
  0x05=>{name=>"Physical"},
  0x06=>{name=>"Still Imaging"},
  0x07=>{name=>"Printer"},
  0x08=>{
    name=>"Mass Storage",
    proc=>{0x50=>"Bulk-Only Transport"},
    0x06=>"SCSI Command",
  },
  0x09=>{
    name=>"HUB",
    proc=>{
      0x00=>"Full speed Hub",
      0x01=>"Hi-speed hub with single TT",
      0x02=>"Hi-speed hub with multiple TTs",
      0x03=>"Super speed hub",
    },
    0x00=>"(HUB)",
  },
  0x0A=>{
    name=>"Communications Data Class",
    0x01=>"Direct Line Control Model",
    0x02=>"Abstract Control Model",
    0x03=>"Telephone Control Model",
  },
  0x0B=>{name=>"Smart Card"},
  0x0D=>{name=>"Content Security"},
  0x0E=>{name=>"USB Video Class"},
  0x0F=>{name=>"Personal Healthcare"},
  0x10=>{
    name=>"Audio/Video Devices",
    0x01=>"AVControl Interface",
    0x02=>"AVData Video Streaming Interface",
    0x03=>"AVData Audio Streaming Interface",
  },
  0x11=>{name=>"Billboard Device Class"},
  0x12=>{name=>"USB Type-C Bridge Class"},
  0x13=>{name=>"USB Bulk Display Protocol Device Class"},
  0x14=>{
    name=>"MCTP Management-controller",
    proc=>{
      0x01=>"MCTP 1.x",
      0x02=>"MCTP 2.x",
    },
    0x00=>"Managed-Device endpoints",
    0x01=>"MCTP Host Interface endpoint",
  },
  0x3C=>{name=>"I3C Device Class"},
  0xDC=>{name=>"Diagnostic Device"},
  0xE0=>{
    name=>"Wireless Controller",
    0x01=>{
      name=>"Wire Framework",
      0x01=>"Bluetooth Programming Interface",
      0x02=>"UWB Radio Control Interface",
      0x03=>"Remote NDIS",
      0x04=>"Bluetooth AMP Controller",
    },
    0x02=>{
      name=>"Wire Adapter",
      0x01=>"Host Wire Adapter Control/Data interface",
      0x02=>"Device Wire Adapter Control/Data interface",
      0x04=>"Device Wire Adapter Isochronous interface",
    },
  },
  0xEF=>{
    name=>"Miscellaneous",
    0x01=>{name=>"Sync",0x01=>"Active Sync device",0x02=>"Palm Sync"},
    0x02=>{
      name=>"Composite",
      0x01=>"Interface Association Descriptor",
      0x02=>"Wire Adapter Multifunction Peripheral programming interface",
    },
    0x03=>{0x01=>"Cable Based Association Framework"},
    0x04=>{
      name=>"RNDIS",
      0x01=>"RNDIS over Ethernet",
      0x02=>"RNDIS over WiFi",
      0x03=>"RNDIS over WiMAX",
      0x04=>"RNDIS over WWAN",
      0x05=>"RNDIS for Raw IPv4",
      0x06=>"RNDIS for Raw IPv6",
      0x07=>"RNDIS for GPRS",
    },
    0x05=>{
      name=>"USB3",
      0x00=>"USB3 Vision Control Interface",
      0x01=>"USB3 Vision Event Interface",
      0x02=>"USB3 Vision Streaming Interface",
    },
    0x06=>{
      name=>"STEP",
      0x01=>"Stream Transport Efficient Protocol for content protection",
      0x02=>"Stream Transport Efficient Protocol for Raw content protection",
    },
    0x07=>{
      0x00=>"Command Interface in IAD",
      0x01=>"Command Interface in Interface Descriptor",
      0x02=>"Media Interface in Interface Descriptor",
    },
    0x08=>{0x01=>"OCP Secure Firmware Recovery"},
    0x09=>{0x01=>"OCP OBMF-ICP"},
  },
  0xFE=>{
    name=>"Application Specific",
    0x01=>"Device Firmware Upgrade",
    0x02=>"IRDA Bridge device",
    0x03=>"USB Test and Measurement Device",
  },
  0xFF=>{name=>"Vendor Specific"},
);

### Device Display Header
sub dsp_device_header {
  my $dev = shift;
  $dev->{apps} //= {  # Application Information Retention
    iManufacturer => '',
    iProduct      => '',
    iSerial       => '',
    bcdUSB        => 0,
  };
  my $desc = $dev->get_device_descriptor();
  $dev->{apps}{bcdUSB} = $desc->{bcdUSB} - 0;
  if (my $handle = $dev->open()) {
    $dev->{apps}{iManufacturer} = $handle->get_string_descriptor_ascii($desc->{iManufacturer}, 80) if $desc->{iManufacturer};
    $dev->{apps}{iProduct}      = $handle->get_string_descriptor_ascii($desc->{iProduct},      80) if $desc->{iProduct};
    $dev->{apps}{iSerialNumber} = $handle->get_string_descriptor_ascii($desc->{iSerialNumber}, 80) if $desc->{iSerialNumber};
    $handle->close();
  }
  return sprintf("Bus %03d Device %03d: ID %04x:%04x %s",
    $dev->get_bus_number(),
    $dev->get_device_address(),
    $desc->{idVendor},
    $desc->{idProduct},
    $dev->{apps}{iProduct} || $dev->{apps}{iManufacturer},
  );
}

sub say_tab {
  my $tab = shift;
  say ' ' x $tab, @_;
}

sub mk_desc {
  my $desc = shift;
  my @data = @_;
  my $r = {};
  foreach my $f (@$desc) {
    my($k, $t, $s) = @$f;
    $s //= 1;
    $r->{$k} = unpack "V1", pack "C4", splice @data, 0, $s;
    last unless @data;
  }
  return $r;
}

sub hexdump {
  my $tab = shift // 0;
  my $ary = shift;
  my $count = 0;
  my ($temp, @line);
  foreach my $byte (@$ary) {
    push @line, sprintf "[%04x]", $count if ($count & 15) == 0;
    $line[-1] .= sprintf " %02X", $byte;
    $line[-1] .= ' ' if ($count & 7) == 7;
    $count++;
  }
  foreach my $line (@line) { say ' ' x $tab, $line; }
}

sub dsp_descriptor {
  my $tab = shift;
  my $dev  = shift;
  my $desc = shift;
  my $list = shift;
  my $title = shift;
  if (defined $title) {
    say_tab $tab-2, $desc_name{$desc->{bDescriptorType}} // "Raw ", "Descriptor: ", $title;
  }
  my @dsp;
  foreach my $tag (@$list) {
    my ($label, $type, $size) = @$tag;
    $size //= 0;
    if (defined(my $value = $desc->{$label})) {
      if ($type == 1) {     # iWord
        push @dsp, sprintf "%-22s0x%04x", $label, $value;
      }
      elsif ($type == 2) {  # bcd
        push @dsp, sprintf "%-22s%3x.%02x (0x%04x)", $label, $value >> 8, $value & 255, $value;
      }
      elsif ($type == 4) {  # iMaxPower
        my $unit = $dev->{apps}{bcdUSB} < 0x300 ? 2 : 8;
        push @dsp, sprintf "%-22s%6d (0x%02x) %d mA", $label, $value, $value, $value * $unit;
      }
      elsif ($type == 5) {  # bmAttributes
        if ($size == 4) {
          push @dsp, sprintf "%-18s0x%08x", $label, $value;
        } 
        elsif ($size == 2) {
          push @dsp, sprintf "%-22s0x%04x", $label, $value, $value;
        }
        else {
          push @dsp, sprintf "%-24s0x%02x (0b%08b)", $label, $value, $value;
        }
        if ($desc->{bDescriptorType} == 0x02) {       # CONFIGURATION
          push @dsp, (' ' x 25)."b:7 BUS_POWERED"   if $value & 0x80;
          push @dsp, (' ' x 25)."b:6 SELF_POWERED"  if $value & 0x40;
          push @dsp, (' ' x 25)."b:5 REMOTE_WAKEUP" if $value & 0x20;
        }
        elsif ($desc->{bDescriptorType} == 0x05) {    # ENDPOINT
          push @dsp, sprintf "  Transfer Type%13s", (qw/Control Isochronous Bulk Interrupt/)[$value & 3];
          push @dsp, sprintf "  Sync Type%17s", (qw/None Async Adaptation Sync/)[($value >> 2) & 3];
          push @dsp, sprintf "  Usage Type%16s", (qw/Data Implicit Explicit [unknown]/)[($value >> 4) & 3];
        }
        elsif ($desc->{bDescriptorSubtype} // 0 == 0x01) { # CMD
          push @dsp, (' ' x 25)."b:1 call management"    if $value & 0x02;
          push @dsp, (' ' x 25)."b:0 use DataInterface"  if $value & 0x01;
        }
        elsif ($desc->{bDescriptorSubtype} // 0 == 0x02) { # ACM
          push @dsp, (' ' x 25)."b:3 NETWORK_CONNECTION" if $value & 0x08;
          push @dsp, (' ' x 25)."b:2 SEND_BREAK"         if $value & 0x04;
          push @dsp, (' ' x 25)."b:1 LINE_CODING, SERIAL_STATE"  if $value & 0x02;
          push @dsp, (' ' x 25)."b:0 COMM_FEATURE"       if $value & 0x01;
        }
      }
      elsif ($type == 8) {  # hex byte
        push @dsp, sprintf "%-24s0x%02x", $label, $value;
      }
      else {
        push @dsp, sprintf "%-22s%6d", $label, $value;
        if ($type == 6) {   # desctype
          $dsp[-1] .= sprintf " (0x%02x)", $value if $value > 9;
          my $name = $desc_name{$value};
          if (defined $name) {
            $dsp[-1] .= sprintf " %s", $name;
          }
        }
        elsif ($type == 7) {  # subreqtype
          $dsp[-1] .= sprintf " (0x%02x)", $value if $value > 9;
          my $name = $cdc_name{$value};
          if (defined $name) {
            $dsp[-1] .= sprintf " %s", $name;
          }
        }
        elsif ($type == 3) {  # string
          my $string = "";
          if ($string) {
            $string = $dev->{apps}{$label};
          }
          elsif ($value) {
            if (my $handle = $dev->open()) {
              $string = $handle->get_string_descriptor_ascii($value, 252);
              $handle->close();
            }
          }
          $dsp[-1] .= sprintf " [%d] ", 2 * length $string;
          $dsp[-1] .= $string;
        }
        elsif ($value > 9) {  # number
          $dsp[-1] .= sprintf " (0x%02x)", $value;
        }
        if ($type == 0) {
          if ($label =~ m{Protocol$}o) {
            my $class = $label;
            $class =~ s{Protocol$}{Class}o;
            $class = $desc->{$class};
            if (exists $class_desc{$class} &&
                exists $class_desc{$class}{proc} &&
                exists $class_desc{$class}{proc}{$value}) {
              $dsp[-1] .= " ".$class_desc{$class}{proc}{$value};
            }
            elsif ($class == 0xE0 || $class == 0xEF) {
              my $subclass = $label;
              $subclass =~ s{Protocol$}{SubClass}o;
              $subclass = $desc->{$subclass};
              if (exists $class_desc{$class} &&
                  exists $class_desc{$class}{$subclass} &&
                  exists $class_desc{$class}{$subclass}{$value}) {
                $dsp[-1] .= " ".$class_desc{$class}{$subclass}{$value};
              }
            }
          }
          elsif ($label =~ m{SubClass$}o) {
            my $class = $label;
            $class =~ s{SubClass$}{Class}o;
            $class = $desc->{$class};
            if (exists $class_desc{$class} &&
                exists $class_desc{$class}{$value}) {
              if (!ref $class_desc{$class}{$value}) {
                $dsp[-1] .= " ".$class_desc{$class}{$value};
              }
              elsif (exists $class_desc{$class}{$value}{name}) {
                $dsp[-1] .= " ".$class_desc{$class}{$value}{name};
              }
            }
          }
          elsif ($label =~ m{Class$}o) {
            if (exists $class_desc{$value} &&
                exists $class_desc{$value}{name}) {
              $dsp[-1] .= " ".$class_desc{$value}{name};
            }
          }
          elsif ($label eq "bMaxPacketSize0" && $dev->{apps}{bcdUSB} >= 0x300) {
            $dsp[-1] .= sprintf " => %d", 2 ** $value;
          }
        }
      }
    }
  }
  for my $line (@dsp) { say ' ' x $tab, $line; }
}

sub dsp_hid_report {
  my $tab = shift // 0;
  my @raw = @_;
  my %tag = (
    0x80=>"Input",
    0x90=>"Output",
    0xA0=>"Collection",
    0xB0=>"Feature",
    0xC0=>"End Collection",
    0x04=>"Usage Page",
    0x14=>"Logical Minimum",
    0x24=>"Logical Maximum",
    0x34=>"Physical Minimum",
    0x44=>"Physical Maximum",
    0x54=>"Unit Exponent",
    0x64=>"Unit",
    0x74=>"Report Size",
    0x84=>"Report ID",
    0x94=>"Report Count",
    0xA4=>"Push",
    0xB4=>"Pop",
    0x08=>"Usage",
    0x18=>"Usage Minimum",
    0x28=>"Usage Maximum",
    0x38=>"Designator Index",
    0x48=>"Designator Minimum",
    0x58=>"Designator Maximum",
    0x68=>"String Index",
    0x88=>"String Minimum",
    0x98=>"String Maximum",
    0xA8=>"Delimiter",
  );
  my $ofs = 0;
  while (@raw) {
    my $item = shift @raw;
    my $size = $item & 0x03;
    my $type = $item & 0xFC;
    $ofs -= 2 if $type == 0xC0;
    my $head = sprintf "%02X ", $item;
    my $value = 0;
    if ($size > 0) {
      $value = shift @raw;
      $head .= sprintf "%02X ", $value;
      if ($size > 1) {
        $head .= sprintf "%02X ", $raw[0];
        $value += shift(@raw) << 8;
        if ($size > 2) {
          $head .= sprintf "%02X ", $raw[0];
          $head .= sprintf "%02X ", $raw[1];
          $value += shift(@raw) << 16;
          $value += shift(@raw) << 24;
        }
      }
      $value -= 2**8 if $size == 1 && ($value & 0x80);
      $value -= 2**16 if $size == 2 && ($value & 0x8000);
      $value -= 2**32 if $size == 3 && ($value & 0x80000000);
    }
    say ' ' x $tab, sprintf("%-15s%s%s (%d)",
      $head, ' ' x $ofs, $tag{$type} // "Unkown", $value);
    $ofs += 2 if $type == 0xA0;
  }
}

sub dsp_func_desc {
  my $tab = shift // 0;
  my $dev = shift;
  my $if = shift;
  my @raw = unpack "C*", $if->{extra};
  while (@raw) {
    my @data = splice @raw, 0, $raw[0];
    my $req = $data[1];
    my $subn = '';
    my $req_sub = {};
    my $req_type = 0;
    my $name = $desc_name{$req} // "Raw ";
    if (exists $if->{bInterfaceClass} && $if->{bInterfaceClass} == 2) {
      $req_sub = \%cdc_name;
      $req_type = 2;
      # $name = $desc_name{$req} // "Raw ";
      $subn = $req_sub->{$data[2]} // "" if $req == 0x24; # CS_INTERFACE
    }
    if ($req == 0x30 && $if->{ss_endpoint_companion}) {
      # say_tab $tab+2, "SuperSpeed Endpoint Companion Descriptor: ", scalar(@data);
      dsp_descriptor $tab+4, $dev, $if->{ss_endpoint_companion}, $desc_list{0x30}, scalar(@data);
      next;
    }
    say_tab $tab, $subn, $name, "Descriptor: ", scalar(@data);
    hexdump $tab+2, \@data;
    if ($data[1] == 0x21) { # HID
      my @dr = ([bLength=>0],[bDescriptorType=>6],[bcdUSB=>2],[bCountryCode=>0],[bNumDescriptors=>0]);
      my $subd = {};
      $subd->{bLength} = shift @data;
      $subd->{bDescriptorType} = shift @data;
      $subd->{bcdUSB} = shift(@data) + (shift(@data) << 8);
      $subd->{bCountryCode} = shift @data;
      $subd->{bNumDescriptors} = shift @data;
      my @hid;
      my $count = 0;
      while (@data) {
        my $n1 = sprintf "bDescriptorType%d", $count;
        my $n2 = sprintf "wDescriptorLength%d", $count;
        $subd->{$n1} = shift @data;
        $subd->{$n2} = shift(@data) + (shift(@data) << 8);
        push @dr, [$n1=>6],[$n2=>0];
        if ($subd->{$n1} == 0x22) { # HID Report
          push @hid, [
            0x81,         # bmRequestType
            0x06,         # bRequest
            $count + ($subd->{$n1} << 8), # wValue
            $if->{bInterfaceNumber},      # wIndex
            $subd->{$n2}, # wLength
            1000,         # timeout
          ];
        }
        dsp_descriptor $tab+2, $dev, $subd, \@dr;
        $count++;
      }
      foreach my $req (@hid) {
        say_tab $tab+2, "Raw Descriptor: ", $req->[4], " - ", $desc_name{$req->[2] >> 8} // "";
        if (my $handle = $dev->open()) {
          my $raw = eval { $handle->control_transfer_read(@$req); };
          $handle->close();
          unless ($raw) {
            say_tab $tab+4, "### INVALID READ ###";
            next;
          }
          my @raw = unpack "C*", $raw;
          hexdump $tab+4, \@raw;
          dsp_hid_report $tab+4, @raw;
        }
      }
    }
    elsif ($data[1] == 0x24 && $req_type == 2) {  # CS_INTERFACE CDC
      my $subt = $data[2];
      my $subd = mk_desc $cdc_desc{$subt}, @data;
      dsp_descriptor $tab+2, $dev, $subd, $cdc_desc{$subt};
    }
    elsif ($data[1] == 0x0B) {  # IAD
      my $subd = mk_desc $desc_list{0x0B}, @data;
      dsp_descriptor $tab+2, $dev, $subd, $desc_list{0x0B};
    }
  }
}

sub dsp_bos_desc {
  my $tab = shift // 0;
  my $dev = shift;
  my $bos = shift;
  dsp_descriptor $tab, $dev, $bos, $desc_list{0x0F}, $bos->{wTotalLength};
  foreach my $cap (@{$bos->{dev_capability}}) {
    my @data = ($cap->{bLength}, $cap->{bDescriptorType}, $cap->{bDevCapabilityType});
    push @data, unpack "C*", $cap->{dev_capability_data};
    say_tab $tab, "BOS ", $cap_name{$cap->{bDevCapabilityType}}, ": ", $cap->{bLength};
    hexdump $tab+2, \@data;
    # print Dump $cap;
  }
}

sub dsp_ep_desc {
  my $tab = shift // 0;
  my $dev = shift;
  my @ep = @_;
  foreach my $ep (@ep) {
    dsp_descriptor $tab+2, $dev, $ep, $desc_list{0x05},
      sprintf("0x%02X", $ep->{bEndpointAddress});
    dsp_func_desc 6, $dev, $ep if $ep->{extra};
  }
}

### Main routine
my $ctx = USB::LibUSB->init();
for my $dev (reverse $ctx->get_device_list()) {
  my $desc = $dev->get_device_descriptor();

  if ($opts{d}) {
    my ($vid, undef, $pid) = $opts{d} =~ m{([\dA-F]{,4})(\:([\dA-F]{,4}))?}io;
    next unless $vid && $desc->{idVendor}  == oct('0x'.$vid);
    if ($pid) { next unless $desc->{idProduct} == oct('0x'.$pid); }
  }

  if ($opts{s}) {
    if (0 <= index $opts{s}, ':') {
      my $ptr = sprintf "%d:%d", $dev->get_bus_number(), $dev->get_device_address();
      next unless 0 <= index $ptr, $opts{s};
    }
    else { next unless $dev->get_device_address() == $opts{s} - 0; }
  }

  say dsp_device_header $dev;

  if ($opts{v}) {
    my $config = $dev->get_active_config_descriptor();

    # Device
    say_tab 2, "Negotiated speed: ", $speed_list[$dev->get_device_speed()];
    dsp_descriptor 4, $dev, $desc, $desc_list{0x01}, '';

    # BOS
    if ($dev->{apps}{bcdUSB} >= 0x201 and my $handle = $dev->open) {
      my $bos = eval { $handle->get_bos_descriptor(); };
      $handle->close();
      dsp_bos_desc 4, $dev, $bos if $bos;
    }

    # Configuration
    $config->{iMaxPower} = $config->{MaxPower}; # rename
    dsp_descriptor 4, $dev, $config, $desc_list{0x02},
      sprintf("#%d", $config->{bConfigurationValue});

    # Interface
    foreach my $interface (@{$config->{interface}}) {
      # Current and Alternative
      foreach my $if (@$interface) {
        dsp_descriptor 6, $dev, $if, $desc_list{0x04},
          sprintf("#%d,%d", $if->{bInterfaceNumber}, $if->{bAlternateSetting});
        
        # Function
        dsp_func_desc 6, $dev, $if if $if->{extra};

        # Endpoint
        dsp_ep_desc 6, $dev, @{$if->{endpoint}} if $if->{endpoint};
      }
    }
    say '';
  }
}
$ctx->exit();
exit(0);
__END__
使用法: lsusb [オプション]...

  USBデバイスの一覧を表示します

  -v  詳細情報を表示する（ディスクリプタを表示）
  -s [バス番号:][デバイス番号]
      指定したデバイス番号および／またはバス番号（10進数）の
      デバイスのみを表示する
  -d ベンダーID[:プロダクトID]
      指定したベンダーIDおよびプロダクトID（16進数）の
      デバイスのみを表示する
  -V  プログラムのバージョンを表示する
  -h  使用法とヘルプを表示する
