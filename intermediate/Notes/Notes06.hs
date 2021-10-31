{-# LANGUAGE DeriveFunctor, MonadComprehensions #-}
module Notes06 where

import Control.Monad (ap, forM, forM_, liftM2)

--------------------------------------------------------------------------------

-- Also in Control.Monad.State
newtype State s a = State { runState :: s -> (s, a) }
                  deriving(Functor)

execState :: State s a -> s -> s
execState (State f) s = fst (f s)

evalState :: State s a -> s -> a
evalState (State f) s = snd (f s)

put :: s -> State s ()
put s = State (\_ -> (s, ()))

get :: State s s
get = State (\s -> (s, s)) 

modify :: (s -> s) -> State s ()
modify f = State (\s -> (f s, ()))

instance Applicative (State s) where pure = return; (<*>) = ap
instance Monad (State s) where
  return x = State (\s -> (s, x))
  State f >>= g = State (\s -> let (s', a) = f s in runState (g a) s')

--------------------------------------------------------------------------------

-- Labelling trees using the State monad

data BinTree a = Leaf a 
               | Node (BinTree a) (BinTree a)
               deriving( Eq, Ord, Show, Functor )

-- The function labelTree should label the leaves of a tree with increasing integers:
--    labelTree (Leaf ()) == Leaf 0
--    labelTree (Node (Leaf ()) (Leaf ())) == Node (Leaf 0) (Leaf 1)
--    labelTree (Node (Leaf ()) (Node (Leaf ()) (Leaf ()))) == Node (Leaf 0) (Node (Leaf 1) (Leaf 2))
--    ..

-- Hint: define a function labelTree_State :: BinTree a -> State Int (BinTree Int), 
--   where the state represents the next leaf value.
-- labelTree_State should be defined by recursion on its argument.
labelTree_State :: BinTree a -> State Int (BinTree Int)
labelTree_State (Leaf _) = do
    x <- get
    modify (\x -> x+1)
    return (Leaf x)
labelTree_State (Node a b) = do
    ma <- labelTree_State a 
    mb <- labelTree_State b
    return (Node ma mb)

-- When reaching a leaf, we should use the current state as the leaf value and increment the state.
-- labelLeaf should increment the state by 1 and return the previous state.
labelLeaf :: State Int Int
labelLeaf = State (\n -> (n, n+1))

-- labelTree should be defined using evalState and labelTree_State
labelTree :: BinTree a -> BinTree Int
labelTree a = evalState (labelTree_State a) 0


-- The function labelTreeMax should label the leaves of a tree with the maximum leaf value 
--        to the left of it (you can assume that all values are positive).
--    labelTreeMax (Leaf 10) == Leaf 10
--    labelTreeMax (Node (Leaf 10) (Leaf 100)) == Node (Leaf 10) (Leaf 100)
--    labelTreeMax (Node (Leaf 100) (Leaf 10)) == Node (Leaf 100) (Leaf 100)
--    labelTreeMax (Node (Leaf 2) (Node (Leaf 1) (Leaf 3))) == Node (Leaf 2) (Node (Leaf 2) (Node Leaf 3))
--    ..
labelTreeMax_State :: BinTree Int -> State Int (BinTree Int)
labelTreeMax_State (Leaf a) = do
    x <- get
    modify (\s -> (if a > s then a else s))
    return (Leaf x)
labelTreeMax_State (Node a b) = do
    ma <- labelTreeMax_State a
    mb <- labelTreeMax_State b
    return (Node ma mb)

labelTreeMax :: BinTree Int -> BinTree Int
labelTreeMax a = evalState (labelTreeMax_State a) 1
    


--------------------------------------------------------------------------------
-- Foldable and Traversable

-- foldMap :: (Foldable t, Monoid m) => (a -> m) -> t a -> m
-- mapM    :: (Traversable t, Monad m) => (a -> m b) -> t a -> m (t b)
-- More general: traverse :: (Traversable t, Applicative m) => (a -> m b) -> t a -> m (t b)

-- Example: [] is Foldable and Traversable
foldMap_List :: Monoid m => (a -> m) -> [a] -> m
foldMap_List f []     = mempty
foldMap_List f (x:xs) = f x <> foldMap_List f xs

mapM_List :: Monad m => (a -> m b) -> [a] -> m [b]
mapM_List f []     = pure []
mapM_List f (x:xs) = (:) <$> f x <*> mapM_List f xs

-- forM :: Monad m => [a] -> (a -> m b) -> m [b]
-- forM xs f = mapM_List f xs

-- Define foldMap and mapM for BinTree
foldMap_BinTree :: Monoid m => (a -> m) -> BinTree a -> m
foldMap_BinTree f (Leaf a) = f a
foldMap_BinTree f (Node a b) = foldMap_BinTree f a <> foldMap_BinTree f b

mapM_BinTree :: Monad m => (a -> m b) -> BinTree a -> m (BinTree b)
mapM_BinTree f (Leaf a) = do
    ma <- f a
    return $ Leaf ma
mapM_BinTree f (Node a b) = do
    ma <- mapM_BinTree f a
    mb <- mapM_BinTree f b
    return (Node ma mb)

instance Foldable BinTree where foldMap = foldMap_BinTree
instance Traversable BinTree where 
  mapM     = mapM_BinTree
  traverse = error "We don't define traverse now, its definition will be identical to mapM."

--------------------------------------------------------------------------------
-- We can use mapM_BinTree to redefine labelTree and labelTreeMax

labelTree' :: BinTree a -> BinTree Int
labelTree' t = evalState (mapM_BinTree undefined t) 0

labelTreeMax' :: BinTree Int -> BinTree Int
labelTreeMax' t = evalState (mapM_BinTree undefined t) 0


--------------------------------------------------------------------------------
-- Define Foldable and Traversable instances for Tree2
data Tree2 a = Leaf2 a | Node2 [Tree2 a]
             deriving (Show, Functor)