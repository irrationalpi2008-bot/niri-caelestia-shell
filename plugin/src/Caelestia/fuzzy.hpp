#pragma once

#include <qchar.h>
#include <qstring.h>
#include <algorithm>

namespace caelestia {

[[nodiscard]] inline int fuzzyScore(const QString& query, const QString& target) {
    if (query.isEmpty()) {
        return 0;
    }
    if (target.isEmpty()) {
        return -1;
    }

    const qsizetype qLen = query.length();
    const qsizetype tLen = target.length();

    if (qLen > tLen) {
        return -1;
    }

    const QString qLower = query.toLower();
    const QString tLower = target.toLower();

    // Exact match
    if (qLower == tLower) {
        return 20000;
    }

    // Prefix match
    if (tLower.startsWith(qLower)) {
        return 10000 + static_cast<int>(1000 - std::min(tLen, static_cast<qsizetype>(1000)));
    }

    // Substring match
    const qsizetype substrIdx = tLower.indexOf(qLower);
    if (substrIdx != -1) {
        const bool wordBoundary = (substrIdx == 0) || !target.at(substrIdx - 1).isLetterOrNumber();
        const int base = wordBoundary ? 7000 : 4000;
        return base + static_cast<int>(500 - std::min(substrIdx, static_cast<qsizetype>(500)))
                    - static_cast<int>(std::min(tLen, static_cast<qsizetype>(500)));
    }

    // Fuzzy subsequence match
    qsizetype qIdx = 0;
    qsizetype tIdx = 0;
    qsizetype prevMatchIdx = -2;
    int score = 1000;
    int consecutiveCount = 0;

    while (qIdx < qLen && tIdx < tLen) {
        const QChar qc = qLower.at(qIdx);
        const QChar tc = tLower.at(tIdx);

        if (qc == tc) {
            score += 20;

            if (tIdx == prevMatchIdx + 1) {
                consecutiveCount++;
                score += 25 * consecutiveCount;
            } else {
                consecutiveCount = 0;
                if (prevMatchIdx >= 0) {
                    const qsizetype gap = tIdx - prevMatchIdx - 1;
                    score -= static_cast<int>(std::min(gap * 2, static_cast<qsizetype>(100)));
                }
            }

            if (tIdx == 0 || !target.at(tIdx - 1).isLetterOrNumber()) {
                score += 35;
            } else if (target.at(tIdx).isUpper() && target.at(tIdx - 1).isLower()) {
                score += 25;
            }

            prevMatchIdx = tIdx;
            qIdx++;
        }
        tIdx++;
    }

    if (qIdx < qLen) {
        return -1;
    }

    score -= static_cast<int>(std::min(tLen, static_cast<qsizetype>(200)));
    return std::max(score, 1);
}

} // namespace caelestia
