<div class="alert">
  <button type="button" class="close" data-dismiss="alert">&times;</button>
  The ORCID Feed service is experimental and features currently change frequently. Please report problems or missing features <a href="https://github.com/ORCID-EU-Labs/orcid-feed/issues">here</a>.
</div>

## Introduction

The ORCID Registry provides information in a user's profile as webpage or via API. The ORCID API currently supports the standard XML and JSON format. ORCID Feed provides profile information in additional formats by parsing and translating the JSON response from the ORCID public API.

ORCID Feed is inspired by the [content negotiation for DOIs](http://crosscite.org/cn/) provided by CrossRef and DataCite, and ORCID Feeds uses many of their concepts, as well as language on this page.

## What is Content Negotiation?

Content negotiation allows a user to request a particular representation of a web resource. ORCID Feed uses content negotation to provide different representations of metadata associated with ORCIDs. A content negotiated request is much like a standard HTTP request, except server-driven negotiation will take place based on the list of acceptable content types a client provides.

### Accept Header

Making a content negotiated request requires the use of a HTTP header, "Accept", with a content type that is acceptable to the client ( that it knows how to parse). For example, a client that wishes to receive citeproc JSON would make a request with an Accept header "application/json":


    $ curl -LH "Accept: application/json" http://feed.labs.orcid-eu.org/0000-0002-1825-0097

    [
      {
        "title": "Correction and Clarifications",
        "volume": "9",
        "URL": "http://dx.doi.org/10.5555/3030303030x",
        "DOI": "10.5555/3030303030x",
        "issue": "11",
        "container-title": "Journal of Psychoceramics",
        "publisher": "CrossRef test user",
        "author": [
          {
            "family": "Carberry",
            "given": "Josiah"
          }
        ],
        "page": "1-3",
        "id": "carberry2012a",
        "type": "article-journal",
        "issued": {
          "date-parts": [
            [
              2012,
              12
            ]
          ]
        }
      },
      ...
    ]

### File extension and Query Parameters

Many requests for ORCID content in different formats will be made by web browers and RSS readers, and they can't easily modify the "Accept" header. ORCID Feed therefore also allows the use of a file extension such as `.json` or a query parameter such as `?format=json`.

    $ curl http://feed.labs.orcid-eu.org/0000-0002-1825-0097.json

    $ curl http://feed.labs.orcid-eu.org/0000-0002-1825-0097?format=json

### Response Codes

<table class="table">
<thead>
<tr><th>Code</th><th>Meaning</th></tr>
</thead>
<tbody>
<tr><td>200</td><td>The request was OK.</td></tr>
<tr><td>404</td><td>The ORCID requested doesn't exist.</td></tr>
<tr><td>406</td><td>Can't serve the requested content type.</td></tr>
</tbody>
</table>

## Supported Content Types

ORCID Feed currently supports the content types listed below. Most of them are also supported by DOI content negotiation with CrossRef and DataCite.

<table class="table">
<thead>
<tr><th>Format</th><th>Extension</th><th>Content Type</th><th>ORCID</th><th>CrossRef</th><th>DataCite</th></tr>
</thead>
<tbody>
<tr><td><a href='http://web.resource.org/rss/1.0/spec'>RSS 1.0</a></td><td>.rss</td><td>application/rss+xml</td><td><span class='label label-success'>Yes</span></td><td><span class='label'>No</span></td><td><span class='label'>No</span></td></tr>
<tr><td><a href='http://gsl-nagoya-u.net/http/pub/citeproc-doc.html'>Citeproc JSON</a></td><td>.json</td><td>application/json</td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td></tr>
<tr><td><a href='http://gsl-nagoya-u.net/http/pub/citeproc-doc.html'>Citeproc YAML</a></td><td>.yml</td><td>application/x-yaml</td><td><span class='label label-success'>Yes</span></td><td><span class='label'>No</span></td><td><span class='label'>No</span></td></tr>
<tr><td><a href='http://en.wikipedia.org/wiki/BibTeX'>BibTeX</a></td><td>.bib</td><td>application/x-bibtex</td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td></tr>
<tr><td><a href='http://citationstyles.org/'>Formatted text citation</a><td>.txt</td></td><td>text/x-bibliography</td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td><td><span class='label label-success'>Yes</span></td></tr>
</tbody>
</table>

## Formatted Citations

ORCID Feed supports formatted citations via the text/bibliography content type. These are the output of the Citation Style Language processor citeproc-ruby. The content type can take an additional parameters to customise its response format. A "style" can be chosen from the list of style names found in the [CSL style repository](https://github.com/citation-style-language/styles/). Many styles are supported, including common styles such as **apa** and **mla**:

    $ curl -LH "Accept: text/x-bibliography; style=apa" http://feed.labs.orcid-eu.org/0000-0002-1825-0097

    Carberry, J. (2012). Correction and Clarifications. Journal of Psychoceramics, 9(11), 1-3. doi:10.5555/3030303030x
    Carberry, J. (2012). The Memory Bus Considered Harmful. Journal of Psychoceramics, 9(11), 1-3. doi:10.5555/666655554444
    Carberry, J. (2011). The Impact of Interactive Epistemologies on Cryptography. Journal of Psychoceramics, 8(11), 1-3. doi:10.5555/987654321
    Carberry, J. (2008). Developing Thin Clients Using Amphibious Epistemologies. Journal of Psychoceramics, 5(11), 1-3. doi:10.5555/12345679
    Carberry, J. (2008). Toward a Unified Theory of High-Energy Metaphysics: Silly String Theory. Journal of Psychoceramics, 5(11), 1-3. doi:10.5555/12345678

## Getting Help

Please report problems or missing features [here](https://github.com/ORCID-EU-Labs/orcid-feed/issues).
