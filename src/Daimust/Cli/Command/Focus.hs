module Daimust.Cli.Command.Focus
  ( Args (..)
  , argsP
  , run
  )
where

import ClassyPrelude

import Options.Applicative

import Daimust.Config (AppIO)
import Daimust.Daim (getCurrentPeriod, runClient)
import Daimust.Data.Period (Period (..), formatPeriod)
import Daimust.Paths (focus, lookupFocus, unfocus)


data Args =
  Args
  { _focusing :: Maybe Focusing
  }
  deriving (Show)

data Focusing
  = Current
  | Prev
  | Next
  | None
  deriving (Eq, Show)

focusingP :: Parser (Maybe Focusing)
focusingP =
  subparser
  ( command "current" (info (pure (Just Current) <**> helper) (progDesc "Focus current period" ))
 <> command "prev" (info (pure (Just Prev) <**> helper) (progDesc "Focus prev period" ))
 <> command "next" (info (pure (Just Next) <**> helper) (progDesc "Focus next period" ))
 <> command "none" (info (pure (Just None) <**> helper) (progDesc "Unfocus" ))
  )
  <|> pure Nothing


argsP :: Parser Args
argsP =
  Args
  <$> focusingP

run :: Args -> AppIO ()
run Args {..} = do
  case _focusing of
    Just Current ->
      runClient getCurrentPeriod
      >>= maybe failGetCurrentPeriod focus
    Just Prev ->
      lookupFocus
      >>= maybe (runClient getCurrentPeriod) (pure . pure)
      >>= maybe failGetCurrentPeriod (focus . decrement)
    Just Next ->
      lookupFocus
      >>= maybe (runClient getCurrentPeriod) (pure . pure)
      >>= maybe failGetCurrentPeriod (focus . increment)
    Just None ->
      unfocus
    _ -> pure ()

  lookupFocus
    >>= say . maybe "no focus" formatPeriod
  where
    failGetCurrentPeriod :: MonadIO m => m ()
    failGetCurrentPeriod = fail "Failed to get current period"


decrement :: Period -> Period
decrement Period {..} =
  Period (_year + (_month - 2) `div` 12) ((_month - 2 + 12) `mod` 12 + 1)

increment :: Period -> Period
increment Period {..} =
  Period (_year + (_month `div` 12)) ((_month `mod` 12) + 1)
