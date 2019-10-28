module Utils where

import qualified Data.ByteString               as B
import qualified Data.Bits
import           Numeric                        ( showHex )
import           Data.Char                      ( toUpper )
import qualified Data.ByteString.Lazy          as BL

snoc :: [a] -> a -> [a]
snoc lst x = lst ++ [x]

splitEvery :: Int -> B.ByteString -> [B.ByteString]
splitEvery n list | list == B.empty = []
                  | otherwise       = first : splitEvery n rest
  where (first, rest) = B.splitAt n list

rotWordLeft :: Int -> B.ByteString -> B.ByteString
rotWordLeft n word = B.drop n word `B.append` B.take n word

rotWordRight :: Int -> B.ByteString -> B.ByteString
rotWordRight n word = B.drop (len - n) word `B.append` B.take (len - n) word
  where len = B.length word

bsXor :: B.ByteString -> B.ByteString -> B.ByteString
bsXor xs ys = B.pack $ B.zipWith Data.Bits.xor xs ys

printBS :: B.ByteString -> IO ()
printBS =
  putStrLn
    . unwords
    . map (("0x" ++) . zfill 2 . map toUpper . (`showHex` ""))
    . B.unpack

printBSL :: [B.ByteString] -> IO ()
printBSL = putStrLn . unlines . map
  (unwords . map (("0x" ++) . zfill 2 . map toUpper . (`showHex` "")) . B.unpack
  )

zfill :: Int -> String -> String
zfill num str = replicate (num - length str) '0' ++ str
