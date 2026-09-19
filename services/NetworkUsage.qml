pragma Singleton

import qs.config

import Quickshell
import Quickshell.Io

import QtQuick
import Caelestia.Services

Singleton {
    id: root

    property int refCount: 0

    // Current speeds in bytes per second
    readonly property real downloadSpeed: SysMonitor.downloadSpeed
    readonly property real uploadSpeed: SysMonitor.uploadSpeed

    // Total bytes transferred since tracking started
    readonly property real downloadTotal: SysMonitor.downloadTotal
    readonly property real uploadTotal: SysMonitor.uploadTotal

    // History of speeds for sparkline (most recent at end)
    readonly property var downloadHistory: SysMonitor.downloadHistory
    readonly property var uploadHistory: SysMonitor.uploadHistory
    readonly property int historyLength: 30

    function formatBytes(bytes: real): var {
        // Handle negative or invalid values
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes)) {
            return {
                value: 0,
                unit: "B/s"
            };
        }

        if (bytes < 1024) {
            return {
                value: bytes,
                unit: "B/s"
            };
        } else if (bytes < 1024 * 1024) {
            return {
                value: bytes / 1024,
                unit: "KB/s"
            };
        } else if (bytes < 1024 * 1024 * 1024) {
            return {
                value: bytes / (1024 * 1024),
                unit: "MB/s"
            };
        } else {
            return {
                value: bytes / (1024 * 1024 * 1024),
                unit: "GB/s"
            };
        }
    }

    function formatBytesTotal(bytes: real): var {
        // Handle negative or invalid values
        if (bytes < 0 || isNaN(bytes) || !isFinite(bytes)) {
            return {
                value: 0,
                unit: "B"
            };
        }

        if (bytes < 1024) {
            return {
                value: bytes,
                unit: "B"
            };
        } else if (bytes < 1024 * 1024) {
            return {
                value: bytes / 1024,
                unit: "KB"
            };
        } else if (bytes < 1024 * 1024 * 1024) {
            return {
                value: bytes / (1024 * 1024),
                unit: "MB"
            };
        } else {
            return {
                value: bytes / (1024 * 1024 * 1024),
                unit: "GB"
            };
        }
    }
}
