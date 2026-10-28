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
  var showsIndicator = false
 }

 /// Recréé par SwiftUI (implémentation par défaut de `updateCache`) quand les sous-vues changent.
 public struct Cache
 {
  var idealSizes: [ CGSize ]? = nil
  var maxWidth: CGFloat? = nil
  var sizes: [ CGSize ] = []
  var rows: [ Row ] = []
  var visibleCount = 0
  var reportedHiddenCount: Int? = nil
 }

 private let horizontalAlignment: HorizontalAlignment
 private let verticalAlignment: VerticalAlignment
 private let horizontalSpacing: CGFloat
 private let verticalSpacing: CGFloat
 /// Utilisé par `VLLimitedFlowStack` : la dernière sous-vue est alors l'indicateur « +N ».
 private let lineLimit: Int?
 private let onHiddenCountChange: (@MainActor (Int) -> Void)?

 init(horizontalAlignment: HorizontalAlignment,
      verticalAlignment: VerticalAlignment,
      horizontalSpacing: CGFloat?,
      verticalSpacing: CGFloat?,
      lineLimit: Int?,
      onHiddenCountChange: (@MainActor (Int) -> Void)?)
 {
  self.horizontalAlignment = horizontalAlignment
  self.verticalAlignment = verticalAlignment
  self.horizontalSpacing = horizontalSpacing ?? 8
  self.verticalSpacing = verticalSpacing ?? 8
  self.lineLimit = lineLimit
  self.onHiddenCountChange = onHiddenCountChange
 }

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             horizontalSpacing: CGFloat? = nil,
             verticalSpacing: CGFloat? = nil)
 {
  self.init(horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            lineLimit: nil,
            onHiddenCountChange: nil)
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

  let sizes = cache.sizes
  let itemCount = itemCount(of: subviews)
  var y = bounds.minY

  for row in cache.rows
  {
   var x: CGFloat = switch horizontalAlignment
   {
    case .leading: bounds.minX
    case .trailing: bounds.maxX - row.size.width
    default: bounds.minX + (bounds.width - row.size.width) / 2
   }

   func place(_ index: Int)
   {
    let size = sizes[index]
    let yOffset: CGFloat = switch verticalAlignment
    {
     case .top: 0
     case .bottom: row.size.height - size.height
     default: (row.size.height - size.height) / 2
    }
    subviews[index].place(at: CGPoint(x: x, y: y + yOffset), proposal: ProposedViewSize(size))
    x += size.width + horizontalSpacing
   }

   for index in row.indices { place(index) }
   if row.showsIndicator { place(itemCount) }
   y += row.size.height + verticalSpacing
  }

  // Vues masquées : sous le cadre, coupées par VLLimitedFlowStack (un Layout ne peut pas cacher une vue)
  var hiddenIndices = Array(cache.visibleCount..<itemCount)
  if itemCount < subviews.count && cache.rows.last?.showsIndicator != true { hiddenIndices.append(itemCount) }
  for index in hiddenIndices
  {
   subviews[index].place(at: CGPoint(x: bounds.minX, y: bounds.maxY + 1), proposal: .zero)
  }

  let hiddenCount = itemCount - cache.visibleCount
  if let onHiddenCountChange, cache.reportedHiddenCount != hiddenCount
  {
   cache.reportedHiddenCount = hiddenCount
   Task { @MainActor in onHiddenCountChange(hiddenCount) }
  }
 }

 /// Nombre de vues hors indicateur.
 private func itemCount(of subviews: Subviews) -> Int
 {
  lineLimit == nil ? subviews.count : max(0, subviews.count - 1)
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

  let itemCount = itemCount(of: subviews)
  if let lineLimit, itemCount < subviews.count
  {
   let result = Self.rows(sizes: Array(cache.sizes.prefix(itemCount)),
                          maxWidth: maxWidth,
                          spacing: horizontalSpacing,
                          lineLimit: lineLimit,
                          indicatorSize: cache.sizes[itemCount])
   cache.rows = result.rows
   cache.visibleCount = result.visibleCount
  }
  else
  {
   cache.rows = Self.rows(sizes: cache.sizes, maxWidth: maxWidth, spacing: horizontalSpacing)
   cache.visibleCount = cache.sizes.count
  }
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

 /// Comme `rows(sizes:maxWidth:spacing:)`, sur au plus `lineLimit` lignes (1 au minimum).
 /// Si tout ne tient pas, la dernière ligne garde la place de l'indicateur, placé après ses vues.
 static func rows(sizes: [ CGSize ],
                  maxWidth: CGFloat,
                  spacing: CGFloat,
                  lineLimit: Int,
                  indicatorSize: CGSize) -> (rows: [ Row ], visibleCount: Int)
 {
  let allRows = Self.rows(sizes: sizes, maxWidth: maxWidth, spacing: spacing)
  let lineLimit = max(1, lineLimit)

  guard allRows.count > lineLimit else { return (allRows, sizes.count) }

  var limitedRows = Array(allRows.prefix(lineLimit - 1))
  let lastRow = allRows[lineLimit - 1]
  var visibleEnd = lastRow.indices.lowerBound
  var rowWidth = indicatorSize.width
  var rowHeight = indicatorSize.height

  while visibleEnd < lastRow.indices.upperBound && rowWidth + spacing + sizes[visibleEnd].width <= maxWidth
  {
   rowWidth += spacing + sizes[visibleEnd].width
   rowHeight = max(rowHeight, sizes[visibleEnd].height)
   visibleEnd += 1
  }

  limitedRows.append(Row(indices: lastRow.indices.lowerBound..<visibleEnd,
                         size: CGSize(width: rowWidth, height: rowHeight),
                         showsIndicator: true))
  return (limitedRows, visibleEnd)
 }
}
