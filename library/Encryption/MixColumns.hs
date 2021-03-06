module Encryption.MixColumns
  ( mixColumns
  , invMixColumns
  )
where

import           Encryption.Utils
import           Encryption.Globals
import qualified Data.ByteString.Lazy          as B
import qualified Data.Word8                    as W
import           Data.List                      ( foldl' )
import           Data.Bits                      ( xor
                                                , shift
                                                , testBit
                                                )
import           Crypto.Number.Basic            ( log2 )


-- Define addition in galois field as xor.
addF2m = xor

-- Define modular division in galois field.
modF2m :: Integer -> Integer -> Integer
modF2m fx i
  | fx < 0 || i < 0 = error
    "modF2m: negative number represent no binary polynomial"
  | fx == 0 = error "modF2m: cannot divide by zero polynomial"
  | fx == 1 = 0
  | otherwise = go i
 where
  lfx = log2 fx
  go n | s == 0    = n `addF2m` fx
       | s < 0     = n
       | otherwise = go $ n `addF2m` shift fx s
    where s = log2 n - lfx

-- Define multiplication in galois field.
mulF2m :: Integer -> Integer -> Integer -> Integer
mulF2m fx n1 n2
  | fx < 0 || n1 < 0 || n2 < 0 = error
    "mulF2m: negative number represent no binary binary polynomial"
  | fx == 0 = error "modF2m: cannot multiply modulo zero polynomial"
  | otherwise = modF2m fx $ go (if n2 `mod` 2 == 1 then n1 else 0) (log2 n2)
 where
  go n s
    | s == 0 = n
    | otherwise = if testBit n2 s
      then go (n `addF2m` shift n1 s) (s - 1)
      else go n (s - 1)

-- Exported mixColumns layer of AES.
mixColumns :: Block -> Block
mixColumns = common matrix

-- Exported inverted mixColumns layer of AES.
invMixColumns :: Block -> Block
invMixColumns = common invMatrix

-- The common part of both mixColumns and invMixColumns.
common :: [B.ByteString] -> Block -> Block
common someMatrix =
  B.concat . map (mulMV aesPolynomial someMatrix) . splitEvery 4


-- Multiply matrix and vector, mod the given polynomial.
mulMV :: Integer -> [B.ByteString] -> B.ByteString -> B.ByteString
mulMV polynomial matrix vector =
  B.pack
    . map
        ( fromInteger
        . foldl' addF2m 0
        . B.zipWith (mulF2mBytes polynomial) vector
        )
    $ matrix


-- Multiply bytes in galois field.
mulF2mBytes :: Integer -> W.Word8 -> W.Word8 -> Integer
mulF2mBytes polynomial w1 w2 =
  mulF2m polynomial (fromIntegral w1) (fromIntegral w2)

-- The matrix for the mixColumns layer.
matrix = map
  B.pack
  [ [0x02, 0x03, 0x01, 0x01]
  , [0x01, 0x02, 0x03, 0x01]
  , [0x01, 0x01, 0x02, 0x03]
  , [0x03, 0x01, 0x01, 0x02]
  ]

-- The matrix for the inverse mixColumns layer.
invMatrix = map
  B.pack
  [ [0x0E, 0x0B, 0x0D, 0x09]
  , [0x09, 0x0E, 0x0B, 0x0D]
  , [0x0D, 0x09, 0x0E, 0x0B]
  , [0x0B, 0x0D, 0x09, 0x0E]
  ]
