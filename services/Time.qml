pragma Singleton

import QtQuick
import Quickshell
import Caelestia.I18n
import Caelestia.Config

Singleton {
    property alias enabled: clock.enabled
    readonly property date date: clock.date
    readonly property int hours: clock.hours
    readonly property int minutes: clock.minutes
    readonly property int seconds: clock.seconds

    readonly property string timeStr: format(Units.twelveHourClock ? "hh:mm:A" : "hh:mm")
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string amPmStr: timeComponents[2] ?? ""

    function format(fmt: string): string {
        return Tr.formatDateTime(clock.date, fmt);
    }

    SystemClock {
        id: clock

        // Per-second ticks wake the shell (and re-render the bar) every second; only pay for that when a seconds display is enabled
        precision: GlobalConfig.bar.clock.showSeconds || GlobalConfig.dashboard.showClockSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
}
