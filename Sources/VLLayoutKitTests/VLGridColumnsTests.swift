import CoreGraphics
import SwiftUI
import Testing
import VLLayoutKit

struct VLGridColumnsTests
{
 private func count(_ width: CGFloat, maxColumns: Int? = nil) -> Int
 {
  VLGridColumns.count(width: width, columnWidthRange: 160...320, maxColumns: maxColumns, spacing: 12)
 }

 @Test func iPhoneWidthGivesTwoColumns()
 {
  #expect(count(358) == 2)
 }

 @Test func iPadWidthGivesFiveColumns()
 {
  #expect(count(1000) == 5)
 }

 @Test func maxColumnsLimitsCount()
 {
  #expect(count(1000, maxColumns: 3) == 3)
 }

 @Test func upperBoundWinsOverMaxColumns()
 {
  #expect(count(1400, maxColumns: 3) == 4)
 }

 @Test func zeroWidthGivesOneColumn()
 {
  #expect(count(0) == 1)
 }

 @Test func infiniteWidthUsesMaxColumns()
 {
  #expect(count(.infinity, maxColumns: 4) == 4)
  #expect(count(.infinity) == 1)
 }

 @Test func itemsCarrySpacingAndAlignment()
 {
  let items = VLGridColumns.items(width: 1000, columnWidthRange: 160...320, spacing: 12, alignment: .center)
  #expect(items.count == 5)
  #expect(items.allSatisfy { $0.spacing == 12 && $0.alignment == .center })
 }
}
