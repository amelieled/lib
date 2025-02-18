// Positive binary integers

require open Stdlib.Set Stdlib.Prop Stdlib.FOL Stdlib.CoC Stdlib.Eq Stdlib.Comp;

inductive positive : TYPE ≔
| xI : positive → positive
| xO : positive → positive
| xH : positive;

// set code for positive

constant symbol pos : Set;

rule τ pos ↪ positive;

// Injections in Prop

symbol is_xI : positive → Prop;

rule is_xI (xI _) ↪ ⊤
with is_xI (xO _) ↪ ⊥
with is_xI xH     ↪ ⊥;

symbol is_xO : positive → Prop;

rule is_xO (xI _) ↪ ⊥
with is_xO (xO _) ↪ ⊤
with is_xO xH     ↪ ⊥;

symbol is_xH : positive → Prop;

rule is_xH (xI _) ↪ ⊥
with is_xH (xO _) ↪ ⊥
with is_xH xH     ↪ ⊤;

// Discriminate constructors

symbol discr_xI_xH p : π (xI p ≠ xH) ≔
begin
  assume p H;
  have f : π (is_xI xH)
  { rewrite left H; refine top; } ;
  refine ⊥ₑ _ f;
end;

symbol discr_xO_xH p : π (xO p ≠ xH) ≔
begin
  assume p H;
  have f : π (is_xO xH)
  { rewrite left H; refine top; } ;
  refine ⊥ₑ _ f;
end;

symbol discr_xI_xO p q : π (xI p ≠ xO q) ≔
begin
  assume p q H;
  have f : π (is_xI (xO q))
  { rewrite left H; refine top; } ;
  refine ⊥ₑ _ f;
end;

// Successor function

symbol succ : positive → positive;

rule succ (xI $p) ↪ xO (succ $p)
with succ (xO $p) ↪ xI $p
with succ xH ↪ xO xH;

// Nat-like Induction Principle

symbol ind_positive_peano Q :
  π (Q xH) →
  (Π p, π (Q p) → π (Q (succ p))) →
  Π p, π (Q p) ≔
begin
  assume Q qH qS p;
  refine ind_positive (λ x, ∀ₜₚ (∀ₛₜ pos (λ _, prop)) (λ P, P xH ⇒ (`∀ y, P y ⇒ P (succ y)) ⇒ P x)) _ _ _ p Q qH qS
  // case xI
  { assume q qrec P pH pS;
    refine pS (xO q) _;
    refine qrec (λ x, P (xO x)) _ _
      { refine pS xH pH; }
      { assume y p2y;
        refine pS (xI y) _;
        refine pS _ p2y; } }
  // case xO
  { assume q qrec P pH pS;
    refine qrec (λ x, P (xO x)) _ _
    { refine pS xH pH; }
    { assume y p2y;
      refine pS (xI y) _;
      refine pS _ p2y; } }
  // case xH
  { assume P pH _; refine pH; }
end;

// Addition of positive numbers with and without a carry

symbol add : positive → positive → positive;
symbol add_carry : positive → positive → positive;

rule add (xI $p) (xI $q) ↪ xO (add_carry $p $q)
with add (xI $p) (xO $q) ↪ xI (add $p $q)
with add (xO $p) (xI $q) ↪ xI (add $p $q)
with add (xO $p) (xO $q) ↪ xO (add $p $q)
with add $x      xH      ↪ succ $x
with add xH      $y      ↪ succ $y;

rule add_carry (xI $p) (xI $q) ↪ xI (add_carry $p $q)
with add_carry (xI $p) (xO $q) ↪ xO (add_carry $p $q)
with add_carry (xO $p) (xI $q) ↪ xO (add_carry $p $q)
with add_carry (xO $p) (xO $q) ↪ xI (add $p $q)
with add_carry $x      xH      ↪ add $x (xO xH)
with add_carry xH      $y      ↪ add (xO xH) $y;
// for efficiency reasons last cases should not be 'succ (succ $x)'


// Check that 7 + 5 = 12
// assert ⊢ add (xI (xI xH)) (xI (xO xH)) ≡ xO (xO (xI xH));
// Check that 110101010 + 101101100 ≡ 1100010110 in base 2 (426 + 364 ≡ 790)
// assert ⊢ add (xO (xI (xO (xI (xO (xI (xO (xI xH))))))))
//              (xO (xO (xI (xI (xO (xI (xI (xO xH)))))))) ≡
//          (xO (xI (xI (xO (xI (xO (xO (xO (xI xH)))))))));

// Interaction of succ and add

symbol succ_add x y : π (succ (add x y) = add_carry x y) ≔
begin
  induction
  // case xI
  { assume p prec;
    induction
      { reflexivity; }
      { assume q _; simplify; rewrite prec; reflexivity; }
      { reflexivity; } }
  // case xO
  { assume p prec;
    induction
      { assume q _; simplify; rewrite prec; reflexivity; }
      { reflexivity; }
      { reflexivity; } }
  // case xH
  { induction { reflexivity; } { reflexivity; } { reflexivity; } ; }
end;

symbol add_succ x y : π (add (succ x) y = succ (add x y)) ≔
begin
  induction
  // case xI
  { assume p prec;
    induction
     { assume q _; simplify; rewrite prec; rewrite succ_add; reflexivity; }
     { assume q _; simplify; rewrite prec; reflexivity; }
     { reflexivity; } }
  // case xO
  { assume p prec;
    induction
      { assume q _; simplify; rewrite succ_add; reflexivity; }
      { reflexivity; }
      { reflexivity; } }
  // case xH
  { induction { reflexivity; } { reflexivity; } { reflexivity; } }
end;

symbol add_succ_right x y : π (add x (succ y) = succ (add x y)) ≔
begin
  refine ind_positive_peano (λ x, `∀ y, add x (succ y) = succ (add x y)) _ _
  // case xH
  { reflexivity; }
  // case succ
  { assume x xrec y;
    rewrite add_succ; rewrite add_succ; rewrite xrec; reflexivity; }
end;

// Associativity of the addition

symbol add_assoc x y z : π (add (add x y) z = add x (add y z)) ≔
begin
  refine ind_positive_peano (λ x, `∀ y, `∀ z, add (add x y) z = add x (add y z)) _ _
  // case xH
  { refine add_succ; }
  // case succ
  { assume x xrec y z;
    rewrite add_succ; rewrite add_succ; rewrite add_succ;
    rewrite xrec; reflexivity; }
end;

// Commutativity of the addition

symbol add_com x y : π (add x y = add y x) ≔
begin
  refine ind_positive_peano (λ x, `∀ y, add x y = add y x) _ _
  // case xH
  { reflexivity; }
  // case succ
  { assume x xrec y;
    rewrite add_succ; rewrite add_succ_right; rewrite xrec; reflexivity; }
end;

// function λ x, 2 * x - 1

symbol pos_pred_double : positive → positive;

rule pos_pred_double (xI $p) ↪ xI (xO $p)
with pos_pred_double (xO $p) ↪ xI (pos_pred_double $p)
with pos_pred_double xH      ↪ xH;


symbol pos_pred_double_succ x : π (pos_pred_double (succ x) = xI x) ≔
begin
  induction
  { assume x xrec; simplify; rewrite xrec; reflexivity; }
  { reflexivity; }
  { reflexivity; }
end;

symbol succ_pos_pred_double x : π (succ (pos_pred_double x) = xO x) ≔
begin
  induction
   { reflexivity; }
   { assume x xrec; simplify; rewrite xrec; reflexivity; }
   { reflexivity; }
end;

// Comparison of positive numbers

symbol compare_acc : positive → comparison → positive → comparison;

rule compare_acc (xI $p) $c (xI $q) ↪ compare_acc $p $c $q
with compare_acc (xI $p) _  (xO $q) ↪ compare_acc $p Gt $q
with compare_acc (xI _)  _  xH      ↪ Gt
with compare_acc (xO $p) _  (xI $q) ↪ compare_acc $p Lt $q
with compare_acc (xO $p) $c (xO $q) ↪ compare_acc $p $c $q
with compare_acc (xO _)  _  xH      ↪ Gt
with compare_acc xH      _  (xI _)  ↪ Lt
with compare_acc xH      _  (xO _)  ↪ Lt
with compare_acc xH      $c xH      ↪ $c;


symbol compare x y ≔ compare_acc x Eq y;

// Commutative property of compare

symbol compare_acc_com x y c :
  π (compare_acc y c x = revcomp (compare_acc x (revcomp c) y)) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _ c; simplify; rewrite xrec; reflexivity; }
     { assume y _ c; simplify; rewrite xrec; reflexivity; }
     { reflexivity; } }
  // case xO
  { assume x xrec;
    induction
     { assume y _ c; simplify; rewrite xrec; reflexivity; }
     { assume y _ c; simplify; rewrite xrec; reflexivity; }
     { reflexivity; } }
  // case xH
  { induction
     { reflexivity; }
     { reflexivity; }
     { assume c; simplify; rewrite revcomp_idem; reflexivity; } }
end;

symbol compare_com x y : π (compare y x = revcomp (compare x y)) ≔
begin
  assume x y; refine compare_acc_com x y Eq;
end;

// Compare decides the equality

symbol compare_acc_nEq x y c : π (c ≠ Eq ⇒ compare_acc x c y ≠ Eq) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _ c H; refine xrec y c H; }
     { assume y _ c H; refine xrec y Gt _; refine discr_Gt_Eq; }
     { assume c _; refine discr_Gt_Eq; } }
  // case xO
  { assume x xrec;
    induction
     { assume y _ c H; refine xrec y Lt _; refine discr_Lt_Eq; }
     { assume y _ c H; refine xrec y c H; }
     { assume c _; refine discr_Gt_Eq; } }
  // case xH
  { induction
     { assume y _ c H; refine discr_Lt_Eq; }
     { assume y _ c H; refine discr_Lt_Eq; }
     { assume c Hc; refine Hc; } }
end;

symbol compare_decides x y : π (compare x y = Eq ⇒ x = y) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _ H; rewrite xrec y H; reflexivity; }
     { assume y _ H; apply ⊥ₑ; refine compare_acc_nEq x y Gt _ H; refine discr_Gt_Eq; }
     { assume H; apply ⊥ₑ; refine discr_Gt_Eq H; } }
  // case xO
  { assume x xrec;
    induction
     { assume y _ H; apply ⊥ₑ; refine compare_acc_nEq x y Lt _ H; refine discr_Lt_Eq; }
     { assume y _ H; rewrite xrec y H; reflexivity; }
     { assume H; apply ⊥ₑ; refine discr_Gt_Eq H; } }
  // case xH
  { induction
    { assume y _ H; apply ⊥ₑ; refine discr_Lt_Eq H; }
    { assume y _ H; apply ⊥ₑ; refine discr_Lt_Eq H; }
    { reflexivity; } }
end;

// Compare with Gt or Lt

symbol compare_Lt x y :
  π (compare_acc x Lt y = comparison_case (compare x y) Lt Lt Gt) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _; refine xrec y; }
     { assume y _; simplify;
       refine ind_comparison (λ c, compare_acc x Gt y = c ⇒ c = comparison_case c Lt Lt Gt) _ _ _ (compare_acc x Gt y) _
         { assume H; apply ⊥ₑ; refine compare_acc_nEq x y Gt _ H; }
         { refine discr_Gt_Eq; }
         { reflexivity; }
         { reflexivity; } }
     { reflexivity; reflexivity; } }
  // case xO
  { assume x xrec;
    induction
     { assume y _; simplify;
       refine ind_comparison (λ c, compare_acc x Lt y = c ⇒ c = comparison_case c Lt Lt Gt) _ _ _ (compare_acc x Lt y) _
         { assume H; apply ⊥ₑ; refine compare_acc_nEq x y Lt _ H; }
         { refine discr_Lt_Eq; }
         { reflexivity; }
         { reflexivity; } }
     { reflexivity; }
     { assume y _; refine xrec y;
       reflexivity; } }
  // case xH
  { induction { reflexivity; } { reflexivity; } { reflexivity; } }
end;


symbol compare_Gt x y :
  π (compare_acc x Gt y = comparison_case (compare x y) Gt Lt Gt) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
      { assume y _; refine xrec y; }
      { assume y _; simplify;
        refine ind_comparison (λ c, compare_acc x Gt y = c ⇒ c = comparison_case c Gt Lt Gt) _ _ _ (compare_acc x Gt y) _
          { assume H; apply ⊥ₑ; refine compare_acc_nEq x y Gt _ H; }
          { refine discr_Gt_Eq; }
          { reflexivity; }
          { reflexivity; } }
      { reflexivity; reflexivity } ; }
  // case xO
  { assume x xrec;
    induction
      { assume y _; simplify;
        refine ind_comparison (λ c, compare_acc x Lt y = c ⇒ c = comparison_case c Gt Lt Gt) _ _ _ (compare_acc x Lt y) _
          { assume H; apply ⊥ₑ; refine compare_acc_nEq x y Lt _ H; }
          { refine discr_Lt_Eq; }
          { reflexivity; }
          { reflexivity; } }
     { reflexivity; assume y _; refine xrec y; }
     { reflexivity; } }
  // case xH
  { induction { reflexivity; } { reflexivity; } { reflexivity; } }
end;

// Compatibility of compare with the addition

symbol compare_xH_Lt y : π (compare_acc xH Lt y = Lt) ≔
begin
  induction { reflexivity; } { reflexivity; } { reflexivity; }
end;

symbol compare_Gt_xH x : π (compare_acc x Gt xH = Gt) ≔
begin
  induction { reflexivity; } { reflexivity; } { reflexivity; }
end;

symbol compare_xH_succ y c : π (compare_acc xH c (succ y) = Lt) ≔
begin
  induction { reflexivity; } { reflexivity; } { reflexivity; }
end;

symbol compare_succ_xH x c : π (compare_acc (succ x) c xH = Gt) ≔
begin
  induction { reflexivity; } { reflexivity; } { reflexivity; }
end;

symbol compare_succ_Lt x y :
  π (compare_acc (succ x) Lt y = compare_acc x Gt y) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _; refine xrec y; }
     { assume y _; refine xrec y; }
     { reflexivity; } }
  // case xO
  { assume x xrec;
    induction { reflexivity; } { reflexivity; } { reflexivity; } }
  // case xH
  { induction
     { assume y _; refine compare_xH_Lt y; }
     { assume y _; refine compare_xH_Lt y; }
     { reflexivity; } }
end;

symbol compare_Gt_succ x y :
  π (compare_acc x Gt (succ y) = compare_acc x Lt y) ≔
begin
  assume x y;
  rewrite compare_acc_com; rewrite .[u in _ = u] compare_acc_com;
  simplify; rewrite compare_succ_Lt; reflexivity;
end;

symbol compare_succ_succ x y c :
  π (compare_acc (succ x) c (succ y) = compare_acc x c y) ≔
begin
  induction
  // case xI
  { assume x xrec;
    induction
     { assume y _ c; refine xrec y c; }
     { assume y _ c; simplify; refine compare_succ_Lt x y; }
     { assume c; simplify; refine compare_succ_xH x c; } }
  // case xO
  { assume x xrec;
    induction
     { assume y _ c; simplify; refine compare_Gt_succ x y; }
     { assume y _ c; reflexivity; }
     { assume c; simplify; refine compare_Gt_xH x; } }
  // case xH
  { induction
     { assume y _ c; simplify; refine compare_xH_succ y c; }
     { assume y _ c; simplify; refine compare_xH_Lt y; }
     { reflexivity; } }
end;

symbol compare_compat_add a x y :
  π (compare (add x a) (add y a) = compare x y) ≔
begin
  refine ind_positive_peano (λ a, `∀ x, `∀ y, compare (add x a) (add y a) = compare x y) _ _
  // case xH
  { assume x y; refine compare_succ_succ x y Eq; }
  // case succ
  { assume a arec x y;
    rewrite add_succ_right; rewrite add_succ_right; rewrite left arec x y;
    simplify; rewrite compare_succ_succ; reflexivity; }
end;

// Multiplication

symbol mul : positive → positive → positive;

rule mul (xI $p) $y ↪ add $p (xO (mul $p $y))
with mul (xO $p) $y ↪ xO (mul $p $y)
with mul xH      $y ↪ $y;
