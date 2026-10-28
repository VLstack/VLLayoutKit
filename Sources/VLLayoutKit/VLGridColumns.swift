import CoreGraphics
import SwiftUI

/// Nombre de colonnes d'une grille adaptative, à partir de la largeur disponible et d'une plage de largeur de colonne.
/// Utilisé par `VLTileGrid`, et par les `LazyVGrid` des applications via `items`.
public enum VLGridColumns
{
 /// - Parameters:
 ///   - width: largeur disponible.
 ///   - columnWidthRange: largeur souhaitée d'une colonne.
 ///   - maxColumns: nombre maximum de colonnes, sauf si les colonnes dépassaient alors la borne haute de `columnWidthRange`.
 ///   - spacing: espacement entre les colonnes.
 /// - Returns: au moins 1 ; sans largeur finie, `maxColumns`, ou 1.
 public static func count(width: CGFloat,
                          columnWidthRange: ClosedRange<CGFloat>,
                          maxColumns: Int? = nil,
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

 /// Colonnes `.flexible()` pour un `LazyVGrid`, en nombre donné par `count`.
 public static func items(width: CGFloat,
                          columnWidthRange: ClosedRange<CGFloat>,
                          maxColumns: Int? = nil,
                          spacing: CGFloat,
                          alignment: Alignment? = .top) -> [ GridItem ]
 {
  Array(repeating: GridItem(.flexible(), spacing: spacing, alignment: alignment),
        count: count(width: width,
                     columnWidthRange: columnWidthRange,
                     maxColumns: maxColumns,
                     spacing: spacing))
 }
}
