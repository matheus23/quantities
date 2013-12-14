module Quantities

import SortedAssociationList

%default total

-- Elementary quantities
data ElemQuantity : Type where
  MkElemQuantity : String -> ElemQuantity

instance Eq ElemQuantity where
  (MkElemQuantity a) == (MkElemQuantity b) = a == b

instance Ord ElemQuantity where
  compare (MkElemQuantity a) (MkElemQuantity b) = compare a b

length : ElemQuantity
length = MkElemQuantity "Length"

mass : ElemQuantity
mass = MkElemQuantity "Mass"

time : ElemQuantity
time = MkElemQuantity "Time"


-- Compound quantities
-- TODO: eliminate zeros in second positions
data Quantity : Type where
  MkQuantity : List (ElemQuantity, Integer) -> Quantity

mkQuantity : List (ElemQuantity, Integer) -> Quantity
mkQuantity xs = MkQuantity (sort xs)

instance Semigroup Quantity where
  (MkQuantity xs) <+> (MkQuantity ys) = MkQuantity $ mergeWith (+) xs ys

instance VerifiedSemigroup Quantity where
  semigroupOpIsAssociative = ?todo

scalar : Quantity
scalar = MkQuantity []

instance Monoid Quantity where
  neutral = scalar

{-
instance VerifiedMonoid Quantity where
  monoidNeutralIsNeutralL l = ?neutralL --proof { compute; trivial; }
  monoidNeutralIsNeutralR r = ?neutralR --proof { compute; trivial; }
-}

infixr 7 ^

(^) : Quantity -> Integer -> Quantity
(^) (MkQuantity xs) i = MkQuantity $ map (\(q, m) => (q, i*m)) xs

instance Group Quantity where
  inverse = flip (^) (-1)

instance AbelianGroup Quantity where

-- Synonyms (quantites are multiplied, not added!)
infixl 6 <*>
infixl 6 </>

(<*>) : Quantity -> Quantity -> Quantity
(<*>) = (<+>)
(</>) : Quantity -> Quantity -> Quantity
(</>) = (<->)

implicit
elemQuantityToQuantity : ElemQuantity -> Quantity
elemQuantityToQuantity q = MkQuantity [(q, 1)]

area : Quantity
area = length ^ 2

volume : Quantity
volume = length ^ 3

speed : Quantity
speed = length </> time

velocity : Quantity
velocity = speed

acceleration : Quantity
acceleration = speed </> time

force : Quantity
force = acceleration <*> mass

energy : Quantity
energy = force <*> length

power : Quantity
power = energy </> time


-- Elementary Units
data ElemUnit : Quantity -> Type where
  MkElemUnit : {q : Quantity} -> String -> Float -> ElemUnit q

multiplyElemUnit : String -> Float -> ElemUnit q -> ElemUnit q
multiplyElemUnit n f (MkElemUnit _ g) = MkElemUnit n (f * g)

syntax one [name] is [factor] [unit] = multiplyElemUnit name factor unit

meter : ElemUnit length
meter = MkElemUnit "m" 1

-- TODO: use general 'kilo', 'milli', etc. combinators
kilometer : ElemUnit length
kilometer = MkElemUnit "km" 1000

second : ElemUnit time
second = MkElemUnit "s" 1

minute : ElemUnit time
minute = one "min" is 60 second

hour : ElemUnit time
hour = one "h" is 60 minute

day : ElemUnit time
day = one "d" is 24 hour


data Unit : Quantity -> Type where
  EmptyUnit : Unit scalar
  ConsUnit  : ElemUnit p -> (i : Integer) -> Unit q -> Unit (p ^ i <*> q)

infixl 7 ^^

(^^) : Float -> Integer -> Float
a ^^ i = case compare i 0 of
  LT => pow (1 / a) (fromIntegerNat (-i))
  _  => pow a (fromIntegerNat i)

ratio : Unit q -> Float
ratio EmptyUnit = 1
ratio (ConsUnit (MkElemUnit _ f) i us) = (f ^^ i) * ratio us

kmh : Unit speed
kmh = ConsUnit kilometer 1 (ConsUnit hour (-1) EmptyUnit)

ms : Unit speed
ms = ConsUnit meter 1 (ConsUnit second (-1) EmptyUnit)


-- Values with a unit
infixl 5 =| -- sensible?
data Measurement : {q : Quantity} -> Unit q -> Type -> Type where
  (=|) : a -> (u : Unit q) -> Measurement u a

-- TODO: show unit
instance Show a => Show (Measurement {q} u a) where
  show (x =| _) = show x

-- TODO: is this sensible?
infixl 5 :|

(:|) : Unit q -> Type -> Type
(:|) = Measurement

-- Floats with a unit
F : Unit q -> Type
F u = Measurement u Float

{-
-- Doubles with a unit
D : Unit q -> Type
D u = Measurement u Double
-}

convertTo : {from : Unit q} -> (to : Unit q) -> F from -> F to
convertTo to (x =| from) = (x * (ratio from / ratio to)) =| to

-- Example:
-- convertTo ms (50 =| kmh)

{-
kilo : Unit a -> Unit a
kilo = multiplyUnit 1000

deci : Unit a -> Unit a
deci = multiplyUnit 0.1

centi : Unit a -> Unit a
centi = multiplyUnit 0.01

milli : Unit a -> Unit a
milli = multiplyUnit 0.001
-}
