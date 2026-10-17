import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/items/data/item_repository.dart';
import '../models/item_model.dart';

class MatchResult {
  const MatchResult({
    required this.item,
    required this.score,
    required this.explanation,
    required this.categoryMatch,
    required this.keywordScore,
    required this.locationScore,
    required this.temporalScore,
  });

  final ItemModel item;
  final double score; // 0.0 to 1.0
  final String explanation;
  final bool categoryMatch;
  final double keywordScore;
  final double locationScore;
  final double temporalScore;

  int get percentage => (score * 100).round();
}

class SimilarityService {
  static const Set<String> _stopWords = {
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
    'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
    'to', 'was', 'were', 'will', 'with', 'my', 'i', 'found', 'lost',
    'near', 'campus', 'some', 'any', 'this', 'item',
  };

  /// Tokenizes a text into lowercased meaningful keywords without punctuation and stop words
  static Set<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length > 1 && !_stopWords.contains(token))
        .toSet();
  }

  /// Calculates Jaccard similarity coefficient between two sets of tokens
  static double jaccardSimilarity(Set<String> setA, Set<String> setB) {
    if (setA.isEmpty && setB.isEmpty) return 0.0;
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;
    if (union == 0) return 0.0;
    return intersection / union;
  }

  /// Evaluates similarity between a target item and a candidate item
  static MatchResult evaluate(ItemModel target, ItemModel candidate) {
    // 1. Category Score (weight: 0.35)
    final bool categoryMatch = target.category.toLowerCase() == candidate.category.toLowerCase();
    final double categoryScore = categoryMatch ? 1.0 : 0.0;

    // 2. Keyword / Token Overlap Score (weight: 0.35)
    final targetTokens = tokenize('${target.title} ${target.description}');
    final candidateTokens = tokenize('${candidate.title} ${candidate.description}');
    final double keywordScore = jaccardSimilarity(targetTokens, candidateTokens);

    // 3. Location Proximity Score (weight: 0.15)
    double locationScore = 0.0;
    if (target.locationLabel.toLowerCase() == candidate.locationLabel.toLowerCase()) {
      locationScore = 1.0;
    } else if (target.lat != null &&
        target.lng != null &&
        candidate.lat != null &&
        candidate.lng != null) {
      // Approximate euclidean distance in degree space (~111km per degree)
      final dLat = target.lat! - candidate.lat!;
      final dLng = target.lng! - candidate.lng!;
      final distDeg = sqrt(dLat * dLat + dLng * dLng);
      // Within ~200 meters (~0.002 deg) = 1.0, falls off to 0 beyond ~1km (~0.01 deg)
      if (distDeg < 0.002) {
        locationScore = 1.0;
      } else if (distDeg < 0.01) {
        locationScore = max(0.0, 1.0 - (distDeg - 0.002) / 0.008);
      }
    } else {
      // Partial label overlap
      final targetLocTokens = tokenize(target.locationLabel);
      final candidateLocTokens = tokenize(candidate.locationLabel);
      locationScore = jaccardSimilarity(targetLocTokens, candidateLocTokens);
    }

    // 4. Temporal Proximity Score (weight: 0.15)
    final diffDays = target.reportedAt.difference(candidate.reportedAt).inHours.abs() / 24.0;
    double temporalScore = 0.0;
    if (diffDays <= 1.0) {
      temporalScore = 1.0;
    } else if (diffDays <= 7.0) {
      temporalScore = max(0.0, 1.0 - ((diffDays - 1.0) / 6.0));
    }

    // Composite weighted score
    final double compositeScore = (categoryScore * 0.35) +
        (keywordScore * 0.35) +
        (locationScore * 0.15) +
        (temporalScore * 0.15);

    // Build human-readable explanation
    final List<String> reasons = [];
    if (categoryMatch) {
      reasons.add('Same category (${target.category})');
    }
    final commonTokens = targetTokens.intersection(candidateTokens);
    if (commonTokens.isNotEmpty) {
      reasons.add('Keywords match: "${commonTokens.take(3).join(', ')}"');
    }
    if (locationScore >= 0.7) {
      reasons.add('Nearby location');
    }
    if (diffDays <= 2) {
      reasons.add('Reported within 48h');
    } else if (diffDays <= 7) {
      reasons.add('Reported within past week');
    }

    final explanation = reasons.isNotEmpty
        ? reasons.join(' • ')
        : 'Low multi-factor correlation';

    return MatchResult(
      item: candidate,
      score: compositeScore,
      explanation: explanation,
      categoryMatch: categoryMatch,
      keywordScore: keywordScore,
      locationScore: locationScore,
      temporalScore: temporalScore,
    );
  }

  /// Finds potential matches for an item among candidates (lost matches found, found matches lost)
  List<MatchResult> findMatches({
    required ItemModel target,
    required List<ItemModel> allItems,
    double minThreshold = 0.30,
  }) {
    final candidateType = target.type == ItemType.lost ? ItemType.found : ItemType.lost;
    final candidates = allItems.where((i) => i.id != target.id && i.type == candidateType);

    final results = <MatchResult>[];
    for (final candidate in candidates) {
      final res = evaluate(target, candidate);
      if (res.score >= minThreshold) {
        results.add(res);
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

final similarityServiceProvider = Provider<SimilarityService>((ref) {
  return SimilarityService();
});

/// Provider for potential matches for an item
final itemMatchesProvider = FutureProvider.autoDispose.family<List<MatchResult>, String>((ref, itemId) async {
  final itemRepo = ref.watch(itemRepositoryProvider);
  final target = await itemRepo.getItemById(itemId);
  if (target == null) return [];

  final allItems = await itemRepo.getItems();
  final similarity = ref.watch(similarityServiceProvider);
  return similarity.findMatches(target: target, allItems: allItems);
});
