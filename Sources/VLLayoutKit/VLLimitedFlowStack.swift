import SwiftUI

/// VLFlowStack limité à `lineLimit` lignes : si tout ne tient pas, la dernière ligne se termine par l'indicateur `overflow`, qui reçoit le nombre de vues masquées.
/// Les vues masquées sont retirées de VoiceOver et ne reçoivent pas les touchers ; l'indicateur doit porter un libellé d'accessibilité explicite (par exemple « 3 autres étiquettes »).
/// Le contenu est coupé au cadre (`.clipped()`) : une ombre qui déborde est coupée aussi.
/// La ligne de l'indicateur compte comme dernière ligne : elle n'est pas justifiée.
public struct VLLimitedFlowStack<Data: RandomAccessCollection, ID: Hashable, Content: View, Overflow: View>: View
{
 private struct Item: Identifiable
 {
  let id: ID
  let offset: Int
  let element: Data.Element
 }

 private let data: Data
 private let id: KeyPath<Data.Element, ID>
 private let lineLimit: Int
 private let horizontalAlignment: HorizontalAlignment
 private let verticalAlignment: VerticalAlignment
 private let spacing: CGFloat?
 private let justification: VLJustification
 private let content: (Data.Element) -> Content
 private let overflow: (Int) -> Overflow

 @State private var hiddenCount = 0

 public init(_ data: Data,
             id: KeyPath<Data.Element, ID>,
             lineLimit: Int,
             horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             spacing: CGFloat? = nil,
             justification: VLJustification = .none,
             @ViewBuilder content: @escaping (Data.Element) -> Content,
             @ViewBuilder overflow: @escaping (Int) -> Overflow)
 {
  self.data = data
  self.id = id
  self.lineLimit = lineLimit
  self.horizontalAlignment = horizontalAlignment
  self.verticalAlignment = verticalAlignment
  self.spacing = spacing
  self.justification = justification
  self.content = content
  self.overflow = overflow
 }

 public var body: some View
 {
  let visibleCount = max(0, data.count - hiddenCount)
  let items = data.enumerated().map { Item(id: $0.element[keyPath: id], offset: $0.offset, element: $0.element) }

  VLFlowStack(horizontalAlignment: horizontalAlignment,
              verticalAlignment: verticalAlignment,
              horizontalSpacing: spacing,
              verticalSpacing: spacing,
              justification: justification,
              lineLimit: lineLimit,
              onHiddenCountChange: { count in if hiddenCount != count { hiddenCount = count } })
  {
   ForEach(items)
   { item in
    content(item.element)
     .accessibilityHidden(item.offset >= visibleCount)
     .allowsHitTesting(item.offset < visibleCount)
   }
   overflow(hiddenCount)
    .accessibilityHidden(hiddenCount == 0)
    .allowsHitTesting(hiddenCount > 0)
  }
  .clipped()
 }
}

public extension VLLimitedFlowStack where Data.Element: Identifiable, ID == Data.Element.ID
{
 init(_ data: Data,
      lineLimit: Int,
      horizontalAlignment: HorizontalAlignment = .center,
      verticalAlignment: VerticalAlignment = .center,
      spacing: CGFloat? = nil,
      justification: VLJustification = .none,
      @ViewBuilder content: @escaping (Data.Element) -> Content,
      @ViewBuilder overflow: @escaping (Int) -> Overflow)
 {
  self.init(data,
            id: \.id,
            lineLimit: lineLimit,
            horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            spacing: spacing,
            justification: justification,
            content: content,
            overflow: overflow)
 }
}
