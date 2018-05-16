-- -----------------------------------------------------------------------------
--
-- (c) The University of Glasgow, 2005-2007
--
-- Running statements interactively
--
-- -----------------------------------------------------------------------------

module ETA.Main.InteractiveEvalTypes (
        Resume(..), History(..), ExecResult(..),
        SingleStep(..), isStep, ExecOptions(..),
        BreakInfo(..)
        ) where

import Eta.REPL.RemoteTypes
import Eta.REPL.Message (EvalExpr, ResumeContext)
import ETA.BasicTypes.Id
import ETA.BasicTypes.Name
import ETA.BasicTypes.Module
import ETA.BasicTypes.RdrName
import ETA.Types.Type
import ETA.BasicTypes.SrcLoc
import ETA.Utils.Exception

import Data.Word
-- import GHC.Stack.CCS

data ExecOptions
 = ExecOptions
     { execSingleStep :: SingleStep         -- ^ stepping mode
     , execSourceFile :: String             -- ^ filename (for errors)
     , execLineNumber :: Int                -- ^ line number (for errors)
     , execWrap :: ForeignHValue -> EvalExpr ForeignHValue
     }

data SingleStep
   = RunToCompletion
   | SingleStep
   | RunAndLogSteps

isStep :: SingleStep -> Bool
isStep RunToCompletion = False
isStep _ = True

data ExecResult
  = ExecComplete
       { execResult :: Either SomeException [Name]
       , execAllocation :: Word64
       }
  | ExecBreak
       { breakNames :: [Name]
       , breakInfo :: Maybe BreakInfo
       }

data BreakInfo = BreakInfo
  { breakInfo_module :: Module
  , breakInfo_number :: Int
  }

data Resume = Resume
       { resumeStmt      :: String       -- the original statement
       , resumeContext   :: ForeignRef (ResumeContext [HValueRef])
       , resumeBindings  :: ([TyThing], GlobalRdrEnv)
       , resumeFinalIds  :: [Id]         -- [Id] to bind on completion
       , resumeApStack   :: ForeignHValue -- The object from which we can get
                                        -- value of the free variables.
       , resumeBreakInfo :: Maybe BreakInfo
                                        -- the breakpoint we stopped at
                                        -- (module, index)
                                        -- (Nothing <=> exception)
       , resumeSpan      :: SrcSpan      -- just a copy of the SrcSpan
                                        -- from the ModBreaks,
                                        -- otherwise it's a pain to
                                        -- fetch the ModDetails &
                                        -- ModBreaks to get this.
       , resumeDecl      :: String       -- ditto
       , resumeCCS       :: RemotePtr ()--CostCentreStack
       , resumeHistory   :: [History]
       , resumeHistoryIx :: Int           -- 0 <==> at the top of the history
       }

data History
   = History {
        historyApStack   :: ForeignHValue,
        historyBreakInfo :: BreakInfo,
        historyEnclosingDecls :: [String]  -- declarations enclosing the breakpoint
   }
