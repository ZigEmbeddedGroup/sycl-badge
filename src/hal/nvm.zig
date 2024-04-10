//! Non-Volatile Memory Controller
pub const Command = enum(u7) {
    /// EP: Only supported in the User page in the auxiliary space.
    erase_page = 0x00,
    /// EB: Erases the block addressed by the ADDR register, not supported in
    /// the user page
    erase_block = 0x01,
    /// WP: Writes the contents of the page buffer to the page addressed by the
    /// ADDR register, not supported in the user page
    write_page = 0x03,
    /// WQW: Writes a 128-bit word at the location addressed by the ADDR
    /// register.
    write_quad_word = 0x04,
    /// SWRST: Power-Cycle the NVM memory and replay the device automatic
    /// calibration procedure and resets the module configuration registers
    software_reset = 0x10,
    /// LR: Locks the region containing the address location in the ADDR
    /// register until next reset.
    lock_region = 0x11,
    /// UR: Unlocks the region containing the address location in the ADDR
    /// register until next reset.
    unlock_region = 0x12,
    /// SPRM
    set_power_reduction_mode = 0x13,
    /// CPRM
    clear_power_reduction_mode = 0x14,
    /// PBC: Clears the page buffer
    page_buffer_clear = 0x15,
    /// SSB
    set_security_bit = 0x16,
    /// BKSWRST: if SmartEEPROM is used also reallocate its data into the
    /// opposite BANK
    bank_swap_and_system_reset = 0x17,
    /// CELCK: DSU CTRL.CE command is not available. As soon as the CELCK
    /// command is successfully executed, the chip erase capability is disabled
    /// and Microchip’s failure analysis capabilities are limited. Therefore,
    /// the software has to ensure there is a way to unlock the chip erase by
    /// executing the CEULCK command.
    chip_erase_lock = 0x18,
    /// CEULCK: The DSU CTRL.CE command is available.
    chip_erase_unlock = 0x19,
    /// SBPDIS: Sets STATUS.BPDIS, bootloader protection is discarded until
    /// CBPDIS is issued or next start-up sequence.
    disable_bootloader_protection = 0x1A,
    /// CBPDIS: Clears STATUS.BPDIS, bootloader protection is not discarded.
    enable_bootloader_protection = 0x1B,
    /// ASEES0: Configure SmartEEPROM to use Sector 0
    smart_eeprom_use_sector_0 = 0x30,
    /// ASEES1: Configure SmartEEPROM to use Sector 1
    smart_eeprom_use_sector_1 = 0x31,
    /// SEERALOC: Starts SmartEEPROM sector reallocation algorithm
    start_smart_eeprom_reallocation = 0x32,
    /// SEEFLUSH: Flush SmartEEPROM data when in buffered mode
    set_flush_smart_eeprom_when_buffered = 0x33,
    /// LSEE: Lock access to SmartEEPROM data from any means
    lock_smart_eeprom = 0x34,
    /// USEE: Unlock access to SmartEEPROM data
    unlock_smart_eeprom = 0x35,
    /// LSEER: Lock access to the SmartEEPROM Register Address Space (above
    /// 64KB)
    lock_smart_eeprom_addr_space = 0x36,
    /// USEER: Unock access to the SmartEEPROM Register Address Space (above
    /// 64KB)
    unlock_smart_eeprom_addr_space = 0x37,
};
