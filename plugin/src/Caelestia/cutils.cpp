#include "cutils.hpp"
#include "fuzzy.hpp"

#include <QtConcurrent/qtconcurrentrun.h>
#include <QtQuick/qquickitemgrabresult.h>
#include <QtQuick/qquickwindow.h>
#include <algorithm>
#include <cmath>
#include <qcolor.h>
#include <qdir.h>
#include <qfileinfo.h>
#include <qfuturewatcher.h>
#include <qqmlengine.h>
#include <qsavefile.h>
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

qreal CUtils::getLuminance(const QColor& c) const {
    if (qFuzzyIsNull(c.redF()) && qFuzzyIsNull(c.greenF()) && qFuzzyIsNull(c.blueF())) {
        return 0.0;
    }
    const double r = static_cast<double>(c.redF());
    const double g = static_cast<double>(c.greenF());
    const double b = static_cast<double>(c.blueF());
    return std::sqrt(0.299 * (r * r) + 0.587 * (g * g) + 0.114 * (b * b));
}

QColor CUtils::alterColour(
    const QColor& c,
    qreal a,
    int layer,
    bool light,
    qreal baseTransparency,
    qreal wallLuminance) const {
    const qreal luminance = getLuminance(c);
    if (luminance <= 0.0001) {
        return QColor::fromRgbF(0.0f, 0.0f, 0.0f, static_cast<float>(std::clamp(a, 0.0, 1.0)));
    }

    const qreal layerFactor = (!light || layer == 1) ? 1.0 : (-static_cast<qreal>(layer) / 2.0);
    const qreal lightFactor = light ? 0.2 : 0.3;
    const qreal wallMult = light ? ((layer == 1) ? 3.0 : 1.0) : 2.5;
    const qreal offset = layerFactor * lightFactor * (1.0 - baseTransparency) * (1.0 + wallLuminance * wallMult);
    const qreal scale = (luminance + offset) / luminance;

    const double r = std::clamp(static_cast<double>(c.redF()) * scale, 0.0, 1.0);
    const double g = std::clamp(static_cast<double>(c.greenF()) * scale, 0.0, 1.0);
    const double b = std::clamp(static_cast<double>(c.blueF()) * scale, 0.0, 1.0);
    const double alpha = std::clamp(a, 0.0, 1.0);

    return QColor::fromRgbF(
        static_cast<float>(r),
        static_cast<float>(g),
        static_cast<float>(b),
        static_cast<float>(alpha));
}

QColor CUtils::onColor(const QColor& c) const {
    const float h = c.hslHueF() < 0.0f ? 0.0f : c.hslHueF();
    const float s = std::clamp(c.hslSaturationF(), 0.0f, 1.0f);
    const float l = c.lightnessF() < 0.5f ? 0.9f : 0.1f;
    return QColor::fromHslF(h, s, l, 1.0f);
}

void CUtils::updateTransparentPalette(
    QObject* targetTPalette,
    QObject* sourcePalette,
    bool transparencyEnabled,
    qreal baseAlpha,
    qreal layersAlpha,
    bool light,
    qreal wallLuminance) const {
    if (!targetTPalette || !sourcePalette) {
        return;
    }

    static const char* layer0Props[] = {
        "m3background",
        "m3surface",
        "m3surfaceDim",
        "m3surfaceBright",
        "m3surfaceVariant",
        "m3inverseSurface"
    };

    static const char* layer1Props[] = {
        "m3primary_paletteKeyColor",
        "m3secondary_paletteKeyColor",
        "m3tertiary_paletteKeyColor",
        "m3neutral_paletteKeyColor",
        "m3neutral_variant_paletteKeyColor",
        "m3onBackground",
        "m3surfaceContainerLowest",
        "m3surfaceContainerLow",
        "m3surfaceContainer",
        "m3surfaceContainerHigh",
        "m3surfaceContainerHighest",
        "m3onSurface",
        "m3onSurfaceVariant",
        "m3inverseOnSurface",
        "m3outline",
        "m3outlineVariant",
        "m3shadow",
        "m3scrim",
        "m3surfaceTint",
        "m3primary",
        "m3onPrimary",
        "m3primaryContainer",
        "m3onPrimaryContainer",
        "m3inversePrimary",
        "m3secondary",
        "m3onSecondary",
        "m3secondaryContainer",
        "m3onSecondaryContainer",
        "m3tertiary",
        "m3onTertiary",
        "m3tertiaryContainer",
        "m3onTertiaryContainer",
        "m3error",
        "m3onError",
        "m3errorContainer",
        "m3onErrorContainer",
        "m3primaryFixed",
        "m3primaryFixedDim",
        "m3onPrimaryFixed",
        "m3onPrimaryFixedVariant",
        "m3secondaryFixed",
        "m3secondaryFixedDim",
        "m3onSecondaryFixed",
        "m3onSecondaryFixedVariant",
        "m3tertiaryFixed",
        "m3tertiaryFixedDim",
        "m3onTertiaryFixed",
        "m3onTertiaryFixedVariant"
    };

    for (const char* prop : layer0Props) {
        const QVariant val = sourcePalette->property(prop);
        if (!val.isValid()) {
            continue;
        }
        QColor targetColor = val.value<QColor>();
        if (transparencyEnabled) {
            targetColor.setAlphaF(static_cast<float>(std::clamp(baseAlpha, 0.0, 1.0)));
        }
        if (targetTPalette->property(prop).value<QColor>() != targetColor) {
            targetTPalette->setProperty(prop, targetColor);
        }
    }

    for (const char* prop : layer1Props) {
        const QVariant val = sourcePalette->property(prop);
        if (!val.isValid()) {
            continue;
        }
        const QColor c = val.value<QColor>();
        QColor targetColor = c;
        if (transparencyEnabled) {
            targetColor = alterColour(c, layersAlpha, 1, light, baseAlpha, wallLuminance);
        }
        if (targetTPalette->property(prop).value<QColor>() != targetColor) {
            targetTPalette->setProperty(prop, targetColor);
        }
    }
}

bool CUtils::writeTextFile(const QString& path, const QString& content) const {
    const QFileInfo fi(path);
    const QDir dir = fi.dir();
    if (!dir.exists()) {
        if (!dir.mkpath(QStringLiteral("."))) {
            return false;
        }
    }
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        return false;
    }
    const QByteArray utf8 = content.toUtf8();
    if (file.write(utf8) != utf8.size()) {
        file.cancelWriting();
        return false;
    }
    return file.commit();
}

} // namespace caelestia
