import VLstackNamespace
import SwiftUI

extension VLstack
{
 @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
 public struct FlowStack: Layout
 {
  private let alignment: Alignment
  private let spacing: CGFloat

  public init(alignment: Alignment = .center,
              spacing: CGFloat = 10)
  {
   self.alignment = alignment
   self.spacing = spacing
  }

  public func sizeThatFits(proposal: ProposedViewSize,
                           subviews: Subviews,
                           cache: inout ()) -> CGSize
  {
   let maxWidth = proposal.width ?? 0
   var height: CGFloat = 0
   let rows = generateRows(maxWidth, proposal, subviews)

   for (index, row) in rows.enumerated()
   {
    if index == ( rows.count - 1 )
    {
     height += row.maxHeightFlowStack(proposal)
    }
    else
    {
     height += row.maxHeightFlowStack(proposal) + spacing
    }
   }

   return .init(width: maxWidth, height: height)
  }

  public func placeSubviews(in bounds: CGRect,
                            proposal: ProposedViewSize,
                            subviews: Subviews,
                            cache: inout ())
  {
   var origin = bounds.origin
   let maxWidth = bounds.width
   let rows = generateRows(maxWidth, proposal, subviews)

   for row in rows
   {
    let leading: CGFloat = bounds.maxX - maxWidth
    let trailing: CGFloat = bounds.maxX - (row.reduce(CGFloat.zero)
                                           {
     partialResult, view in
     let width = view.sizeThatFits(proposal).width
     if view == row.last
     {
      return partialResult + width
     }

     return partialResult + width + spacing
    })
    let center = ( trailing + leading ) / 2

    origin.x = (alignment == .leading ? leading : alignment == .trailing ? trailing : center)

    for view in row
    {
     let viewSize = view.sizeThatFits(proposal)
     view.place(at: origin, proposal: proposal)
     origin.x += ( viewSize.width + spacing )
    }
    origin.y += ( row.maxHeightFlowStack(proposal) + spacing )
   }
  }

  internal func generateRows(_ maxWidth: CGFloat,
                             _ proposal: ProposedViewSize,
                             _ subviews: Subviews) -> [ [ LayoutSubviews.Element ] ]
  {
   var row: [ LayoutSubviews.Element ] = []
   var rows: [ [ LayoutSubviews.Element ] ] = []

   var origin = CGRect.zero.origin

   for view in subviews
   {
    let viewSize = view.sizeThatFits(proposal)

    if ( origin.x + viewSize.width + spacing ) > maxWidth
    {
     rows.append(row)
     row.removeAll()
     origin.x = 0
     row.append(view)
     origin.x += ( viewSize.width + spacing )
    }
    else
    {
     row.append(view)
     origin.x += ( viewSize.width + spacing )
    }
   }

   if !row.isEmpty
   {
    rows.append(row)
    row.removeAll()
   }

   return rows
  }
 }
}

extension [ LayoutSubviews.Element ]
{
 internal func maxHeightFlowStack(_ proposal: ProposedViewSize) -> CGFloat
 {
  return self.compactMap { $0.sizeThatFits(proposal).height }.max() ?? 0
 }
}
