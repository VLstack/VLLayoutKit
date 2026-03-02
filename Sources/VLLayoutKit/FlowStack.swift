import CoreGraphics
import SwiftUI
import VLstackNamespace

extension VLstack
{
 @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
 public struct FlowStack: Layout
 {
  struct ElementInfo
  {
   let view: LayoutSubviews.Element
   let size: CGSize
  }

  public struct Row
  {
   var elements: [ ElementInfo ]
   var size: CGSize
  }

  public struct Cache
  {
   var rows: [ Row ] = []
   var width: CGFloat? = nil
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

  public func updateCache(_ cache: inout Cache,
                          subviews: Subviews,
                          proposal: ProposedViewSize)
  {
   let maxWidth = proposal.width ?? .infinity

   guard cache.width != proposal.width else { return }

   var rows: [ Row ] = []
   var currentElements: [ ElementInfo ] = []
   var currentRowWidth: CGFloat = 0
   var currentRowHeight: CGFloat = 0

   for view in subviews
   {
    let viewSize = view.sizeThatFits(proposal)
    let element = ElementInfo(view: view, size: viewSize)

    if !currentElements.isEmpty && (currentRowWidth + horizontalSpacing + viewSize.width) > maxWidth
    {
     rows.append(Row(elements: currentElements,
                     size: CGSize(width: currentRowWidth, height: currentRowHeight)))
     currentElements = []
     currentRowWidth = 0
     currentRowHeight = 0
    }

    currentElements.append(element)
    currentRowWidth += (currentElements.count == 1 ? viewSize.width : horizontalSpacing + viewSize.width)
    currentRowHeight = max(currentRowHeight, viewSize.height)
   }

   if !currentElements.isEmpty
   {
    rows.append(Row(elements: currentElements,
                    size: CGSize(width: currentRowWidth, height: currentRowHeight)))
   }

   cache.rows = rows
   cache.width = proposal.width
  }

  public func sizeThatFits(proposal: ProposedViewSize,
                           subviews: Subviews,
                           cache: inout Cache) -> CGSize
  {
   updateCache(&cache, subviews: subviews, proposal: proposal)

   let totalVerticalSpacing: CGFloat = CGFloat(max(0, cache.rows.count - 1)) * verticalSpacing
   let totalHeight = cache.rows.map(\.size.height).reduce(0, +) + totalVerticalSpacing
   let totalWidth = cache.rows.map(\.size.width).max() ?? 0

   return CGSize(width: proposal.width ?? totalWidth, height: totalHeight)
  }

  public func placeSubviews(in bounds: CGRect,
                            proposal: ProposedViewSize,
                            subviews: Subviews,
                            cache: inout Cache)
  {
   updateCache(&cache, subviews: subviews, proposal: proposal)

   var y = bounds.minY

   for row in cache.rows
   {
    var x: CGFloat = switch horizontalAlignment
    {
     case .leading: bounds.minX
     case .trailing: bounds.maxX - row.size.width
     default: bounds.minX + (bounds.width - row.size.width) / 2
    }

    for element in row.elements
    {
     let yOffset: CGFloat = switch verticalAlignment
     {
      case .top: 0
      case .bottom: row.size.height - element.size.height
      default: (row.size.height - element.size.height) / 2
     }
     element.view.place(at: CGPoint(x: x, y: y + yOffset), proposal: proposal)
     x += element.size.width + horizontalSpacing
    }
    y += row.size.height + verticalSpacing
   }
  }
 }
}
