import CoreGraphics
import SwiftUI

/// Grille de tuiles carrées où chaque vue occupe une ou plusieurs colonnes et lignes, comme les widgets iOS.
/// Le nombre de colonnes dépend de la largeur proposée et de la plage de largeur de colonne ; la hauteur d'une ligne est égale à la largeur d'une colonne.
/// Chaque tuile va dans la première position libre, dans l'ordre de lecture : les petites tuiles comblent les trous laissés par les grandes.
/// Contrairement à `LazyVGrid`, toutes les vues sont créées d'un coup (pas de chargement paresseux) : à réserver aux grilles de taille raisonnable.
public struct VLTileGrid: Layout
{
 struct TileSize: Equatable, Sendable
 {
  var columns: Int
  var rows: Int
 }

 struct Placement: Equatable
 {
  var column: Int
  var row: Int
  var columns: Int
  var rows: Int
 }

 /// Recréé par SwiftUI (implémentation par défaut de `updateCache`) quand les sous-vues changent.
 public struct Cache
 {
  var width: CGFloat? = nil
  var columnCount = 1
  var columnWidth: CGFloat = 0
  var placements: [ Placement ] = []
  var rowCount = 0
 }

 private let columnWidthRange: ClosedRange<CGFloat>
 private let maxColumns: Int?
 private let spacing: CGFloat

 /// - Parameters:
 ///   - columnWidthRange: largeur souhaitée d'une colonne.
 ///   - maxColumns: nombre maximum de colonnes, sauf si les colonnes dépassaient alors la borne haute de `columnWidthRange`.
 ///   - spacing: espacement entre les colonnes et entre les lignes.
 public init(columnWidthRange: ClosedRange<CGFloat>,
             maxColumns: Int? = nil,
             spacing: CGFloat = 8)
 {
  self.columnWidthRange = columnWidthRange
  self.maxColumns = maxColumns
  self.spacing = spacing
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

  let height = length(of: cache.rowCount, cellSize: cache.columnWidth)

  guard let proposedWidth = proposal.width, proposedWidth.isFinite
  else { return CGSize(width: length(of: cache.columnCount, cellSize: cache.columnWidth), height: height) }
  return CGSize(width: proposedWidth, height: height)
 }

 public func placeSubviews(in bounds: CGRect,
                           proposal: ProposedViewSize,
                           subviews: Subviews,
                           cache: inout Cache)
 {
  computeLayout(subviews: subviews, proposal: proposal, cache: &cache)

  let step = cache.columnWidth + spacing

  for (index, placement) in cache.placements.enumerated()
  {
   subviews[index].place(at: CGPoint(x: bounds.minX + CGFloat(placement.column) * step,
                                     y: bounds.minY + CGFloat(placement.row) * step),
                         proposal: ProposedViewSize(width: length(of: placement.columns, cellSize: cache.columnWidth),
                                                    height: length(of: placement.rows, cellSize: cache.columnWidth)))
  }
 }

 /// Longueur occupée par `count` cellules et les espacements entre elles.
 private func length(of count: Int,
                     cellSize: CGFloat) -> CGFloat
 {
  count > 0 ? CGFloat(count) * cellSize + CGFloat(count - 1) * spacing : 0
 }

 /// Calcule colonnes et placements, seulement si la largeur a changé depuis le dernier calcul.
 private func computeLayout(subviews: Subviews,
                            proposal: ProposedViewSize,
                            cache: inout Cache)
 {
  let width = proposal.width ?? .infinity

  guard cache.width != width else { return }

  let columnCount = Self.columnCount(width: width,
                                     columnWidthRange: columnWidthRange,
                                     maxColumns: maxColumns,
                                     spacing: spacing)
  let arrangement = Self.placements(sizes: subviews.map { $0[TileSizeKey.self] },
                                    columnCount: columnCount)

  cache.columnCount = columnCount
  cache.columnWidth = width.isFinite
   ? max(0, (width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount))
   : columnWidthRange.upperBound
  cache.placements = arrangement.placements
  cache.rowCount = arrangement.rowCount
  cache.width = width
 }

 /// Nombre de colonnes pour une largeur donnée (même logique que `LG.Layout.columns` de Logeo).
 /// Sans largeur finie : `maxColumns`, ou une seule colonne.
 static func columnCount(width: CGFloat,
                         columnWidthRange: ClosedRange<CGFloat>,
                         maxColumns: Int?,
                         spacing: CGFloat) -> Int
 {
  guard width.isFinite else { return max(1, maxColumns ?? 1) }
  guard width > 0 else { return 1 }

  let totalWidth = width + spacing
  let minWidth = max(1, columnWidthRange.lowerBound + spacing)
  let maxWidth = max(minWidth, columnWidthRange.upperBound + spacing)
  let minColumns = max(1, Int(totalWidth / maxWidth))

  var count = max(1, Int(totalWidth / minWidth))
  if let maxColumns { count = min(count, maxColumns) }
  return max(minColumns, count)
 }

 /// Place chaque tuile dans la première position libre, dans l'ordre de lecture.
 /// Une tuile plus large que la grille est ramenée au nombre de colonnes.
 static func placements(sizes: [ TileSize ],
                        columnCount: Int) -> (placements: [ Placement ], rowCount: Int)
 {
  let columnCount = max(1, columnCount)
  var occupied: [ [ Bool ] ] = []
  var placements: [ Placement ] = []

  func isFree(column: Int, row: Int, columns: Int, rows: Int) -> Bool
  {
   for r in row..<(row + rows) where r < occupied.count
   {
    for c in column..<(column + columns) where occupied[r][c] { return false }
   }
   return true
  }

  for size in sizes
  {
   let columns = min(max(1, size.columns), columnCount)
   let rows = max(1, size.rows)
   var row = 0

   while true
   {
    if let column = (0...(columnCount - columns)).first(where: { isFree(column: $0, row: row, columns: columns, rows: rows) })
    {
     placements.append(Placement(column: column, row: row, columns: columns, rows: rows))
     while occupied.count < row + rows
     {
      occupied.append(Array(repeating: false, count: columnCount))
     }
     for r in row..<(row + rows)
     {
      for c in column..<(column + columns) { occupied[r][c] = true }
     }
     break
    }
    row += 1
   }
  }

  return (placements, occupied.count)
 }
}

private struct TileSizeKey: LayoutValueKey
{
 static let defaultValue = VLTileGrid.TileSize(columns: 1, rows: 1)
}

public extension View
{
 /// Emprise de la vue dans un `VLTileGrid`, en colonnes et en lignes (1 x 1 par défaut).
 /// Une emprise plus large que la grille est ramenée au nombre de colonnes.
 func tileSize(columns: Int, rows: Int) -> some View
 {
  layoutValue(key: TileSizeKey.self, value: VLTileGrid.TileSize(columns: columns, rows: rows))
 }
}
