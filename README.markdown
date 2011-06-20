# MLJSON - A JSON Facade on top of MarkLogic

The MLJSON project is a set of libraries and REST endpoints to enable the [MarkLogic Server] to become an advanced [JSON] store.

#### MarkLogic  ####
 - High-performance, scalable database for unstructured information
 - "NoSQL" datastore (no tables, rows, columns) - just documents and unique IDs (URIs).
 - Uses XML datamodel for documents, query-able via XQuery, XSLT, XPath
 - Uses search-engine techniques to efficiently expose real-time fulltext search 
 - ACID-compliant CRUD (Create, Read, Update, Delete)

#### JSON ####
  - JavaScript Object Notation
  - A lightweight data-encoding and interchange format
  - Native to JavaScript, now widely utilized across languages
  - Commonly used for passing data to web browsers

#### Design goal
Enable developers to store and search/query JSON inside MarkLogic (without knowledge of XQuery, XSLT, or XPath)

#### Design considerations: 
1. Approach things from a JSON angle
- Create the XML to match the JSON, not vice-versa 
2. Make good use of MarkLogic indexes
- Craft the XML so it's fast to query
3. XML representation of JSON is an implementation detail - users only need think in terms of JSON

#### Overview
MLJSON exposes REST endpoints that allow a developer to
easily store and retrieve JSON documents from the database ([CRUD]).  It also
exposes a very powerful query interface that uses a native JSON syntax:

Query using native JSON syntax 
- Don't expose the XML internals to users 
- Support full range of MarkLogic indexes

This query interface allows the user to find documents via "path" expressions as
well as full text search expressions.  For those familiar with MarkLogic, it
exposes all of the functionality found in the [CTS search functions].

#### Presentation
Here are some [slides] from a presentation on MLJSON given at XML Prague 2011.

___

## Files
 - lib/json.xqy - Has two public functions:
   - jsonToXML - parses a JSON string into XML that can be stored in MarkLogic
   - xmlToJSON - parses the generated XML into a JSON string
 - lib/json-query.xqy - Tinkering with ways to query the stored JSON
 - jsonquery.xqy - A REST endpoint for querying JSON documents
 - jsonstore.xqy - A REST endpoint for storing, managing and retrieving JSON documents

## Capabilities of jsonstore.xqy
#### Insert a JSON document
 - Request type: PUT or POST
 - Request body should be the JSON document
 - Example: jsonstore.xqy?uri=/foo/bar.json
 - Optional: When inserting a document you can set permissions, properties, collections and a document quality.
   - jsonstore.xqy?uri=/foo/bar.json&permission=public:read&permission=admin:write
   - jsonstore.xqy?uri=/foo/bar.json&property=key:value&property=published:false
   - jsonstore.xqy?uri=/foo/bar.json&collection=public&collection=published
   - jsonstore.xqy?uri=/foo/bar.json&quality=10
   - jsonstore.xqy?uri=/foo/bar.json&permission=public:read&collection=public&quality=10

 - Notes:
   - You can set multiple permissions, properties and collections by including multiple definitions in your request, as shown above
   - Permissions must follow a <role>:<capability> pattern where capability is one of read, update or execute
   - Properties must follow a <key>:<value> pattern where the key is alphanumeric and starts with a letter

#### Get a JSON document
 - Request type: GET
 - Example: jsonstore.xqy?uri=/foo/bar.json
 - Optional: To fetch metadat associated about the document, specify what you'd like to include in the response.
   - jsonstore.xqy?uri=/foo/bar.json?include=content - Simply returns the document as supplied via the PUT (default)
   - jsonstore.xqy?uri=/foo/bar.json?include=permissions - Returns the permissions on the document
   - jsonstore.xqy?uri=/foo/bar.json?include=collections - Returns the collections on the document
   - jsonstore.xqy?uri=/foo/bar.json?include=properties - Returns the properties on the document
   - jsonstore.xqy?uri=/foo/bar.json?include=quality - Returns the quality of the document
   - jsonstore.xqy?uri=/foo/bar.json?include=content&include=permissions&include=quality - Returns the content, permissions and quality of the document
   - jsonstore.xqy?uri=/foo/bar.json?include=all - Returns the content along with all of its metadata

#### Delete a JSON document
 - Request type: DELETE
 - Example: jsonstore.xqy?uri=/foo/bar.json

#### Set a property on a document
 - Request type: POST
 - Properties are **not** held inside the JSON document, properties are stored outside of the document and don't effect the stored document at all.  They are best thought of as metadata about the document but should be avoided if possible due to storage overhead.
 - Example: jsonstore.xqy?uri=/foo/bar.json&property=publishState:final&property=needsEditorial:false

#### Set permissions on a document
 - Request type: POST
 - When setting permissions on a document, all of the existing permissions are overwritten.
 - Example: jsonstore.xqy?uri=/foo/bar.json&permission=public:read&permission=admin:write

#### Set collections on a document
 - Request type: POST
 - When setting collections on a document, all of the existing collections are overwritten.
 - Example: jsonstore.xqy?uri=/foo/bar.json&collection=public&collection=published

#### Set the quality of a document
 - Request type: POST
 - Example: jsonstore.xqy?uri=/foo/bar.json&quality=10

## TODO
 - jsonstore.xqy:
   - Move a document
   - Copy a document
 - Some real tests

  [MarkLogic]: http://developer.marklogic.com
  [MarkLogic Server]: http://developer.marklogic.com
  [CRUD]: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete
  [CTS search functions]: http://developer.marklogic.com/pubs/4.2/apidocs/cts-query.html
  [JSON]: http://json.org
  [slides]: http://www.xmlprague.cz/2011/presentations/jason-hunter-mljson.pdf
