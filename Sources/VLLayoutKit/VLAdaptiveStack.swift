import CoreGraphics
import SwiftUI

/// Place les vues côte à côte si elles tiennent toutes à leur taille idéale, et les empile sinon.
/// Le contenu est écrit une seule fois : les vues gardent leur identité (focus, état) et peuvent s'animer d'un sens à l'autre.
public struct VLAdaptiveStack: Layout
{
 /// Recréé par SwiftUI (implémentation par défaut de `updateCache`) quand les sous-vues changent.
 public struct Cache
 {
  var idealDimensions: [ ViewDimensions ]? = nil
  var maxWidth: CGFloat? = nil
  var isHorizontal = true
  var sizes: [ CGSize ] = []
  /// Décalage de chaque vue sur l'axe secondaire : vertical en mode horizontal, horizontal en mode vertical.
  var offsets: [ CGFloat ] = []
  var size: CGSize = .zero
 }

 private let horizontalAlignment: HorizontalAlignment
 private let verticalAlignment: VerticalAlignment
 private let horizontalSpacing: CGFloat
 private let verticalSpacing: CGFloat
 private let justification: VLJustification

 /// `verticalAlignment` sert en mode horizontal, `horizontalAlignment` en mode vertical.
 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             horizontalSpacing: CGFloat? = nil,
             verticalSpacing: CGFloat? = nil,
             justification: VLJustification = .none)
 {
  self.horizontalAlignment = horizontalAlignment
  self.verticalAlignment = verticalAlignment
  self.horizontalSpacing = horizontalSpacing ?? 8
  self.verticalSpacing = verticalSpacing ?? 8
  self.justification = justification
 }

 public init(horizontalAlignment: HorizontalAlignment = .center,
             verticalAlignment: VerticalAlignment = .center,
             spacing: CGFloat? = nil,
             justification: VLJustification = .none)
 {
  self.init(horizontalAlignment: horizontalAlignment,
            verticalAlignment: verticalAlignment,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            justification: justification)
 }

 public init(alignment: Alignment,
             spacing: CGFloat? = nil,
             justification: VLJustification = .none)
 {
  self.init(horizontalAlignment: alignment.horizontal,
            verticalAlignment: alignment.vertical,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            justification: justification)
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

  // Comme un HStack : largeur du contenu, sauf si la justification doit remplir la ligne
  guard cache.isHorizontal, justification != .none, let proposedWidth = proposal.width, proposedWidth.isFinite else { return cache.size }
  return CGSize(width: proposedWidth, height: cache.size.height)
 }

 public func placeSubviews(in bounds: CGRect,
                           proposal: ProposedViewSize,
                           subviews: Subviews,
                           cache: inout Cache)
 {
  computeLayout(subviews: subviews, proposal: proposal, cache: &cache)

  if cache.isHorizontal
  {
   let widths = cache.sizes.map(\.width)
   let slots = VLFlowStack.justifiedSlots(widths: widths,
                                          availableWidth: bounds.width,
                                          spacing: horizontalSpacing,
                                          justification: justification,
                                          isLastRow: false)
    ?? Self.naturalSlots(widths: widths,
                         spacing: horizontalSpacing,
                         availableWidth: bounds.width,
                         alignment: horizontalAlignment)

   for index in subviews.indices
   {
    subviews[index].place(at: CGPoint(x: bounds.minX + slots[index].x, y: bounds.minY + cache.offsets[index]),
                          proposal: ProposedViewSize(width: slots[index].width, height: cache.sizes[index].height))
   }
  }
  else
  {
   var y = bounds.minY
   for index in subviews.indices
   {
    let size = cache.sizes[index]
    subviews[index].place(at: CGPoint(x: bounds.minX + cache.offsets[index], y: y),
                          proposal: ProposedViewSize(size))
    y += size.height + verticalSpacing
   }
  }
 }

 /// Choisit le sens, mesure et aligne les vues, seulement si la largeur a changé depuis le dernier calcul.
 private func computeLayout(subviews: Subviews,
                            proposal: ProposedViewSize,
                            cache: inout Cache)
 {
  let maxWidth = proposal.width ?? .infinity

  guard cache.maxWidth != maxWidth else { return }

  let idealDimensions = cache.idealDimensions ?? subviews.map { $0.dimensions(in: .unspecified) }
  cache.idealDimensions = idealDimensions
  cache.isHorizontal = Self.isHorizontal(widths: idealDimensions.map(\.width),
                                         spacing: horizontalSpacing,
                                         maxWidth: maxWidth)

  if cache.isHorizontal
  {
   let aligned = Self.alignedOffsets(lengths: idealDimensions.map(\.height),
                                     guides: idealDimensions.map { $0[verticalAlignment] })
   cache.sizes = idealDimensions.map { CGSize(width: $0.width, height: $0.height) }
   cache.offsets = aligned.offsets
   cache.size = CGSize(width: Self.totalLength(idealDimensions.map(\.width), spacing: horizontalSpacing),
                       height: aligned.length)
  }
  else
  {
   // Chaque vue reçoit la largeur du conteneur : un texte passe à la ligne, une vue extensible la prend toute
   let dimensions = subviews.map { $0.dimensions(in: ProposedViewSize(width: maxWidth, height: nil)) }
   let aligned = Self.alignedOffsets(lengths: dimensions.map(\.width),
                                     guides: dimensions.map { $0[horizontalAlignment] })
   cache.sizes = dimensions.map { CGSize(width: $0.width, height: $0.height) }
   cache.offsets = aligned.offsets
   cache.size = CGSize(width: aligned.length,
                       height: Self.totalLength(dimensions.map(\.height), spacing: verticalSpacing))
  }
  cache.maxWidth = maxWidth
 }

 /// Vrai si les vues tiennent côte à côte, espacements compris (au millième de point près).
 /// Une seule vue trop large passe aussi en vertical, pour recevoir la largeur du conteneur.
 static func isHorizontal(widths: [ CGFloat ],
                          spacing: CGFloat,
                          maxWidth: CGFloat) -> Bool
 {
  totalLength(widths, spacing: spacing) <= maxWidth + 0.001
 }

 /// Somme des longueurs et des espacements entre les vues (aucun aux extrémités).
 static func totalLength(_ lengths: [ CGFloat ],
                         spacing: CGFloat) -> CGFloat
 {
  lengths.reduce(0, +) + CGFloat(max(0, lengths.count - 1)) * spacing
 }

 /// Aligne les guides de toutes les vues sur une même ligne ; renvoie le décalage de chaque vue et la longueur totale.
 /// Vaut pour tout guide : bords, centre, lignes de base ou guide personnalisé.
 static func alignedOffsets(lengths: [ CGFloat ],
                            guides: [ CGFloat ]) -> (offsets: [ CGFloat ], length: CGFloat)
 {
  let line = guides.max() ?? 0
  let offsets = guides.map { line - $0 }
  let length = zip(offsets, lengths).map { $0 + $1 }.max() ?? 0
  return (offsets, length)
 }

 /// Placement de la ligne non justifiée, selon `alignment` quand le cadre est plus large que le contenu.
 static func naturalSlots(widths: [ CGFloat ],
                          spacing: CGFloat,
                          availableWidth: CGFloat,
                          alignment: HorizontalAlignment) -> [ VLFlowStack.Slot ]
 {
  let freeWidth = max(0, availableWidth - totalLength(widths, spacing: spacing))
  var x: CGFloat = switch alignment
  {
   case .leading: 0
   case .trailing: freeWidth
   default: freeWidth / 2
  }

  var slots: [ VLFlowStack.Slot ] = []
  for width in widths
  {
   slots.append(VLFlowStack.Slot(x: x, width: width))
   x += width + spacing
  }
  return slots
 }
}
