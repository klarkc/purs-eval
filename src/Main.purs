module Main (main) where

import Prelude (Unit, bind, discard)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Node.Process (stdin, stdout)
import Node.Stream.Aff (readSome, write, end, toStringUTF8, fromStringUTF8)
import Compiler (successFromJson, runCompiler)

main :: Effect Unit
main = launchAff_ do
  { buffers } <- readSome stdin
  code <- toStringUTF8 buffers
  let settings = { protocol: "https"
                 , hostname: "compile.purescript.org"
                 , port: 443
                 , parser: successFromJson
                 }
  code' <- runCompiler settings code
  output <- fromStringUTF8 code'
  write stdout output
  end stdout
