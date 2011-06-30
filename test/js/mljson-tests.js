if(typeof mljson == "undefined" || !mljson) {
    mljson = {};
}


mljson.badJSON = [
    {
        "jsonString": "[1 2]",
        "error": "Unexpected token number: '[1 2]'. Expected either a comma or closing array",
        "purpose": "Missing commas in arrays"
    },
    {
        "jsonString": "{\"foo\" \"bar\"}",
        "error": "Unexpected token string: '{\"foo\" \"bar\"}'. Expected a colon",
        "purpose": "Missing colons in objects"
    },
    {
        "jsonString": "[1, 2",
        "error": "Unexpected token : '1, 2'. Expected either a comma or closing array",
        "purpose": "Missing brackets in arrays"
    },
    {
        "jsonString": "[1.2.2]",
        "error": "Unexpected token error: '[1.2.2]'. Expected either a comma or closing array",
        "purpose": "Too many periods in a number"
    }
];

mljson.validJSON = [
    {
        "json": true,
        "purpose": "Primitive true"
    },
    {
        "json": false,
        "purpose": "Primitive false"
    },
    {
        "json": [],
        "purpose": "Empty array"
    },
    {
        "json": null,
        "purpose": "Primitive null"
    },
    {
        "json": {},
        "purpose": "Empty object"
    },
    {
        "json": -1,
        "purpose": "Negative numbers"
    },
    {
        "json": 1.2,
        "purpose": "Floating points"
    },
    {
        "json": ["hello", "world", [], {}, null, false, true],
        "purpose": "General array with all data types"
    },
    {
        "json": {"": "bar"},
        "purpose": "Key with zero length"
    },
    {
        "json": {"_foo": "bar"},
        "purpose": "Meta escaping (escaping our invalid xml element name escaping)"
    },
    {
        "json": {"f•o": "bar"},
        "purpose": "Unicode chars in the key"
    },
    {
        "json": {"key with spaces": true},
        "purpose": "Keys with spaces"
    },
    {
        "json": {"foo": "bar\nbaz"},
        "purpose": "Newlines in strings"
    },
    {
        "json": {"foo": "\"bar\""},
        "purpose": "Double quotes in strings"
    },
    {
        "json": {"foo": "'bar'"},
        "purpose": "Single quotes in strings"
    },
    {
        "json": {"foo": "", "bar": ""},
        "purpose": "Object value strings with zero length"
    },
    {
        "json": {"text": "ぐらまぁでちゅね♥おはようです！"},
        "purpose": "Unicode value strings"
    },
    {
        "json": {"text": "\u3050\u3089\u307e\u3041\u3067\u3061\u3085\u306d\u2665\u304a\u306f\u3088\u3046\u3067\u3059\uff01"},
        "purpose": "Escaped unicode strings"
    },
    {
        "json": [1, 2, 3, [4, 5, [ 7, 8, 9], 6]],
        "purpose": "Nexted arrays"
    },
    {
        "json": [1, 2, 3, [4, 5, [7, 8, 9], 6], 10],
        "purpose": "Nested arrays with trailing values"
    },
    {
        "json": {
            "foo": 1,
            "bar": {"baz": 2, "yaz": 3}
        },
        "purpose": "Nested objects"
    },
    {
        "json": {
            "foo": 1,
            "em": {"a": "b"},
            "bar": "aa"
        },
        "purpose": "Nested objects with trailing key/value"
    },
    {
        "json": {"false": "false"},
        "purpose": "false as a key/value"
    }
];

$(document).ready(function() {
    module("Bad JSON");
    for (var i = 0; i < mljson.badJSON.length; i += 1) {
        mljson.badFromServerTest(mljson.badJSON[i]);
    }

    module("Good JSON");
    for (var i = 0; i < mljson.validJSON.length; i += 1) {
        mljson.jsonFromServerTest(mljson.validJSON[i]);
    }

    module("JSON Construction");
    asyncTest("Array construction", function() {
        $.ajax({
            url: "/test/xq/array-construction.xqy",
            success: function() {
                ok(true, "Array construction");
            },
            error: function() {
                ok(false, "Array construction");
            },
            complete: function() { start(); }
        });
    });
    asyncTest("Object construction", function() {
        $.ajax({
            url: "/test/xq/object-construction.xqy",
            success: function() {
                ok(true, "Object construction");
            },
            error: function() {
                ok(false, "Object construction");
            },
            complete: function() { start(); }
        });
    });
    asyncTest("Object construction duplicate key should fail", function() {
        $.ajax({
            url: "/test/xq/object-construction-dup-keys.xqy",
            success: function() {
                ok(false, "Object construction duplicate key should fail");
            },
            error: function() {
                ok(true, "Object construction duplicate key should fail");
            },
            complete: function() { start(); }
        });
    });

    // Missing REST
    // Missing Update Functions
});


mljson.jsonFromServer = function(test, success, error) {
    var jsonString = test.jsonString;
    if(jsonString === undefined) {
        jsonString = JSON.stringify(test.json)
    }
    asyncTest(test.purpose, function() {
        $.ajax({
            url: '/test/xq/isomorphic.xqy',
            data: 'json=' + jsonString,
            method: 'POST',
            success: success,
            error: error,
            complete: function() { start(); }
        });
    });
};

mljson.badFromServerTest = function(test) {
    mljson.jsonFromServer(test,
        function(data, t, j) {
            equals(data, test.error, test.purpose);
        },
        function(j, t, error) {
            equals(error, test.error, test.purpose);
        }
    );
};

mljson.jsonFromServerTest = function(test) {
    mljson.jsonFromServer(test,
        function(data, t, j) {
            deepEqual(JSON.parse(data), test.json, test.purpose);
        },
        function(j, t, e) { ok(false, test.purpose); } 
    );
};
