#include "cutils.hpp"
#include "fuzzy.hpp"

#include <QtConcurrent/qtconcurrentrun.h>
#include <QtQuick/qquickitemgrabresult.h>
#include <QtQuick/qquickwindow.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qfuturewatcher.h>
#include <qqmlengine.h>
#include <vector>

namespace caelestia {

void CUtils::saveItem(QQuickItem* target, const QUrl& path) {
    this->saveItem(target, path, QRect(), QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) {
    this->saveItem(target, path, rect, QJSValue(), QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) {
    this->saveItem(target, path, QRect(), onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) {
    this->saveItem(target, path, QRect(), onSaved, onFailed);
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) {
    this->saveItem(target, path, rect, onSaved, QJSValue());
}

void CUtils::saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) {
    if (!target) {
        qWarning() << "CUtils::saveItem: a target is required";
        return;
    }

    if (!path.isLocalFile()) {
        qWarning() << "CUtils::saveItem:" << path << "is not a local file";
        return;
    }

    if (!target->window()) {
        qWarning() << "CUtils::saveItem: unable to save target" << target << "without a window";
        return;
    }

    auto scaledRect = rect;
    const qreal scale = target->window()->devicePixelRatio();
    if (rect.isValid() && !qFuzzyCompare(scale + 1.0, 2.0)) {
        scaledRect =
            QRectF(rect.left() * scale, rect.top() * scale, rect.width() * scale, rect.height() * scale).toRect();
    }

    const QSharedPointer<const QQuickItemGrabResult> grabResult = target->grabToImage();

    QObject::connect(grabResult.data(), &QQuickItemGrabResult::ready, this,
        [grabResult, scaledRect, path, onSaved, onFailed, this]() {
            const auto future = QtConcurrent::run([=]() {
                QImage image = grabResult->image();

                if (scaledRect.isValid()) {
                    image = image.copy(scaledRect);
                }

                const QString file = path.toLocalFile();
                const QString parent = QFileInfo(file).absolutePath();
                return QDir().mkpath(parent) && image.save(file);
            });

            auto* watcher = new QFutureWatcher<bool>(this);
            auto* engine = qmlEngine(this);

            QObject::connect(watcher, &QFutureWatcher<bool>::finished, this, [=]() {
                if (watcher->result()) {
                    if (onSaved.isCallable()) {
                        onSaved.call(
                            { QJSValue(path.toLocalFile()), engine->toScriptValue(QVariant::fromValue(path)) });
                    }
                } else {
                    qWarning() << "CUtils::saveItem: failed to save" << path;
                    if (onFailed.isCallable()) {
                        onFailed.call({ engine->toScriptValue(QVariant::fromValue(path)) });
                    }
                }
                watcher->deleteLater();
            });
            watcher->setFuture(future);
        });
}

bool CUtils::copyFile(const QUrl& source, const QUrl& target, bool overwrite) const {
    if (!source.isLocalFile()) {
        qWarning() << "CUtils::copyFile: source" << source << "is not a local file";
        return false;
    }
    if (!target.isLocalFile()) {
        qWarning() << "CUtils::copyFile: target" << target << "is not a local file";
        return false;
    }

    if (overwrite && QFile::exists(target.toLocalFile())) {
        if (!QFile::remove(target.toLocalFile())) {
            qWarning() << "CUtils::copyFile: overwrite was specified but failed to remove" << target.toLocalFile();
            return false;
        }
    }

    return QFile::copy(source.toLocalFile(), target.toLocalFile());
}

bool CUtils::deleteFile(const QUrl& path) const {
    if (!path.isLocalFile()) {
        qWarning() << "CUtils::deleteFile: path" << path << "is not a local file";
        return false;
    }

    return QFile::remove(path.toLocalFile());
}

bool CUtils::exists(const QString& path) const {
    return QFile::exists(path);
}

QString CUtils::toLocalFile(const QUrl& url) const {
    if (!url.isLocalFile()) {
        qWarning() << "CUtils::toLocalFile: given url is not a local file" << url;
        return QString();
    }

    return url.toLocalFile();
}

qreal CUtils::getBacklightBrightness() const {
    QDir dir("/sys/class/backlight");
    const QStringList entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (!entries.isEmpty()) {
        const QString blPath = dir.absoluteFilePath(entries.first());
        QFile curFile(blPath + "/brightness");
        QFile maxFile(blPath + "/max_brightness");
        if (curFile.open(QIODevice::ReadOnly) && maxFile.open(QIODevice::ReadOnly)) {
            bool ok1 = false, ok2 = false;
            qint64 cur = QString::fromUtf8(curFile.readAll().trimmed()).toLongLong(&ok1);
            qint64 max = QString::fromUtf8(maxFile.readAll().trimmed()).toLongLong(&ok2);
            if (ok1 && ok2 && max > 0) {
                return static_cast<qreal>(cur) / static_cast<qreal>(max);
            }
        }
    }
    return 0.5;
}

QList<QObject*> CUtils::fuzzySearch(
    const QString& search,
    const QList<QObject*>& items,
    const QStringList& keys,
    const QList<qreal>& weights) const {
    const QString trimmed = search.trimmed();
    if (trimmed.isEmpty()) {
        return items;
    }

    struct ScoredObject {
        double score;
        QObject* obj;
    };

    std::vector<ScoredObject> matches;
    matches.reserve(static_cast<size_t>(items.size()));

    for (QObject* item : items) {
        if (!item) {
            continue;
        }

        double totalScore = 0.0;
        bool anyMatch = false;

        for (qsizetype i = 0; i < keys.size(); ++i) {
            const QString& key = keys.at(i);
            const double weight = (i < weights.size()) ? weights.at(i) : 1.0;
            const QString val = item->property(key.toUtf8().constData()).toString();
            const int score = fuzzyScore(trimmed, val);
            if (score > 0) {
                anyMatch = true;
                totalScore += static_cast<double>(score) * weight;
            }
        }

        if (anyMatch) {
            matches.push_back({ totalScore, item });
        }
    }

    std::sort(matches.begin(), matches.end(), [](const ScoredObject& a, const ScoredObject& b) {
        return a.score > b.score;
    });

    QList<QObject*> result;
    result.reserve(static_cast<qsizetype>(matches.size()));
    for (const auto& m : matches) {
        result.append(m.obj);
    }
    return result;
}

} // namespace caelestia
