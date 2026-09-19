#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <qqmlintegration.h>
#include <QHash>

namespace caelestia {

class SysMonitor : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantMap memory READ memory NOTIFY memoryChanged)
    Q_PROPERTY(QVariantMap cpu READ cpu NOTIFY cpuChanged)
    Q_PROPERTY(QVariantList network READ network NOTIFY networkChanged)
    Q_PROPERTY(QVariantList disk READ disk NOTIFY diskChanged)
    Q_PROPERTY(QVariantList processes READ processes NOTIFY processesChanged)
    Q_PROPERTY(QVariantMap system READ system NOTIFY systemChanged)
    Q_PROPERTY(QVariantList diskmounts READ diskmounts NOTIFY diskmountsChanged)
    Q_PROPERTY(QVariantMap gpu READ gpu NOTIFY gpuChanged)

    Q_PROPERTY(double cpuPerc READ cpuPerc NOTIFY cpuPercChanged)
    Q_PROPERTY(QString cpuModelClean READ cpuModelClean NOTIFY cpuModelCleanChanged)
    Q_PROPERTY(QString gpuNameClean READ gpuNameClean NOTIFY gpuNameCleanChanged)

    Q_PROPERTY(double downloadSpeed READ downloadSpeed NOTIFY networkRatesChanged)
    Q_PROPERTY(double uploadSpeed READ uploadSpeed NOTIFY networkRatesChanged)
    Q_PROPERTY(double downloadTotal READ downloadTotal NOTIFY networkRatesChanged)
    Q_PROPERTY(double uploadTotal READ uploadTotal NOTIFY networkRatesChanged)
    Q_PROPERTY(QList<qreal> downloadHistory READ downloadHistory NOTIFY networkRatesChanged)
    Q_PROPERTY(QList<qreal> uploadHistory READ uploadHistory NOTIFY networkRatesChanged)

    Q_PROPERTY(int updateInterval READ updateInterval WRITE setUpdateInterval NOTIFY updateIntervalChanged)
    Q_PROPERTY(int maxProcesses READ maxProcesses WRITE setMaxProcesses NOTIFY maxProcessesChanged)
    Q_PROPERTY(QString sortBy READ sortBy WRITE setSortBy NOTIFY sortByChanged)

public:
    explicit SysMonitor(QObject* parent = nullptr);
    ~SysMonitor() override;

    QVariantMap memory() const;
    QVariantMap cpu() const;
    QVariantList network() const;
    QVariantList disk() const;
    QVariantList processes() const;
    QVariantMap system() const;
    QVariantList diskmounts() const;
    QVariantMap gpu() const;

    double cpuPerc() const;
    QString cpuModelClean() const;
    QString gpuNameClean() const;

    double downloadSpeed() const;
    double uploadSpeed() const;
    double downloadTotal() const;
    double uploadTotal() const;
    QList<qreal> downloadHistory() const;
    QList<qreal> uploadHistory() const;

    int updateInterval() const;
    void setUpdateInterval(int interval);

    int maxProcesses() const;
    void setMaxProcesses(int max);

    QString sortBy() const;
    void setSortBy(const QString& sort);

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void updateAll();
    Q_INVOKABLE void updateSystemOnce();
    Q_INVOKABLE void updateGpuOnce();

signals:
    void memoryChanged();
    void cpuChanged();
    void networkChanged();
    void diskChanged();
    void processesChanged();
    void systemChanged();
    void diskmountsChanged();
    void gpuChanged();
    void cpuPercChanged();
    void cpuModelCleanChanged();
    void gpuNameCleanChanged();
    void networkRatesChanged();
    void updateIntervalChanged();
    void maxProcessesChanged();
    void sortByChanged();

private:
    void updateMemory();
    void updateCpu();
    void updateNetwork();
    void updateDisk();
    void updateProcesses();
    void updateSystem();
    void updateDiskmounts();
    void updateGpu();

    static QString cleanCpuName(const QString& name);
    static QString cleanGpuName(const QString& name);

    QTimer m_timer;
    int m_updateInterval = 2000;
    int m_maxProcesses = 100;
    QString m_sortBy = "cpu";

    QVariantMap m_memory;
    QVariantMap m_cpu;
    QVariantList m_network;
    QVariantList m_disk;
    QVariantList m_processes;
    QVariantMap m_system;
    QVariantList m_diskmounts;
    QVariantMap m_gpu;

    double m_cpuPerc = 0.0;
    QString m_cpuModelClean;
    QString m_gpuNameClean;
    qint64 m_lastCpuTotal = 0;
    qint64 m_lastCpuIdle = 0;

    double m_downloadSpeed = 0.0;
    double m_uploadSpeed = 0.0;
    double m_downloadTotal = 0.0;
    double m_uploadTotal = 0.0;
    QList<qreal> m_downloadHistory;
    QList<qreal> m_uploadHistory;
    static constexpr int m_historyLength = 30;

    qint64 m_initialRxBytes = 0;
    qint64 m_initialTxBytes = 0;
    qint64 m_prevRxBytes = 0;
    qint64 m_prevTxBytes = 0;
    qint64 m_prevNetworkTimestamp = 0;
    bool m_networkInitialized = false;

    // Process State
    struct ProcessInfo {
        int pid;
        int ppid;
        double cpu;
        double memoryPercent;
        qint64 memoryKB;
        QString command;
        QString fullCommand;
        qint64 utime;
        qint64 stime;
    };
    QHash<int, ProcessInfo> m_lastProcesses;
    
    // Process CPU calculation helpers
    qint64 m_sysUptime; 
    long m_clockTicks;
    qint64 m_memTotalKB = 1;
};

} // namespace caelestia
