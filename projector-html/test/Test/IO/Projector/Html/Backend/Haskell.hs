{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module Test.IO.Projector.Html.Backend.Haskell where


import qualified Data.List as L
import qualified Data.Text as T
import qualified Data.Text.IO as T

import           Disorder.Core
import           Disorder.Core.IO
import           Disorder.Jack

import           P

import           Projector.Core
import           Projector.Html.Core.Prim
import qualified Projector.Html.Core.Library as Lib
import           Projector.Html.Backend.Haskell

import           System.Exit (ExitCode(..))
import           System.FilePath.Posix ((</>), (<.>))
import           System.IO.Temp (withTempDirectory)
import           System.Process (readProcessWithExitCode)


prop_empty_module =
  once (ghcProp moduleName moduleText)
  where
    moduleName = ModuleName "TestModule"
    moduleText = renderModule moduleName mempty

prop_library_module =
  once (ghcProp moduleName moduleText)
  where
    moduleName = ModuleName "LibModule"
    moduleText = renderModule moduleName . genModule Lib.types $ [
        (Name "helloWorld", Lib.tHtml,
          ECon (Constructor "Plain") Lib.nHtml [ELit (VString "Hello, world!")])
      ]

-- Compiles with GHC in the current sandbox, failing if exit status is nonzero.
ghcProp :: ModuleName -> Text -> Property
ghcProp (ModuleName n) modl =
  testIO . withTempDirectory "./dist/" "gen-hs-XXXXXX" $ \tmpDir -> do
    -- TODO convert module names to valid nested paths
    let path = tmpDir </> T.unpack n <.> "hs"
    T.writeFile path modl
    (code, _out, err) <- readProcessWithExitCode "cabal" ["exec", "--", "ghc", path] ""
    case code of
      ExitSuccess ->
        pure (property True)
      ExitFailure i ->
        let errm = L.unlines [
                "GHC exited with failing status: " <> T.unpack (renderIntegral i)
              , err
              ]
        in pure $ counterexample errm (property False)


return []
tests = $disorderCheckEnvAll TestRunNormal