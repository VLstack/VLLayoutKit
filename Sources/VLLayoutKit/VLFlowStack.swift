import CoreGraphics
import SwiftUI

/// Range les vues en lignes et passe à la ligne quand la largeur manque (étiquettes, puces).
/// Chaque vue est mesurée à sa taille idéale ; une vue plus large que le conteneur est remesurée à la largeur du conteneur.
public struct VLFlowStack: Layout
{
 /// Remplissage des lignes, sauf la dernière, qui suit toujours `horizontalAlignment`.
 public enum Justification: CaseIterable, Sendable
 {
  /// Rendu naturel : chaque ligne suit `horizontalAlignment`.
  case none
  /// Les vues gardent leur taille ; la place libre est répartie dans les espacements.
  case spaceBetween
  /// Les espacements restent fixes ; la place libre est partagée à parts égales entre les vues.
  /// Seule une vue extensible grandit : écrire par exemple `.frame(maxWidth: .infinity)` avant le fond de la puce.
  case stretch
 }

 struct Row: Equatable
 {
  var indices: Range<Int>
  var size: CGSize
  var showsIndicator = false
 }

 /// Position horizontale (depuis le bord du conteneur) et largeur d'une vue dans sa ligne.
 struct Slot: Equatable
 {
  var x: CGFloat
  var width: CGFloat
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
 private let justification: Justification
 /// Utilisé par `VLLimitedFlowStack` : la dernière sous-vue est alors l'indicateur « +N ».
 private let lineLimit: Int?
 private let onHiddenCountChange: (@MainActor (Int) -> Void)?

 init(horizontalAlignment: HorizontalAlignment,
      verticalAlignment: VerticalAlignment,
      horizontalSpacing: CGFloat?,
      verticalSpacing: CGFloat?,
      justification: Justification,
      lineLimit: Int?,
      onHiddenCountChange: (@MainActor (Int) -> Void)?)
 {
  self.horizontalAlignment = horizontalAlignment
  self.verticalAlignment = verticalAlignment
  self.horizontalSpacing = horizontalSpacing ?? 8
  self.verticalSpacing = verticalSpacing ?? 8
  self.justification = justification
  self.lineLimit = lineLimit
  self.onHiddenCountChange = onHiddenCountChange
 }

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             horizontalSpacing: CGFloat? = nil,
             verticalSpacing: CGFloat? = nil,
             justification: Justification = .none)
 {
  self.init(horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: horizontalSpacing,
            verticalSpacing: verticalSpacing,
            justification: justification,
            lineLimit: nil,
            onHiddenCountChange: nil)
 }

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             spacing: CGFloat? = nil,
             justification: Justification = .none)
 {
  self.init(horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            justification: justification)
 }

 public init(alignment: Alignment,
             spacing: CGFloat? = nil,
             justification: Justification = .none)
 {
  self.init(horizontalAlignment: alignment.horizontal,
            verticalAlignment: alignment.vertical,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            justification: justification)
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

  for (rowIndex, row) in cache.rows.enumerated()
  {
   var indices = Array(row.indices)
   if row.showsIndicator { indices.append(itemCount) }
   let widths = indices.map { sizes[$0].width }

   let slots = Self.justifiedSlots(widths: widths,
                                   availableWidth: bounds.width,
                                   spacing: horizontalSpacing,
                                   justification: justification,
                                   isLastRow: rowIndex == cache.rows.count - 1)
    ?? naturalSlots(widths: widths, rowWidth: row.size.width, availableWidth: bounds.width)

   for (index, slot) in zip(indices, slots)
   {
    let height = sizes[index].height
    let yOffset: CGFloat = switch verticalAlignment
    {
     case .top: 0
     case .bottom: row.size.height - height
     default: (row.size.height - height) / 2
    }
    subviews[index].place(at: CGPoint(x: bounds.minX + slot.x, y: y + yOffset),
                          proposal: ProposedViewSize(width: slot.width, height: height))
   }
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

 /// Placement d'une ligne non justifiée, selon `horizontalAlignment`.
 private func naturalSlots(widths: [ CGFloat ],
                           rowWidth: CGFloat,
                           availableWidth: CGFloat) -> [ Slot ]
 {
  var x: CGFloat = switch horizontalAlignment
  {
   case .leading: 0
   case .trailing: availableWidth - rowWidth
   default: (availableWidth - rowWidth) / 2
  }

  var slots: [ Slot ] = []
  for width in widths
  {
   slots.append(Slot(x: x, width: width))
   x += width + horizontalSpacing
  }
  return slots
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

 /// Placement d'une ligne justifiée, ou nil si la ligne suit `horizontalAlignment` :
 /// pas de justification, dernière ligne, largeur infinie, pas de place libre, ou une seule vue en `.spaceBetween`.
 static func justifiedSlots(widths: [ CGFloat ],
                            availableWidth: CGFloat,
                            spacing: CGFloat,
                            justification: Justification,
                            isLastRow: Bool) -> [ Slot ]?
 {
  guard justification != .none, !isLastRow, availableWidth.isFinite, !widths.isEmpty else { return nil }

  let usedWidth = widths.reduce(0, +) + CGFloat(widths.count - 1) * spacing
  let freeWidth = availableWidth - usedWidth

  guard freeWidth > 0 else { return nil }

  var slots: [ Slot ] = []
  var x: CGFloat = 0

  switch justification
  {
   case .none:
    return nil

   case .spaceBetween:
    guard widths.count > 1 else { return nil }
    let gap = spacing + freeWidth / CGFloat(widths.count - 1)
    for width in widths
    {
     slots.append(Slot(x: x, width: width))
     x += width + gap
    }

   case .stretch:
    let extra = freeWidth / CGFloat(widths.count)
    for width in widths
    {
     slots.append(Slot(x: x, width: width + extra))
     x += width + extra + spacing
    }
  }

  return slots
 }
}
