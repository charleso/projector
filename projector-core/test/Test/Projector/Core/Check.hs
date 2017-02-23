{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
module Test.Projector.Core.Check where


import           Disorder.Core
import           Disorder.Jack

import           P

import           Projector.Core.Check
import           Projector.Core.Syntax (extractAnnotation)

import           Test.Projector.Core.Arbitrary

import           Text.Show.Pretty (ppShow)


prop_welltyped =
  gamble genWellTypedTestExpr' $ \(ty, ctx, e) ->
    typeCheck ctx e === pure ty

prop_welltyped_shrink =
  jackShrinkProp 5 genWellTypedTestExpr' $ \(ty, ctx, e) ->
    typeCheck ctx e === pure ty

prop_welltyped_letrec =
  gamble genWellTypedTestLetrec $ \(ctx, mexps) ->
    let etypes = fmap fst mexps
        exprs = fmap snd mexps
        atypes = fmap (fmap (fst . extractAnnotation)) (typeCheckAll ctx exprs)
    in atypes === pure etypes

prop_illtyped =
  gamble genIllTypedTestExpr' $ \(ctx, e) ->
    property
      (case typeCheck ctx e of
         Left _ ->
           property True
         Right ty ->
           counterexample (ppShow ty) (property False))

prop_illtyped_shrink =
  jackShrinkProp 5 genIllTypedTestExpr' $ \(ctx, e) ->
    property (isLeft (typeCheck ctx e))

{-
-- these are disabled until we can represent type schemes
-- (sometimes functions will simplify into id, which we can't type)

-- prop_nf_consistent =
  gamble genWellTypedTestExpr' $ \(ty, ctx, e) ->
    typeCheck ctx (nf mempty e) === pure ty

-- prop_whnf_consistent =
  gamble genWellTypedTestExpr' $ \(ty, ctx, e) ->
    typeCheck ctx (whnf mempty e) === pure ty
-}

return []
tests = $disorderCheckEnvAll TestRunNormal
