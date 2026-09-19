pragma Singleton

import qs.config
import Quickshell
import Quickshell.Io
import QtQuick
import Caelestia.Services

Singleton {
    id: root

    // CPU properties
    property string cpuName: SysMonitor.cpuModelClean || cleanCpuName(SysMonitor.cpu.model || "")
    property real cpuPerc: SysMonitor.cpuPerc
    property real cpuTemp: SysMonitor.cpu.temperature || 0

    // GPU properties
    readonly property string gpuType: Config.services.gpuType.toUpperCase() || SysMonitor.gpu.type || "NONE"
    property string gpuName: SysMonitor.gpuNameClean || cleanGpuName(SysMonitor.gpu.name || "")
    property real gpuPerc: SysMonitor.gpu.utilization || 0
    property real gpuTemp: SysMonitor.gpu.temperature || 0

    // Memory properties
    readonly property real memUsed: SysMonitor.memUsed
    readonly property real memTotal: SysMonitor.memTotal
    readonly property real memPerc: SysMonitor.memPerc

    // Storage properties (aggregated)
    readonly property real storagePerc: SysMonitor.storagePerc

    // Individual disks: Array of { mount, used, total, free, perc }
    readonly property var disks: SysMonitor.formattedDisks

    property real lastCpuIdle
    property real lastCpuTotal

    property int refCount

    function cleanCpuName(name: string): string {
        if (!name) return "";
        let cleaned = name.replace(/\(R\)/gi, "").replace(/\(TM\)/gi, "").replace(/CPU/gi, "").replace(/\d+th Gen /gi, "").replace(/\d+nd Gen /gi, "").replace(/\d+rd Gen /gi, "").replace(/\d+st Gen /gi, "").replace(/Core /gi, "").replace(/Processor/gi, "").replace(/\s+/g, " ").trim();

        if (cleaned.length > 25) {
            cleaned = cleaned.substring(0, 22) + "...";
        }
        return cleaned;
    }

    function cleanGpuName(name: string): string {
        if (!name) return "";
        let cleaned = name.replace(/NVIDIA GeForce /gi, "")
                          .replace(/NVIDIA /gi, "")
                          .replace(/AMD Radeon /gi, "")
                          .replace(/AMD /gi, "")
                          .replace(/Intel\(R\) /gi, "")
                          .replace(/Intel /gi, "")
                          .replace(/\(R\)/gi, "")
                          .replace(/\(TM\)/gi, "")
                          .replace(/Graphics/gi, "")
                          .replace(/ Laptop GPU/gi, "")
                          .replace(/ Mobile/gi, "")
                          .replace(/ Desktop/gi, "")
                          .replace(/\s+/g, " ")
                          .trim();

        if (cleaned.length > 25) {
            cleaned = cleaned.substring(0, 22) + "...";
        }
        return cleaned;
    }

    function formatKib(kib: real): var {
        const mib = 1024;
        const gib = 1024 ** 2;
        const tib = 1024 ** 3;

        if (kib >= tib)
            return {
                value: kib / tib,
                unit: "TiB"
            };
        if (kib >= gib)
            return {
                value: kib / gib,
                unit: "GiB"
            };
        if (kib >= mib)
            return {
                value: kib / mib,
                unit: "MiB"
            };
        return {
            value: kib,
            unit: "KiB"
        };
    }

    Timer {
        running: root.refCount > 0
        interval: Config.dashboard.resourceUpdateInterval
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            SysMonitor.updateAll();
        }
    }
    
    Connections {
        target: SysMonitor
        
        function onCpuChanged() {
            let data = SysMonitor.cpu;
            if (!root.cpuName) root.cpuName = root.cleanCpuName(data.model || "");
            root.cpuTemp = data.temperature || 0;
        }
    }

}
