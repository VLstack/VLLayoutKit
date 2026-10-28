import CoreGraphics
import Testing
@testable import VLLayoutKit

struct VLFlowStackTests
{
 private func size(_ width: CGFloat, _ height: CGFloat = 10) -> CGSize
 {
  CGSize(width: width, height: height)
 }

 @Test func emptyGivesNoRow()
 {
  #expect(VLFlowStack.rows(sizes: [], maxWidth: 100, spacing: 8).isEmpty)
 }

 @Test func allOnOneRow()
 {
  let rows = VLFlowStack.rows(sizes: [ size(30), size(40, 20) ], maxWidth: 100, spacing: 8)
  #expect(rows == [ VLFlowStack.Row(indices: 0..<2, size: size(78, 20)) ])
 }

 @Test func exactWidthFits()
 {
  let rows = VLFlowStack.rows(sizes: [ size(30), size(62) ], maxWidth: 100, spacing: 8)
  #expect(rows == [ VLFlowStack.Row(indices: 0..<2, size: size(100)) ])
 }

 @Test func wrapsWithoutSpacingAtRowEdges()
 {
  let rows = VLFlowStack.rows(sizes: [ size(30), size(40), size(50, 15) ], maxWidth: 100, spacing: 8)
  #expect(rows == [ VLFlowStack.Row(indices: 0..<2, size: size(78)),
                    VLFlowStack.Row(indices: 2..<3, size: size(50, 15)) ])
 }

 @Test func tooWideViewIsAloneOnItsRow()
 {
  let rows = VLFlowStack.rows(sizes: [ size(30), size(150), size(30) ], maxWidth: 100, spacing: 8)
  #expect(rows == [ VLFlowStack.Row(indices: 0..<1, size: size(30)),
                    VLFlowStack.Row(indices: 1..<2, size: size(150)),
                    VLFlowStack.Row(indices: 2..<3, size: size(30)) ])
 }

 @Test func infiniteWidthKeepsOneRow()
 {
  let rows = VLFlowStack.rows(sizes: [ size(300), size(400), size(500) ], maxWidth: .infinity, spacing: 8)
  #expect(rows == [ VLFlowStack.Row(indices: 0..<3, size: size(1216)) ])
 }

 // MARK: - Limite de lignes

 private func limitedRows(_ widths: [ CGFloat ], lineLimit: Int) -> (rows: [ VLFlowStack.Row ], visibleCount: Int)
 {
  VLFlowStack.rows(sizes: widths.map { size($0) }, maxWidth: 100, spacing: 8, lineLimit: lineLimit, indicatorSize: size(20))
 }

 @Test func allFitWithoutIndicator()
 {
  let result = limitedRows([ 30, 30 ], lineLimit: 1)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<2, size: size(68)) ])
  #expect(result.visibleCount == 2)
 }

 @Test func indicatorTakesRoomOnLastLine()
 {
  let result = limitedRows([ 30, 30, 30 ], lineLimit: 1)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<2, size: size(96), showsIndicator: true) ])
  #expect(result.visibleCount == 2)
 }

 @Test func indicatorReplacesLastViewWhenNeeded()
 {
  let result = limitedRows([ 40, 40, 40 ], lineLimit: 1)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<1, size: size(68), showsIndicator: true) ])
  #expect(result.visibleCount == 1)
 }

 @Test func indicatorAloneOnLastLine()
 {
  let result = limitedRows([ 95, 95 ], lineLimit: 1)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<0, size: size(20), showsIndicator: true) ])
  #expect(result.visibleCount == 0)
 }

 @Test func firstLinesKeptBeforeLastLine()
 {
  let result = limitedRows([ 60, 60, 60, 60 ], lineLimit: 2)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<1, size: size(60)),
                           VLFlowStack.Row(indices: 1..<2, size: size(88), showsIndicator: true) ])
  #expect(result.visibleCount == 2)
 }

 @Test func lineLimitBelowOneActsAsOne()
 {
  let result = limitedRows([ 30, 30, 30 ], lineLimit: 0)
  #expect(result.rows == [ VLFlowStack.Row(indices: 0..<2, size: size(96), showsIndicator: true) ])
  #expect(result.visibleCount == 2)
 }
}
