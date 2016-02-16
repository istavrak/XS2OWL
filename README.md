# XS2OWL
The XS2OWL framework aims to support semantic interoperability between the Semantic Web and XML environments. In particular, it supports the automatic transformation of XML Schemas in OWL syntax.

## Technical details
It has been implemented as an XSLT stylesheet which takes as input the XML Schema file (.xsd) that will be transformed to OWL.

### How to use it

You can apply the XSLT file on an XSD using the open-source Saxon-HE from [saxonica](http://www.saxonica.com/products/products.xml) from command line:
```$ java -jar saxon9he.jar -s:example.xsd -xsl:XS2OWL/xs2owl2.0.10.xsl
```
It will produce 2 files, i.e. main.owl and owl2xml.owl.


### The XS2OWL transformation generates two ontologies
* A main ontology that represents the XML Schema constructs using OWL constructs.
* A mapping ontology that associates the names of the XML Schema constructs with the IDs of the equivalent main ontology constructs and captures any information present in the XML Schema that cannot be captured in the main ontology due to the expressivity limitations of the OWL 2.0 syntax.

### XS2OWL Framework Key features
* Uplifts XML Schema 1.0 and XML Schema 1.1 to OWL 2.0 syntax.
* Allows to down lift from the generated ontology to the original XML Schema.
* Captures the semantics of the unique, key and keyref XML identity constraints.
* Includes an XPath Evaluator, which is able to evaluate an XPath expression over the XML Schema, since the XPath expressions do not refer to the node hierarchy of the XML Schema but in the node structure of the XML data following it.

## Citation
*The SPARQL2XQuery interoperability framework*:
N. Bikakis, C. Tsinaraki, I. Stavrakantonakis, N. Gioldasis, S. Christodoulakis. World Wide Web 18 (2), 403-490.
