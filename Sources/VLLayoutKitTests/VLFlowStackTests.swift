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
}
