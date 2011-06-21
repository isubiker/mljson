(:
Copyright 2011 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)

xquery version "1.0-ml";

module namespace json="http://marklogic.com/json";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function json:jsonToXML(
    $json as xs:string
) as element(json)
{
    let $tokens := json:tokenize($json)
    let $value := json:parseValue($tokens, 1)
    let $test :=
        if(xs:integer($value/@position) != fn:count($tokens) + 1)
        then json:outputError($tokens, xs:integer($value/@position), "Unhandled tokens")
        else ()
    return <json>{ $value/(@type, @boolean), $value/node() }</json>
};

declare private function json:parseValue(
    $tokens as element(token)*,
    $position as xs:integer
) as element(value)
{
    let $token := $tokens[$position]
    let $value :=
        if($token/@t = "lbrace")
        then json:parseObject($tokens, $position + 1)

        else if($token/@t = "lsquare")
        then json:parseArray($tokens, $position + 1)

        else if($token/@t = "number")
        then <value type="number" position="{ $position + 1 }">{ fn:string($token) }</value>

        else if($token/@t = "string")
        then <value type="string" position="{ $position + 1 }">{ json:unescapeJSONString($token) }</value>

        else if($token/@t = "true" or $token/@t = "false")
        then <value boolean="{ $token }" position="{ $position + 1 }"/>

        else if($token/@t = "null")
        then <value type="null" position="{ $position + 1 }"/>

        else json:outputError($tokens, $position, "Expected an object, array, string, number, boolean or null")

    return $value
};

declare private function json:parseArray(
    $tokens as element(token)*,
    $position as xs:integer
) as element(value)
{
    let $finalLocation := $position
    let $items :=
        let $foundClosingBracket := fn:false()

        for $index in ($position to fn:count($tokens))
        where $foundClosingBracket = fn:false() and $index >= $finalLocation
        return
            if($tokens[$index]/@t = "rsquare")
            then (
                xdmp:set($foundClosingBracket, fn:true()),
                xdmp:set($finalLocation, $index + 1)
            )

            else if($tokens[$index]/@t = "comma")
            then xdmp:set($finalLocation, $index)

            else
                let $test := json:shouldBeOneOf($tokens, $index, ("lbrace", "lsquare", "string", "number", "true", "false", "null"), "Expected an array, object, string, number, boolean or null")
                let $value := json:parseValue($tokens, $index)
                let $set := xdmp:set($finalLocation, xs:integer($value/@position))
                let $test := json:shouldBeOneOf($tokens, $finalLocation, ("comma", "rsquare"), "Expected either a comma or closing array")
                return <item>{ $value/(@type, @boolean), $value/node() }</item>

    return <value type="array" position="{ $finalLocation }">{ $items }</value>
};

declare private function json:parseObject(
    $tokens as element(token)*,
    $position as xs:integer
) as element(value)
{
    if($tokens[$position + 1]/@t = "rbrace")
    then <value type="object" position="{ $position + 1 }"/>
    else

    let $finalLocation := $position
    let $items :=
        let $foundClosingBrace := fn:false()

        for $index in ($position to fn:count($tokens))
        where $foundClosingBrace = fn:false() and $index >= $finalLocation
        return
            if($tokens[$index]/@t = "rbrace")
            then (
                xdmp:set($foundClosingBrace, fn:true()),
                xdmp:set($finalLocation, $index + 1)
            )

            else if($tokens[$index]/@t = "comma")
            then xdmp:set($finalLocation, $index)

            else
                let $test := json:shouldBeOneOf($tokens, $index, "string", "Expected an object key")
                let $test := json:shouldBeOneOf($tokens, $index + 1, "colon", "Expected a colon")
                let $test := json:shouldBeOneOf($tokens, $index + 2, ("lbrace", "lsquare", "string", "number", "true", "false", "null"), "Expected an array, object, string, number, boolean or null")

                let $key := json:escapeNCName($tokens[$index])
                let $value := json:parseValue($tokens, $index + 2)
                let $set := xdmp:set($finalLocation, xs:integer($value/@position))
                let $test := json:shouldBeOneOf($tokens, $finalLocation, ("comma", "rbrace"), "Expected either a comma or closing object")

                return element { $key } { $value/(@type, @boolean), $value/node() }

    return <value type="object" position="{ $finalLocation }">{ $items }</value>
};


declare private function json:shouldBeOneOf(
    $tokens as element(token)*,
    $index as xs:integer,
    $types as xs:string+,
    $expectedMessage as xs:string
) as empty-sequence()
{
    if($tokens[$index]/@t = $types)
    then ()
    else json:outputError($tokens, $index, $expectedMessage)
};

declare private function json:outputError(
    $tokens as element(token)*,
    $index as xs:integer,
    $expectedMessage as xs:string
) as empty-sequence()
{
    let $context := fn:string-join(
        let $contextTokens := $tokens[$index - 3 to $index + 4]
        let $valueTokenTypes := ("string", "number", "true", "false", "null")
        for $token at $loc in $contextTokens
        let $value :=
            if($token/@t = "string")
            then fn:concat('"', fn:string($token), '"')
            else fn:string($token)
        return
            if($token/@t = ("comma", "colon"))
            then fn:concat($value, " ")
            else if($token/@t = $valueTokenTypes and $contextTokens[$loc + 1]/@t = $valueTokenTypes)
            then fn:concat($value, " ")
            else $value
    , "")
    return fn:error(xs:QName("json:PARSE01"), fn:concat("Unexpected token ", fn:string($tokens[$index]/@t), ": '", $context, "'. ", $expectedMessage))
};

declare private function json:unescapeJSONString($val as xs:string)
  as xs:string
{
    fn:string-join(
        let $regex := '[^\\]+|(\\")|(\\\\)|(\\/)|(\\b)|(\\f)|(\\n)|(\\r)|(\\t)|(\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])'
        for $match in fn:analyze-string($val, $regex)/*
        return 
            if($match/*:group/@nr = 1) then """"
            else if($match/*:group/@nr = 2) then "\"
            else if($match/*:group/@nr = 3) then "/"
            (: else if($match/*:group/@nr = 4) then "&#x08;" :)
            (: else if($match/*:group/@nr = 5) then "&#x0C;" :)
            else if($match/*:group/@nr = 6) then "&#x0A;"
            else if($match/*:group/@nr = 7) then "&#x0D;"
            else if($match/*:group/@nr = 8) then "&#x09;"
            else if($match/*:group/@nr = 9) then fn:codepoints-to-string(xdmp:hex-to-integer(fn:substring($match, 3)))
            else fn:string($match)
    , "")
};

declare private function json:tokenize(
    $json as xs:string
) as element(token)*
{
    let $tokens := ("\{", "\}", "\[", "\]", ":", ",", "true", "false", "null", "\s+",
        '"([^"\\]|\\"|\\\\|\\/|\\b|\\f|\\n|\\r|\\t|\\u[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])*"',
        "-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?")
    let $regex := fn:string-join(for $t in $tokens return fn:concat("(",$t,")"),"|")
    for $match in fn:analyze-string($json, $regex)/*
    return
        if($match/self::*:non-match) then json:createToken("error", fn:string($match))
        else if($match/*:group/@nr = 1) then json:createToken("lbrace", fn:string($match))
        else if($match/*:group/@nr = 2) then json:createToken("rbrace", fn:string($match))
        else if($match/*:group/@nr = 3) then json:createToken("lsquare", fn:string($match))
        else if($match/*:group/@nr = 4) then json:createToken("rsquare", fn:string($match))
        else if($match/*:group/@nr = 5) then json:createToken("colon", fn:string($match))
        else if($match/*:group/@nr = 6) then json:createToken("comma", fn:string($match))
        else if($match/*:group/@nr = 7) then json:createToken("true", fn:string($match))
        else if($match/*:group/@nr = 8) then json:createToken("false", fn:string($match))
        else if($match/*:group/@nr = 9) then json:createToken("null", fn:string($match))
        else if($match/*:group/@nr = 10) then () (:ignore whitespace:)
        else if($match/*:group/@nr = 11) then
            let $v := fn:string($match)
            let $len := fn:string-length($v)
            return json:createToken("string", fn:substring($v, 2, $len - 2))
        else if($match/*:group/@nr = 13) then json:createToken("number", fn:string($match))
        else json:createToken("error", fn:string($match))
};

declare private function json:createToken(
    $type as xs:string,
    $value as xs:string
) as element(token)
{
    <token t="{ $type }">{ $value }</token>
};




declare function json:xmlToJSON(
    $element as element()
) as xs:string
{
    fn:string-join(json:processElement($element), "")
};

declare private function json:processElement(
    $element as element()
) as xs:string*
{
    if($element/@type = "object") then json:outputObject($element)
    else if($element/@type = "array") then json:outputArray($element)
    else if($element/@type = "null") then "null"
    else if(fn:exists($element/@boolean)) then xs:string($element/@boolean)
    else if($element/@type = "number") then xs:string($element)
    else ('"', json:escapeJSONString($element), '"')
};

declare private function json:outputObject(
    $element as element()
) as xs:string*
{
    "{",
        for $child at $pos in $element/*
        return (
            if($pos = 1) then () else ",",
            '"', json:unescapeNCName(fn:local-name($child)), '":', json:processElement($child)
        ),
    "}"
};

declare private function json:outputArray(
    $element as element()
) as xs:string*
{
    "[",
        for $child at $pos in $element/*
        return (
            if($pos = 1) then () else ",",
            json:processElement($child)
        ),
    "]"
};

(: Need to backslash escape any double quotes, backslashes, and newlines :)
declare private function json:escapeJSONString(
    $string as xs:string
) as xs:string
{
    let $string := fn:replace($string, "\\", "\\\\")
    let $string := fn:replace($string, """", "\\""")
    let $string := fn:replace($string, fn:codepoints-to-string((13, 10)), "\\n")
    let $string := fn:replace($string, fn:codepoints-to-string(13), "\\n")
    let $string := fn:replace($string, fn:codepoints-to-string(10), "\\n")
    return $string
};

declare private function json:encodeHexStringHelper(
    $num as xs:integer,
    $digits as xs:integer
) as xs:string*
{
    if($digits > 1)
    then json:encodeHexStringHelper($num idiv 16, $digits - 1)
    else (),
    ("0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F")[$num mod 16 + 1]
};

declare private function json:escapeNCName(
    $val as xs:string
) as xs:string
{
    if($val = "")
    then "_"
    else
        fn:string-join(
            let $regex := ':|_|(\i)|(\c)|.'
            for $match at $pos in fn:analyze-string($val, $regex)/*
            return
                if($match/*:group/@nr = 1 or ($match/*:group/@nr = 2 and $pos != 1))
                then fn:string($match)
                else ("_", json:encodeHexStringHelper(fn:string-to-codepoints($match), 4))
        , "")
};

declare private function json:unescapeNCName(
    $val as xs:string
) as xs:string
{
    if($val = "_")
    then ""
    else
        fn:string-join(
            let $regex := '(_[A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9][A-Fa-f0-9])|[^_]+'
            for $match at $pos in fn:analyze-string($val, $regex)/*
            return
                if($match/*:group/@nr = 1)
                then fn:codepoints-to-string(xdmp:hex-to-integer(fn:substring($match, 2)))
                else fn:string($match)
      , "")
};
