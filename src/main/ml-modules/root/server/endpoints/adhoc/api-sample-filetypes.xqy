xquery version "1.0-ml";

import module namespace  check-user-lib = "http://www.marklogic.com/data-explore/lib/check-user-lib" at "/server/lib/check-user-lib.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config" at "/server/lib/config.xqy";
import module namespace const = "http://www.marklogic.com/data-explore/lib/const" at "/server/lib/const.xqy";
declare option xdmp:mapping "false";


declare variable $sampleSize := 384; (: 95% +/-5% confidence :)
declare variable $sampleThreshold := 1000;


declare function local:sampleFs() {
  local:sampleFs( xdmp:database-name(xdmp:database()) )
};

declare function local:sampleFs($databaseName) {

  (: TODO -- Handle error case where user has insufficient eval privileges :)
  let $out := xdmp:javascript-eval('

let checkUserLib = require("/server/lib/check-user-lib.xqy");
let cfg = require("/server/lib/config.xqy");
let constlib = require("/server/lib/const.xqy");

//let sampleSize = 384; // (: 95% +/-5% confidence :)
//let sampleThreshold = 1000;


let HSVtoRGB = function(h, s, v) {
    let i = math.floor(h * 6);
    let f = h * 6 - i;
    let p = v * (1 - s);
    let q = v * (1 - f * s);
    let t = v * (1 - (1 - f) * s);
    switch (i % 6) {
      case 0: return [ fn.round(v * 255), fn.round(t * 255), fn.round(p * 255) ]
      case 1: return [ fn.round(q * 255), fn.round(v * 255), fn.round(p * 255) ]
      case 2: return [ fn.round(p * 255), fn.round(v * 255), fn.round(t * 255) ]
      case 3: return [ fn.round(p * 255), fn.round(q * 255), fn.round(v * 255) ]
      case 4: return [ fn.round(t * 255), fn.round(p * 255), fn.round(v * 255) ]
      case 5: return [ fn.round(v * 255), fn.round(p * 255), fn.round(q * 255) ]
      default: return (255,255,255)
    }
};

let codeToHex = function(rgbColors) {
  let hex = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"];
  let values = [
    math.floor(rgbColors[0] / 16) + 1, rgbColors[0] - (math.floor(rgbColors[0] / 16)*16),
    math.floor(rgbColors[1] / 16) + 1, rgbColors[1] - (math.floor(rgbColors[1] / 16)*16),
    math.floor(rgbColors[2] / 16) + 1, rgbColors[2] - (math.floor(rgbColors[2] / 16)*16)
  ]
  return "#"
    + hex[values[0]] + hex[values[1]]
    + hex[values[2]] + hex[values[3]]
    + hex[values[4]] + hex[values[5]];
};

let hexToInt = function(hex) {
  hex = fn.upperCase(hex);
  let value = 0;
  for (let i = 1; i <= fn.stringLength(hex); i++) {
    let letter = fn.substring(hex, i, 1);
    let number = 0;
    switch (letter) {
      case "A":
        number = 10;
        break;
      case "B":
        number = 11;
        break;
      case "C":
        number = 12;
        break;
      case "D":
        number = 13;
        break;
      case "E":
        number = 14;
        break;
      case "F":
        number = 15;
        break;
      default:
        number = parseInt(letter);
    }
    value += ((math.pow(16, i - 1)) * number);
  }

  return value;
};

let colorHash = function(stringValue) {
  let hash = xdmp.md5(stringValue);
  let len = math.floor(fn.stringLength(hash) / 3);
  // Divide hash into 3 parts, representing Hue, Saturation, and Value
  // Only generate values with higher Saturations and Values, because they prettier
  let hsv = [
    hexToInt( fn.substring(hash, (len * 0) + 1, len) ) % 256,
    156 + hexToInt( fn.substring(hash, (len * 1) + 1, len) ) % 100,
    156 + hexToInt( fn.substring(hash, (len * 2) + 1, len) ) % 100
  ];
  let rgb = HSVtoRGB(hsv[0] / 256, hsv[1] / 256, hsv[2] / 256);
  let rgbhex = codeToHex(rgb);
  return rgbhex
};

let getDocTypes = function(knownDocTypes) {

  let docTypes = [];

  // Skip stuff we already know about
  let negations = [];
  for (let k in knownDocTypes) {
    if (k instanceof xs.QName) {
      negations.push( cts.notQuery(cts.elementQuery(k, cts.andQuery([]))) );
    } else if (fn.matches(k,"XMLELEMENT")) {
      try {
        let element = xs.QName(fn.tokenize(k, "\\|").toArray()[0]);
        negations.push( cts.notQuery(cts.elementQuery(element, cts.andQuery([]))) );
        } catch (e) {
          // No negation; nothing to do
        }
    } else if (fn.matches(k, "\\|")) {
      let ext = fn.tokenize(k, "\\|").toArray().reverse()[0];
      if (ext) {
        negations.push( cts.notQuery(cts.elementQuery(element, cts.andQuery([]))) );
      }
    }
  }

  // See how much we have left
  let numDocs = cts.estimate(cts.andQuery( negations ));

  // Build a dataset of relevant URIs
  let dataset = null;
  if (numDocs > sampleThreshold) {
    dataset = fn.subsequence(cts.search(cts.andQuery(negations), "score-random" ), 1, sampleSize).toArray().map(function(d){ return fn.baseUri(d) });
  } else {
    dataset = cts.search(cts.andQuery(negations)).toArray().map(function(d){ return fn.baseUri(d) });
  }

  // Categorize the dataset
  for (let uri of dataset) {
    let contentType = (uri) ? xdmp.uriContentType(uri) : null;
    let extension = (fn.matches(uri, "\\.")) ? (fn.tokenize(uri, "\\.").toArray().reverse()[0]) : null;

    if (fn.matches(contentType,"/xml")) {
      docTypes.push( fn.nodeName(cts.doc(uri).xpath("/element()")) + "|XMLELEMENT" );
    } else if (fn.matches(contentType, "/x-unknown-content-type")) {
      docTypes.push( contentType );
    } else {
      docTypes.push( fn.stringJoin([contentType,((extension) ? (extension) : null)], "|") );
    }

  }

 return docTypes;
};

// Get all the document types
let docTypes = [];
for (let i = 1; i <= 3; i++) { //3
  docTypes = docTypes.concat( getDocTypes(docTypes) );
  docTypes = [...new Set(docTypes)];
}

// Count each type of document
let numDocs = {};
let ambiguousTypes = [];
for (let d of docTypes) {
  let extension = null;
  let rootElement = null;
  let contentType = null;
  if (fn.matches(d, "\\|")) {
    extension = fn.tokenize(d, "\\|").toArray().reverse()[0];
    if (extension == "XMLELEMENT") {
      extension = null;
      rootElement = fn.tokenize(d, "\\|").toArray()[0];
    }
  } else {
    contentType = d;
  }

  // Doctype counts
  if (extension) {
    numDocs[extension] = fn.count(cts.uriMatch("*." + extension));
  } else if (fn.contains(d, "x-unknown-content-type")) {
    numDocs[d] = 999; // (: TODO logic :)
    ambiguousTypes.push(d);
  } else if (rootElement) {
    try {
      numDocs[rootElement] = cts.estimate(cts.andQuery([ cts.elementQuery(xs.QName(rootElement), cts.andQuery([])) ]));
    } catch (e) {
      ambiguousTypes.push(rootElement);
    }
  } else if (contentType) {
    numDocs[contentType] = 888; // TODO logic
    ambiguousTypes.push(contentType);
  } else {
    numDocs[d] = 777; // TODO logic
    ambiguousTypes.push(d);
  }

}

// Resolve ambiguous types, on average // TODO statistically sample db for better count
if (ambiguousTypes) {
  let totalDocs = cts.estimate(cts.andQuery([]));
  let knownTypes = Object.keys(numDocs).filter(x => !ambiguousTypes.includes(x) );
  let subtotal = totalDocs;
  for (let k of knownTypes) {
    subtotal -= numDocs[k];
  }
  for (let a of ambiguousTypes) {
    numDocs[a] = subtotal / ambiguousTypes.length;
  }
}

// Build graphviz output format
let graphVizOutput = [];
for (let name of Object.keys(numDocs)) {
  let item = {};
  item.name = name;
  item.value = numDocs[name];
  item.color = colorHash(name);
  graphVizOutput.push(item);
}

// When empty, set this as default
if (graphVizOutput.length <= 0) {
  graphVizOutput.push({
    "id": "X",
    "name": "Empty",
    "color": "#DFDFDF",
    "value": 1
  });
}

// Order by frequency
graphVizOutput.sort((a, b) => a.value < b.value );
for (let ii = 0; ii < graphVizOutput.length; ii++) { graphVizOutput[ii].id = ii; }


graphVizOutput

    ', (
      xs:QName("sampleSize"), $sampleSize,
      xs:QName("sampleThreshold"), $sampleThreshold
    ),

    <options xmlns="xdmp:eval">
      <database>{xdmp:database($databaseName)}</database>
    </options>
  )

  return $out
};





if (check-user-lib:is-logged-in() and (check-user-lib:is-wizard-user()))
then (
  let $database := map:get($cfg:getRequestFieldsMap, "dbName")
  let $database := if ( fn:empty($database) ) then ("Documents") else xdmp:url-decode($database)
  return
    if ($database and fn:string-length($database) gt 0 and $database ne "undefined") then (
      local:sampleFs($database)
    ) else (
      local:sampleFs()
    )
)
else (xdmp:set-response-code(401, "User is not authorized."))


