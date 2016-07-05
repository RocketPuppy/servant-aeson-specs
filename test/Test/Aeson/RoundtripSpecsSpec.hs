{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Test.Aeson.RoundtripSpecsSpec where

import           Control.Applicative
import           Data.Aeson
import           GHC.Generics
import           Test.Hspec
import           Test.Hspec.Core.Runner
import           Test.QuickCheck

import           Test.Aeson.GenericSpecs
import           Test.Utils

spec :: Spec
spec = do
  describe "roundtripSpecs" $ do
    it "detects incompatible json encodings" $ do
      roundtripSpecs faultyRoundtripProxy `shouldTestAs` Summary 1 1

    context "when used with compatible encodings" $ do
      it "creates passing tests" $ do
        roundtripSpecs correctProxy `shouldTestAs` Summary 1 0

      it "creates passing tests for sum types" $ do
        roundtripSpecs correctSumProxy `shouldTestAs` Summary 1 0

-- | Type where roundtrips don't work.
data FaultyRoundtrip
  = FaultyRoundtrip {
    faultyRoundtripFoo :: String,
    faultyRoundtripBar :: Int
  }
  deriving (Show, Eq, Generic)

faultyRoundtripProxy :: Proxy FaultyRoundtrip
faultyRoundtripProxy = Proxy

instance ToJSON FaultyRoundtrip where
  toJSON x = object $
    "foo" .= faultyRoundtripFoo x :
    "bar" .= faultyRoundtripBar x :
    []

instance FromJSON FaultyRoundtrip

instance Arbitrary FaultyRoundtrip where
  arbitrary = FaultyRoundtrip <$> arbitrary <*> arbitrary

data Correct
  = Correct {
    correctFoo :: String,
    correctBar :: String
  }
  deriving (Show, Eq, Generic)

correctProxy :: Proxy Correct
correctProxy = Proxy

instance ToJSON Correct

instance FromJSON Correct

instance Arbitrary Correct where
  arbitrary = Correct <$> arbitrary <*> arbitrary

data CorrectSum
  = Foo {
    correctSumFoo :: String
  }
  | Bar {
    correctSumFoo :: String,
    correctSumBar :: String
  }
  deriving (Show, Eq, Generic)

correctSumProxy :: Proxy CorrectSum
correctSumProxy = Proxy

instance ToJSON CorrectSum where
  toJSON = \ case
    Foo foo -> object ["Foo" .= foo]
    Bar foo bar -> object
      ["Bar" .= object ["correctSumFoo" .= foo, "correctSumBar" .= bar]]

instance FromJSON CorrectSum where
  parseJSON = withObject "CorrectSum" $ \ o ->
    (Foo <$> o .: "Foo") <|>
    (o .: "Bar" >>= \ dict ->
      Bar <$> dict .: "correctSumFoo" <*> dict .: "correctSumBar")

instance Arbitrary CorrectSum where
  arbitrary = oneof $
    (Foo <$> arbitrary) :
    (Bar <$> arbitrary <*> arbitrary) :
    []
