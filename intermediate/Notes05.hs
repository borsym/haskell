{-# LANGUAGE DeriveFunctor, MonadComprehensions #-}
module Notes05 where

import Control.Monad (ap, forM, forM_)

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

instance Applicative (State s) where pure = return; (<*>) = ap
instance Monad (State s) where
  return x = State (\s -> (s, x))
  State f >>= g = State (\s -> let (s', a) = f s in runState (g a) s')

--------------------------------------------------------------------------------

-- Define modify' using put and get
modify' :: (s -> s) -> State s ()
modify' f = do
    x <- get
    put $ f x 

-- Define modify using   State (\s -> ...)
modify :: (s -> s) -> State s ()
modify f = State (\s -> (f s, ()))

-- "Translations" of imperative programs using the State monad

-- forM :: Monad m => [a] -> (a -> m b) -> m [b]
-- forM_ :: Monad m => [a] -> (a -> m b) -> m () -- forM_ discards the results of forM

-- Example:
--   x = 1
--   for i from 1 to n
--     x = x + 1
ex :: Integer -> State Integer ()
ex n = do
  put 1                   -- x = 1
  forM_ [1..n] $ \_ -> do -- for i from 1 to n
    modify (\x -> x + 1)
    -- x <- get 
    -- put (x+1)             --   x = x+1

runEx :: Integer -> Integer
runEx n = execState (ex n) 1

-- impFactorial should be a translation of the imperative program
--    x = 1
--    for i from 1 to n
--      x = x * i

impFactorial :: Integer -> State Integer ()
impFactorial n = do
    forM_ [1..n] $ \i -> do
        modify (\x -> x * i)

runFactorial :: Integer -> Integer
runFactorial n = execState (impFactorial n) 1

-- impFibo should be a translation of the imperative program
--    (a, b) = (1, 1)
--    for i from 1 to n
--      (a, b) = (b, a+b)

impFibo :: Integer -> State (Integer, Integer) ()
impFibo n = do
    -- put (1,1)
    forM_ [1..n] $ \_ -> do
        modify (\(a,b) -> (b, a + b))

runFibo :: Integer -> Integer
runFibo n = fst (execState (impFibo n) (1, 1))

-- impGcd should be a translation of the imperative program 
--   (a, b) are inputs: they are given to the program using the second argument of execState
--
--   while b /= 0
--     (a, b) = (b, a `mod` b)
--
--   (you may want to define whileM first)

impGcd :: State (Integer, Integer) ()
impGcd = do
    whileM
        (do (_, b) <- get
            return (b /= 0)
        )
        (modify (\(a,b) -> (b, a `mod` b)))

runGcd :: Integer -> Integer -> Integer
runGcd x y = fst $ execState impGcd (x, y)

-- 

-- whileM cond ma  should correspond to 
--    while cond
--      do ma

whileM :: Monad m => m Bool -> m a -> m ()
whileM cond ma = do
    b <- cond -- b :: Bool
    if b then do ma
                 whileM cond ma
    else return ()
        


takeWhileM :: Monad m => (a -> m Bool) -> [a] -> m [a] 
takeWhileM = undefined
