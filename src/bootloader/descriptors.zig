const microzig = @import("microzig");
const usb = microzig.core.usb;

const vid = 0x123;
const pid = 0x456;

pub const device_descriptor = usb.descriptors.Device{
    .bcdUSB = 0x02_00,
    .bDeviceClass = .misc,
    .bDeviceSubclass = @enumFromInt(0x02),
    .bDeviceProtocol = @enumFromInt(0x01),
    .bMaxPacketSize0 = 0x40,
    .idVendor = vid,
    .idProduct = pid,
    .bcdDevice = 0x42_01,
    .iManufacturer = 0x01,
    .iProduct = 0x02,
    .iSerialNumber = 0x03,
    .bNumConfigurations = 0x01,
};

const max_power_ma = 500;

pub const cfg_descriptor = usb.descriptor.Configuration {
    .wTotalLength = 0, // TODO
    .bNumInterfaces = 5,
    .bConfigurationValue = 1,
    .iConfiguration = 0,
    .bmAttributes = 0x80, // bus-powered
    .bMaxPower = max_power_ma / 2,
};

pub const msc_interface = usb.descriptor.Interface {
    .bInterfaceNumber = 0,
    .bAlternateSetting  = 0,
    .bNumEndpoints = 2,
    .bInterfaceClass = 8, // class code - mass storage
    .bInterfaceSubClass = 6, // SCSI transparent command set
    .bInterfaceProtocol = 80, // bulk only transport
    .iInterface = 0,
};

pub const endpoints = [2]usb.descriptor.Endpoint {
    .{
        .bEndpointAddress = usb_ep_msc_in | 0x80, // in, 2
        .bmAttributes = 2, // transfer type - bulk
        .wMaxPacketSize = PKT_SIZE,
        .bInterval = 0,
    },
.{
    .bEndpointAddress = usb_ep_msc_out, // out, 1
                                        .bmAttributes = 2, // transfer type -
                                                           // bulk
    .wMaxPacketSize = PKT_SIZE,
    .bInterval = 0,
},
};

pub const bos = usb.descriptor.BOS {
    .wTotalLength = 5,
    .bNumDeviceCaps = 0,
};


//__attribute__((__aligned__(4))) const char devDescriptor[] = {
//    /* Device descriptor */
//    0x12, // bLength
//    0x01, // bDescriptorType
//// bcdUSBL - v2.00; v2.10 is needed for WebUSB; there were issues with newer laptops running Win10
//// but it seems to be resolved
//    0x00,
//    0x02,           //
//    0xEF,           // bDeviceClass:    Misc
//    0x02,           // bDeviceSubclass:
//    0x01,           // bDeviceProtocol:
//    0x40,           // bMaxPacketSize0
//    USB_VID & 0xff, // vendor ID
//    USB_VID >> 8,   //
//    USB_PID & 0xff, // product ID
//    USB_PID >> 8,   //
//    0x01,           // bcdDeviceL
//    0x42,           //
//    0x01,           // iManufacturer    // 0x01
//    0x02,           // iProduct
//    0x03,           // SerialNumber (required (!) for WebUSB)
//    0x01            // bNumConfigs
//};
//
//#define CFG_DESC_SIZE (32)
//#define HID_IF_NUM (1)
//
//#define USB_POWER_MA 500
//__attribute__((__aligned__(4))) char cfgDescriptor[] = {
//    /* ============== CONFIGURATION 1 =========== */
//    /* Configuration 1 descriptor */
//    0x09,          // CbLength
//    0x02,          // CbDescriptorType
//    CFG_DESC_SIZE, // CwTotalLength 2 EP + Control
//    0x00,
//    1, // CbNumInterfaces
//    0x01,                                   // CbConfigurationValue
//    0x00,                                   // CiConfiguration
//    0x80,                                   // CbmAttributes 0x80 - bus-powered
//    USB_POWER_MA / 2,                       // MaxPower (*2mA)
//
//    // MSC
//
//    9,               /// descriptor size in bytes
//    4,               /// descriptor type - interface
//     0, /// interface number
//    0,               /// alternate setting number
//    2,               /// number of endpoints
//     8,     /// class code - mass storage
//    6,               /// subclass code - SCSI transparent command set
//    80,              /// protocol code - bulk only transport
//    0,               /// interface string index
//
//    7,                    /// descriptor size in bytes
//    5,                    /// descriptor type - endpoint
//    USB_EP_MSC_IN | 0x80, /// endpoint direction and number - in, 2
//    2,                    /// transfer type - bulk
//    PKT_SIZE,             /// maximum packet size
//    0,
//    0, /// not used
//
//    7,              /// descriptor size in bytes
//    5,              /// descriptor type - endpoint
//    USB_EP_MSC_OUT, /// endpoint direction and number - out, 1
//    2,              /// transfer type - bulk
//    PKT_SIZE,       /// maximum packet size
//    0,
//    0, /// maximum NAK rate
//};
//
//
//__attribute__((__aligned__(4))) static char bosDescriptor[] = {
//    0x05, // Length
//    0x0F, // Binary Object Store descriptor
//    0x05, 0x00, // Length
//    0x00        // num caps
//
//};
