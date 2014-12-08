-- | Bindings to make the popular containers library compatible with subhask
module SubHask.Compatibility.Containers
    where

import Control.Monad
import qualified Data.Map as M
import qualified Data.Map.Strict as MS
import qualified Data.Set as Set
import qualified Prelude as P

import SubHask.Algebra
import SubHask.Algebra.Container
import SubHask.Algebra.Ord
import SubHask.Category
import SubHask.Internal.Prelude

-------------------------------------------------------------------------------
-- | This is a thin wrapper around Data.Map

newtype Map k v = Map (M.Map (WithPreludeOrd k) (WithPreludeOrd v))
    deriving (Read,Show,NFData)

type instance Scalar (Map k v) = Int
type instance Logic (Map k v) = Bool
type instance Elem (Map k v) = (k,v)

instance (Eq v, Ord k, Semigroup v, Arbitrary k, Arbitrary v) => Arbitrary (Map k v) where
    arbitrary = liftM fromList arbitrary

instance Normed (Map k v) where
    abs (Map m) = M.size m

instance (Eq k, Eq v) => Eq_ (Map k v) where
    (Map m1)==(Map m2) = m1 P.== m2

instance (Ord k, Eq v) => POrd_ (Map k v) where
    inf (Map m1) (Map m2) = Map $ M.differenceWith go (M.intersection m1 m2) m2
        where
            go v1 v2 = if v1==v2 then Just v1 else Nothing

instance Ord k => Semigroup (Map k v) where
    (Map m1)+(Map m2) = Map $ M.union m1 m2

instance Ord k => Monoid (Map k v) where
    zero = Map $ M.empty

instance (Ord k, Eq v) => Container (Map k v) where
    elem (k,v) (Map m) = case M.lookup (WithPreludeOrd k) m of
        Nothing -> False
        Just (WithPreludeOrd v') -> v==v'

    notElem (k,v) (Map m) = case M.lookup (WithPreludeOrd k) m of
        Nothing -> True
        Just (WithPreludeOrd v') -> v/=v'

instance (Ord k, Eq v) => Indexed (Map k v) where
    (Map m) !! k = liftM unWithPreludeOrd $ M.lookup (WithPreludeOrd k) m
    hasIndex k (Map m) = M.member (WithPreludeOrd k) m
--     indices (Map m) = map unWithPreludeOrd $ M.keys m
--     values (Map m) = map unWithPreludeOrd $ M.elems m

instance (Ord k, Eq v) => Unfoldable (Map k v) where
    singleton (k,v) = Map $ M.singleton (WithPreludeOrd k) (WithPreludeOrd v)

----------------------------------------
-- | This is a thin wrapper around Data.Map.Strict

newtype Map' k v = Map' (MS.Map (WithPreludeOrd k) (WithPreludeOrd v))
    deriving (Read,Show,NFData)

type instance Scalar (Map' k v) = Int
type instance Logic (Map' k v) = Bool
type instance Elem (Map' k v) = (k,v)

instance (Eq v, Ord k, Semigroup v, Arbitrary k, Arbitrary v) => Arbitrary (Map' k v) where
    arbitrary = liftM fromList arbitrary

instance Normed (Map' k v) where
    abs (Map' m) = MS.size m

instance (Eq k, Eq v) => Eq_ (Map' k v) where
    (Map' m1)==(Map' m2) = m1 P.== m2

instance (Ord k, Eq v) => POrd_ (Map' k v) where
    inf (Map' m1) (Map' m2) = Map' $ MS.differenceWith go (MS.intersection m1 m2) m2
        where
            go v1 v2 = if v1==v2 then Just v1 else Nothing

instance Ord k => Semigroup (Map' k v) where
    (Map' m1)+(Map' m2) = Map' $ MS.union m1 m2

instance Ord k => Monoid (Map' k v) where
    zero = Map' $ MS.empty

instance (Ord k, Eq v) => Container (Map' k v) where
    elem (k,v) (Map' m) = case MS.lookup (WithPreludeOrd k) m of
        Nothing -> False
        Just (WithPreludeOrd v') -> v==v'

    notElem (k,v) (Map' m) = case MS.lookup (WithPreludeOrd k) m of
        Nothing -> True
        Just (WithPreludeOrd v') -> v/=v'

instance (Ord k, Eq v) => Indexed (Map' k v) where
    (Map' m) !! k = liftM unWithPreludeOrd $ MS.lookup (WithPreludeOrd k) m
    hasIndex k (Map' m) = MS.member (WithPreludeOrd k) m

    indices (Map' m) = map unWithPreludeOrd $ MS.keys m
    values (Map' m) = map unWithPreludeOrd $ MS.elems m

mapIndices :: (Ord k1, Ord k2) => (k1 -> k2) -> Map' k1 v -> Map' k2 v
mapIndices f (Map' m) = Map' $ MS.mapKeys (\(WithPreludeOrd k) -> WithPreludeOrd $ f k) m

mapValues :: (Ord k, Eq v1, Eq v2) => (v1 -> v2) -> Map' k v1 -> Map' k v2
mapValues f (Map' m) = Map' $ MS.map (\(WithPreludeOrd v) -> WithPreludeOrd $ f v) m

instance (Ord k, Eq v) => Unfoldable (Map' k v) where
    singleton (k,v) = Map' $ MS.singleton (WithPreludeOrd k) (WithPreludeOrd v)
    fromList xs = Map' $ MS.fromList $ map (\(k,v) -> (WithPreludeOrd k,WithPreludeOrd v)) xs

instance (Ord k, Eq v) => Foldable (Map' k v) where
    toList (Map' m) = map (\(WithPreludeOrd k,WithPreludeOrd v) -> (k,v))
                    $ MS.toList m

-------------------------------------------------------------------------------
-- | This is a thin wrapper around the container's set type

newtype Set a = Set (Set.Set (WithPreludeOrd a))
    deriving (Read,Show,NFData)

instance (Ord a, Arbitrary a) => Arbitrary (Set a) where
    arbitrary = liftM fromList arbitrary

type instance Scalar (Set a) = Int
type instance Logic (Set a) = Logic a
type instance Elem (Set a) = a

instance Normed (Set a) where
    abs (Set s) = Set.size s

instance Eq a => Eq_ (Set a) where
    (Set s1)==(Set s2) = s1'==s2'
        where
            s1' = removeWithPreludeOrd $ Set.toList s1
            s2' = removeWithPreludeOrd $ Set.toList s2
            removeWithPreludeOrd [] = []
            removeWithPreludeOrd (WithPreludeOrd x:xs) = x:removeWithPreludeOrd xs

instance Ord a => POrd_ (Set a) where
    inf (Set s1) (Set s2) = Set $ Set.intersection s1 s2

instance Ord a => MinBound_ (Set a) where
    minBound = Set $ Set.empty

instance Ord a => Lattice_ (Set a) where
    sup (Set s1) (Set s2) = Set $ Set.union s1 s2

instance Ord a => Semigroup (Set a) where
    (Set s1)+(Set s2) = Set $ Set.union s1 s2

instance Ord a => Monoid (Set a) where
    zero = Set $ Set.empty

instance Ord a => Abelian (Set a)

instance Ord a => Container (Set a) where
    elem a (Set s) = Set.member (WithPreludeOrd a) s
    notElem a (Set s) = not $ Set.member (WithPreludeOrd a) s

instance Ord a => Unfoldable (Set a) where
    singleton a = Set $ Set.singleton (WithPreludeOrd a)

    fromList as = Set $ Set.fromList $ map WithPreludeOrd as
