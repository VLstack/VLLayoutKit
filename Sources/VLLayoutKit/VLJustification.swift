/// Remplissage d'une ligne : toutes les lignes sauf la dernière dans VLFlowStack, la ligne unique du mode horizontal dans VLAdaptiveStack.
public enum VLJustification: CaseIterable, Sendable
{
 /// Rendu naturel : la ligne suit `horizontalAlignment`.
 case none
 /// Les vues gardent leur taille ; la place libre est répartie dans les espacements.
 case spaceBetween
 /// Les espacements restent fixes ; la place libre est partagée à parts égales entre les vues.
 /// Seule une vue extensible grandit : écrire par exemple `.frame(maxWidth: .infinity)` avant le fond de la puce.
 case stretch
}
