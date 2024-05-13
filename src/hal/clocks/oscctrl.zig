const microzig = @import("microzig");
const OSCCTRL = microzig.chip.peripherals.OSCCTRL;

pub fn wait_for_dpll_enabled(index: u1) void {
    while (OSCCTRL.DPLL[index].DPLLSYNCBUSY.read().ENABLE != 0) {}
}

pub fn wait_for_dpll_clkrdy(index: u1) void {
    while (OSCCTRL.DPLL[index].DPLLSTATUS.read().CLKRDY == 0) {}
}

pub fn wait_for_dpll_ratio(index: u1) void {
    while (OSCCTRL.DPLL[index].DPLLSYNCBUSY.read().DPLLRATIO != 0) {}
}
