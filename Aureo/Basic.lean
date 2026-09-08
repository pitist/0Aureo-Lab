import Mathlib

namespace Aureo

theorem prueba_aureo (a b : Nat) (h : a = b) : a = b := by
  exact h

theorem suma_cero (n : Nat) : n + 0 = n := by
  simp

end Aureo
