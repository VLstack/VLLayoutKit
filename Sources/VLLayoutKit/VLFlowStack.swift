import CoreGraphics
import SwiftUI

/// Range les vues en lignes et passe à la ligne quand la largeur manque (étiquettes, puces).
/// Chaque vue est mesurée à sa taille idéale ; une vue plus large que le conteneur est remesurée à la largeur du conteneur.
public struct VLFlowStack: Layout
{
 struct Row: Equatable
 {
  var indices: Range<Int>
  var size: CGSize
 }

 /// Recréé par SwiftUI (implémentation par défaut de `updateCache`) quand les sous-vues changent.
 public struct Cache
 {
  var idealSizes: [ CGSize ]? = nil
  var maxWidth: CGFloat? = nil
  var sizes: [ CGSize ] = []
  var rows: [ Row ] = []
 }

 private let horizontalAlignment: HorizontalAlignment
 private let verticalAlignment: VerticalAlignment
 private let horizontalSpacing: CGFloat
 private let verticalSpacing: CGFloat

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             horizontalSpacing: CGFloat? = nil,
             verticalSpacing: CGFloat? = nil)
 {
  self.horizontalAlignment = horizontalAlignment
  self.verticalAlignment = verticalAlignment
  self.horizontalSpacing = horizontalSpacing ?? 8
  self.verticalSpacing = verticalSpacing ?? 8
 }

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             spacing: CGFloat? = nil)
 {
  self.init(horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: spacing,
            verticalSpacing: spacing)
 }

 public init(alignment: Alignment,
             spacing: CGFloat? = nil)
 {
  self.init(horizontalAlignment: alignment.horizontal,
            verticalAlignment: alignment.vertical,
            horizontalSpacing: spacing,
            verticalSpacing: spacing)
 }

 public func makeCache(subviews: Subviews) -> Cache
 {
  Cache()
 }

 public func sizeThatFits(proposal: ProposedViewSize,
                          subviews: Subviews,
                          cache: inout Cache) -> CGSize
 {
  computeLayout(subviews: subviews, proposal: proposal, cache: &cache)

  let totalVerticalSpacing: CGFloat = CGFloat(max(0, cache.rows.count - 1)) * verticalSpacing
  let totalHeight = cache.rows.map(\.size.height).reduce(0, +) + totalVerticalSpacing
  let totalWidth = cache.rows.map(\.size.width).max() ?? 0

  guard let proposedWidth = proposal.width, proposedWidth.isFinite else { return CGSize(width: totalWidth, height: totalHeight) }
  return CGSize(width: proposedWidth, height: totalHeight)
 }

 public func placeSubviews(in bounds: CGRect,
                           proposal: ProposedViewSize,
                           subviews: Subviews,
                           cache: inout Cache)
 {
  computeLayout(subviews: subviews, proposal: proposal, cache: &cache)

  var y = bounds.minY

  for row in cache.rows
  {
   var x: CGFloat = switch horizontalAlignment
   {
    case .leading: bounds.minX
    case .trailing: bounds.maxX - row.size.width
    default: bounds.minX + (bounds.width - row.size.width) / 2
   }

   for index in row.indices
   {
    let size = cache.sizes[index]
    let yOffset: CGFloat = switch verticalAlignment
    {
     case .top: 0
     case .bottom: row.size.height - size.height
     default: (row.size.height - size.height) / 2
    }
    subviews[index].place(at: CGPoint(x: x, y: y + yOffset), proposal: ProposedViewSize(size))
    x += size.width + horizontalSpacing
   }
   y += row.size.height + verticalSpacing
  }
 }

 /// Mesure les vues et calcule les lignes, seulement si la largeur a changé depuis le dernier calcul.
 private func computeLayout(subviews: Subviews,
                            proposal: ProposedViewSize,
                            cache: inout Cache)
 {
  let maxWidth = proposal.width ?? .infinity

  guard cache.maxWidth != maxWidth else { return }

  let idealSizes = cache.idealSizes ?? subviews.map { $0.sizeThatFits(.unspecified) }
  cache.idealSizes = idealSizes
  cache.sizes = zip(subviews, idealSizes).map
  { subview, idealSize in
   idealSize.width > maxWidth ? subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil)) : idealSize
  }
  cache.rows = Self.rows(sizes: cache.sizes, maxWidth: maxWidth, spacing: horizontalSpacing)
  cache.maxWidth = maxWidth
 }

 /// Répartit les tailles en lignes. Une vue plus large que `maxWidth` occupe seule sa ligne.
 static func rows(sizes: [ CGSize ],
                  maxWidth: CGFloat,
                  spacing: CGFloat) -> [ Row ]
 {
  var rows: [ Row ] = []
  var start = 0
  var rowWidth: CGFloat = 0
  var rowHeight: CGFloat = 0

  for (index, size) in sizes.enumerated()
  {
   if index > start && rowWidth + spacing + size.width > maxWidth
   {
    rows.append(Row(indices: start..<index,
                    size: CGSize(width: rowWidth, height: rowHeight)))
    start = index
    rowWidth = 0
    rowHeight = 0
   }

   rowWidth += (index == start ? 0 : spacing) + size.width
   rowHeight = max(rowHeight, size.height)
  }

  if start < sizes.count
  {
   rows.append(Row(indices: start..<sizes.count,
                   size: CGSize(width: rowWidth, height: rowHeight)))
  }

  return rows
 }
}
