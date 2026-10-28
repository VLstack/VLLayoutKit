import CoreGraphics
import Testing
@testable import VLLayoutKit

struct VLTileGridTests
{
 private static let small = VLTileGrid.TileSize(columns: 1, rows: 1)
 private static let medium = VLTileGrid.TileSize(columns: 2, rows: 1)
 private static let large = VLTileGrid.TileSize(columns: 2, rows: 2)

 private func placement(_ column: Int, _ row: Int, _ columns: Int = 1, _ rows: Int = 1) -> VLTileGrid.Placement
 {
  VLTileGrid.Placement(column: column, row: row, columns: columns, rows: rows)
 }

 // MARK: - Placements

 @Test func emptyGivesNoPlacement()
 {
  let result = VLTileGrid.placements(sizes: [], columnCount: 2)
  #expect(result.placements.isEmpty)
  #expect(result.rowCount == 0)
 }

 @Test func smallTilesFollowReadingOrder()
 {
  let result = VLTileGrid.placements(sizes: [ Self.small, Self.small, Self.small ], columnCount: 2)
  #expect(result.placements == [ placement(0, 0), placement(1, 0), placement(0, 1) ])
  #expect(result.rowCount == 2)
 }

 @Test func largeTileTakesFullWidthOnTwoColumns()
 {
  let result = VLTileGrid.placements(sizes: [ Self.large, Self.small ], columnCount: 2)
  #expect(result.placements == [ placement(0, 0, 2, 2), placement(0, 2) ])
  #expect(result.rowCount == 3)
 }

 @Test func tooWideTileIsClamped()
 {
  let result = VLTileGrid.placements(sizes: [ Self.large ], columnCount: 1)
  #expect(result.placements == [ placement(0, 0, 1, 2) ])
  #expect(result.rowCount == 2)
 }

 @Test func smallTilesFillBesideLargeOnFourColumns()
 {
  let result = VLTileGrid.placements(sizes: [ Self.large, Self.small, Self.small, Self.small, Self.small ], columnCount: 4)
  #expect(result.placements == [ placement(0, 0, 2, 2), placement(2, 0), placement(3, 0), placement(2, 1), placement(3, 1) ])
  #expect(result.rowCount == 2)
 }

 @Test func laterSmallTileFillsHole()
 {
  let result = VLTileGrid.placements(sizes: [ Self.small, Self.medium, Self.small ], columnCount: 2)
  #expect(result.placements == [ placement(0, 0), placement(0, 1, 2, 1), placement(1, 0) ])
  #expect(result.rowCount == 2)
 }
}
