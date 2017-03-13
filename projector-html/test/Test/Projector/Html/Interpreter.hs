{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module Test.Projector.Html.Interpreter where

import qualified Data.Map.Strict as M

import           Disorder.Core

import           P

import           Projector.Core
import           Projector.Html
import           Projector.Html.Data.Annotation
import           Projector.Html.Interpreter
import           Projector.Html.Syntax.QQ  (template)

import           Test.QuickCheck.Jack


-- FIX We need a generator to round-trip property test this
prop_interpret_unit =
  once . either (flip counterexample False) id $ do
     (at, a) <- first show . checkTemplate mempty $
       [template|\t : String -> <div id="a" class="{ t }">{ text t }</div>|]
     let
       ma = M.fromList [("a", (at, LibraryFunction (Name "a")))]
       na = M.fromList [(Name "a", a)]
     (_, b) <- first show . checkTemplateIncremental mempty ma $
       [template|<a>{ a "b" }</a><!-- c --><hr id="d" />e|]
     h <- first show . interpret mempty na $ b
     pure $
       h
       ===
       Nested [
           Element "a" [] . Nested $ [
               Whitespace " "
             , Element "div" [Attribute "id" "a", Attribute "class" "b"] $ Plain "b"
             ]
         , Comment " c "
         , VoidElement "hr" [Attribute "id" "d"]
         , Raw "e"
         ]


return []
tests = $disorderCheckEnvAll TestRunNormal