import CoreGraphics
import Testing
import SwiftUI
@testable import VLLayoutKit

struct VLAdaptiveStackTests
{
 // MARK: - Choix du sens

 @Test func exactWidthStaysHorizontal()
 {
  #expect(VLAdaptiveStack.isHorizontal(widths: [ 30, 62 ], spacing: 8, maxWidth: 100))
 }

 @Test func onePointShortGoesVertical()
 {
  #expect(!VLAdaptiveStack.isHorizontal(widths: [ 30, 62 ], spacing: 8, maxWidth: 99))
 }

 @Test func infiniteWidthStaysHorizontal()
 {
  #expect(VLAdaptiveStack.isHorizontal(widths: [ 300, 400, 500 ], spacing: 8, maxWidth: .infinity))
 }

 @Test func zeroWidthGoesVertical()
 {
  #expect(!VLAdaptiveStack.isHorizontal(widths: [ 10, 10 ], spacing: 8, maxWidth: 0))
 }

 @Test func emptyStaysHorizontal()
 {
  #expect(VLAdaptiveStack.isHorizontal(widths: [], spacing: 8, maxWidth: 0))
 }

 @Test func singleTooWideViewGoesVertical()
 {
  #expect(!VLAdaptiveStack.isHorizontal(widths: [ 150 ], spacing: 8, maxWidth: 100))
 }

 @Test func spacingOnlyBetweenViews()
 {
  #expect(VLAdaptiveStack.totalLength([ 10, 20, 30 ], spacing: 8) == 76)
  #expect(VLAdaptiveStack.totalLength([ 10 ], spacing: 8) == 10)
  #expect(VLAdaptiveStack.totalLength([], spacing: 8) == 0)
 }

 // MARK: - Alignement sur l'axe secondaire

 @Test func leadingOrTopGuidesKeepViewsAtZero()
 {
  let result = VLAdaptiveStack.alignedOffsets(lengths: [ 10, 20 ], guides: [ 0, 0 ])
  #expect(result.offsets == [ 0, 0 ])
  #expect(result.length == 20)
 }

 @Test func centerGuidesCenterViews()
 {
  let result = VLAdaptiveStack.alignedOffsets(lengths: [ 10, 20 ], guides: [ 5, 10 ])
  #expect(result.offsets == [ 5, 0 ])
  #expect(result.length == 20)
 }

 @Test func trailingOrBottomGuidesAlignEnds()
 {
  let result = VLAdaptiveStack.alignedOffsets(lengths: [ 10, 20 ], guides: [ 10, 20 ])
  #expect(result.offsets == [ 10, 0 ])
  #expect(result.length == 20)
 }

 @Test func baselineGuidesCanGrowTotalLength()
 {
  let result = VLAdaptiveStack.alignedOffsets(lengths: [ 20, 30 ], guides: [ 18, 10 ])
  #expect(result.offsets == [ 0, 8 ])
  #expect(result.length == 38)
 }

 @Test func emptyHasNoOffset()
 {
  let result = VLAdaptiveStack.alignedOffsets(lengths: [], guides: [])
  #expect(result.offsets.isEmpty)
  #expect(result.length == 0)
 }

 // MARK: - Ligne non justifiée

 @Test func naturalSlotsFollowAlignment()
 {
  let leading = VLAdaptiveStack.naturalSlots(widths: [ 20, 20 ], spacing: 8, availableWidth: 100, alignment: .leading)
  let center = VLAdaptiveStack.naturalSlots(widths: [ 20, 20 ], spacing: 8, availableWidth: 100, alignment: .center)
  let trailing = VLAdaptiveStack.naturalSlots(widths: [ 20, 20 ], spacing: 8, availableWidth: 100, alignment: .trailing)
  #expect(leading == [ VLFlowStack.Slot(x: 0, width: 20), VLFlowStack.Slot(x: 28, width: 20) ])
  #expect(center == [ VLFlowStack.Slot(x: 26, width: 20), VLFlowStack.Slot(x: 54, width: 20) ])
  #expect(trailing == [ VLFlowStack.Slot(x: 52, width: 20), VLFlowStack.Slot(x: 80, width: 20) ])
 }
}
