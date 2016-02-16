<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xdt="http://www.w3.org/2005/xpath-datatypes" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:owl="http://www.w3.org/2002/07/owl" xmlns:self="xs2owl2.0.10.xsl">
	<!-- Lab. Of Distributed Multimedia Information Systems And Applications (MUSIC)
	     Technical University of Crete (TUC) 
		 Researchers: Chrisa Tsinaraki, Ioannis Stavrakantonakis
		 Version:2.0.10
		 License: MIT License
	-->
	<xsl:output media-type="text/xml" version="1.0" encoding="UTF-8" indent="yes" use-character-maps="owl"/>
	<xsl:strip-space elements="*"/>
	<xsl:character-map name="owl">
		<xsl:output-character character="&amp;" string="&amp;"/>
	</xsl:character-map>
	<xsl:variable name="not_specified" select="'NS'"/>
	
	<!-- Obsolete -->
	<xsl:variable name="datatype_entity_name" select="'datatypes'"/>
	
	<xsl:variable name="schema_element" select="/xsd:schema"/>
	
	<xsl:variable name="target_namespace">
		<xsl:value-of select="/xsd:schema/@targetNamespace"/>
	</xsl:variable>

	<xsl:variable name="named_simple_type_names" as="xsd:string">
		<xsl:variable name="val">
			<xsl:for-each select="//xsd:simpleType">
				<xsl:value-of select="concat(' ',string(./@name),' ')"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="string($val)"/>
	</xsl:variable>
	
	<xsl:variable name="named_elements" as="xsd:string">
		<xsl:variable name="val_elem">
			<xsl:for-each select="//xsd:element">
				<xsl:value-of select="concat(' ',string(./@name),'%',string(./@type),' ')"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="normalize-space(string($val_elem))"/>
	</xsl:variable>
	
	<xsl:variable name="named_groups">
		<xsl:variable name="val_groups">
			<xsl:for-each select="//xsd:group/descendant::xsd:element">
				<xsl:variable name="tempGroupName">
					<xsl:value-of select="./ancestor::xsd:group/@name"/>
				</xsl:variable>
				<xsl:value-of select="concat(' ',string($tempGroupName),'%',string(./@name),'#',string(./@type))"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="normalize-space(string($val_groups))"/>
	</xsl:variable>
	
	<xsl:variable name="classes_keys_hashtable">
		<xsl:variable name="elements_with_key_unique">
			<xsl:for-each select="//xsd:element/descendant::xsd:key | //xsd:element/descendant::xsd:unique">
				<xsl:variable name="HasKeyValue" select="self:HasKey(.,./ancestor::xsd:element/@name,./ancestor::xsd:element/@type)"/>
				<xsl:variable name="key" select="self:XPath_selectorRange_to_classID(./xsd:selector/@xpath)"/>
				<xsl:value-of select="concat(',','key:', $key ,',',$HasKeyValue)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring(normalize-space(string($elements_with_key_unique)),2)"/>
	</xsl:variable>
	
	<xsl:variable name="properties_referTo_hashtable">
		<xsl:variable name="elements_with_keyref">
			<xsl:for-each select="//xsd:element/descendant::xsd:keyref">
				<xsl:variable name="SelectorProperty" select="self:XPath_selector_to_propertyID(./xsd:selector/@xpath)"/>
				<xsl:variable name="Refer" select="./@refer"/>
				<xsl:variable name="Key" select="//xsd:element/descendant::xsd:key[./@name=$Refer]"></xsl:variable>
				<xsl:variable name="SelectorRange_Class" select="self:XPath_selectorRange_to_classID($Key/xsd:selector/@xpath)"/>
				<xsl:value-of select="concat(',','key:', $SelectorProperty ,',',$SelectorRange_Class)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="substring(normalize-space(string($elements_with_keyref)),2)"/>
	</xsl:variable>
	
	<xsl:variable name="xsd_namespaces">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:variable name="name" select="./name()"/>
			<xsl:choose>
				<xsl:when test="string(.)='http://www.w3.org/2001/XMLSchema'">
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="string(' ')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:variable>
	
	<xsl:variable name="equivalent_target_namespaces">
		<xsl:for-each select="/xsd:schema/namespace::*">
			<xsl:variable name="name" select="./name()"/>
			<xsl:choose>
				<xsl:when test=".=$target_namespace">
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="string(' ')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:variable>
	
	<xsl:variable name="is_empty_namespace_xsd" as="xsd:boolean">
		<xsl:variable name="empty_namespace_xsd" select="/xsd:schema/namespace::*[string(name())='' and string(.)='http://www.w3.org/2001/XMLSchema']"/>
		<xsl:choose>
			<xsl:when test="string($empty_namespace_xsd)=''">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="true()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- ###############################################################-->
	<!-- ######					Function Definitions    		  ######-->
	<!-- ###############################################################-->
	<!-- Function that allows escaping a string -->
	<xsl:function name="self:escape" as="xsd:string">
		<xsl:param name="input"/>
		<xsl:value-of select="replace(replace(replace(replace(replace(replace($input,'&amp;','&amp;amp;'),'&gt;','&amp;gt;'),'&lt;','&amp;lt;'),'&quot;','&amp;quot;'),'&#x21;','&amp;#x21;'),'&#x7f;','&amp;#x7f;')"/>
	</xsl:function>
	<!-- Function that produces the Entity Definitions in the beginning of the document -->
	<xsl:function name="self:entity_definition" as="xsd:string">
		<xsl:param name="schema"/>
		<xsl:variable name="start">
			<xsl:value-of select="concat(string('&#10;&lt;!DOCTYPE rdf:RDF [&#10;'),
			string('&#9;&lt;!ENTITY xsd &quot;http://www.w3.org/2001/XMLSchema#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY owl &quot;http://www.w3.org/2002/07/owl#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY rdf &quot;http://www.w3.org/1999/02/22-rdf-syntax-ns#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY rdfs &quot;http://www.w3.org/2000/01/rdf-schema#&quot;&gt;&#10;'))"/>
		</xsl:variable>
		<xsl:variable name="rest">
			<xsl:for-each select="$schema/namespace::*[not(name()='' or name()='xsd')]">
				<xsl:variable name="uri">
					<xsl:choose>
						<xsl:when test=". = $target_namespace">
							<xsl:value-of select="string('#')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="not(contains(.,'#'))">
									<xsl:value-of select="concat(.,'#')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="."/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="concat('&#9;&lt;!ENTITY&#9;',name(),' &quot;',$uri,string('&quot;&gt;&#10;'))"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="concat($start,$rest,string(']&gt;&#10;'))"/>
	</xsl:function>
	<!-- Function that produces Namespace Declarations in the rdf:RDF element -->
	<xsl:function name="self:namespace_declaration" as="xsd:string">
		<xsl:param name="target_namespace"/>
		<xsl:param name="namespace"/>
		<xsl:variable name="namespace_name">
			<xsl:value-of select="$namespace/name()"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$namespace_name = ''">
				<xsl:sequence select="string(' xmlns:xsd=&quot;&amp;xsd;&quot;')"/>
			</xsl:when>
			<xsl:when test="$namespace_name = 'xml' or $namespace_name = 'xsd'">
				<xsl:sequence select="string(' ')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="uri">
					<xsl:choose>
						<xsl:when test="$namespace = $target_namespace">
							<xsl:value-of select="string('#')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="not(contains($namespace,'#'))">
									<xsl:value-of select="concat($namespace, '#')"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$namespace"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:sequence select="concat(string(' xmlns:'),string($namespace_name), string('=&quot;'), string($uri), string('&quot;'))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces RDF URI references from XSD URI references -->
	<xsl:function name="self:rdf_uri_from_xsd_uri" as="xsd:string">
		<xsl:param name="xsd_uri"/>
		<xsl:sequence select="concat(string('&amp;'),substring-before($xsd_uri,':'),string(';'),substring-after($xsd_uri,':'))"/>
	</xsl:function>
	<!-- Function that produces subclassOf elements -->
	<xsl:function name="self:subclass_of">
		<xsl:param name="class"/>
		<xsl:param name="is_simple_type_descendant"/>
		<xsl:variable name="baseClass" select="if ($is_simple_type_descendant=false()) then $class/xsd:complexContent/xsd:extension/@base else $class/xsd:simpleContent/xsd:restriction/@base"/>
		<xsl:choose>
			<xsl:when test="contains($baseClass,':')">
				<xsl:value-of select="concat(string('&lt;rdfs:subClassOf rdf:resource=&quot;'),self:rdf_uri_from_xsd_uri($baseClass),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
			</xsl:when>
			<xsl:when test="not(string($baseClass)='')">
				<xsl:sequence select="concat(string('&lt;rdfs:subClassOf rdf:resource=&quot;#'),$baseClass,string('&quot;/&gt;&#10;&#9;&#9;'))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="string('')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces rdfs:label elements -->
	<xsl:function name="self:label" as="xsd:string">
		<xsl:param name="text"/>
		<xsl:sequence select="concat(string('&lt;rdfs:label&gt;'),string($text),string('&lt;/rdfs:label&gt;&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces rdfs:comment elements -->
	<xsl:function name="self:comment" as="xsd:string">
		<xsl:param name="text"/>
		<xsl:sequence select="concat(string('&lt;rdfs:comment&gt;'),self:escape(string($text)),string('&lt;/rdfs:comment&gt;&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces xml comments -->
	<xsl:function name="self:xml_comment" as="xsd:string">
		<xsl:param name="text"/>
		<xsl:sequence select="concat(string('&lt;!--&#9;'),string($text),string('&#9;--&gt;&#10;&#9;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces xml comments enclosed in lines of line_elements -->
	<xsl:function name="self:enclosed_xml_comment" as="xsd:string">
		<xsl:param name="text"/>
		<xsl:param name="line_element"/>
		<xsl:param name="length"/>
		<xsl:variable name="line">
			<xsl:for-each select="1 to $length">
				<xsl:value-of select="$line_element"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:sequence select="concat(self:xml_comment($line),self:xml_comment($text),self:xml_comment($line))"/>
	</xsl:function>
	<!-- Function that produces the functional property type -->
	<xsl:function name="self:functional_property" as="xsd:string">
		<xsl:sequence select="string('&lt;rdf:type rdf:resource=&quot;&amp;owl;FunctionalProperty&quot;/&gt;&#10;&#9;&#9;')"/>
	</xsl:function>
	<!-- Function that produces the "class_name" class as domain -->
	<xsl:function name="self:domain" as="xsd:string">
		<xsl:param name="class_name"/>
		<xsl:sequence select="concat(string('&lt;rdfs:domain rdf:resource=&quot;#'),string($class_name),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
	</xsl:function>
	
	<!-- Function that produces the "type" as range -->
	<xsl:function name="self:object_property_range" as="xsd:string">
		<xsl:param name="type"/>
		<xsl:choose>
			<xsl:when test="not($type='')">
				<xsl:choose>
					<xsl:when test="contains($type,':')">
						<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;'),self:rdf_uri_from_xsd_uri($type),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;#'),string($type),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="string('')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces unique property names -->
	<xsl:function name="self:property_name" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="class"/>
		<xsl:variable name="type" select="$element/@type"/>
		<xsl:choose>
			<xsl:when test="contains($type,':')">
				<xsl:value-of select="concat($element/@name,'__',substring-before($type,':'),'_',substring-after($type,':'))"/>
			</xsl:when>
			<xsl:when test="string($type)=''">
				<xsl:value-of select="concat($element/@name,'__',$class,'_',$element/@name,'_UNType')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($element/@name,'__',$type)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that guesstimates unique property names 
		 Params name: Name of property(string)
		 		type: Type of property(string)
		 		group: Group name of property(string)
	-->
	<xsl:function name="self:property_name_guesstimate" as="xsd:string">
		<xsl:param name="name"/>
		<xsl:param name="type"/>
		<xsl:param name="group"/>
		<xsl:choose>
			<xsl:when test="string($group)=''">
				<xsl:choose>
					<xsl:when test="contains($type,':')">
						<xsl:value-of select="concat($name,'__',replace($type,':','_'))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat($name,'__',$type)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($name,'_',$group,'__',replace($type,':','_'))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that checks if an owl:cardinality restriction should be generated for the property "property"-->
	<xsl:function name="self:group_attribute_cardinality" as="xsd:string">
		<xsl:param name="property"/>
		<xsl:param name="grp_name"/>
		<xsl:param name="schema"/>
		<xsl:variable name="property_ref" select="string($property/@ref)"/>
		<xsl:variable name="attribute_use" select="$property/@use"/>
		<xsl:variable name="attribute_name">
			<xsl:choose>
				<xsl:when test="string($property_ref)=''">
					<xsl:variable name="type">
						<xsl:choose>
							<xsl:when test="nilled($property/xsd:simpleType)=false()">
								<xsl:value-of select="self:unnamed_datatype_name($not_specified, concat($property/@name,'_',$grp_name))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$property/@type"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:value-of select="concat('#',self:property_from_group_name(string($property/@name),$grp_name,$type))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($property_ref,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($property_ref)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($property_ref)],$not_specified))"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$attribute_use='required'">
				<xsl:sequence select="self:sub_class_content(self:cardinality_restriction($attribute_name,1))"/>
			</xsl:when>
			<xsl:when test="$attribute_use='prohibited'">
				<xsl:sequence select="self:sub_class_content(self:cardinality_restriction($attribute_name,0))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="self:sub_class_content(self:max_cardinality_restriction($attribute_name,1))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces has_value restrictions for choices and sequences-->
	<xsl:function name="self:expand_fixed_values" as="xsd:string">
		<xsl:param name="seq_choice"/>
		<xsl:param name="class_name"/>
		<xsl:variable name="ret">
			<xsl:for-each select="$seq_choice/xsd:element[not(string(./@fixed)='')]">
				<xsl:value-of select="self:fixed_value(.,$class_name)"/>
			</xsl:for-each>
			<xsl:for-each select="$seq_choice/xsd:choice, $seq_choice/xsd:sequence">
				<xsl:value-of select="self:expand_fixed_values(.,$class_name)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="$ret"/>
	</xsl:function>
	<!-- Function that checks if an owl:hasValue restriction should be generated for the property "property"-->
	<xsl:function name="self:fixed_value" as="xsd:string">
		<xsl:param name="property"/>
		<xsl:param name="class"/>
		<xsl:variable name="property_fixed" select="string($property/@fixed)"/>
		<xsl:variable name="property_ref" select="string($property/@ref)"/>
		<xsl:variable name="attribute_name">
			<xsl:choose>
				<xsl:when test="string($property_ref)=''">
					<xsl:value-of select="concat('#',self:property_name($property,$class))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($property_ref,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($property_ref)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',$property_ref)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:sequence select="self:sub_class_content(self:hasValue($attribute_name,$property_fixed))"/>
	</xsl:function>
	<!-- Function that checks if an owl:cardinality restriction should be generated for the property "property"-->
	<xsl:function name="self:attribute_cardinality" as="xsd:string">
		<xsl:param name="property"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="property_ref" select="string($property/@ref)"/>
		<xsl:variable name="attribute_use" select="$property/@use"/>
		<xsl:variable name="attribute_name">
			<xsl:choose>
				<xsl:when test="string($property_ref)=''">
					<xsl:value-of select="concat('#',self:property_name($property,$class))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($property_ref,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($property_ref)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($property_ref)],$not_specified))"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$attribute_use='required'">
				<xsl:sequence select="self:sub_class_content(self:cardinality_restriction($attribute_name,1))"/>
			</xsl:when>
			<xsl:when test="$attribute_use='prohibited'">
				<xsl:sequence select="self:sub_class_content(self:cardinality_restriction($attribute_name,0))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="self:sub_class_content(self:max_cardinality_restriction($attribute_name,1))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that takes the "minOccurs" value of an element  -->
	<xsl:function name="self:min_occurs" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:variable name="mo">
			<xsl:value-of select="$element/@minOccurs"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$mo='' or nilled($mo)">
				<xsl:value-of select="string(1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$mo"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that takes the "maxOccurs" value of an element  -->
	<xsl:function name="self:max_occurs" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:variable name="mo">
			<xsl:value-of select="$element/@maxOccurs"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="($mo='' or nilled($mo))">
				<xsl:value-of select="string(1)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$mo"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- function that returns the produced name of an element -->
	<xsl:function name="self:produced_element_name" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="class"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="ref" select="string($element/@ref)"/>
		<xsl:choose>
			<xsl:when test="$ref=''">
				<xsl:choose>
					<xsl:when test="string($group_name)=''">
						<xsl:value-of select="concat('#',self:property_name($element,$class))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="element_type" select="if (string($element/@type)='') then  self:unnamed_datatype_name($not_specified, concat($element/@name,'_',$group_name)) else string($element/@type)"/>
						<xsl:value-of select="concat('#',self:property_from_group_name($element/@name,$group_name,$element_type))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="contains($ref,':')">
						<xsl:value-of select="self:rdf_uri_from_xsd_uri($ref)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="actual_element" select="$schema_element/xsd:element[string(./@name)=$ref]"/>
						<xsl:value-of select="concat('#',self:property_name($actual_element,$not_specified))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that checks if a cardinality restriction should be generated for the property representing the sequence element "element" -->
	<xsl:function name="self:sequence_element_cardinality" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="sequence_min_occurs"/>
		<xsl:param name="sequence_max_occurs"/>
		<xsl:param name="class"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="element_name" select="self:produced_element_name($element,$class,$schema_element,$group_name)"/>
		<xsl:variable name="element_min_occurs" select="self:min_occurs($element)"/>
		<xsl:variable name="element_max_occurs" select="self:max_occurs($element)"/>
		<xsl:variable name="total_min_occurs" select="number($element_min_occurs)*number($sequence_min_occurs)"/>
		<xsl:choose>
			<xsl:when test="not(string($sequence_max_occurs)='unbounded' or string($element_max_occurs)='unbounded')">
				<xsl:variable name="total_max_occurs" select="number($element_max_occurs)*number($sequence_max_occurs)"/>
				<xsl:sequence select="if ($total_min_occurs=$total_max_occurs) then
				self:cardinality_restriction($element_name,number($total_min_occurs))
				else if (number($element_min_occurs)=0) then string(self:max_cardinality_restriction($element_name,number($total_max_occurs)))
				else if ((number($sequence_min_occurs)=number($sequence_max_occurs)) or (number($element_max_occurs)-number($element_min_occurs)>=number($element_min_occurs))) then concat(self:min_cardinality_restriction($element_name,number($total_min_occurs)),self:max_cardinality_restriction($element_name,number($total_max_occurs)))
				else self:exact_seq_element_cardinality($element_name,$sequence_min_occurs,$sequence_max_occurs,$element_min_occurs,$element_max_occurs)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="if ($total_min_occurs=0) then string('')
				else self:min_cardinality_restriction($element_name,number($total_min_occurs))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces exact min and max cardinality restrictions for elements with max<> min -->
	<xsl:function name="self:exact_seq_element_cardinality" as="xsd:string">
		<xsl:param name="element_name"/>
		<xsl:param name="seq_min"/>
		<xsl:param name="seq_max"/>
		<xsl:param name="el_min"/>
		<xsl:param name="el_max"/>
		<xsl:variable name="lmin" as="xsd:integer">
			<xsl:value-of select="$seq_min"/>
		</xsl:variable>
		<xsl:variable name="lmax" as="xsd:integer">
			<xsl:value-of select="$seq_max"/>
		</xsl:variable>
		<xsl:variable name="ret">
			<xsl:for-each select="$lmin to $lmax">
				<xsl:choose>
					<xsl:when test="number($el_min)*number(.)=number($el_max)*number(.)">
						<xsl:value-of select="self:cardinality_restriction($element_name,number(number($el_max)*number(.)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:unnamed_intersection_class(concat(self:min_cardinality_restriction($element_name,number(number($el_min)*number(.))),self:max_cardinality_restriction($element_name,number(number($el_max)*number(.)))))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="self:unnamed_union_class($ret)"/>
	</xsl:function>
	<!-- Function that produces owl:hasValue restrictions on property "property_name"-->
	<xsl:function name="self:hasValue" as="xsd:string">
		<xsl:param name="property_name"/>
		<xsl:param name="value"/>
		<xsl:variable name="before_pname" as="xsd:string" select="string-join((string('&lt;owl:Restriction&gt;'),string('&lt;owl:onProperty rdf:resource=&quot;')), string('&#10;&#9;&#9;&#9;&#9;'))"/>
		<xsl:variable name="after_pname" as="xsd:string" select="string-join((string('&quot;/&gt;'),string('&lt;owl:hasValue&gt;')),string('&#10;&#9;&#9;&#9;&#9;'))"/>
		<xsl:variable name="after_cvalue" as="xsd:string" select="string-join((string('&lt;/owl:hasValue&gt;'),string('&lt;/owl:Restriction&gt;')),string('&#10;&#9;&#9;&#9;'))"/>
		<xsl:value-of select="concat(string($before_pname),string($property_name),string($after_pname),string($value),string($after_cvalue),string('&#10;&#9;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces owl:cardinality restrictions on property "property_name"-->
	<xsl:function name="self:cardinality_restriction" as="xsd:string">
		<xsl:param name="property_name"/>
		<xsl:param name="cardinality_value"/>
		<xsl:variable name="before_pname" as="xsd:string" select="string-join((string('&lt;owl:Restriction&gt;'),string('&lt;owl:onProperty rdf:resource=&quot;')), string('&#10;&#9;&#9;&#9;&#9;'))"/>
		<xsl:variable name="after_pname" as="xsd:string" select="string-join((string('&quot;/&gt;'),string('&lt;owl:cardinality rdf:datatype=&quot;&amp;xsd;nonNegativeInteger&quot;&gt;')),string('&#10;&#9;&#9;&#9;&#9;'))"/>
		<xsl:variable name="after_cvalue" as="xsd:string" select="string-join((string('&lt;/owl:cardinality&gt;'),string('&lt;/owl:Restriction&gt;')),string('&#10;&#9;&#9;&#9;'))"/>
		<xsl:value-of select="concat(string($before_pname),string($property_name),string($after_pname),string($cardinality_value),string($after_cvalue),string('&#10;&#9;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces owl:minCardinality restrictions on property "property_name"-->
	<xsl:function name="self:min_cardinality_restriction" as="xsd:string">
		<xsl:param name="property_name"/>
		<xsl:param name="cardinality_value"/>
		<xsl:variable name="before_pname" as="xsd:string">
			<xsl:value-of select="string-join((string('&lt;owl:Restriction&gt;'),string('&lt;owl:onProperty rdf:resource=&quot;')), string('&#10;&#9;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="after_pname" as="xsd:string">
			<xsl:value-of select="string-join((string('&quot;/&gt;'),string('&lt;owl:minCardinality rdf:datatype=&quot;&amp;xsd;nonNegativeInteger&quot;&gt;')),string('&#10;&#9;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="after_cvalue" as="xsd:string">
			<xsl:value-of select="string-join((string('&lt;/owl:minCardinality&gt;'),string('&lt;/owl:Restriction&gt;')),string('&#10;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($before_pname),string($property_name),string($after_pname),string($cardinality_value),string($after_cvalue),string('&#10;&#9;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces owl:maxCardinality restrictions on property "property_name"-->
	<xsl:function name="self:max_cardinality_restriction" as="xsd:string">
		<xsl:param name="property_name"/>
		<xsl:param name="cardinality_value"/>
		<xsl:variable name="before_pname" as="xsd:string">
			<xsl:value-of select="string-join((string('&lt;owl:Restriction&gt;'),string('&lt;owl:onProperty rdf:resource=&quot;')), string('&#10;&#9;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="after_pname" as="xsd:string">
			<xsl:value-of select="string-join((string('&quot;/&gt;'),string('&lt;owl:maxCardinality rdf:datatype=&quot;&amp;xsd;nonNegativeInteger&quot;&gt;')),string('&#10;&#9;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="after_cvalue" as="xsd:string">
			<xsl:value-of select="string-join((string('&lt;/owl:maxCardinality&gt;'),string('&lt;/owl:Restriction&gt;')),string('&#10;&#9;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($before_pname),string($property_name),string($after_pname),string($cardinality_value),string($after_cvalue),string('&#10;&#9;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces subClass elements with content "content"-->
	<xsl:function name="self:sub_class_content" as="xsd:string">
		<xsl:param name="content"/>
		<xsl:variable name="before_c" as="xsd:string">
			<xsl:value-of select="string('&lt;rdfs:subClassOf&gt;&#10;&#9;&#9;&#9;')"/>
		</xsl:variable>
		<xsl:variable name="after_c" as="xsd:string">
			<xsl:value-of select="string('&lt;/rdfs:subClassOf&gt;&#10;&#9;&#9;')"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($before_c),$content,string($after_c))"/>
	</xsl:function>
	<!-- Function that produces *lite* owl:maxCardinality restrictions on choice elements-->
	<xsl:function name="self:max_cardinality_lite_for_choice" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_max_occurs"/>
		<xsl:param name="class"/>
		<xsl:variable name="choice_elements" select="count($choice/xsd:element)"/>
		<xsl:variable name="u_choice_elements" select="count($choice/xsd:element[./@maxOccurs='unbounded'])"/>
		<xsl:choose>
			<xsl:when test="$choice_elements=$u_choice_elements ">
				<xsl:value-of select="string('')"/>
			</xsl:when>
			<xsl:when test="number($choice_elements)-number($u_choice_elements)=1">
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element[not(string(./@maxOccurs)='unbounded')]">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:value-of select="self:sub_class_content(self:max_cardinality_restriction($element_name,number(self:max_occurs(.))*number($choice_max_occurs)))"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="$ret"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element[not(string(./@maxOccurs)='unbounded')]">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:value-of select="self:max_cardinality_restriction($element_name,number(self:max_occurs(.))*number($choice_max_occurs))"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="self:sub_class_content(self:unnamed_intersection_class($ret))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces *lite* cardinality restrictions on choice elements-->
	<xsl:function name="self:all_cardinalities_lite_for_choice" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_min_occurs"/>
		<xsl:param name="choice_max_occurs"/>
		<xsl:param name="class"/>
		<xsl:variable name="choice_elements" select="count($choice/xsd:element)"/>
		<xsl:variable name="ur_choice_elements" select="count($choice/xsd:element[number(./@minOccurs)=0 and ./@maxOccurs='unbounded'])"/>
		<xsl:choose>
			<xsl:when test="$choice_elements=$ur_choice_elements ">
				<xsl:value-of select="string('')"/>
			</xsl:when>
			<xsl:when test="number($choice_elements)-number($ur_choice_elements)=1">
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:choose>
							<xsl:when test="./@maxOccurs='unbounded' and number(./@minOccurs)=0">
								<xsl:value-of select="string('')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:choose>
									<xsl:when test="./@maxOccurs='unbounded'">
										<xsl:value-of select="self:sub_class_content(self:min_cardinality_restriction($element_name,number(self:min_occurs(.))*number($choice_min_occurs)))"/>
									</xsl:when>
									<xsl:when test="./@minOccurs=0">
										<xsl:value-of select="self:sub_class_content(self:max_cardinality_restriction($element_name,number(self:max_occurs(.))*number($choice_max_occurs)))"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="total_min_occurs" select="number($choice_min_occurs)*number(self:min_occurs(.))"/>
										<xsl:variable name="total_max_occurs" select="number($choice_max_occurs)*number(self:max_occurs(.))"/>
										<xsl:choose>
											<xsl:when test="$total_min_occurs=$total_max_occurs">
												<xsl:value-of select="self:sub_class_content(self:cardinality_restriction($element_name,$total_max_occurs))"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="self:sub_class_content(self:unnamed_intersection_class(concat(self:min_cardinality_restriction($element_name,$total_min_occurs),self:max_cardinality_restriction($element_name,$total_max_occurs))))"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="$ret"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="max">
					<xsl:for-each select="$choice/xsd:element">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:choose>
							<xsl:when test="./@maxOccurs='unbounded'">
								<xsl:value-of select="string('')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="self:max_cardinality_restriction($element_name,number(self:max_occurs(.))*number($choice_max_occurs))"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="min">
					<xsl:for-each select="$choice/xsd:element">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:choose>
							<xsl:when test="number(./@minOccurs)=0">
								<xsl:value-of select="string('')"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="self:min_cardinality_restriction($element_name,number(self:min_occurs(.)))"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="self:sub_class_content(self:unnamed_intersection_class(concat(self:unnamed_intersection_class($max),self:unnamed_union_class($min))))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces cardinality restrictions on choice elements-->
	<xsl:function name="self:all_cardinalities_for_choice" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_min_occurs"/>
		<xsl:param name="choice_max_occurs"/>
		<xsl:param name="class"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="choice_elements" select="count($choice/xsd:element)"/>
		<xsl:variable name="ur_choice_elements" select="count($choice/xsd:element[number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded'])"/>
		<xsl:variable name="nur_choice_elements" select="number($choice_elements)-number($ur_choice_elements)"/>
		<xsl:variable name="choice_sequences" select="count($choice/xsd:sequence)"/>
		<xsl:variable name="ur_choice_sequences" select="count($choice/xsd:sequence[number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded'])"/>
		<xsl:variable name="nur_choice_sequences" select="number($choice_sequences)-number($ur_choice_sequences)"/>
		<xsl:variable name="choice_groups" select="count($choice/xsd:group)"/>
		<xsl:variable name="ur_choice_groups" select="count($choice/xsd:group[number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded'])"/>
		<xsl:variable name="nur_choice_groups" select="number($choice_groups)-number($ur_choice_groups)"/>
		<xsl:variable name="choice_choices" select="count($choice/xsd:choice)"/>
		<xsl:variable name="ur_choice_choices" select="count($choice/xsd:choice[number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded'])"/>
		<xsl:variable name="nur_choice_choices" select="number($choice_choices)-number($ur_choice_choices)"/>
		<xsl:variable name="total" select="number($choice_elements)+number($choice_sequences)+number($choice_choices)+number($choice_groups)"/>
		<xsl:variable name="cmo" as="xsd:integer">
			<xsl:value-of select="$choice_min_occurs"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="(number($nur_choice_elements)=0 and number($nur_choice_sequences)=0 and number($nur_choice_choices)=0 and number($nur_choice_groups)=0) or (number($choice_min_occurs)=0 and string($choice_max_occurs)='unbounded')">
				<xsl:value-of select="string('')"/>
			</xsl:when>
			<xsl:when test="number($nur_choice_elements)=1 and number($nur_choice_sequences)=0 and number($nur_choice_choices)=0 and number($nur_choice_groups)=0">
				<xsl:variable name="temp">
					<xsl:for-each select="$choice/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
						<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
						<xsl:choose>
							<xsl:when test="number(./@minOccurs)=0">
								<xsl:value-of select="self:unnamed_union_class(self:max_cardinality_restriction($element_name,number(self:max_occurs(.))*number($choice_max_occurs)))"/>
							</xsl:when>
							<xsl:when test="string(./@maxOccurs)='unbounded'">
								<xsl:variable name="element" select="."/>
								<xsl:value-of select="self:unnamed_union_class(self:min_cardinality_restriction($element_name,number(self:min_occurs($element))))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="total_min_occurs" select="number($choice_min_occurs)*number(self:min_occurs(.))"/>
								<xsl:variable name="total_max_occurs" select="number($choice_max_occurs)*number(self:max_occurs(.))"/>
								<xsl:choose>
									<xsl:when test="$total_min_occurs=$total_max_occurs">
										<xsl:value-of select="self:unnamed_union_class(self:cardinality_restriction($element_name,$total_max_occurs))"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="self:unnamed_intersection_class(concat(self:min_cardinality_restriction($element_name,$total_min_occurs),self:max_cardinality_restriction($element_name,$total_max_occurs)))"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="number($total)>1">
						<xsl:variable name="zret">
							<xsl:for-each select="$choice/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
								<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
								<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_union_class(concat($zret,$temp))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$temp"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="number($nur_choice_elements)=0 and number($nur_choice_sequences)=1 and number($nur_choice_choices)=0 and number($nur_choice_groups)=0">
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:sequence[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
						<xsl:choose>
							<xsl:when test="string(./@maxOccurs)='unbounded' or string($choice_max_occurs)='unbounded'">
								<xsl:value-of select="self:sequence_cardinality(.,number($choice_min_occurs),'unbounded',$class,$schema_element,$group_name)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="self:sequence_cardinality(.,number($choice_min_occurs),number($choice_max_occurs),$class,$schema_element,$group_name)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="normalize-space(string($nz))=''">
						<xsl:value-of select="''"/>
					</xsl:when>
					<xsl:when test="number($total)>1">
						<xsl:variable name="z">
							<xsl:for-each select="$choice/xsd:sequence[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
								<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
								<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:unnamed_union_class($nz)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="number($nur_choice_elements)=0 and number($nur_choice_sequences)=0 and number($nur_choice_choices)=1 and number($nur_choice_groups)=0">
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:choice[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
						<xsl:variable name="min_occurs" select="self:min_occurs(.)"/>
						<xsl:choose>
							<xsl:when test="string(./@maxOccurs)='unbounded' or string($choice_max_occurs)='unbounded'">
								<xsl:value-of select="self:min_cardinality_for_choice(.,number($min_occurs)*number($choice_min_occurs),$class,$schema_element,$group_name)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="max_occurs" select="self:max_occurs(.)"/>
								<xsl:variable name="min_p" as="xsd:integer">
									<xsl:value-of select="number($min_occurs)*number($choice_min_occurs)">
									</xsl:value-of>
								</xsl:variable>
								<xsl:value-of select="self:all_cardinalities_for_choice(.,$min_p,number($max_occurs)*number($choice_max_occurs),$class,$schema_element,$group_name)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="normalize-space(string($nz))=''">
						<xsl:value-of select="''"/>
					</xsl:when>
					<xsl:when test="number($total)>1">
						<xsl:variable name="z">
							<xsl:for-each select="$choice/xsd:choice[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
								<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
								<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:unnamed_union_class($nz)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:when test="number($nur_choice_elements)=0 and number($nur_choice_sequences)=0 and number($nur_choice_choices)=0 and number($nur_choice_groups)=1">
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:group[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
						<xsl:choose>
							<xsl:when test="string(./@maxOccurs)='unbounded' or string($choice_max_occurs)='unbounded'">
								<xsl:value-of select="self:group_cardinality(.,number($choice_min_occurs),'unbounded',$class,$schema_element)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="self:group_cardinality(.,number($choice_min_occurs),number($choice_max_occurs),$class,$schema_element)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="normalize-space(string($nz))=''">
						<xsl:value-of select="''"/>
					</xsl:when>
					<xsl:when test="number($total)>1">
						<xsl:variable name="z">
							<xsl:for-each select="$choice/xsd:group[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
								<xsl:variable name="grp_name" select="./@name"/>
								<xsl:for-each select="./xsd:sequence[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')], ./xsd:choice[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
									<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$grp_name)"/>
									<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
								</xsl:for-each>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:unnamed_union_class($nz)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ret">
					<xsl:variable name="nz_elements" select="$choice/xsd:element[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="nu_elements" select="$choice/xsd:element[not(string(./@maxOccurs)='unbounded')]"/>
					<xsl:variable name="z_choice_elements" select="count($choice/xsd:element[number(./@minOccurs)=0])"/>
					<xsl:variable name="nz_choice_elements" select="number($choice_elements)-number($z_choice_elements)"/>
					<xsl:variable name="u_choice_elements" select="count($choice/xsd:element[string(./@maxOccurs)='unbounded'])"/>
					<xsl:variable name="nu_choice_elements" select="number($choice_elements)-number($u_choice_elements)"/>
					<xsl:variable name="nz_sequences" select="$choice/xsd:sequence[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="nu_sequences" select="$choice/xsd:sequence[not(string(./@maxOccurs)='unbounded')]"/>
					<xsl:variable name="z_choice_sequences" select="count($choice/xsd:sequence[number(./@minOccurs)=0])"/>
					<xsl:variable name="nz_choice_sequences" select="number($choice_sequences)-number($z_choice_sequences)"/>
					<xsl:variable name="u_choice_sequences" select="count($choice/xsd:sequence[string(./@maxOccurs)='unbounded'])"/>
					<xsl:variable name="nu_choice_sequences" select="number($choice_sequences)-number($u_choice_sequences)"/>
					<xsl:variable name="nz_groups" select="$choice/xsd:group[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="nu_groups" select="$choice/xsd:group[not(string(./@maxOccurs)='unbounded')]"/>
					<xsl:variable name="z_choice_groups" select="count($choice/xsd:group[number(./@minOccurs)=0])"/>
					<xsl:variable name="nz_choice_groups" select="number($choice_groups)-number($z_choice_groups)"/>
					<xsl:variable name="u_choice_groups" select="count($choice/xsd:group[string(./@maxOccurs)='unbounded'])"/>
					<xsl:variable name="nu_choice_groups" select="number($choice_groups)-number($u_choice_groups)"/>
					<xsl:variable name="nz_choices" select="$choice/xsd:choice[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="nu_choices" select="$choice/xsd:choice[not(string(./@maxOccurs)='unbounded')]"/>
					<xsl:variable name="z_choice_choices" select="count($choice/xsd:choice[number(./@minOccurs)=0])"/>
					<xsl:variable name="nz_choice_choices" select="number($choice_choices)-number($z_choice_choices)"/>
					<xsl:variable name="u_choice_choices" select="count($choice/xsd:choice[string(./@maxOccurs)='unbounded'])"/>
					<xsl:variable name="nu_choice_choices" select="number($choice_choices)-number($u_choice_choices)"/>
					<xsl:variable name="nur_total" select="number($nur_choice_elements)+number($nur_choice_sequences)+number($nur_choice_choices)+number($nur_choice_groups)"/>
					<xsl:variable name="nz_total" select="number($nz_choice_elements)+number($nz_choice_sequences)+number($nz_choice_choices)+number($nz_choice_groups)"/>
					<xsl:variable name="nu_total" select="number($nu_choice_elements)+number($nu_choice_sequences)+number($nu_choice_choices)+number($nu_choice_groups)"/>
					<xsl:variable name="temp_min" select="tokenize(self:sequence_values($nur_total,$choice_min_occurs),'@')"/>
					<xsl:variable name="temp_max" select="tokenize(self:sequence_values($nur_total,$choice_max_occurs),'@')"/>
					<xsl:variable name="nz" select="$choice/xsd:element[not(number(./@minOccurs)=0)], $choice/xsd:sequence[not(number(./@minOccurs)=0)], $choice/xsd:choice[not(number(./@minOccurs)=0)], $choice/xsd:group[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="nu" select="$choice/xsd:element[not(string(./@maxOccurs)='unbounded')], $choice/xsd:sequence[not(string(./@maxOccurs)='unbounded')], $choice/xsd:choice[not(string(./@maxOccurs)='unbounded')], $choice/xsd:group[not(string(./@maxOccurs)='unbounded')]"/>
					<xsl:variable name="min_restrictions">
						<xsl:choose>
							<xsl:when test="number($choice_min_occurs)=0 or number($nz_total)=0">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:when test="number($nz_choice_elements)=1 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=0 and number($nz_choice_groups)=0">
								<xsl:variable name="element" select="$nz_elements[position()=1]"/>
								<xsl:variable name="element_name" select="self:produced_element_name($element,$class,$schema_element,$group_name)"/>
								<xsl:for-each select="0 to $cmo">
									<xsl:value-of select="self:min_cardinality_restriction($element_name,number(.)*number(self:min_occurs($element)))"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nz_choice_elements)=0 and number($nz_choice_sequences)=1 and number($nz_choice_choices)=0 and number($nz_choice_groups)=0">
								<xsl:variable name="item" select="$choice/xsd:sequence[not(number(./@minOccurs)=0)]"/>
								<xsl:value-of select="self:sequence_cardinality($item,0,0,$class,$schema_element,$group_name)"/>
								<xsl:for-each select="1 to $cmo">
									<xsl:value-of select="self:sequence_cardinality($item,number(.),'unbounded',$class,$schema_element,$group_name)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nz_choice_elements)=0 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=1 and number($nz_choice_groups)=0">
								<xsl:variable name="item" select="$choice/xsd:choice[not(number(./@minOccurs)=0)]"/>
								<xsl:variable name="min_occurs" select="self:min_occurs($item)"/>
								<xsl:value-of select="self:sequence_cardinality($item,0,0,$class,$schema_element,$group_name)"/>
								<xsl:for-each select="1 to $choice_min_occurs">
									<xsl:value-of select="self:min_cardinality_for_choice($item,number(.)*number($min_occurs),$class,$schema_element,$group_name)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nz_choice_elements)=0 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=0 and number($nz_choice_groups)=1">
								<xsl:variable name="item" select="$choice/xsd:group[not(number(./@minOccurs)=0)]"/>
								<xsl:for-each select="$item/xsd:sequence[not(number(./@minOccurs)=0)],$item/xsd:choice[not(number(./@minOccurs)=0)]">
									<xsl:value-of select="self:sequence_cardinality($item,0,0,$class,$schema_element,$group_name)"/>
								</xsl:for-each>
								<xsl:for-each select="1 to $choice_min_occurs">
									<xsl:value-of select="self:group_cardinality($item,number(.),'unbounded',$class,$schema_element)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="data($temp_min)[not(string(.)='')]">
									<xsl:variable name="card_values" select="tokenize(.,'#')"/>
									<xsl:variable name="nz_index" as="xsd:integer">
										<xsl:value-of select="$nz_total"/>
									</xsl:variable>
									<xsl:variable name="card_restrictions">
										<xsl:for-each select="1 to $nz_index">
											<xsl:variable name="i" select="." as="xsd:integer"/>
											<xsl:variable name="item" select="$nz[position()=$i]"/>
											<xsl:variable name="item_name" select="if (contains($item/name(),':')) then substring-after($item/name(),':') else $item/name()"/>
											<xsl:choose>
												<xsl:when test="$item_name='element'">
													<xsl:variable name="element_name" select="self:produced_element_name($item,$class,$schema_element,$group_name)"/>
													<xsl:value-of select="self:min_cardinality_restriction($element_name,number(data($card_values[position()=$i]))*number(self:min_occurs($item)))"/>
												</xsl:when>
												<xsl:when test="$item_name='sequence'">
													<xsl:value-of select="self:sequence_cardinality($item,number(data($card_values[position()=$i])),'unbounded',$class,$schema_element,$group_name)"/>
												</xsl:when>
												<xsl:when test="$item_name='group'">
													<xsl:value-of select="self:group_cardinality($item,number(data($card_values[position()=$i])),'unbounded',$class,$schema_element)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:variable name="min_occurs" select="self:min_occurs($item)"/>
													<xsl:value-of select="self:min_cardinality_for_choice($item,number($min_occurs)*number(data($card_values[position()=$i])),$class,$schema_element,'')"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:variable>
									<xsl:value-of select="self:unnamed_intersection_class($card_restrictions)"/>
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="max_restrictions">
						<xsl:choose>
							<xsl:when test="number($nu_total)=0">
								<xsl:value-of select="''"/>
							</xsl:when>
							<xsl:when test="number($nu_choice_elements)=1 and number($nu_choice_sequences)=0 and number($nu_choice_choices)=0 and number($nu_choice_groups)=0">
								<xsl:variable name="element" select="$nu_elements[position()=1]"/>
								<xsl:variable name="element_name" select="self:produced_element_name($element,$class,$schema_element,$group_name)"/>
								<xsl:variable name="cmaxo" as="xsd:integer">
									<xsl:value-of select="$choice_max_occurs"/>
								</xsl:variable>
								<xsl:for-each select="1 to $cmaxo">
									<xsl:value-of select="self:max_cardinality_restriction($element_name,number(.)*number(self:max_occurs($element)))"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nu_choice_elements)=0 and number($nu_choice_sequences)=1 and number($nu_choice_choices)=0 and number($nu_choice_groups)=0">
								<xsl:variable name="item" select="$choice/xsd:sequence[not(string(self:max_occurs(.))='unbounded')]"/>
								<xsl:for-each select="1 to $choice_max_occurs">
									<xsl:value-of select="self:sequence_cardinality($item,0,number(.)*number($choice_max_occurs),$class,$schema_element,$group_name)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nu_choice_elements)=0 and number($nu_choice_sequences)=0 and number($nu_choice_choices)=1 and number($nu_choice_groups)=0">
								<xsl:variable name="item" select="$choice/xsd:choice[not(string(self:max_occurs(.))='unbounded')]"/>
								<xsl:variable name="min_occurs" select="self:min_occurs($item)"/>
								<xsl:variable name="max_occurs" select="self:max_occurs($item)"/>
								<xsl:for-each select="1 to $choice_max_occurs">
									<xsl:value-of select="self:all_cardinalities_for_choice($item,0,number(.)*number($max_occurs),$class,$schema_element,$group_name)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:when test="number($nu_choice_elements)=0 and number($nu_choice_sequences)=0 and number($nu_choice_choices)=0 and number($nu_choice_groups)=1">
								<xsl:variable name="item" select="$choice/xsd:group[not(string(self:max_occurs(.))='unbounded')]"/>
								<xsl:for-each select="1 to $choice_max_occurs">
									<xsl:value-of select="self:group_cardinality($item,0,number(.)*number($choice_max_occurs),$class,$schema_element)"/>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="data($temp_max)[not(string(.)='')]">
									<xsl:variable name="card_values" select="tokenize(.,'#')"/>
									<xsl:variable name="nu_index" as="xsd:integer">
										<xsl:value-of select="$nu_total"/>
									</xsl:variable>
									<xsl:variable name="card_restrictions">
										<xsl:for-each select="1 to $nu_index">
											<xsl:variable name="i" select="." as="xsd:integer"/>
											<xsl:variable name="item" select="$nu[position()=$i]"/>
											<xsl:variable name="item_name" select="if (contains($item/name(),':')) then substring-after($item/name(),':') else $item/name()"/>
											<xsl:choose>
												<xsl:when test="$item_name='element'">
													<xsl:variable name="element_name" select="self:produced_element_name($item,$class,$schema_element,$group_name)"/>
													<xsl:value-of select="self:max_cardinality_restriction($element_name,number(data($card_values[position()=$i]))*number(self:max_occurs($item)))"/>
												</xsl:when>
												<xsl:when test="$item_name='sequence'">
													<xsl:value-of select="self:sequence_cardinality($item,0,number(data($card_values[position()=$i])),$class,$schema_element,$group_name)"/>
												</xsl:when>
												<xsl:when test="$item_name='group'">
													<xsl:value-of select="self:group_cardinality($item,0,number(data($card_values[position()=$i])),$class,$schema_element)"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:variable name="min_occurs" select="self:min_occurs($item)"/>
													<xsl:variable name="max_occurs" select="self:max_occurs($item)"/>
													<xsl:value-of select="self:all_cardinalities_for_choice($item,0, number($max_occurs)*number(data($card_values[position()=$i])),$class,$schema_element,$group_name)"/>
												</xsl:otherwise>
											</xsl:choose>
										</xsl:for-each>
									</xsl:variable>
									<xsl:value-of select="self:unnamed_intersection_class($card_restrictions)"/>
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="normalize-space(string($min_restrictions))='' and normalize-space(string($max_restrictions))=''">
							<xsl:value-of select="''"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:if test="((number($ur_choice_elements)>0) or (number($ur_choice_sequences)>0) or (number($ur_choice_choices)>0) or (number($ur_choice_groups)>0))">
								<xsl:variable name="temp">
									<xsl:for-each select="$choice/xsd:element[not(number(./@minOccurs)=0 and string(./@maxOccurs)='unbounded')]">
										<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
										<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
									</xsl:for-each>
								</xsl:variable>
								<xsl:value-of select="self:unnamed_intersection_class($temp)"/>
							</xsl:if>
							<xsl:choose>
								<xsl:when test="normalize-space(string($min_restrictions))=''">
									<xsl:value-of select="self:unnamed_union_class($max_restrictions)"/>
								</xsl:when>
								<xsl:when test="normalize-space(string($max_restrictions))=''">
									<xsl:value-of select="self:unnamed_union_class($min_restrictions)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="self:unnamed_intersection_class(concat(self:unnamed_union_class($min_restrictions),self:unnamed_union_class($max_restrictions)))"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="if (string($ret)='') then '' else self:unnamed_union_class($ret)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces owl:minCardinality restrictions on choice elements-->
	<xsl:function name="self:min_cardinality_for_choice" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_min_occurs"/>
		<xsl:param name="class"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="choice_elements" select="count($choice/xsd:element)"/>
		<xsl:variable name="choice_sequences" select="count($choice/xsd:sequence)"/>
		<xsl:variable name="choice_choices" select="count($choice/xsd:choice)"/>
		<xsl:variable name="choice_groups" select="count($choice/xsd:group)"/>
		<xsl:variable name="z_choice_elements" select="number(count($choice/xsd:element[number(self:min_occurs(.))=0]))"/>
		<xsl:variable name="z_choice_sequences" select="count($choice/xsd:sequence[number(self:min_occurs(.))=0])"/>
		<xsl:variable name="z_choice_choices" select="count($choice/xsd:choice[number(self:min_occurs(.))=0])"/>
		<xsl:variable name="z_choice_groups" select="count($choice/xsd:group[number(self:min_occurs(.))=0])"/>
		<xsl:variable name="nz_choice_elements" select="number($choice_elements)-number($z_choice_elements)"/>
		<xsl:variable name="nz_choice_sequences" select="number($choice_sequences)-number($z_choice_sequences)"/>
		<xsl:variable name="nz_choice_choices" select="number($choice_choices)-number($z_choice_choices)"/>
		<xsl:variable name="nz_choice_groups" select="number($choice_groups)-number($z_choice_groups)"/>
		<xsl:choose>
			<xsl:when test="(number($choice_min_occurs)=0) or (number($nz_choice_elements)=0 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=0 and number($nz_choice_groups)=0)">
				<xsl:value-of select="string('')"/>
			</xsl:when>
			<xsl:when test="number($nz_choice_elements=1) and number($nz_choice_sequences)=0 and number($nz_choice_choices)=0 and ($nz_choice_groups)=0">
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element[not(number(./@minOccurs)=0)]">
						<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
						<xsl:value-of select="self:unnamed_union_class(self:min_cardinality_restriction($element_name,number(self:min_occurs(.))))"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="$ret"/>
			</xsl:when>
			<xsl:when test="number($nz_choice_elements)=0 and ($nz_choice_sequences)=1 and ($nz_choice_choices)=0 and ($nz_choice_groups)=0">
				<xsl:variable name="z">
					<xsl:for-each select="$choice/xsd:sequence[not(number(./@minOccurs)=0)]/xsd:element[not(number(./@minOccurs)=0)]">
						<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
						<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:sequence[not(number(./@minOccurs)=0)]">
						<xsl:value-of select="self:sequence_cardinality(.,number($choice_min_occurs),'unbounded',$class,$schema_element,$group_name)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="if (normalize-space(string($nz))='') then '' else self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
			</xsl:when>
			<xsl:when test="number($nz_choice_elements)=0 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=0 and number($nz_choice_groups)=1">
				<xsl:variable name="z">
					<xsl:for-each select="$choice/xsd:group[not(number(./@minOccurs)=0)]">
						<xsl:variable name="grp_name" select="string(./@name)"/>
						<xsl:for-each select="./xsd:sequence[not(number(./@minOccurs)=0)]/xsd:element[not(number(./@minOccurs)=0)], ./xsd:choice[not(number(./@minOccurs)=0)]/xsd:element[not(number(./@minOccurs)=0)]">
							<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$grp_name)"/>
							<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:group[not(number(./@minOccurs)=0)]">
						<xsl:value-of select="self:group_cardinality(.,number($choice_min_occurs),'unbounded',$class,$schema_element)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="if (normalize-space(string($nz))='') then '' else self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
			</xsl:when>
			<xsl:when test="number($nz_choice_elements)=0 and number($nz_choice_sequences)=0 and number($nz_choice_choices)=1 and number($nz_choice_groups)=0">
				<xsl:variable name="z">
					<xsl:for-each select="$choice/xsd:choice[not(number(./@minOccurs)=0)]/xsd:element[not(number(./@minOccurs)=0)]">
						<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
						<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:variable name="nz">
					<xsl:for-each select="$choice/xsd:choice[not(number(./@minOccurs)=0)]">
						<xsl:variable name="min_occurs" select="self:min_occurs(.)"/>
						<xsl:value-of select="self:min_cardinality_for_choice(.,number($min_occurs)*number($choice_min_occurs),$class,$schema_element,$group_name)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="if (normalize-space(string($nz))='') then '' else self:unnamed_union_class(concat(self:unnamed_intersection_class($z),self:unnamed_union_class($nz)))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ret">
					<xsl:if test="((number($z_choice_elements)>0) or (number($z_choice_sequences)>0) or (number($z_choice_choices)>0) or (number($z_choice_groups)>0)) ">
						<xsl:variable name="temp">
							<xsl:for-each select="$choice/xsd:element[not(number(./@minOccurs)=0)]">
								<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,$group_name)"/>
								<xsl:value-of select="self:cardinality_restriction($element_name,0)"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_intersection_class($temp)"/>
					</xsl:if>
					<xsl:variable name="nz" select="$choice/xsd:element[not(number(./@minOccurs)=0)],$choice/xsd:sequence[not(number(./@minOccurs)=0)],$choice/xsd:choice[not(number(./@minOccurs)=0)] ,$choice/xsd:group[not(number(./@minOccurs)=0)]"/>
					<xsl:variable name="temp" select="tokenize(self:sequence_values(count($nz),$choice_min_occurs),'@')"/>
					<xsl:for-each select="data($temp)[not(string(.)='')]">
						<xsl:variable name="card_values" select="tokenize(.,'#')"/>
						<xsl:variable name="total" as="xsd:integer">
							<xsl:value-of select="(number($nz_choice_elements)+number($nz_choice_sequences)+number($nz_choice_choices)+number($nz_choice_groups))">
						</xsl:value-of>
						</xsl:variable>
						<xsl:variable name="card_restrictions">
							<xsl:for-each select="1 to $total">
								<xsl:variable name="i" select="." as="xsd:integer"/>
								<xsl:variable name="item" select="$nz[position()=$i]"/>
								<xsl:variable name="item_name" select="if (contains($item/name(),':')) then substring-after($item/name(),':') else $item/name()"/>
								<xsl:choose>
									<xsl:when test="$item_name='element'">
										<xsl:variable name="element_name" select="self:produced_element_name($item,$class,$schema_element,$group_name)"/>
										<xsl:value-of select="self:min_cardinality_restriction($element_name,number(data($card_values[position()=$i]))*number(self:min_occurs($item)))"/>
									</xsl:when>
									<xsl:when test="$item_name='sequence'">
										<xsl:value-of select="self:sequence_cardinality($item,number(data($card_values[position()=$i])),'unbounded',$class,$schema_element,$group_name)"/>
									</xsl:when>
									<xsl:when test="$item_name='group'">
										<xsl:if test="number(data($card_values[position()=$i]))!=0">
											<xsl:value-of select="self:group_cardinality($item,number(data($card_values[position()=$i])),'unbounded',$class,$schema_element)"/>
										</xsl:if>
									</xsl:when>
									<xsl:otherwise>
										<xsl:variable name="min_occurs" select="self:min_occurs($item)"/>
										<xsl:value-of select="self:min_cardinality_for_choice($item,number($min_occurs)*number($choice_min_occurs),$class,$schema_element,'')"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:variable>
						<xsl:value-of select="self:unnamed_intersection_class($card_restrictions)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="self:unnamed_union_class($ret)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces sequences of the values of "N" items that should have "sum" as sum. The values of the same row are separated by #, each row ends with @ -->
	<xsl:function name="self:sequence_values" as="xsd:string">
		<xsl:param name="N"/>
		<xsl:param name="sum"/>
		<xsl:variable name="index" as="xsd:integer">
			<xsl:value-of select="$sum"/>
		</xsl:variable>
		<xsl:variable name="ret">
			<xsl:choose>
				<xsl:when test="number($N)=2">
					<xsl:for-each select="0 to $index">
						<xsl:variable name="i" select="."/>
						<xsl:for-each select="0 to $index">
							<xsl:if test="number($i)+number(.)=number($sum)">
								<xsl:value-of select="concat($i,'#',.,'@')"/>
							</xsl:if>
						</xsl:for-each>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="rest">
						<xsl:for-each select="0 to $index">
							<xsl:variable name="i" select="."/>
							<xsl:variable name="temp" select="tokenize(self:sequence_values(number($N)-1,number($sum)-number(.)),'@')"/>
							<xsl:for-each select="data($temp)[not(string(.)='')]">
								<xsl:value-of select="concat($i,'#',.,'@')"/>
							</xsl:for-each>
						</xsl:for-each>
					</xsl:variable>
					<xsl:value-of select="$rest"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$ret"/>
	</xsl:function>
	<!-- Function that produces *lite* owl:minCardinality restrictions on choice elements-->
	<xsl:function name="self:min_cardinality_lite_for_choice" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_min_occurs"/>
		<xsl:param name="class"/>
		<xsl:variable name="choice_elements" select="count($choice/xsd:element)"/>
		<xsl:variable name="z_choice_elements" select="count($choice/xsd:element[number(./@minOccurs)=0])"/>
		<xsl:choose>
			<xsl:when test="number($z_choice_elements)>0">
				<xsl:value-of select="string('')"/>
			</xsl:when>
			<xsl:when test="number($choice_elements)=1">
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element">
						<xsl:variable name="element_name" select="self:produced_element_name(.,$class,$schema_element,'')"/>
						<xsl:value-of select="self:sub_class_content(self:min_cardinality_restriction($element_name,number(self:min_occurs(.))*number($choice_min_occurs)))"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="$ret"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="ret">
					<xsl:for-each select="$choice/xsd:element">
						<xsl:variable name="element_name" select="concat('#',if (string(./@ref)='') then self:property_name(.,$class) else string(./@ref))"/>
						<xsl:value-of select="self:min_cardinality_restriction($element_name,number(self:min_occurs(.)))"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="self:sub_class_content(self:unnamed_union_class($ret))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces unnamed union OWL Classes  -->
	<xsl:function name="self:unnamed_union_class" as="xsd:string">
		<xsl:param name="classes"/>
		<xsl:value-of select="concat('&lt;owl:Class&gt;&#10;&#9;&#9;&#9;&#9;&lt;owl:unionOf rdf:parseType=&quot;Collection&quot;&gt;&#10;&#9;&#9;&#9;&#9;',$classes,'&lt;/owl:unionOf&gt;&#10;&#9;&lt;/owl:Class&gt;&#10;&#9;')"/>
	</xsl:function>
	<!-- Function that produces unnamed intersection OWL Classes -->
	<xsl:function name="self:unnamed_intersection_class" as="xsd:string">
		<xsl:param name="classes"/>
		<xsl:value-of select="concat('&lt;owl:Class&gt;&#10;&#9;&#9;&#9;&#9;&lt;owl:intersectionOf rdf:parseType=&quot;Collection&quot;&gt;&#10;&#9;&#9;&#9;&#9;',$classes,'&lt;/owl:intersectionOf&gt;&#10;&#9;&lt;/owl:Class&gt;&#10;&#9;')"/>
	</xsl:function>
	<!-- Function that produces OWL Classes from Complex Types -->
	<xsl:function name="self:deep_class_from_complex_type">
		<xsl:param name="class"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="class_name"/>
		<xsl:param name="schema_element"/>
		<xsl:value-of disable-output-escaping="yes" select="self:class_from_complex_type($class,$named_simple_type_names, $xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces,$class_name,$schema_element)"/>
		<!-- attribute group representation -->
		<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:attributeGroup,$class/xsd:attributeGroup">
			<xsl:variable name="grp_name" select="string(./@ref)"/>
			<xsl:variable name="group" select="$schema_element/xsd:attributeGroup[string(./@name)=$grp_name]"/>
			<xsl:for-each select="$group/xsd:attribute">
				<xsl:value-of select="self:add_referenced_group_attributes_domain(.,$grp_name,$class_name,string($group/xsd:annotation/xsd:documentation),$schema_element)"/>
			</xsl:for-each>
		</xsl:for-each>
		<!-- attribute representation -->
		<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:attribute,$class/xsd:simpleContent/xsd:extension/xsd:attribute, $class/xsd:attribute">
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_attribute(.,$class_name,$equivalent_target_namespaces,$schema_element)"/>
		</xsl:for-each>
		<!-- simple type subclass representation -->
		<xsl:for-each select="$class/xsd:simpleContent/xsd:extension[not(string(./@base)='') and self:is_simple_type(string(./@base),$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces,boolean(./xsd:simpleType))]">
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_for_extension(.,$class_name,$equivalent_target_namespaces)"/>
		</xsl:for-each>
		<!-- element representation -->
		<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:sequence,$class/xsd:complexContent/xsd:extension/xsd:choice,$class/xsd:sequence,$class/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:transform_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name)"/>
		</xsl:for-each>
		<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:group,$class/xsd:group">
			<xsl:variable name="grp_name" select="string(./@ref)"/>
			<xsl:variable name="group" select="$schema_element/xsd:group[string(./@name)=$grp_name]"/>
			<xsl:for-each select="$group/xsd:sequence,$group/xsd:choice">
				<xsl:value-of disable-output-escaping="yes" select="self:transform_group_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name,$grp_name)"/>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that produces OWL transforms group elements to properties -->
	<xsl:function name="self:transform_group_elements">
		<xsl:param name="schema_element"/>
		<xsl:param name="group_container"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="class_name"/>
		<xsl:param name="grp_name"/>
		<xsl:for-each select="$group_container/xsd:element">
			<xsl:variable name="ref" select="string(./@ref)"/>
			<xsl:variable name="element_name" select="if ($ref='') then string(./@name) else string(./@ref)"/>
			<xsl:variable name="type" select="if ($ref='') then string(./@type) else string($schema_element/xsd:element[string(./@name)=$ref]/@type)"/>
			<xsl:variable name="annotation" select="if (string(./xsd:annotation/xsd:documentation)='') then '' else self:comment(./xsd:annotation/xsd:documentation)"/>
			<xsl:variable name="contains_simple_type_def" as="xsd:boolean">
				<xsl:choose>
					<xsl:when test="$ref=''">
						<xsl:value-of disable-output-escaping="yes" select="boolean(./xsd:simpleType)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="actual_element" select="$schema_element/xsd:element[string(./@name)=$ref]"/>
						<xsl:value-of disable-output-escaping="yes" select="boolean($actual_element/xsd:simpleType)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($contains_simple_type_def))  "/>
			<xsl:choose>
				<xsl:when test="$is_simple_type">
					<xsl:choose>
						<xsl:when test="$ref!=''">
							<xsl:variable name="element_type" select="if (string($type)!='') then $type else self:unnamed_datatype_name($not_specified, $element_name)"/>
							<xsl:value-of select="self:datatype_property(true(),concat('#',self:property_name($schema_element/xsd:element[string(./@name)=$ref],$not_specified)), '',self:domain($class_name),'','',$annotation)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="element_type" select="if (string($type)!='') then $type else self:unnamed_datatype_name($not_specified, concat($element_name,'_',$grp_name))"/>
							<xsl:value-of select="self:datatype_property(true(),concat('#',self:property_from_group_name($element_name,$grp_name,$element_type)), '',self:domain($class_name),'','',$annotation)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$ref!=''">
							<xsl:variable name="element_type" select="if (string($type)!='') then $type else self:unnamed_datatype_name($not_specified, $element_name)"/>
							<xsl:value-of select="self:object_property(true(),concat('#',self:property_name($schema_element/xsd:element[string(./@name)=$ref],$not_specified)), '',self:domain($class_name),'','',$annotation)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="element_type" select="if (string($type)!='') then $type else self:unnamed_datatype_name($not_specified, concat($element_name,'_',$grp_name))"/>
							<xsl:value-of select="self:object_property(true(),concat('#',self:property_from_group_name($element_name,$grp_name,$element_type)), '',self:domain($class_name),'','',$annotation)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:for-each select="$group_container/xsd:sequence,$group_container/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:transform_group_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name,$grp_name)"/>
		</xsl:for-each>
		<xsl:for-each select="$group_container/xsd:group">
			<xsl:variable name="new_grp_name" select="string(./@ref)"/>
			<xsl:variable name="new_group" select="$schema_element/xsd:group[string(./@name)=$new_grp_name]"/>
			<xsl:for-each select="$new_group/xsd:sequence,$new_group/xsd:choice">
				<xsl:value-of disable-output-escaping="yes" select="self:transform_group_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name,$new_grp_name)"/>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:function>
	
	<!-- Function that transforms elements to properties -->
	<xsl:function name="self:transform_elements">
		<xsl:param name="schema_element"/>
		<xsl:param name="sequence_or_choice"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="class_name"/>
		<xsl:for-each select="$sequence_or_choice/xsd:element">
			<xsl:variable name="ref" select="string(./@ref)"/>
			<xsl:variable name="type" select="if ($ref='') then string(./@type) else string($schema_element/xsd:element[string(./@name)=$ref]/@type)"/>
			<xsl:variable name="contains_simple_type_def" as="xsd:boolean">
				<xsl:choose>
					<xsl:when test="$ref=''">
						<xsl:value-of disable-output-escaping="yes" select="boolean(./xsd:simpleType)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="actual_element" select="$schema_element/xsd:element[string(./@name)=$ref]"/>
						<xsl:value-of disable-output-escaping="yes" select="boolean($actual_element/xsd:simpleType)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($contains_simple_type_def))  "/>
			<xsl:choose>
				<xsl:when test="$is_simple_type=true()">
					<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_element(.,$class_name,$equivalent_target_namespaces,$schema_element)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of disable-output-escaping="yes" select="self:object_property_from_element(.,$class_name,$schema_element,$equivalent_target_namespaces)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:for-each select="$sequence_or_choice/xsd:sequence,$sequence_or_choice/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:transform_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name)"/>
		</xsl:for-each>
		<xsl:for-each select="$sequence_or_choice/xsd:group">
			<xsl:variable name="grp_name" select="string(./@ref)"/>
			<xsl:variable name="group" select="$schema_element/xsd:group[string(./@name)=$grp_name]"/>
			<xsl:for-each select="$group/xsd:sequence,$group/xsd:choice">
				<xsl:value-of disable-output-escaping="yes" select="self:transform_group_elements($schema_element,.,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces,$class_name,$grp_name)"/>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that produces OWL transforms group elements to properties -->
	<xsl:function name="self:transform_group">
		<xsl:param name="group_name"/>
		<xsl:param name="group_container"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:for-each select="$group_container/xsd:element">
			<xsl:variable name="type" select="./@type"/>
			<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean(./xsd:simpleType))  "/>
			<xsl:choose>
				<xsl:when test="$is_simple_type">
					<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_group(.,$equivalent_target_namespaces,$group_name)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of disable-output-escaping="yes" select="self:object_property_from_group(.,$schema_element,$group_name,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
		<xsl:for-each select="$group_container/xsd:sequence,$group_container/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:transform_group($group_name,.,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces)"/>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that produces OWL Classes from Complex Types -->
	<xsl:function name="self:class_from_complex_type" as="xsd:string">
		<xsl:param name="class"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="class_name"/>
		<xsl:param name="schema_element"/>
		
		<!-- Retrieves the key related to the class -->
		<xsl:variable name="keyStructure" select="self:getHashTableValue($classes_keys_hashtable,$class_name)"/>
		
		<xsl:variable name="class_start">
			<xsl:value-of select="concat(string('&lt;owl:Class rdf:ID=&quot;'),string($class_name),string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="is_simple_type_descendant" select="self:is_simple_type(string($class/xsd:simpleContent/xsd:extension/@base),$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($class/xsd:simpleContent/xsd:extension/xsd:simpleType))"/>
		<xsl:variable name="subclass">
			<xsl:value-of select="self:subclass_of($class,$is_simple_type_descendant)"/>
		</xsl:variable>
		<xsl:variable name="annotation" select="if (string($class/xsd:annotation/xsd:documentation)='') then '' else self:comment($class/xsd:annotation/xsd:documentation)"/>
		<!-- required attribute restrictions -->
		<xsl:variable name="attributes">
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:attribute,$class/xsd:simpleContent/xsd:extension/xsd:attribute,$class/xsd:attribute">
				<xsl:value-of select="self:attribute_cardinality(.,$class_name,$schema_element)"/>
				<xsl:if test="not(string(./@fixed)='')">
					<xsl:value-of select="self:fixed_value(.,$class_name)"/>
				</xsl:if>
			</xsl:for-each>
			<!-- referenced attributes in attribute groups -->
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:attributeGroup,$class/xsd:simpleContent/xsd:extension/xsd:attributeGroup,$class/xsd:attributeGroup">
				<xsl:variable name="grp_name" select="string(./@ref)"/>
				<xsl:variable name="group" select="$schema_element/xsd:attributeGroup[string(./@name)=$grp_name]"/>
				<xsl:for-each select="$group/xsd:attribute">
					<xsl:value-of select="self:group_attribute_cardinality(.,$grp_name,$schema_element)"/>
				</xsl:for-each>
			</xsl:for-each>
			<!-- attribute representing extension from simple type-->
			<xsl:for-each select="$class/xsd:simpleContent/xsd:extension[not(string(./@base)='') and $is_simple_type_descendant]">
				<xsl:variable name="sc_name" select="concat('content__',replace(./@base,':','_'))"/>
				<xsl:value-of select="self:sub_class_content(self:cardinality_restriction(concat('#',$sc_name),1))"/>
			</xsl:for-each>
		</xsl:variable>
		<!-- required sequence element restrictions -->
		<xsl:variable name="sequence_elements">
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:sequence,$class/xsd:sequence">
				<xsl:value-of select="self:sub_class_content(self:sequence_cardinality(.,1,1,$class_name,$schema_element,''))"/>
			</xsl:for-each>
		</xsl:variable>
		<!-- required group element restrictions -->
		<xsl:variable name="group_elements">
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:group,$class/xsd:group">
				<xsl:value-of select="self:sub_class_content(self:group_cardinality(.,1,1,$class_name,$schema_element))"/>
			</xsl:for-each>
		</xsl:variable>
		<!-- required choice element restrictions -->
		<xsl:variable name="choice_elements">
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:choice, $class/xsd:choice">
				<xsl:variable name="min_occurs" select="self:min_occurs(.)"/>
				<xsl:variable name="max_occurs" select="self:max_occurs(.)"/>
				<xsl:choose>
					<xsl:when test="number($min_occurs)=0 and $max_occurs='unbounded'">
						<xsl:value-of select="string('')"/>
					</xsl:when>
					<!--	*Lite* restrictions for choice element cardinalities	-->
					<!--
					<xsl:when test="number($min_occurs)=0">
						<xsl:value-of select="self:max_cardinality_lite_for_choice(.,$max_occurs,$class_name)"/>
					</xsl:when>
					<xsl:when test="string($max_occurs)='unbounded'">
						<xsl:value-of select="self:min_cardinality_lite_for_choice(.,$min_occurs,$class_name)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:all_cardinalities_lite_for_choice(.,$min_occurs,$max_occurs,$class_name)"/>
					</xsl:otherwise>
					-->
					<xsl:when test="string($max_occurs)='unbounded'">
						<xsl:variable name="ret" select="self:min_cardinality_for_choice(.,$min_occurs,$class_name,$schema_element,'')"/>
						<xsl:value-of select="if (normalize-space(string($ret))='') then '' else self:sub_class_content($ret)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="ret" select="self:all_cardinalities_for_choice(.,$min_occurs,$max_occurs,$class_name,$schema_element,'')"/>
						<xsl:value-of select="if (normalize-space(string($ret))='') then '' else self:sub_class_content($ret)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<!-- fixed values for elements -->
		<xsl:variable name="element_fixed_values">
			<xsl:for-each select="$class/xsd:complexContent/xsd:extension/xsd:sequence,$class/xsd:sequence,$class/xsd:complexContent/xsd:extension/xsd:choice, $class/xsd:choice">
				<xsl:value-of select="self:expand_fixed_values(.,$class_name)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="concat(string($class_start),string($subclass),string($attributes),string($element_fixed_values),string($group_elements),string($sequence_elements),string($choice_elements),self:label($class_name),$annotation,$keyStructure,string('&lt;/owl:Class&gt;&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces cardinality restrictions for groups -->
	<xsl:function name="self:group_cardinality">
		<xsl:param name="ref_group"/>
		<xsl:param name="min_import"/>
		<xsl:param name="max_import"/>
		<xsl:param name="class_name"/>
		<xsl:param name="schema_element"/>
		<xsl:variable name="group_name" select="string($ref_group/@ref)"/>
		<xsl:variable name="group" select="$schema_element/xsd:group[string(./@name)=$group_name]"/>
		<xsl:variable name="min_occurs" select="self:min_occurs($ref_group)"/>
		<xsl:variable name="max_occurs" select="self:max_occurs($ref_group)"/>
		<xsl:for-each select="$group/xsd:sequence">
			<xsl:value-of select="if (string($max_import)='unbounded' or string($max_occurs)='unbounded') then self:sequence_cardinality(.,number($min_import)*number($min_occurs),'unbounded',$class_name,$schema_element,$group_name) else self:sequence_cardinality(.,number($min_import)*number($min_occurs),number($max_import)*number($max_occurs),$class_name,$schema_element,$group_name)"/>
		</xsl:for-each>
		<xsl:for-each select="$group/xsd:choice">
			<xsl:variable name="c_min_occurs" select="self:min_occurs(.)"/>
			<xsl:variable name="c_max_occurs" select="self:max_occurs(.)"/>
			<xsl:choose>
				<xsl:when test="number($min_import)*number($c_min_occurs)*number($min_occurs)=0 and (string($max_import)='unbounded' or string($max_occurs)='unbounded' or $c_max_occurs='unbounded')">
					<xsl:value-of select="string('')"/>
				</xsl:when>
				<xsl:when test="string($max_import)='unbounded' or string($max_occurs)='unbounded' or string($c_max_occurs)='unbounded'">
					<xsl:variable name="ret" select="self:min_cardinality_for_choice(.,number($min_import)*number($c_min_occurs)*number($min_occurs),$class_name,$schema_element,$group_name)"/>
					<xsl:value-of select="if (normalize-space(string($ret))='') then '' else $ret"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="ret" select="self:all_cardinalities_for_choice(.,number($min_import)*number($c_min_occurs)*number($min_occurs), number($max_import)*number($c_max_occurs)*number($max_occurs),$class_name,$schema_element,$group_name)"/>
					<xsl:value-of select="if (normalize-space(string($ret))='') then '' else $ret"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that produces cardinality restrictions for sequences -->
	<xsl:function name="self:sequence_cardinality">
		<xsl:param name="sequence"/>
		<xsl:param name="min_import"/>
		<xsl:param name="max_import"/>
		<xsl:param name="class_name"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="min_occurs" select="self:min_occurs($sequence)"/>
		<xsl:variable name="max_occurs" select="self:max_occurs($sequence)"/>
		<xsl:variable name="elements">
			<xsl:for-each select="$sequence/xsd:element">
				<xsl:choose>
					<xsl:when test="string($max_occurs)='unbounded' or string($max_import)='unbounded'">
						<xsl:value-of select="self:sequence_element_cardinality(.,number($min_occurs)*number($min_import),'unbounded',$class_name,$schema_element,$group_name)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:sequence_element_cardinality(.,number($min_occurs)*number($min_import),number($max_occurs)*number($max_import),$class_name,$schema_element,$group_name)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="seqs">
			<xsl:for-each select="$sequence/xsd:sequence">
				<xsl:choose>
					<xsl:when test="string($max_occurs)='unbounded' or string($max_import)='unbounded'">
						<xsl:value-of select="self:sequence_cardinality(.,number($min_occurs)*number($min_import),'unbounded',$class_name,$schema_element,$group_name)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:sequence_cardinality(.,number($min_occurs)*number($min_import),number($max_occurs)*number($max_import),$class_name,$schema_element,$group_name)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="choices">
			<xsl:for-each select="$sequence/xsd:choice">
				<xsl:variable name="choice_min_occurs" select="self:min_occurs(.)"/>
				<xsl:variable name="choice_max_occurs" select="self:max_occurs(.)"/>
				<xsl:choose>
					<xsl:when test="string($choice_max_occurs)='unbounded' or string($max_occurs)='unbounded' or string($max_import)='unbounded'">
						<xsl:value-of select="self:min_cardinality_for_choice(.,number($min_occurs)*number($choice_min_occurs)*number($min_import),$class_name,$schema_element,$group_name)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:all_cardinalities_for_choice(.,number($min_occurs)*number($choice_min_occurs)*number($min_import), number($max_occurs)*number($choice_max_occurs)*number($max_import),$class_name,$schema_element,$group_name)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="groups">
			<xsl:for-each select="$sequence/xsd:group">
				<xsl:choose>
					<xsl:when test="string($max_occurs)='unbounded' or string($max_import)='unbounded'">
						<xsl:value-of select="self:group_cardinality(.,number($min_occurs)*number($min_import),'unbounded',$class_name,$schema_element)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:group_cardinality(.,number($min_occurs)*number($min_import),number($max_occurs)*number($max_import),$class_name,$schema_element)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="if ((normalize-space(string($elements))='' and normalize-space(string($seqs))='' and normalize-space(string($choices))='') or (number($min_import)=0 and string($max_import)='unbounded')) then '' else self:unnamed_intersection_class(concat($elements,$seqs,$choices,$groups))"/>
	</xsl:function>
	<!-- Function that produces rdfs:Datatype elements from a simple type name -->
	<xsl:function name="self:datatype_from_name" as="xsd:string">
		<xsl:param name="simple_type_name"/>
		<xsl:param name="entity"/>
		<xsl:variable name="dt_start">
			<xsl:value-of select="concat(string('&lt;rdfs:Datatype rdf:about=&quot;&amp;'),$entity,';',string($simple_type_name),string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="dt_end">
			<xsl:value-of select="string('&lt;/rdfs:Datatype&gt;')"/>
		</xsl:variable>
		<xsl:variable name="dt_def">
			<xsl:value-of select="concat('&lt;rdfs:isDefinedBy rdf:resource=&quot;&amp;',$entity,';&quot;/&gt;&#10;&#9;&#9;')"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($dt_start),string($dt_def),self:label($simple_type_name),string($dt_end),string('&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that produces an unnamed type name -->
	<xsl:function name="self:unnamed_datatype_name" as="xsd:string">
		<xsl:param name="class_name"/>
		<xsl:param name="datatype_name"/>
		<xsl:value-of select="concat($class_name,'_',$datatype_name,'_UNType')"/>
	</xsl:function>
	<!-- Function that produces an unnamed type as datatype range -->
	<xsl:function name="self:unnamed_datatype_range" as="xsd:string">
		<xsl:param name="class_name"/>
		<xsl:param name="datatype_name"/>
		<xsl:choose>
			<xsl:when test="string($datatype_name)=''">
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;'),'#',self:unnamed_datatype_name($class_name,$datatype_name),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces the "type" as datatype range -->
	<xsl:function name="self:datatype_range">
		<xsl:param name="type"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:choose>
			<xsl:when test="not(string($type)='')">
				<xsl:variable name="ns_name" select="substring-before($type,':')"/>
				<xsl:choose>
					<xsl:when test="contains($type,':')">
						<xsl:choose>
							<xsl:when test="not($ns_name='') and contains($equivalent_target_namespaces,$ns_name)">
								<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;'),self:rdf_uri_from_xsd_uri(replace($type,concat($ns_name,':'), concat($datatype_entity_name,':'))),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;'),self:rdf_uri_from_xsd_uri($type),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="contains($named_simple_type_names,$type)">
								<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;#'),string($type),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="concat(string('&lt;rdfs:range rdf:resource=&quot;&amp;xsd;'),string($type),string('&quot;/&gt;&#10;&#9;&#9;'))"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="string('')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces Object Properties from Elements -->
	<xsl:function name="self:object_property_from_element">
		<xsl:param name="element"/>
		<xsl:param name="class_name"/>
		<xsl:param name="schema"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="element_name" select="$element/@name"/>
		<xsl:variable name="element_type" select="$element/@type"/>
		<xsl:variable name="id" select="self:property_name($element,$class_name)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($element/@ref)='')">
				<xsl:value-of select="self:add_referenced_object_property_domain($element,$class_name,$annotation,$schema)"/>
			</xsl:when>
			<xsl:when test="not(string($element/@type)='')">
				<xsl:value-of select="self:add_object_property_domain($element,$class_name)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="substitution_group" select="self:sub_property($element/@substitutionGroup, $schema, $equivalent_target_namespaces)"/>
				<xsl:value-of select="self:deep_class_from_complex_type($element/xsd:complexType,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, self:unnamed_datatype_name($class_name,$element_name),$schema_element)"/>
				
				<xsl:variable name="keyrefRange" select="self:getHashTableValue($properties_referTo_hashtable,$id)"/>
				<xsl:choose>
					<xsl:when test="not($keyrefRange='')">
						<xsl:value-of select="self:object_property(false(),$id,$substitution_group,self:domain($class_name),self:object_property_range($keyrefRange), self:label($element_name), $annotation)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:object_property(false(),$id,$substitution_group,self:domain($class_name),self:object_property_range(self:unnamed_datatype_name($class_name,$element_name)), self:label($element_name), $annotation)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces Object Properties without domain -->
	<xsl:function name="self:object_property_wo_domain_no_UN">
		<xsl:param name="element"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="element_name" select="$element/@name"/>
		<xsl:variable name="element_type" select="$element/@type"/>
		<xsl:variable name="id" select="self:property_name($element,'')"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="substitution_group" select="self:sub_property($element/@substitutionGroup, $schema_element, $equivalent_target_namespaces)"/>
		<xsl:value-of select="self:object_property(false(),$id,$substitution_group,'',self:object_property_range($element_type), self:label($element_name),$annotation)"/>
	</xsl:function>
	
	<!-- Function that answers if a type is simple type -->
	<xsl:function name="self:is_simple_type" as="xsd:boolean">
		<xsl:param name="type"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="contains_simple_type_element"/>
		<xsl:variable name="n_name" select="substring-before($type,':')"/>
		<xsl:choose>
			<xsl:when test="contains(string($named_simple_type_names),$type)">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="$contains_simple_type_element=true()">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="$is_empty_namespace_xsd=true() and $n_name=''">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="$n_name=''">
				<xsl:value-of select="false()"/>
			</xsl:when>
			<xsl:when test="contains(string($xsd_namespaces),$n_name)">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:when test="contains(string($equivalent_target_namespaces),$n_name)">
				<xsl:value-of select="boolean(contains(string($named_simple_type_names),concat(' ',substring-after($type,':'),' ')))"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces subPropertyOf elements -->
	<xsl:function name="self:sub_property">
		<xsl:param name="super_property"/>
		<xsl:param name="schema"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:choose>
			<xsl:when test="string($super_property)=''">
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="substitution_tokens"  select="tokenize($super_property,' ')" />
				<xsl:variable name="num_substitution_tokens" select="count($substitution_tokens)"/>
				<xsl:for-each select="1 to xsd:integer($num_substitution_tokens)" >
					<xsl:variable name="i" select="." as="xsd:integer"/>
					<xsl:variable name="item">
						<xsl:value-of select="$substitution_tokens[position()=$i]"/>
					</xsl:variable>
					
					<xsl:variable name="n_name" as="xsd:string">
						<xsl:value-of select="substring-before($item,':')"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="string($n_name)=string('') or contains(string($equivalent_target_namespaces),string($n_name))">
							<xsl:variable name="sp_name">
								<xsl:variable name="temp" select="substring-after($item,':')" as="xsd:string"/>
								<xsl:choose>
									<xsl:when test="$temp=''">
										<xsl:value-of select="$item"/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="$temp"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<xsl:variable name="sp_element" select="$schema/xsd:element[@name=$sp_name]"/>
							<xsl:value-of select="concat('&lt;rdfs:subPropertyOf rdf:resource=&quot;#', self:property_name($sp_element,$not_specified), '&quot;/&gt;&#10;&#9;&#9;')"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('&lt;rdfs:subPropertyOf rdf:resource=&quot;',self:rdf_uri_from_xsd_uri($item),'&quot;/&gt;&#10;&#9;&#9;')"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces Object Properties from top-level Elements -->
	<xsl:function name="self:object_property_from_top_element">
		<xsl:param name="element"/>
		<xsl:param name="schema_element"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="element_name" select="$element/@name"/>
		<xsl:variable name="element_type" select="$element/@type"/>
		<xsl:variable name="id" select="self:property_name($element,$not_specified)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="substitution_group" select="self:sub_property($element/@substitutionGroup, $schema_element, $equivalent_target_namespaces)"/>
		
		
		<xsl:choose>
			<xsl:when test="nilled($element/xsd:complexType)=false()">
				<xsl:value-of select="self:deep_class_from_complex_type($element/xsd:complexType,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, self:unnamed_datatype_name($not_specified,$element_name),$schema_element)"/>
				<xsl:value-of select="self:object_property(false(),$id,$substitution_group,'',self:object_property_range(self:unnamed_datatype_name($not_specified,$element_name)), self:label($element_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="range" select="if ($element_type) then self:object_property_range($element_type) else ''"/>
				<xsl:value-of select="self:object_property(false(),$id,$substitution_group,'',$range, self:label($element_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces DataType Properties from Elements -->
	<xsl:function name="self:datatype_property_from_element">
		<xsl:param name="element"/>
		<xsl:param name="class_name"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="schema"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($element/@ref)='')">
				<xsl:value-of select="self:add_referenced_element_domain($element,$class_name,$annotation,$schema)"/>
			</xsl:when>
			<xsl:when test="not(string($element/@type)='')">
				<xsl:value-of select="self:add_datatype_domain($element,$class_name)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="element_name" select="$element/@name"/>
				<xsl:variable name="element_type" select="$element/@type"/>
				<xsl:variable name="id" select="self:property_name($element,$class_name)"/>
				<xsl:variable name="substitution_group" select="self:sub_property($element/@substitutionGroup, $schema, $equivalent_target_namespaces)"/>
				<xsl:value-of select="self:datatype_from_simple_type2($element/xsd:simpleType,$class_name,$element_name,'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,$substitution_group,self:domain($class_name),self:unnamed_datatype_range($class_name,$element_name), self:label($element_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces DataType Properties from top-level Elements -->
	<xsl:function name="self:datatype_property_from_top_element">
		<xsl:param name="element"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="schema_element"/>
		<xsl:variable name="element_name" select="$element/@name"/>
		<xsl:variable name="element_type" select="$element/@type"/>
		<xsl:variable name="id" select="self:property_name($element,$not_specified)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="substitution_group" select="self:sub_property($element/@substitutionGroup, $schema_element, $equivalent_target_namespaces)"/>
		
		<xsl:choose>
			<xsl:when test="nilled($element/xsd:simpleType)=false()">
				<xsl:value-of select="self:datatype_from_simple_type2($element/xsd:simpleType,$not_specified,$element_name,'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,$substitution_group,'',self:datatype_range($element_type,$equivalent_target_namespaces), self:label($element_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="self:datatype_property(false(),$id,$substitution_group,'',self:datatype_range($element_type,$equivalent_target_namespaces), self:label($element_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces DataType Properties representing that a class extends a simple type -->
	<xsl:function name="self:datatype_property_for_extension" as="xsd:string">
		<xsl:param name="extension"/>
		<xsl:param name="class_name"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="property_type" select="$extension/@base"/>
		<xsl:variable name="id" select="concat('content__',replace($property_type,':','_'))"/>
		<xsl:value-of select="self:datatype_property(false(),$id,'',self:domain($class_name),self:datatype_range($property_type,$equivalent_target_namespaces), '',self:comment(concat('Datatype property representing that ', $class_name,' is derived from ',$property_type)))"/>
	</xsl:function>
	
	<!-- Function that produces names for datatype properties produced from attribute groups -->
	<xsl:function name="self:property_from_group_name" as="xsd:string">
		<xsl:param name="element_name"/>
		<xsl:param name="group_name"/>
		<xsl:param name="type"/>
		<xsl:value-of select="concat($element_name,'_',$group_name,'__',replace($type,':','_'))"/>
	</xsl:function>
	
	<!-- Function that produces DataType Properties from model groups -->
	<xsl:function name="self:datatype_property_from_group">
		<xsl:param name="element"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="group_name"/>
		<xsl:variable name="element_name" select="string($element/@name)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($element/@ref)='')">
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:when test="(nilled($element/xsd:simpleType)=false())">
				<xsl:variable name="element_type" select="self:unnamed_datatype_name($not_specified, concat($element_name,'_',$group_name))"/>
				<xsl:variable name="id" select="self:property_from_group_name($element_name,$group_name,$element_type)"/>
				<xsl:value-of select="self:datatype_from_simple_type2($element/xsd:simpleType,$not_specified,concat($element_name,'_',$group_name),'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:unnamed_datatype_range($not_specified, concat($element_name,'_',$group_name)), self:label($element_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="element_type" select="$element/@type"/>
				<xsl:variable name="id" select="self:property_from_group_name($element_name,$group_name,$element_type)"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:datatype_range($element_type,$equivalent_target_namespaces), self:label($element_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces Object Properties from model groups -->
	<xsl:function name="self:object_property_from_group">
		<xsl:param name="element"/>
		<xsl:param name="schema"/>
		<xsl:param name="group_name"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="element_name" select="string($element/@name)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($element/@ref)='')">
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:when test="(nilled($element/xsd:complexType)=false())">
				<xsl:variable name="element_type" select="self:unnamed_datatype_name($not_specified, concat($element_name,'_',$group_name))"/>
				<xsl:variable name="id" select="self:property_from_group_name($element_name,$group_name,$element_type)"/>
				<xsl:value-of select="self:deep_class_from_complex_type($element/xsd:complexType,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, $element_type,$schema)"/>
				<xsl:value-of select="self:object_property(false(),$id,'','',self:object_property_range($element_type), self:label($element_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="element_type" select="$element/@type"/>
				<xsl:variable name="id" select="self:property_from_group_name($element_name,$group_name,$element_type)"/>
				<xsl:value-of select="self:object_property(false(),$id,'','',self:object_property_range($element_type), self:label($element_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces DataType Properties from attribute groups -->
	<xsl:function name="self:datatype_property_from_attribute_group">
		<xsl:param name="attribute"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="ag_name"/>
		<xsl:variable name="attribute_name" select="string($attribute/@name)"/>
		<xsl:variable name="annotation" select="if (string($attribute/xsd:annotation/xsd:documentation)='') then '' else self:comment($attribute/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($attribute/@ref)='')">
				<xsl:value-of select="''"/>
			</xsl:when>
			<xsl:when test="nilled($attribute/xsd:simpleType)=false()">
				<xsl:variable name="attribute_type" select="self:unnamed_datatype_name($not_specified, concat($attribute_name,'_',$ag_name))"/>
				<xsl:variable name="id" select="self:property_from_group_name($attribute_name,$ag_name,$attribute_type)"/>
				<xsl:value-of select="self:datatype_from_simple_type2($attribute/xsd:simpleType,$not_specified,concat($attribute_name,'_',$ag_name),'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:unnamed_datatype_range($not_specified, concat($attribute_name,'_',$ag_name)), self:label($attribute_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="attribute_type" select="$attribute/@type"/>
				<xsl:variable name="id" select="self:property_from_group_name($attribute_name,$ag_name,$attribute_type)"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:datatype_range($attribute_type,$equivalent_target_namespaces), self:label($attribute_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces DataType Properties from top-level attributes -->
	<xsl:function name="self:datatype_property_from_top_attribute">
		<xsl:param name="attribute"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="attribute_name" select="$attribute/@name"/>
		<xsl:variable name="id" select="self:property_name($attribute,$not_specified)"/>
		<xsl:variable name="attribute_type" select="$attribute/@type"/>
		<xsl:variable name="annotation" select="if (string($attribute/xsd:annotation/xsd:documentation)='') then '' else self:comment($attribute/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="nilled($attribute/xsd:simpleType)=false()">
				<xsl:value-of select="self:datatype_from_simple_type2($attribute/xsd:simpleType,$not_specified,$attribute_name,'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:unnamed_datatype_range($not_specified,$attribute_name), self:label($attribute_name),$annotation)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="self:datatype_property(false(),$id,'','',self:datatype_range($attribute_type,$equivalent_target_namespaces), self:label($attribute_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces DataType Properties from attributes -->
	<xsl:function name="self:datatype_property_from_attribute">
		<xsl:param name="attribute"/>
		<xsl:param name="class_name"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:param name="schema_element"/>
		<xsl:variable name="annotation" select="if (string($attribute/xsd:annotation/xsd:documentation)='') then '' else self:comment($attribute/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="not(string($attribute/@ref)='')">
				<xsl:value-of select="self:add_referenced_datatype_domain($attribute,$class_name,$annotation,$schema_element)"/>
			</xsl:when>
			<xsl:when test="not(string($attribute/@type)='')">
				<xsl:value-of select="self:add_datatype_domain($attribute,$class_name)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="attribute_name" select="$attribute/@name"/>
				<xsl:variable name="id" select="self:property_name($attribute,$class_name)"/>
				<xsl:variable name="attribute_type" select="$attribute/@type"/>
				<xsl:value-of select="self:datatype_from_simple_type2($attribute/xsd:simpleType,$class_name,$attribute_name,'','')"/>
				<xsl:value-of select="self:datatype_property(false(),$id,'',self:domain($class_name),self:unnamed_datatype_range($class_name,$attribute_name), self:label($attribute_name),$annotation)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces DataType Properties without domain -->
	<xsl:function name="self:datatype_property_wo_domain_not_UN">
		<xsl:param name="construct"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="annotation" select="if (string($construct/xsd:annotation/xsd:documentation)='') then '' else self:comment($construct/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="construct_name" select="$construct/@name"/>
		<xsl:variable name="id" select="self:property_name($construct,'')"/>
		<xsl:variable name="construct_type" select="$construct/@type"/>
		<xsl:value-of select="self:datatype_property(false(),$id,'','',self:datatype_range($construct_type,$equivalent_target_namespaces), self:label($construct_name),$annotation)"/>
	</xsl:function>
	<!-- Function that copies simple types -->
	<xsl:function name="self:add_referenced_group_attributes_domain" as="xsd:string">
		<xsl:param name="attribute"/>
		<xsl:param name="grp_name"/>
		<xsl:param name="class_name"/>
		<xsl:param name="grp_annotation"/>
		<xsl:param name="schema"/>
		<xsl:variable name="ref_name" select="string($attribute/@ref)"/>
		<xsl:variable name="attribute_name" select="if ($ref_name='') then string($attribute/@name) else $ref_name"/>
		<xsl:variable name="annotation" select="if (string($attribute/xsd:annotation/xsd:documentation)='') then $grp_annotation else self:comment(concat($grp_annotation,' ',$attribute/xsd:annotation/xsd:documentation))"/>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="contains($attribute_name,':')">
					<xsl:value-of select="self:rdf_uri_from_xsd_uri($attribute_name)"/>
				</xsl:when>
				<xsl:when test="$ref_name=''">
					<xsl:variable name="type">
						<xsl:choose>
							<xsl:when test="nilled($attribute/xsd:simpleType)=false()">
								<xsl:value-of select="self:unnamed_datatype_name($not_specified, concat($attribute/@name,'_',$grp_name))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$attribute/@type"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:value-of select="concat('#',self:property_from_group_name($attribute_name,$grp_name,$type))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($attribute_name,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($attribute_name)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($attribute_name)],$not_specified))"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="self:datatype_property(true(),$id, '',self:domain($class_name),'','',$annotation)"/>
	</xsl:function>
	<!-- Function that adds domain to properties representing referenced elements -->
	<xsl:function name="self:add_referenced_object_property_domain" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="class_name"/>
		<xsl:param name="datatype_annotation"/>
		<xsl:param name="schema"/>
		<xsl:variable name="element_name" select="string($element/@ref)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="id" select="self:produced_element_name($element,$class_name,$schema,'')"/>
		<xsl:value-of select="self:object_property(true(),$id, '',self:domain($class_name),'','',concat($datatype_annotation, ' ', $annotation))"/>
	</xsl:function>
	<!-- Function that adds domain to properties -->
	<xsl:function name="self:add_object_property_domain" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="class_name"/>
		<xsl:variable name="element_name" select="string($element/@name)"/>
		<xsl:variable name="id" select="self:property_name($element,'')"/>
		<xsl:value-of select="self:object_property(true(),$id, '',self:domain($class_name),'','','')"/>
	</xsl:function>
	<!-- Function that adds domain to properties representing referenced attributes -->
	<xsl:function name="self:add_referenced_datatype_domain" as="xsd:string">
		<xsl:param name="attribute"/>
		<xsl:param name="class_name"/>
		<xsl:param name="datatype_annotation"/>
		<xsl:param name="schema"/>
		<xsl:variable name="attribute_name" select="string($attribute/@ref)"/>
		<xsl:variable name="annotation" select="if (string($attribute/xsd:annotation/xsd:documentation)='') then '' else self:comment($attribute/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="contains($attribute_name,':')">
					<xsl:value-of select="self:rdf_uri_from_xsd_uri($attribute_name)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($attribute_name)],$not_specified))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="self:datatype_property(true(),$id, '',self:domain($class_name),'','',concat($datatype_annotation, ' ', $annotation))"/>
	</xsl:function>
	<!-- Function that adds domain to datatype properties -->
	<xsl:function name="self:add_datatype_domain" as="xsd:string">
		<xsl:param name="attribute"/>
		<xsl:param name="class_name"/>
		<xsl:variable name="attribute_name" select="string($attribute/@name)"/>
		<xsl:variable name="id" select="self:property_name($attribute,'')"/>
		<xsl:value-of select="self:datatype_property(true(),$id, '',self:domain($class_name),'','','')"/>
	</xsl:function>
	<!-- Function that copies simple types -->
	<xsl:function name="self:add_referenced_element_domain" as="xsd:string">
		<xsl:param name="element"/>
		<xsl:param name="class_name"/>
		<xsl:param name="datatype_annotation"/>
		<xsl:param name="schema"/>
		<xsl:variable name="element_name" select="string($element/@ref)"/>
		<xsl:variable name="annotation" select="if (string($element/xsd:annotation/xsd:documentation)='') then '' else self:comment($element/xsd:annotation/xsd:documentation)"/>
		<xsl:variable name="id">
			<xsl:choose>
				<xsl:when test="contains($element_name,':')">
					<xsl:value-of select="self:rdf_uri_from_xsd_uri($element_name)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('#',self:property_name($schema/xsd:element[string(./@name)=string($element_name)],$not_specified))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="self:datatype_property(true(),$id, '',self:domain($class_name),'','',concat($datatype_annotation, ' ', $annotation))"/>
	</xsl:function>
	<!-- Function that produces owl:ObjectProperty -->
	<!-- if reference is true, rdf:about is used, if false, rdf:ID -->
	<xsl:function name="self:object_property" as="xsd:string">
		<xsl:param name="reference"/>
		<xsl:param name="id"/>
		<xsl:param name="sub_group"/>
		<xsl:param name="domain"/>
		<xsl:param name="range"/>
		<xsl:param name="label"/>
		<xsl:param name="comment"/>
		<xsl:variable name="op_start">
			<xsl:choose>
				<xsl:when test="$reference">
					<xsl:value-of select="concat(string('&lt;owl:ObjectProperty rdf:about=&quot;#'), $id,string('&quot;&gt;&#10;&#9;&#9;'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat(string('&lt;owl:ObjectProperty rdf:ID=&quot;'), $id,string('&quot;&gt;&#10;&#9;&#9;'))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		
		
		<xsl:variable name="num_sub_tokens" as="xsd:integer">
			<xsl:value-of select="count($sub_group)"/>
		</xsl:variable>
		
		<xsl:variable name="keyrefRange" select="self:getHashTableValue($properties_referTo_hashtable,$id)"/>
		
		<xsl:choose>
			<xsl:when test="not($keyrefRange='')">
				<xsl:choose>
					<xsl:when test="$num_sub_tokens>1">
						<xsl:variable name="concated_sub_items"  select="string-join($sub_group,' ')"/>
						<xsl:value-of select="concat(string($op_start),$concated_sub_items,$domain,self:object_property_range($keyrefRange),$label,$comment,string('&lt;/owl:ObjectProperty&gt;&#10;&#9;'))"/>
					</xsl:when> 
					<xsl:otherwise>
						<xsl:value-of select="concat(string($op_start),$sub_group,$domain,self:object_property_range($keyrefRange),$label,$comment,string('&lt;/owl:ObjectProperty&gt;&#10;&#9;'))"/>
					</xsl:otherwise>
				</xsl:choose>				
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$num_sub_tokens>1">
						<xsl:variable name="concated_sub_items"  select="string-join($sub_group,' ')"/>
						<xsl:value-of select="concat(string($op_start),$concated_sub_items,$domain,$range,$label,$comment,string('&lt;/owl:ObjectProperty&gt;&#10;&#9;'))"/>
					</xsl:when> 
					<xsl:otherwise>
						<xsl:value-of select="concat(string($op_start),$sub_group,$domain,$range,$label,$comment,string('&lt;/owl:ObjectProperty&gt;&#10;&#9;'))"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		

		
		
	</xsl:function>
	
	
	<!-- Function that produces owl:Datatype properties -->
	<!-- if reference is true, rdf:about is used, if false, rdf:ID -->
	<xsl:function name="self:datatype_property" as="xsd:string">
		<xsl:param name="reference"/>
		<xsl:param name="id"/>
		<xsl:param name="sub_group"/>
		<xsl:param name="domain"/>
		<xsl:param name="range"/>
		<xsl:param name="label"/>
		<xsl:param name="comment"/>
		<xsl:variable name="dp_start">
			<xsl:choose>
				<xsl:when test="$reference">
					<xsl:value-of select="concat(string('&lt;owl:DatatypeProperty rdf:about=&quot;#'), $id,string('&quot;&gt;&#10;&#9;&#9;'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat(string('&lt;owl:DatatypeProperty rdf:ID=&quot;'), $id,string('&quot;&gt;&#10;&#9;&#9;'))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
		<xsl:variable name="num_sub_tokens" as="xsd:integer">
			<xsl:value-of select="count($sub_group)"/>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$num_sub_tokens>1">
				<xsl:variable name="concated_sub_items"  select="string-join($sub_group,' ')"/>
				<xsl:value-of select="concat(string($dp_start),$concated_sub_items,$domain,$range,$label,$comment,string('&lt;/owl:DatatypeProperty&gt;&#10;&#9;'))"/>
			</xsl:when> 
			<xsl:otherwise>
				<xsl:value-of select="concat(string($dp_start),$sub_group,$domain,$range,$label,$comment,string('&lt;/owl:DatatypeProperty&gt;&#10;&#9;'))"/>
			</xsl:otherwise>
		</xsl:choose>
		
	</xsl:function>
	
	<!-- Function that copies simple types -->
	<!-- This function is able to copy every element to the output xml file. -->
	<xsl:function name="self:copy_xsd_type" as="xsd:string">
		<xsl:param name="xsd_type"/>
		<xsl:variable name="name" select="$xsd_type/name()"/>
		<xsl:variable name="ret">
			<xsl:value-of disable-output-escaping="yes" select="concat('&#10;&lt;',string($name))"/>
			<xsl:for-each select="$xsd_type/@*">
				<xsl:variable name="data" select="concat('&quot;',self:escape(normalize-space(string(data(.)))),'&quot;')"/>
				<xsl:value-of disable-output-escaping="no" select="concat(' ',string(./name()),'=',$data)"/>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="'&gt;'"/>
			<xsl:for-each select="$xsd_type/node()">
				<xsl:choose>
					<xsl:when test="string(./name())=''">
						<xsl:value-of disable-output-escaping="no" select="self:escape(normalize-space(data(.)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:copy_xsd_type(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="concat('&#10;&#9;&lt;/',string($name),'&gt;')"/>
		</xsl:variable>
		<xsl:value-of select="string($ret)"/>
	</xsl:function>
	<!-- Function that copies simple types and names them with "name"-->
	<xsl:function name="self:copy_xsd_type_with_name" as="xsd:string">
		<xsl:param name="xsd_type"/>
		<xsl:param name="type_name"/>
		<xsl:variable name="name" select="$xsd_type/name()"/>
		<xsl:variable name="ret">
			<xsl:value-of disable-output-escaping="yes" select="concat('&#10;&lt;',string($name),' name=&quot;',$type_name,'&quot; ')"/>
			<xsl:for-each select="$xsd_type/@*">
				<xsl:variable name="data" select="concat('&quot;',self:escape(normalize-space(string(data(.)))),'&quot;')"/>
				<xsl:value-of disable-output-escaping="no" select="concat(' ',string(./name()),'=',$data)"/>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="'&gt;'"/>
			<xsl:for-each select="$xsd_type/node()">
				<xsl:choose>
					<xsl:when test="string(./name())=''">
						<xsl:value-of disable-output-escaping="no" select="self:escape(normalize-space(data(.)))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="self:copy_xsd_type(.)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="concat('&#10;&#9;&lt;/',string($name),'&gt;')"/>
		</xsl:variable>
		<xsl:value-of select="string($ret)"/>
	</xsl:function>
	<!-- Function that produces rdfs:Datatype elements from simple types -->
	<xsl:function name="self:datatype_from_simple_type" as="xsd:string">
		<xsl:param name="simple_type"/>
		<xsl:variable name="simple_type_name">
			<xsl:value-of select="$simple_type/@name"/>
		</xsl:variable>
		<xsl:variable name="dt_start">
			<xsl:value-of select="concat(string('&lt;rdfs:Datatype rdf:about=&quot;&amp;'),$datatype_entity_name,';',string($simple_type_name),string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="dt_end">
			<xsl:value-of select="string('&lt;/rdfs:Datatype&gt;')"/>
		</xsl:variable>
		<xsl:variable name="dt_def">
			<xsl:value-of select="concat('&lt;rdfs:isDefinedBy rdf:resource=&quot;&amp;',$datatype_entity_name,';&quot;/&gt;&#10;&#9;&#9;')"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($dt_start),string($dt_def),self:label($simple_type_name),string($dt_end),string('&#10;&#9;'))"/>
	</xsl:function>
	
	<xsl:function name="self:datatype_from_simple_type2">
		<xsl:param name="simple_type"/>
		<xsl:param name="preancestor_name"/>
		<xsl:param name="ancestor_name"/>
		<xsl:param name="nested_simpleTypes"/>
		<xsl:param name="position"/>
		<xsl:variable name="simple_type_name">
			<xsl:choose>
				<xsl:when test="$simple_type/@name!=''">
					<xsl:value-of select="$simple_type/@name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$position">
							<xsl:choose>
								<xsl:when test="$preancestor_name!=''">
									<xsl:value-of select="concat(self:unnamed_datatype_name($preancestor_name,$ancestor_name),'_',$position)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="concat(self:unnamed_datatype_name($not_specified,$ancestor_name),'_',$position)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:when>
						<xsl:otherwise>
							<xsl:choose>
								<xsl:when test="$preancestor_name!=''">
									<xsl:value-of select="self:unnamed_datatype_name($preancestor_name,$ancestor_name)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="self:unnamed_datatype_name($not_specified,$ancestor_name)"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="simple_type_Restriction" select="$simple_type/xsd:restriction"/>
		<xsl:variable name="simple_type_Union" select="$simple_type/xsd:union"/>
		<xsl:variable name="simple_type_List" select="$simple_type/xsd:list"/>
		
		<xsl:variable name="dt_start">
			<xsl:value-of select="concat(string('&lt;rdfs:Datatype rdf:ID=&quot;'),string($simple_type_name),string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="dt_end">
			<xsl:value-of select="string('&lt;/rdfs:Datatype&gt;')"/>
		</xsl:variable>
		<xsl:variable name="annotation" select="if (string($simple_type/xsd:annotation/xsd:documentation)='') then '' else self:comment($simple_type/xsd:annotation/xsd:documentation)"/>
		<xsl:choose>
			<xsl:when test="nilled($simple_type_Restriction)=false()">
				<xsl:variable name="equivalent_result_list" select="self:equivalentClass($simple_type_Restriction,'restriction',$ancestor_name,$simple_type_name,$nested_simpleTypes)"/>
				<xsl:value-of select="concat(string($dt_start),string($equivalent_result_list[1]),$annotation,string($dt_end),string('&#10;&#9;'))"/>
				<xsl:value-of select="$equivalent_result_list[2]"/>				
			</xsl:when>
			<xsl:when test="nilled($simple_type_Union)=false()">
				<xsl:variable name="equivalent_result_list" select="self:equivalentClass($simple_type_Union,'union',$ancestor_name,$simple_type_name,$nested_simpleTypes)"/>
				<xsl:value-of select="concat(string($dt_start),string($equivalent_result_list[1]),$annotation,string($dt_end),string('&#10;&#9;'))"/>
				<xsl:value-of select="$equivalent_result_list[2]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="equivalent_result_list" select="self:equivalentClass($simple_type_List,'list',$ancestor_name,$simple_type_name,$nested_simpleTypes)"/>
				<xsl:value-of select="concat(string($dt_start),string($equivalent_result_list[1]),$annotation,string($dt_end),string('&#10;&#9;'))"/>
				<xsl:value-of select="$equivalent_result_list[2]"/>		
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces the EQUIVALENT CLASS structure for the simple type generator-->
	<xsl:function name="self:equivalentClass">
		<xsl:param name="res_def" />
		<xsl:param name="type_def"/>
		<xsl:param name="preancestor_name"/>
		<xsl:param name="ancestor_name"/>
		<xsl:param name="nested_simpleTypes"/>
		<xsl:variable name="eq_start">
			<xsl:value-of select="string('&lt;owl:equivalentClass&gt;')" />
		</xsl:variable>
		<xsl:variable name="dt_start">
			<xsl:value-of select="string('&lt;rdfs:Datatype&gt;&#10;&#9;&#9;')" />
		</xsl:variable>

		<xsl:variable name="descr_start">
			<xsl:value-of select="string('&lt;rdf:Description&gt;&#10;&#9;&#9;')" />
		</xsl:variable>
		<xsl:variable name="descr_end">
			<xsl:value-of select="string('&lt;/rdf:Description&gt;')" />
		</xsl:variable>
		
		<xsl:variable name="dt_end">
			<xsl:value-of select="string('&lt;/rdfs:Datatype&gt;')"/>
		</xsl:variable>
		<xsl:variable name="eq_end">
			<xsl:value-of select="string('&lt;/owl:equivalentClass&gt;')" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$type_def='restriction'">
				<xsl:variable name="base">
					<xsl:choose>
						<xsl:when test="$res_def/@base!=''">
							<xsl:value-of select="$res_def/@base" />							
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="self:unnamed_datatype_name($preancestor_name,$ancestor_name)" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="ondt">
					<xsl:choose>
						<xsl:when test="contains($base,':')">
							<xsl:value-of select="concat(string('&lt;owl:onDatatype rdf:resource=&quot;'),self:rdf_uri_from_xsd_uri($base),string('&quot;/&gt;'))" />
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat(string('&lt;owl:onDatatype rdf:resource=&quot;'),string($base),string('&quot;/&gt;'))" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="withRes_start">
					<xsl:value-of select="string('&lt;owl:withRestrictions rdf:parseType=&quot;Collection&quot;&gt;')" />
				</xsl:variable>
				<xsl:variable name="withRes_end">
					<xsl:value-of select="string('&lt;/owl:withRestrictions&gt;')" />
				</xsl:variable>
				<xsl:variable name="withRes_def">
					<xsl:for-each select="$res_def/child::node()">
						<xsl:variable name="el_name" select="local-name(.)" />
						<xsl:choose>
							<xsl:when test="($el_name!='annotation') and ($el_name!='simpleType')">
								<xsl:variable name="el_value">
									<xsl:if test="./@value">
										<xsl:value-of select="./@value" />
									</xsl:if>
									<xsl:if test="./@test">
										<xsl:value-of select="./@test" />
									</xsl:if>
								</xsl:variable>
								<xsl:value-of select="concat(string('&lt;rdf:Description&gt;&lt;xs:'),$el_name,string('&gt;'),string($el_value),string('&lt;/xs:'),$el_name,string('&gt;'),string('&lt;/rdf:Description&gt;'))" />
							</xsl:when>
							<xsl:when test="($el_name='annotation')">
								<xsl:variable name="annotation" select="if (string(./xsd:documentation)='') then '' else self:comment(./xsd:documentation)"/>
								<xsl:value-of select="$annotation" />
							</xsl:when>
						</xsl:choose>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="concat(string($eq_start),string($dt_start),string($ondt),string($withRes_start),$withRes_def,string($withRes_end),string($dt_end),string($eq_end))" />
				<xsl:if test="not($res_def/@base)">
					<xsl:variable name="nested_datatype" select="self:datatype_from_simple_type2($res_def/xsd:simpleType,$preancestor_name,$ancestor_name,$nested_simpleTypes,'')"/>
					<xsl:value-of select="concat($nested_datatype[1],$nested_datatype[2])"/>
				</xsl:if>
			</xsl:when>
			<xsl:when test="$type_def='union'">
				<xsl:variable name="unionOf_start">
					<xsl:value-of select="string('&lt;owl:unionOf rdf:parseType=&quot;Collection&quot;&gt;')" />
				</xsl:variable>
				<xsl:variable name="unionOf_end">
					<xsl:value-of select="string('&lt;/owl:unionOf&gt;')" />
				</xsl:variable>
				<xsl:variable name="unionOf_def">
					<xsl:variable name="union_memberTypes" select="normalize-space($res_def/@memberTypes)"/>
					<xsl:choose>
						<xsl:when test="$union_memberTypes!=''">
							<xsl:variable name="memTypes_string"  select="tokenize($union_memberTypes,' ')" />
							<xsl:variable name="num_memberTypes" select="count($memTypes_string)"/>
							<xsl:for-each select="1 to xsd:integer($num_memberTypes)" >
								<xsl:variable name="i" select="." as="xsd:integer"/>
								<xsl:variable name="item">
									<xsl:value-of select="$memTypes_string[position()=$i]"/>
								</xsl:variable>
								<xsl:value-of select="concat(string('&lt;rdf:Description rdf:about=&quot;'),$item,string('&quot;/&gt;'))" />
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="num_union_list" select="count($res_def/xsd:simpleType)"/>
							<xsl:for-each select="1 to $num_union_list">
								<xsl:variable name="i" select="."/>
								<xsl:variable name="name_item" select="concat(self:unnamed_datatype_name($preancestor_name,$ancestor_name),'_',$i)"/>
								<xsl:value-of select="concat(string('&lt;rdf:Description rdf:about=&quot;'),$name_item,string('&quot;/&gt;'))" />
							</xsl:for-each>
							
							<xsl:if test="$res_def/xsd:annotation">
								<xsl:variable name="annotation" select="if (string($res_def/xsd:annotation/xsd:documentation)='') then '' else self:comment($res_def/xsd:annotation/xsd:documentation)"/>
								<xsl:value-of select="$annotation" />
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="concat(string($eq_start),string($dt_start),string($unionOf_start),$unionOf_def,string($unionOf_end),string($dt_end),string($eq_end))" />
				<xsl:if test="not($res_def/@memberTypes)">
					<xsl:variable name="num_union_list" select="count($res_def/xsd:simpleType)"/>
					<xsl:variable name="for_result">
						<xsl:for-each select="1 to $num_union_list">
							<xsl:variable name="i" select="."/>
							<xsl:variable name="item" select="$res_def/xsd:simpleType[$i]"/>
							<xsl:variable name="temp" select="$res_def/xsd:simpleType[$i]/xsd:restriction/@base"/>
							<xsl:variable name="nested_datatype" select="self:datatype_from_simple_type2($item,$preancestor_name,$ancestor_name,$nested_simpleTypes,$i)"/>
							<xsl:value-of select="concat($nested_datatype[1],$nested_datatype[2])"/>
						</xsl:for-each>
					</xsl:variable>
					<xsl:value-of select="$for_result"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="itemType">
					<xsl:choose>
						<xsl:when test="$res_def/@itemType!=''">
							<xsl:value-of select="$res_def/@itemType" />							
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="self:unnamed_datatype_name($preancestor_name,$ancestor_name)" />
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="one_start">
					<xsl:value-of select="string('&lt;owl:oneOf&gt;')" />
				</xsl:variable>
				<xsl:variable name="one_end">
					<xsl:value-of select="string('&lt;/owl:oneOf&gt;')" />
				</xsl:variable>
				<xsl:variable name="ondt">
					<xsl:value-of select="concat(string('&lt;owl:onDatatype rdf:resource=&quot;'),string('&amp;xsd;'),string($itemType),string('&quot;/&gt;'))" />
				</xsl:variable>
				
				<xsl:variable name="one_body">
					<xsl:if test="$res_def/xsd:annotation">
						<xsl:variable name="annotation" select="if (string($res_def/xsd:annotation/xsd:documentation)='') then '' else self:comment($res_def/xsd:annotation/xsd:documentation)"/>
						<xsl:value-of select="$annotation" />
					</xsl:if>
					<xsl:variable name="rdf_type">
						<xsl:value-of select="string('&lt;rdf:type rdf:resource=&quot;#List&quot;/&gt;')"/>
					</xsl:variable>
					<xsl:variable name="rdf_rest">
						<xsl:value-of select="string('&lt;rdf:rest rdf:resource=&quot;#nil&quot;/&gt;')"/>
					</xsl:variable>
					<xsl:variable name="first_start">
						<xsl:value-of select="string('&lt;rdf:first&gt;')"/>
					</xsl:variable>
					<xsl:variable name="first_end">
						<xsl:value-of select="string('&lt;/rdf:first&gt;')"/>
					</xsl:variable>
					<xsl:value-of select="concat(string('&lt;rdf:Description&gt;'),$rdf_type,$first_start,$itemType,$first_end,$rdf_rest,string('&lt;/rdf:Description&gt;'))" />
				</xsl:variable>
				<xsl:value-of select="concat(string($eq_start),string($dt_start),string($one_start),string($one_body),string($one_end),string($dt_end),string($eq_end))" />
				<xsl:if test="not($res_def/@itemType)">
					<xsl:variable name="nested_datatype" select="self:datatype_from_simple_type2($res_def/xsd:simpleType,$preancestor_name,$ancestor_name,$nested_simpleTypes,'')"/>
					<xsl:value-of select="concat($nested_datatype[1],$nested_datatype[2])"/>
				</xsl:if>			
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- EO Equivalent Class -->
	
	<!-- Function that retrieves the value of a HashTable key-value pair  -->
	<xsl:function name="self:getHashTableValue">
		<xsl:param name="hashtable" />
		<xsl:param name="key" />
		
		<xsl:variable name="seperator" select="','"/>
		<xsl:variable name="value">
			<xsl:if test="contains(substring-after($hashtable, concat('key:', $key, $seperator)), 'key:')">
				<xsl:value-of select="substring-before(substring-after($hashtable, concat('key:', $key, $seperator)), concat($seperator, 'key:'))" />
			</xsl:if>
			<xsl:if test="not(contains(substring-after($hashtable, concat('key:', $key, $seperator)), 'key:'))">
				<xsl:value-of select="substring-after($hashtable, concat('key:', $key, $seperator))" />
			</xsl:if>
		</xsl:variable>
		
		<xsl:value-of select="string($value)"/>
	</xsl:function>
	
	<!-- Function that inserts into a HashTable, one new key-value pair.
		 Returns the new HashTable. -->
	<xsl:function name="self:add_HashTable_Pair">
		<xsl:param name="hashtable" />
		<xsl:param name="key" />
		<xsl:param name="value" />
		
		<xsl:variable name="AddNewPair">
			<xsl:if test="contains($hashtable, 'key')">
				<xsl:value-of select="concat($hashtable,',','key:', $key ,',',$value)" />
			</xsl:if>
			<xsl:if test="not(contains($hashtable, 'key'))">
				<xsl:value-of select="concat('key:', $key ,',',$value)" />
			</xsl:if>
		</xsl:variable>
		
		<xsl:value-of select="string($AddNewPair)"/>
	</xsl:function>
	
	<!-- Function that produces owl:Class owl:HasKey from unique element -->
	<xsl:function name="self:HasKey">
		<xsl:param name="identity_constraint_nodes"/>
		<xsl:param name="el_name"/>
		<xsl:param name="el_type"/>
		
		<xsl:variable name="selector_xpath" select="$identity_constraint_nodes/xsd:selector/@xpath"/>
		
		<!--<xsl:variable name="RestrictionID" select="concat($el_name,'_',$identity_constraint_nodes/@name,'_',$el_type)"/>
		<xsl:variable name="descr_start">
			<xsl:value-of select="concat('&lt;owl:Restriction rdf:ID=&quot;',$RestrictionID,'&quot; &gt;&#10;&#9;&#9;')" />
		</xsl:variable>
		<xsl:variable name="descr_end">
			<xsl:value-of select="string('&lt;/owl:Restriction&gt;')" />
		</xsl:variable>
		<xsl:variable name="descr_start2">
			<xsl:value-of select="concat('&lt;owl:Restriction rdf:about=&quot;',$RestrictionID,'&quot; &gt;&#10;&#9;&#9;')" />
		</xsl:variable>-->
		
		<!--<xsl:variable name="onProperty">
			<xsl:value-of select="concat('&lt;owl:onProperty rdf:resource=&quot;#',$el_name ,'&quot;/&gt;&#10;&#9;&#9;')" />
		</xsl:variable>-->
	
		<xsl:variable name="hasKey_start">
			<xsl:value-of select="string('&lt;owl:hasKey rdf:parseType=&quot;Collection&quot;&gt;&#10;&#9;&#9;')" />
		</xsl:variable>
		<xsl:variable name="hasKey_end">
			<xsl:value-of select="string('&lt;/owl:hasKey&gt;')" />
		</xsl:variable>
		
		<!-- Addon to serve multiple paths. -->
		<xsl:variable name="selector_tokens"  select="tokenize($selector_xpath,'\|')"/>
		<xsl:variable name="num_selector_tokens" select="count($selector_tokens)"/>
		<xsl:for-each select="1 to xsd:integer($num_selector_tokens)" >
			<xsl:variable name="i" select="." as="xsd:integer"/>
			<xsl:variable name="selector_item">
				<xsl:value-of select="$selector_tokens[position()=$i]"/>
			</xsl:variable>
			
			<xsl:variable name="hasKey_def">
				<xsl:for-each select="$identity_constraint_nodes/xsd:field">
					<xsl:variable name="field_xpath" select="@xpath"/>
					<xsl:variable name="propertyID" select=" self:XPath_field_to_propertyID($selector_item,$field_xpath)"/>
					<xsl:value-of select="concat(string('&lt;rdf:Description rdf:about=&quot;#'),$propertyID,string('&quot;/&gt;'))"/>
				</xsl:for-each>
			</xsl:variable>
		
			<xsl:value-of select="concat($hasKey_start,$hasKey_def,$hasKey_end)"/>
				
			
		</xsl:for-each>
	</xsl:function>
	
	<!-- OBSOLETE - Function that analyzes an XPath and returns a node tree of the evaluation of Xpath -->
	<xsl:function name="self:Xpath_analyzer" as="xsd:string">
		<xsl:param name="xpath"/>

		<!-- <xsl:message>
			<xsl:value-of select="'XPATH_ANALYZER_Start'"/>
		</xsl:message>
		<xsl:message>
			<xsl:value-of select="concat('xpath:  ',$xpath)"/>
		</xsl:message> -->
		<!--<xsl:message>
			<xsl:value-of select="concat('GROUPS: ',$named_groups)"/>
		</xsl:message>-->
		<!--<xsl:variable name="testRoot" select="$schema_element//node()[./@name='PersonType']"></xsl:variable>
		<xsl:message>
			<xsl:value-of select="concat('TESTING place: ',string(local-name(($testRoot//node())[1])))"/>
		</xsl:message>-->
		<!--<xsl:message>
			<xsl:value-of select="concat('ELEMENTS: ',$named_elements)"/>
		</xsl:message>-->
		
		<xsl:variable name="element_tokens"  select="tokenize($named_elements,' ')" />
		<xsl:variable name="num_element_tokens" select="count($element_tokens)"/>
		<xsl:variable name="result">
			<xsl:for-each select="1 to xsd:integer($num_element_tokens)" >
				<xsl:variable name="i" select="." as="xsd:integer"/>
				<xsl:variable name="item">
					<xsl:value-of select="$element_tokens[position()=$i]"/>
				</xsl:variable>
				
				<xsl:variable name="el_name" as="xsd:string">
					<xsl:value-of select="substring-before($item,'%')"/>
				</xsl:variable>
				<xsl:if test="$el_name=$xpath">
					<xsl:variable name="el_type" as="xsd:string">
						<xsl:value-of select="substring-after($item,'%')"/>
					</xsl:variable>
					<!-- <xsl:message>
						<xsl:value-of select="self:property_name_guesstimate($el_name,$el_type,'personGroup')"/>
							
					</xsl:message> -->
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:value-of select="$result"/>
		<!-- <xsl:message>
			<xsl:value-of select="'XPATH_ANALYZER_End'"/>
		</xsl:message> -->
	</xsl:function>
	
	<!-- OBSOLETE  -->
	<!-- Function that evaluates an XPath.  -->
	<!-- Params: xpath (string)
				 pre_xpath_nodeTree. It forces a change of the starting point of evaluation. (node tree) 
		  		 Returns a node tree.
	-->			 
	<xsl:function name="self:XPath_evaluator">
		<xsl:param name="xpath"/>
		<xsl:param name="pre_xpath_nodeTree"/>
		<xsl:choose>
			<xsl:when test="$xpath">
				<!-- root_dashes boolean answers if field xpath contains root step or not. -->
				<xsl:variable name="root_dashes" select="contains($xpath,'.//')"/>
				
				<!-- field_wo_root=field - (.//) -->
				<xsl:variable name="xpath_wo_root" select="replace($xpath,'.//','')"/>
				
				<!-- split at '/' -->
				<xsl:variable name="xpath_current_element" select="if (contains($xpath_wo_root,'/')) then (substring-before($xpath_wo_root,'/'))
						else ($xpath_wo_root)"/>
				<xsl:variable name="xpath_remainder" select="if (contains($xpath_wo_root,'/')) then (substring-after($xpath_wo_root,'/'))
						else ()"/>
			
				<xsl:choose>
					<xsl:when test="$root_dashes">
						<xsl:sequence select="self:XPath_evaluator($xpath_remainder,$schema_element//node()[./@name=$xpath_current_element])"/>
					</xsl:when>
					<xsl:when test="nilled($pre_xpath_nodeTree)=false()">
						<xsl:sequence select="self:XPath_evaluator($xpath_remainder,$pre_xpath_nodeTree//node()[./@name=$xpath_current_element])"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="self:XPath_evaluator($xpath_remainder,$schema_element//node()[./@name=$xpath_current_element])"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$pre_xpath_nodeTree"/>
			</xsl:otherwise>
		</xsl:choose>
		
	
		<!-- count tokenized components -->
		<!--<xsl:variable name="num_xpath_components" select="count($xpath_components)"/>-->
		
		<!--<xsl:variable name="firstElement">
			<xsl:choose>
				<xsl:when test="nilled($pre_xpath_nodeTree)=false()">
					<xsl:copy-of select="$pre_xpath_nodeTree"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select="$schema_element"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>-->
		
		<!--<xsl:for-each select="1 to xsd:integer($num_xpath_components)" >
			<xsl:variable name="i" select="." as="xsd:integer"/>
			<xsl:variable name="item">
				<xsl:value-of select="$xpath_components[position()=$i]"/>
			</xsl:variable>
		</xsl:for-each>
		

		<xsl:variable name="result">
			<xsl:for-each select="1 to xsd:integer($num_element_tokens)" >
				<xsl:variable name="i" select="." as="xsd:integer"/>
				<xsl:variable name="item">
					<xsl:value-of select="$element_tokens[position()=$i]"/>
				</xsl:variable>
				
				<xsl:variable name="el_name" as="xsd:string">
					<xsl:value-of select="substring-before($item,'%')"/>
				</xsl:variable>
				<xsl:if test="$el_name=$xpath">
					<xsl:variable name="el_type" as="xsd:string">
						<xsl:value-of select="substring-after($item,'%')"/>
					</xsl:variable>
					<xsl:message>
						<xsl:value-of select="self:property_name_guesstimate($el_name,$el_type,'personGroup')"/>
						
					</xsl:message>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>-->
		
		
		<!--<xsl:for-each select="1 to xsd:integer($num_xpath_components)">
			<xsl:variable name="i" select="." as="xsd:integer"/>
			<xsl:variable name="item">
				<xsl:value-of select="$xpath_components[position()=$i]"/>
			</xsl:variable>
			<xsl:sequence select="self:XPath_evaluator($item,$firstElement)"/>
			
			<xsl:sequence select="$schema_element//node()[./@name='PersonType']"/>
		</xsl:for-each>-->
		
	</xsl:function>
	
	<!-- Function that evaluates a Selector/Field subset XPath.  -->
	<!-- Params: xpath (string)
		 pre_xpath_nodeTree. It forces a change of the starting point of evaluation. (node tree) 
		 group_name (string). Einai keno (''), pernei timi mono otan emfanistei kapoio group.
		 
		 #Returns a node tree.
	-->	
	<xsl:function name="self:XPath_keys_evaluator">
		<xsl:param name="xpath"/>
		<xsl:param name="pre_xpath_nodeTree"/>
		<xsl:param name="group_name"/>
		
		<xsl:choose>
			<xsl:when test="$xpath">
				<!-- root_dashes boolean answers if field xpath contains root step or not. -->
				<xsl:variable name="root_dashes" select="contains($xpath,'.//')"/>
				
				<!-- field_wo_root=field - (.//) -->
				<xsl:variable name="xpath_wo_root" select="replace($xpath,'.//','')"/>
				
				<!-- split at '/' -->
				<xsl:variable name="xpath_current_element" select="if (contains($xpath_wo_root,'/')) then (substring-before($xpath_wo_root,'/'))
					else ($xpath_wo_root)"/>
				<xsl:variable name="xpath_remainder" select="if (contains($xpath_wo_root,'/')) then (substring-after($xpath_wo_root,'/'))
					else ()"/>
				
				<!-- If current element is an attribute -->
				<xsl:variable name="xpath_current_element_wo_at" select="if (contains($xpath_current_element,'@')) then (replace($xpath_current_element,'@','')) else ($xpath_current_element)"/>
				
				<xsl:choose>
					<xsl:when test="$root_dashes">
						<xsl:sequence select="self:XPath_keys_evaluator($xpath_remainder,$schema_element//node()[./@name=$xpath_current_element_wo_at],$group_name)"/>
					</xsl:when>
					<xsl:when test="nilled($pre_xpath_nodeTree)=false()">
						
						<xsl:variable name="temp_result" select="$pre_xpath_nodeTree//node()[./@name=$xpath_current_element_wo_at]"/>
						
						<xsl:choose>
							<xsl:when test="$temp_result">
								<xsl:sequence select="self:XPath_keys_evaluator($xpath_remainder,$pre_xpath_nodeTree//node()[./@name=$xpath_current_element_wo_at],$group_name)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:variable name="temp_type" select="$pre_xpath_nodeTree/@type"/>
								<xsl:variable name="temp_ref" select="$pre_xpath_nodeTree/@ref"/>
								<xsl:variable name="temp_group_ref" select="$pre_xpath_nodeTree/child::node()[local-name()='group']/@ref"/>
								<xsl:variable name="temp_attr_group_ref" select="$pre_xpath_nodeTree/child::node()[local-name()='attributeGroup']/@ref"/>
								<xsl:choose>
									<xsl:when test="$schema_element//node()[./@name=$temp_type]">
										<xsl:sequence select="self:XPath_keys_evaluator($xpath,$schema_element//node()[./@name=$temp_type],$group_name)"/>
									</xsl:when>
									<xsl:when test="$schema_element//node()[./@name=$temp_ref]">
										<xsl:sequence select="self:XPath_keys_evaluator($xpath,$schema_element//node()[./@name=$temp_ref],$group_name)"/>
									</xsl:when>
									<xsl:when test="$schema_element//node()[./@name=$temp_group_ref]">
										<xsl:sequence select="self:XPath_keys_evaluator($xpath,$schema_element//node()[./@name=$temp_group_ref],$temp_group_ref)"/>
									</xsl:when>
									<xsl:when test="$schema_element//node()[./@name=$temp_attr_group_ref]">
										<xsl:sequence select="self:XPath_keys_evaluator($xpath,$schema_element//node()[./@name=$temp_attr_group_ref],$temp_attr_group_ref)"/>
									</xsl:when>
								</xsl:choose>
							</xsl:otherwise>
						</xsl:choose>
						
					</xsl:when>
					<xsl:otherwise>
						<xsl:sequence select="self:XPath_keys_evaluator($xpath_remainder,$schema_element//node()[./@name=$xpath_current_element_wo_at],$group_name)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="$pre_xpath_nodeTree,$group_name"/>
			</xsl:otherwise>
		</xsl:choose>
		
			
		
	</xsl:function>
	
	<!-- Function that returns property ID from a field.   -->
	<!-- Params: Selector_xpath is an XPath (string)
				 Field_xpath is an XPath (string)
		 Returns owl property ID. (string)
	-->			 
	<xsl:function name="self:XPath_field_to_propertyID">
		<xsl:param name="selector_xpath"/>
		<xsl:param name="field_xpath"/>
		
		<xsl:variable name="selector_nodes" select="self:XPath_keys_evaluator($selector_xpath,node()[false()],'')"/>
		<xsl:variable name="selected_node" select="self:XPath_keys_evaluator($field_xpath,$selector_nodes[1],$selector_nodes[2])"/>
		
		<xsl:variable name="name">
			<xsl:value-of select="$selected_node[1]/@name"/>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:value-of select="$selected_node[1]/@type"/>
		</xsl:variable>
		
		<xsl:value-of select="self:property_name_guesstimate($name,$type,$selected_node[2])"/>
		
	</xsl:function>
	
	<!-- Function that returns property ID from a selector.   -->
	<!-- Params: Selector_xpath is an XPath (string)
 		 Returns owl property ID. (string)
	-->			 
	<xsl:function name="self:XPath_selector_to_propertyID">
		<xsl:param name="selector_xpath"/>
		
		<xsl:variable name="selector_nodes" select="self:XPath_keys_evaluator($selector_xpath,node()[false()],'')"/>
		
		<xsl:variable name="name">
			<xsl:value-of select="$selector_nodes[1]/@name"/>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:value-of select="$selector_nodes[1]/@type"/>
		</xsl:variable>
			
		<xsl:value-of select="self:property_name_guesstimate($name,$type,$selector_nodes[2])"/>
		
	</xsl:function>
	
	<!-- Function that finds the Class that corresponds to a selector path within an identity constraint -->
	<xsl:function name="self:XPath_selectorRange_to_classID">
		<xsl:param name="selector_xpath"/>
		
		<xsl:variable name="selector_nodes" select="self:XPath_keys_evaluator($selector_xpath,node()[false()],'')"/>
	
		<xsl:variable name="type">
			<xsl:value-of select="$selector_nodes[1]/@type"/>
		</xsl:variable>
		
		<xsl:value-of select="$type"/>
		
	</xsl:function>
	
	
	<!-- Function that produces datatype property with owl:FunctionalProperty from key element -->
	<xsl:function name="self:datatype_property_for_functional" as="xsd:string">
		<xsl:param name="reference"/>
		<xsl:variable name="dp_start">
			<xsl:value-of select="concat(string('&lt;owl:DatatypeProperty rdf:about=&quot;'), $reference,string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($dp_start),string(self:functional_property()),string('&lt;/owl:DatatypeProperty&gt;&#10;&#9;'))"/>
	</xsl:function>
	
	<!-- Function that produces object property with owl:FunctionalProperty from key element -->
	<xsl:function name="self:object_property_for_functional" as="xsd:string">
		<xsl:param name="reference"/>
		<xsl:variable name="op_start">
			<xsl:value-of select="concat(string('&lt;owl:ObjectProperty rdf:about=&quot;'), $reference,string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($op_start),string(self:functional_property()),string('&lt;/owl:ObjectProperty&gt;&#10;&#9;'))"/>
	</xsl:function>
	
	<!-- Function that produces owl:Ontology from the xml schema -->
	<xsl:function name="self:ontology_from_schema" as="xsd:string">
		<xsl:param name="schema"/>
		<xsl:variable name="ontology_start">
			<xsl:value-of select="string('&#10;&#9;&lt;owl:Ontology rdf:about=&quot;&quot;&gt;&#10;&#9;&#9;')"/>
		</xsl:variable>
		<xsl:variable name="ontology_end">
			<xsl:value-of select="string('&lt;/owl:Ontology&gt;')"/>
		</xsl:variable>
		<xsl:variable name="d_comment">
			<xsl:value-of select="self:enclosed_xml_comment(concat('In the &quot;',$datatype_entity_name,'&quot; entity, we refer to the file with the simple datatypes produced from the original schema.'),'#',85)"/>
		</xsl:variable>
		<xsl:variable name="i_comment">
			<xsl:value-of select="self:enclosed_xml_comment('The imported and included files in the xsd follow - Should be double-checked for existence and if they should be imported using owl:imports.','#',113)"/>
		</xsl:variable>
		<xsl:variable name="import_include">
			<xsl:for-each select="$schema/xsd:import">
				<xsl:value-of select="self:xml_comment(concat('&lt;import namespace=&quot;',./@namespace,'&quot; schemaLocation=&quot;',./@schemaLocation,'&quot;/&gt;'))"/>
			</xsl:for-each>
			<xsl:for-each select="$schema/xsd:include">
				<xsl:value-of select="self:xml_comment(concat('&lt;include schemaLocation=&quot;',./@schemaLocation,'&quot;/&gt;'))"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="annotation" select="if (string($schema/xsd:annotation/xsd:documentation)='') then '' else self:comment($schema/xsd:annotation/xsd:documentation)"/>
		<xsl:value-of select="concat(string($ontology_start),$i_comment,$import_include,$d_comment,$annotation,string($ontology_end),string('&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that element information  -->
	<xsl:function name="self:element_info" as="xsd:string">
		<xsl:param name="name"/>
		<xsl:param name="op_id"/>
		<xsl:param name="el_id"/>
		<xsl:variable name="start" select="concat('&lt;ox:ElementInfoType rdf:ID=&quot;',$name,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="op" select="concat('&lt;ox:propertyID&gt;',$op_id,'&lt;/ox:propertyID&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="ei" select="concat('&lt;ox:elementID&gt;',$el_id,'&lt;/ox:elementID&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:ElementInfoType&gt;&#10;&#9;'"/>
		<xsl:value-of select="concat($start,$op,$ei, $end)"/>
	</xsl:function>
	<!-- Function that datatype property information  -->
	<xsl:function name="self:datatype_property_info" as="xsd:string">
		<xsl:param name="name"/>
		<xsl:param name="dp_id"/>
		<xsl:param name="att_id"/>
		<xsl:param name="type"/>
		<xsl:variable name="start" select="concat('&lt;ox:DatatypePropertyInfoType rdf:ID=&quot;',$name,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="dp" select="concat('&lt;ox:datatypePropertyID&gt;',$dp_id,'&lt;/ox:datatypePropertyID&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="att" select="if (string($att_id)='') then '' else concat('&lt;ox:XMLConstructID&gt;',$att_id,'&lt;/ox:XMLConstructID&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="type" select="concat('&lt;ox:datatypePropertyType&gt;',$type,'&lt;/ox:datatypePropertyType&gt;&#10;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:DatatypePropertyInfoType&gt;&#10;&#9;'"/>
		<xsl:value-of select="concat($start,$dp,$att,$type,$end)"/>
	</xsl:function>
	<!-- Function that produces "subclass"attribute information for owl2xml -->
	<xsl:function name="self:sc_att_info" as="xsd:string">
		<xsl:param name="ext"/>
		<xsl:param name="class"/>
		<xsl:variable name="name" select="concat('content__',replace($ext/@base,':','_'))"/>
		<xsl:value-of select="self:datatype_property_info(concat($class,'_',$name),$name,'','Extension')"/>
	</xsl:function>
	<!-- Function that produces group information for owl2xml -->
	<xsl:function name="self:group_container_info">
		<xsl:param name="group_container"/>
		<xsl:param name="group_name"/>
		<xsl:param name="schema"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:for-each select="$group_container/xsd:element[string(./@ref)='']">
			<xsl:variable name="is_simple_type" select="self:is_simple_type(./@type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean(./xsd:simpleType))"/>
			<xsl:variable name="name" select="replace(self:produced_element_name(.,$not_specified,$schema,$group_name),'#','')"/>
			<xsl:if test="$is_simple_type">
				<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_info($name,$name,./@name,'Element')"/>
			</xsl:if>
			<xsl:if test="./xsd:simpleType">
				<xsl:value-of select="self:st_info(./xsd:simpleType,$schema,$not_specified,concat(./@name,'_',$group_name),'','')"/>
			</xsl:if>
			<xsl:value-of disable-output-escaping="yes" select="self:element_info(concat($name,'__ei'),$name,./@name)"/>
		</xsl:for-each>
		<xsl:for-each select="$group_container/xsd:sequence,$group_container/xsd:choice">
			<xsl:value-of select="self:group_container_info(.,$group_name,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that produces attribute from attribute group information for owl2xml -->
	<xsl:function name="self:att_from_group_info" >
		<xsl:param name="att"/>
		<xsl:param name="ag_name"/>
		<xsl:param name="schema"/>
		<xsl:choose>
			<xsl:when test="string($att/@ref)=''">
				<xsl:variable name="type">
					<xsl:choose>
						<xsl:when test="nilled($att/xsd:simpleType)=false()">
							<xsl:value-of select="self:unnamed_datatype_name($not_specified, concat($att/@name,'_',$ag_name))"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$att/@type"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:variable name="name" select="self:property_from_group_name($att/@name,$ag_name,$type)"/>
				<xsl:value-of select="self:datatype_property_info($name,$name,$att/@name,'Attribute')"/>
				<xsl:if test="nilled($att/xsd:simpleType)=false()">
					<xsl:value-of select="self:st_info($att/xsd:simpleType,$schema,$not_specified,$att/@name,'','')"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="''"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Function that produces top-level attribute information for owl2xml -->
	<xsl:function name="self:top_element_info">
		<xsl:param name="element"/>
		<xsl:param name="schema"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="is_simple_type" select="self:is_simple_type($element/@type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($element/xsd:simpleType))  "/>
		<xsl:variable name="name" select="self:property_name($element,$not_specified)"/>
		<xsl:if test="$is_simple_type">
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_info($name,$name,$element/@name,'Element')"/>
		</xsl:if>
		<xsl:value-of disable-output-escaping="yes" select="self:element_info(concat($name,'__ei'),$name,$element/@name)"/>
		<xsl:if test="$element/xsd:simpleType">
			<xsl:value-of select="self:st_info($element/xsd:simpleType,$schema,$not_specified,$element/@name,'','')"/>
		</xsl:if>
		<xsl:if test="$element/xsd:alternative">
			<xsl:variable name="alt_end" select="'&lt;/ox:AlternativeTypeInfoType&gt;'"/>
			
			<xsl:variable name="alt_pid_start" select="'&lt;ox:propertyID&gt;'"/>
			<xsl:variable name="alt_pid_end" select="'&lt;/ox:propertyID&gt;'"/>
			
			<xsl:variable name="alt_assert_start" select="'&lt;ox:alternativeAssert&gt;'"/>
			<xsl:variable name="alt_assert_end" select="'&lt;/ox:alternativeAssert&gt;'"/>
			
			<xsl:variable name="alt_type_start" select="'&lt;ox:alternativeType&gt;'"/>
			<xsl:variable name="alt_type_end" select="'&lt;/ox:alternativeType&gt;'"/>
			
			<xsl:variable name="alternatives" select="$element/xsd:alternative"/>
			<xsl:variable name="altCount" select="count($alternatives)"/>
			<xsl:for-each select="1 to $altCount">
				<xsl:variable name="i" select="."/>
				<xsl:variable name="item" select="$alternatives[position()=$i]"/>
				<xsl:variable name="altType">
					<xsl:choose>
						<xsl:when test="$item/@type">
							<xsl:value-of select="$item/@type"/>
						</xsl:when>
						<xsl:when test="$item/xsd:simpleType">
							<xsl:value-of select="self:unnamed_datatype_name($name,$i)"/>
						</xsl:when>
						<xsl:when test="$item/xsd:complexType">
						</xsl:when>
					</xsl:choose>
				</xsl:variable>

				<xsl:variable name="altAssertion" select="$item/@test"/>
				
				<xsl:variable name="AltID" select="concat($name,'_',$altType,'_ai')"/>
				
				<xsl:variable name="alt_start" select="concat('&lt;ox:AlternativeTypeInfoType rdf:ID=&quot;',$AltID,'&quot;&gt;')"/>
				
				<xsl:value-of select="concat($alt_start,$alt_pid_start,$name,$alt_pid_end,$alt_assert_start,$altAssertion,$alt_assert_end,$alt_type_start,$altType,$alt_type_end,$alt_end)"/>
				<xsl:if test="$item/xsd:simpleType">
					<xsl:value-of select="self:st_info($item,$schema,$name,$i,'','')"/>
				</xsl:if>
			</xsl:for-each>
		</xsl:if>
		<xsl:if test="$element/xsd:unique">
			<xsl:variable name="RestrictionID" select="concat($element/@name,'_',$element/xsd:unique/@name,'_',$element/@type)"/>
			<xsl:value-of select="self:HasKey_info($RestrictionID,self:XPath_selectorRange_to_classID($element/xsd:unique/xsd:selector/@xpath),'',$element/xsd:unique/@name,'',$element/@name,$element/xsd:unique/xsd:selector/@xpath,$element/xsd:unique/xsd:field,'unique')"/>
		</xsl:if>
		<xsl:if test="$element/xsd:key">
			<xsl:variable name="RestrictionID" select="concat($element/@name,'_',$element/xsd:key/@name,'_',$element/@type)"/>
			<xsl:value-of select="self:HasKey_info($RestrictionID,self:XPath_selectorRange_to_classID($element/xsd:key/xsd:selector/@xpath),'',$element/xsd:key/@name,'',$element/@name,$element/xsd:key/xsd:selector/@xpath,$element/xsd:key/xsd:field,'key')"/>
		</xsl:if>
		<xsl:if test="$element/xsd:keyref">
			<xsl:variable name="RestrictionID" select="concat($element/@name,'_',$element/xsd:keyref/@name,'_',$element/@type)"/>
			<xsl:value-of select="self:HasKey_info($RestrictionID,'',self:XPath_selector_to_propertyID($element/xsd:keyref/xsd:selector/@xpath),$element/xsd:keyref/@name,$element/xsd:keyref/@refer,$element/@name,$element/xsd:keyref/xsd:selector/@xpath,$element/xsd:keyref/xsd:field,'keyref')"/>
		</xsl:if>
	</xsl:function>
	
	<!-- Function that creates the instances of mapping ontology about identity constraints -->
	<xsl:function name="self:HasKey_info">
		<xsl:param name="restrictionID"/>
		<xsl:param name="classID"/>
		<xsl:param name="opID"/>
		<xsl:param name="ICName"/>
		<xsl:param name="referKey"/>
		<xsl:param name="HostElementID"/>
		<xsl:param name="selectorPath"/>
		<xsl:param name="fieldsPaths"/>
		<xsl:param name="constrType"/>
		
		<xsl:variable name="field_start" select="'&lt;ox:fieldPath&gt;'"/>
		<xsl:variable name="field_end" select="'&lt;/ox:fieldPath&gt;'"/>
		
		<xsl:variable name="selector_start" select="'&lt;ox:selectorPath&gt;'"/>
		<xsl:variable name="selector_end" select="'&lt;/ox:selectorPath&gt;'"/>
		
		<xsl:variable name="constraintType_start" select="'&lt;ox:constraintType&gt;'"/>
		<xsl:variable name="constraintType_end" select="'&lt;/ox:constraintType&gt;'"/>
		
		<xsl:variable name="classID_start" select="'&lt;ox:classID&gt;'"/>
		<xsl:variable name="classID_end" select="'&lt;/ox:classID&gt;'"/>
		
		<xsl:variable name="opID_start" select="'&lt;ox:opID&gt;'"/>
		<xsl:variable name="opID_end" select="'&lt;/ox:opID&gt;'"/>
		
		<xsl:variable name="ICName_start" select="'&lt;ox:ICName&gt;'"/>
		<xsl:variable name="ICName_end" select="'&lt;/ox:ICName&gt;'"/>
		
		<xsl:variable name="RefersTo_start" select="'&lt;ox:RefersTo&gt;'"/>
		<xsl:variable name="RefersTo_end" select="'&lt;/ox:RefersTo&gt;'"/>
		
		<xsl:variable name="HostELementID_start" select="'&lt;ox:HostELementID&gt;'"/>
		<xsl:variable name="HostELementID_end" select="'&lt;/ox:HostELementID&gt;'"/>
		
		<xsl:variable name="IdentityConst_start" select="concat('&lt;ox:IdentityConstraintInfoType rdf:ID=&quot;',$restrictionID,'_ui&quot; ','&gt;')"/>
		<xsl:variable name="IdentityConst_end" select="'&lt;/ox:IdentityConstraintInfoType&gt;'"/>
		
		<xsl:variable name="ICProperties_start" select="'&lt;ox:ICProperties&gt;'"/>
		<xsl:variable name="ICProperties_end" select="'&lt;/ox:ICProperties&gt;'"/>
		
		<xsl:variable name="ICPropertyType_start" select="'&lt;ox:ICPropertyType&gt;'"/>
		<xsl:variable name="ICPropertyType_end" select="'&lt;/ox:ICPropertyType&gt;'"/>
		
		<xsl:variable name="Property_start" select="'&lt;ox:Property&gt;'"/>
		<xsl:variable name="Property_end" select="'&lt;/ox:Property&gt;'"/>
		
		<xsl:variable name="fieldsCount" select="count($fieldsPaths)"/>
		<xsl:variable name="fieldDef">
			<xsl:for-each select="1 to $fieldsCount">
				<xsl:variable name="i" select="."/>
				<xsl:variable name="item" select="$fieldsPaths[position()=$i]"/>
				<xsl:variable name="itemPropertyID" select="self:XPath_field_to_propertyID($selectorPath,$item/@xpath)"/>
				<!--<xsl:value-of select="concat($field_start,$item/@xpath,$field_end)"/>-->
				<xsl:value-of select="concat($ICPropertyType_start,$Property_start,$itemPropertyID,$Property_end,$field_start,$item/@xpath,$field_end,$ICPropertyType_end)"/>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:choose>
			<xsl:when test="$classID=''">
				<xsl:value-of select="concat($IdentityConst_start,$opID_start,$opID,$opID_end,$ICName_start,$ICName,$ICName_end,$RefersTo_start,$referKey,$RefersTo_end,$HostELementID_start,$HostElementID,$HostELementID_end,$selector_start,$selectorPath,$selector_end,$ICProperties_start,$fieldDef,$ICProperties_end,$constraintType_start,$constrType,$constraintType_end,$IdentityConst_end)"/>		
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($IdentityConst_start,$classID_start,$classID,$classID_end,$ICName_start,$ICName,$ICName_end,$HostELementID_start,$HostElementID,$HostELementID_end,$selector_start,$selectorPath,$selector_end,$ICProperties_start,$fieldDef,$ICProperties_end,$constraintType_start,$constrType,$constraintType_end,$IdentityConst_end)"/>
			</xsl:otherwise>
		</xsl:choose>
		
		
	</xsl:function>
	
	<xsl:function name="self:assert_info">
		<xsl:param name="test"/>
		<xsl:param name="xpathDefaultNamespace"/>
		<xsl:param name="annotation"/>
		<xsl:param name="ct_name"/>
		<xsl:param name="position"/>
		
		<xsl:variable name="asrt_info_start" select="'&lt;ox:AssertInfo&gt;'"/>
		<xsl:variable name="asrt_info_end" select="'&lt;/ox:AssertInfo&gt;'"/>

		<xsl:variable name="asrt_start" select="concat('&lt;ox:AssertInfoType rdf:ID=&quot;',$ct_name,'_assert_',$position,'&quot;&gt;')"/>
		<xsl:variable name="asrt_end" select="'&lt;/ox:AssertInfoType&gt;'"/>
		
		<xsl:variable name="asrt_test_start" select="'&lt;ox:TestExpression&gt;'"/>
		<xsl:variable name="asrt_test_end" select="'&lt;/ox:TestExpression&gt;'"/>
		
		<xsl:variable name="asrt_xpathDefNS_start" select="if ($xpathDefaultNamespace) then '&lt;ox:XpathDefaultNamespace&gt;' else ''"/>
		<xsl:variable name="asrt_xpathDefNS_end" select="if ($xpathDefaultNamespace) then '&lt;/ox:XpathDefaultNamespace&gt;'  else ''"/>
		
		<xsl:variable name="asrt_annotation_start" select="if ($annotation) then '&lt;rdfs:comment&gt;' else ''"/>
		<xsl:variable name="asrt_annotation_end" select="if ($annotation) then '&lt;/rdfs:comment&gt;' else ''"/>
		
		
		<xsl:value-of select="concat($asrt_info_start,$asrt_start,$asrt_test_start,$test,$asrt_test_end,$asrt_xpathDefNS_start,$xpathDefaultNamespace,$asrt_xpathDefNS_end,$asrt_annotation_start,$annotation,$asrt_annotation_end,$asrt_end,$asrt_info_end)"/>
	</xsl:function>
	
	<!-- Function that produces top-level attribute information for owl2xml -->
	<xsl:function name="self:top_att_info" >
		<xsl:param name="att"/>
		<xsl:param name="schema"/>
		<xsl:variable name="name" select="self:property_name($schema/xsd:attribute[string(./@name)=string($att/@name)],$not_specified)"/>
		<xsl:value-of select="self:datatype_property_info($name,$name,$att/@name,'Attribute')"/>
		<xsl:if test="$att/xsd:simpleType">
			<xsl:value-of select="self:st_info($att/xsd:simpleType,$schema,$not_specified,$att/@name,'','')"/>
		</xsl:if>
	</xsl:function>
	<!-- Function that produces container element datatype property information for owl2xml -->
	<xsl:function name="self:container_dp_element_info" as="xsd:string">
		<xsl:param name="container"/>
		<xsl:param name="class"/>
		<xsl:param name="group_name"/>
		<xsl:param name="schema"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="elements">
			<xsl:variable name="start" select="'&lt;ox:DatatypePropertyInfo&gt;&#10;&#9;&#9;'"/>
			<xsl:variable name="end" select="'&lt;/ox:DatatypePropertyInfo&gt;&#10;&#9;'"/>
			<xsl:for-each select="$container/xsd:element">
				<xsl:variable name="ref" select="string(./@ref)"/>
				<xsl:variable name="el_name" select="string(./@name)"/>
				<xsl:variable name="in">
					<xsl:choose>
						<xsl:when test="string($group_name)!='' and string($ref)=''">
							<xsl:variable name="actual_element" select="$schema/xsd:group[string(./@name)=string($group_name)]/(xsd:choice|xsd:sequence)//xsd:element[string(./@name)=string($el_name)] except $schema/xsd:group//xsd:complexType//xsd:element"/>
							<xsl:variable name="type" select="$actual_element/@type"/>
							<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($actual_element/xsd:simpleType))  "/>
							<xsl:if test="$is_simple_type">
								<xsl:variable name="name" select="self:produced_element_name(.,$class,$schema,$group_name)"/>
								<xsl:value-of select="concat('&lt;ox:DatatypePropertyInfoType rdf:about=&quot;',$name,'&quot;/&gt;&#10;&#9;')"/>
							</xsl:if>
						</xsl:when>
						<xsl:when test="string($ref)=''">
							<xsl:variable name="is_simple_type" select="self:is_simple_type(./@type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean(./xsd:simpleType))  "/>
							<xsl:if test="$is_simple_type">
								<xsl:variable name="name" select="self:property_name(.,$class)"/>
								<xsl:value-of select="self:datatype_property_info(concat($class,'_',$name),$name,./@name,'Element')"/>
							</xsl:if>
						</xsl:when>
						<xsl:otherwise>
							<xsl:variable name="type" select="$schema/xsd:element[string(./@name)=$ref]/@type"/>
							<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($schema/xsd:element[string(./@name)=$ref]/xsd:simpleType))  "/>
							<xsl:if test="$is_simple_type">
								<xsl:variable name="name" select="self:produced_element_name(.,$class,$schema,$group_name)"/>
								<xsl:value-of select="concat('&lt;ox:DatatypePropertyInfoType rdf:about=&quot;',$name,'&quot;/&gt;&#10;&#9;')"/>
							</xsl:if>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="if (string($in)='') then '' else concat($start,$in,$end)"/>
			</xsl:for-each>
			<xsl:for-each select="$container/xsd:sequence,$container/xsd:choice">
				<xsl:value-of select="self:container_dp_element_info(.,$class,$group_name,$schema,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="string($elements)"/>
	</xsl:function>
	<!-- Function that produces an element container with "data" inside -->
	<xsl:function name="self:element_container" as="xsd:string">
		<xsl:param name="data"/>
		<xsl:value-of select="concat('&lt;ox:ElementContainer&gt;&#10;&#9;&#9;',$data,'&lt;/ox:ElementContainer&gt;&#10;&#9;')"/>
	</xsl:function>
	<!-- Function that produces an item with "data" inside -->
	<xsl:function name="self:item" as="xsd:string">
		<xsl:param name="data"/>
		<xsl:value-of select="concat('&lt;ox:Item&gt;&#10;&#9;&#9;',$data,'&lt;/ox:Item&gt;&#10;&#9;')"/>
	</xsl:function>
	<!-- Function that produces a minOccurs with "data" inside -->
	<xsl:function name="self:min_occurences" as="xsd:string">
		<xsl:param name="data"/>
		<xsl:value-of select="concat('&lt;ox:minOccurs&gt;',$data,'&lt;/ox:minOccurs&gt;&#10;&#9;&#9;')"/>
	</xsl:function>
	<!-- Function that produces a maxOccurs with "data" inside -->
	<xsl:function name="self:max_occurences" as="xsd:string">
		<xsl:param name="data"/>
		<xsl:value-of select="concat('&lt;ox:maxOccurs&gt;',$data,'&lt;/ox:maxOccurs&gt;&#10;&#9;&#9;')"/>
	</xsl:function>
	<!-- Function that produces a SeqElementRefType  -->
	<xsl:function name="self:seq_element_ref_type" as="xsd:string">
		<xsl:param name="id"/>
		<xsl:param name="eid"/>
		<xsl:param name="min_occ"/>
		<xsl:param name="max_occ"/>
		<xsl:param name="order"/>
		<xsl:variable name="start" select="concat('&lt;ox:SeqElementRefType rdf:ID=&quot;',$id,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:SeqElementRefType&gt;&#10;&#9;'"/>
		<xsl:variable name="min" select="self:min_occurences($min_occ)"/>
		<xsl:variable name="max" select="self:max_occurences($max_occ)"/>
		<xsl:variable name="ei" select="concat('&lt;ox:elementID&gt;',$eid,'&lt;/ox:elementID&gt;&#10;&#9;&#9;&#9;')"/>
		<xsl:variable name="pos" select="concat('&lt;ox:itemPosition&gt;',$order,'&lt;/ox:itemPosition&gt;&#10;&#9;&#9;')"/>
		<xsl:value-of select="concat($start,$ei,$min,$max,$pos,$end)"/>
	</xsl:function>
	<!-- Function that produces an ElementRefType  -->
	<xsl:function name="self:element_ref_type" as="xsd:string">
		<xsl:param name="id"/>
		<xsl:param name="eid"/>
		<xsl:param name="min_occ"/>
		<xsl:param name="max_occ"/>
		<xsl:variable name="start" select="concat('&lt;ox:ElementRefType rdf:ID=&quot;',$id,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:ElementRefType&gt;&#10;&#9;'"/>
		<xsl:variable name="min" select="self:min_occurences($min_occ)"/>
		<xsl:variable name="max" select="self:max_occurences($max_occ)"/>
		<xsl:variable name="ei" select="concat('&lt;ox:elementID&gt;',$eid,'&lt;/ox:elementID&gt;&#10;&#9;&#9;&#9;')"/>
		<xsl:value-of select="concat($start,$ei,$min,$max,$end)"/>
	</xsl:function>
	<!-- Function that produces sequence information for owl2xml -->
	<xsl:function name="self:group_info">
		<xsl:param name="is_top"/>
		<xsl:param name="group_ref"/>
		<xsl:param name="group_order_id"/>
		<xsl:param name="group_order"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="name" select="$group_ref/@ref"/>
		<xsl:variable name="group" select="$schema_element/xsd:group[string(./@name)=$name]"/>
		<xsl:variable name="items">
			<xsl:choose>
				<xsl:when test="$is_top">
					<xsl:for-each select="$group/xsd:sequence">
						<xsl:value-of select="self:element_container(self:sequence_info(.,concat($group_order_id,'_',$group_order),$group_order,$name,self:min_occurs($group_ref),self:max_occurs($group_ref),$class,$schema))"/>
					</xsl:for-each>
					<xsl:for-each select="$group/xsd:choice">
						<xsl:value-of select="self:element_container(self:choice_info(.,concat($group_order_id,'_',$group_order),$group_order,$name,self:min_occurs($group_ref),self:max_occurs($group_ref),$class,$schema))"/>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:for-each select="$group/xsd:sequence">
						<xsl:value-of select="self:item(self:sequence_info(.,concat($group_order_id,'_',$group_order),$group_order,$name,self:min_occurs($group_ref),self:max_occurs($group_ref),$class,$schema))"/>
					</xsl:for-each>
					<xsl:for-each select="$group/xsd:choice">
						<xsl:value-of select="self:item(self:choice_info(.,concat($group_order_id,'_',$group_order),$group_order,$name,self:min_occurs($group_ref),self:max_occurs($group_ref),$class,$schema))"/>
					</xsl:for-each>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$items"/>
	</xsl:function>
	<!-- Function that produces sequence information for owl2xml -->
	<xsl:function name="self:sequence_info" as="xsd:string">
		<xsl:param name="sequence"/>
		<xsl:param name="sequence_order"/>
		<xsl:param name="item_order"/>
		<xsl:param name="group_name"/>
		<xsl:param name="group_min"/>
		<xsl:param name="group_max"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="start" select="concat('&lt;ox:SequenceInfoType rdf:ID=&quot;',$class,'_sequence_',$sequence_order,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:SequenceInfoType&gt;&#10;&#9;'"/>
		<xsl:variable name="min" select="self:min_occurences(number(self:min_occurs($sequence))*number($group_min))"/>
		<xsl:variable name="local_max" select="self:max_occurs($sequence)"/>
		<xsl:variable name="max" select="if (string($group_max)='unbounded' or string($local_max)='unbounded' ) then self:max_occurences('unbounded') else self:max_occurences(number($local_max)*number($group_max))"/>
		<xsl:variable name="pos" select="concat('&lt;ox:itemPosition&gt;',$item_order,'&lt;/ox:itemPosition&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="items">
			<xsl:for-each select="$sequence/xsd:element">
				<xsl:variable name="name" select="if (string(./@ref)='') then self:property_name(.,$class) else replace(self:produced_element_name(.,$class,$schema,$group_name),'#','')"/>
				<xsl:variable name="eid" select="if (string(./@ref)='') then concat($class,'_',$name,'__ei') else concat($name,'__ei')"/>
				<xsl:value-of select="self:item(self:seq_element_ref_type(concat($class,'_',$name,'_ref'),$eid,self:min_occurs(.),self:max_occurs(.),position()))"/>
			</xsl:for-each>
			<xsl:for-each select="$sequence/xsd:sequence">
				<xsl:value-of select="self:item(self:sequence_info(.,concat($sequence_order,'_',position()),position(),$group_name,1,1,$class,$schema))"/>
			</xsl:for-each>
			<xsl:for-each select="$sequence/xsd:choice">
				<xsl:value-of select="self:item(self:choice_info(.,concat($sequence_order,'_',position()),position(),$group_name,1,1,$class,$schema))"/>
			</xsl:for-each>
			<xsl:for-each select="$sequence/xsd:group">
				<xsl:value-of select="self:group_info(false(),.,concat($sequence_order,'_',position()),position(),$class,$schema)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="concat($start,$min,$max,$pos,$items,$end)"/>
	</xsl:function>
	<!-- Function that produces choice information for owl2xml -->
	<xsl:function name="self:choice_info" as="xsd:string">
		<xsl:param name="choice"/>
		<xsl:param name="choice_order"/>
		<xsl:param name="item_order"/>
		<xsl:param name="group_name"/>
		<xsl:param name="group_min"/>
		<xsl:param name="group_max"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="start" select="concat('&lt;ox:ChoiceType rdf:ID=&quot;',$class,'_choice_',$choice_order,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:ChoiceType&gt;&#10;&#9;'"/>
		<xsl:variable name="min" select="self:min_occurences(number(self:min_occurs($choice))*number($group_min))"/>
		<xsl:variable name="local_max" select="self:max_occurs($choice)"/>
		<xsl:variable name="max" select="if (string($group_max)='unbounded' or string($local_max)='unbounded' ) then self:max_occurences('unbounded') else self:max_occurences(number($local_max)*number($group_max))"/>
		<xsl:variable name="pos" select="concat('&lt;ox:itemPosition&gt;',$item_order,'&lt;/ox:itemPosition&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="items">
			<xsl:for-each select="$choice/xsd:element">
				<xsl:variable name="name" select="if (string(./@ref)='') then self:property_name(.,$class) else replace(self:produced_element_name(.,$class,$schema,$group_name),'#','')"/>
				<xsl:variable name="eid" select="if (string(./@ref)='') then concat($class,'_',$name,'__ei') else concat($name,'__ei')"/>
				<xsl:value-of select="self:item(self:element_ref_type(concat($class,'_',$name,'_ref'),$eid,self:min_occurs(.),self:max_occurs(.)))"/>
			</xsl:for-each>
			<xsl:for-each select="$choice/xsd:sequence">
				<xsl:value-of select="self:item(self:sequence_info(.,concat($choice_order,'_',position()),position(),$group_name,1,1,$class,$schema))"/>
			</xsl:for-each>
			<xsl:for-each select="$choice/xsd:choice">
				<xsl:value-of select="self:item(self:choice_info(.,concat($choice_order,'_',position()),position(),$group_name,1,1,$class,$schema))"/>
			</xsl:for-each>
			<xsl:for-each select="$choice/xsd:group">
				<xsl:value-of select="self:group_info(false(),.,concat($choice_order,'_',position()),position(),$class,$schema)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="concat($start,$min,$max,$pos,$items,$end)"/>
	</xsl:function>
	<!-- Function that produces container element information for owl2xml -->
	<xsl:function name="self:container_element_info" as="xsd:string">
		<xsl:param name="container"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="elements">
			<xsl:for-each select="$container/xsd:element[string(./@ref)='']">
				<xsl:variable name="name" select="self:property_name(.,$class)"/>
				<xsl:value-of select="self:element_info(concat($class,'_',$name,'__ei'),$name,./@name)"/>
			</xsl:for-each>
			<xsl:for-each select="$container/xsd:sequence,$container/xsd:choice">
				<xsl:value-of select="self:container_element_info(.,$class,$schema)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="string($elements)"/>
	</xsl:function>
	<!-- Function that produces attribute information for owl2xml -->
	<xsl:function name="self:att_info">
		<xsl:param name="att"/>
		<xsl:param name="class"/>
		<xsl:param name="schema"/>
		<xsl:variable name="ref" select="string($att/@ref)"/>
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="string($ref)=''">
					<xsl:value-of select="self:property_name($att,$class)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($ref,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($ref)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($ref)],$not_specified))"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start" select="'&lt;ox:DatatypePropertyInfo&gt;&#10;&#9;&#9;'"/>
		<xsl:variable name="end" select="'&lt;/ox:DatatypePropertyInfo&gt;&#10;&#9;'"/>
		<xsl:variable name="in">
			<xsl:choose>
				<xsl:when test="$ref=''">
					<xsl:value-of select="self:datatype_property_info(concat($class,'_',$name),$name,$att/@name,'Attribute')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="concat('&lt;ox:DatatypePropertyInfoType rdf:about=&quot;',$name,'&quot;/&gt;&#10;&#9;')"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="concat($start,$in,$end)"/>
		<xsl:if test="$att/xsd:simpleType">
			<xsl:value-of select="self:st_info($att/xsd:simpleType,$schema,$not_specified,$att/@name,'','')"/>
		</xsl:if>
	</xsl:function>
	<!-- Function that produces references for group attribute information for owl2xml -->
	<xsl:function name="self:group_att_info_ref" as="xsd:string">
		<xsl:param name="att"/>
		<xsl:param name="ag_name"/>
		<xsl:param name="schema"/>
		<xsl:variable name="ref" select="string($att/@ref)"/>
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="string($ref)=''">
					<xsl:variable name="type">
						<xsl:choose>
							<xsl:when test="nilled($att/xsd:simpleType)=false()">
								<xsl:value-of select="self:unnamed_datatype_name($not_specified, concat($att/@name,'_',$ag_name))"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$att/@type"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:value-of select="concat('#',self:property_from_group_name(string($att/@name),$ag_name,$type))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="contains($ref,':')">
							<xsl:value-of select="self:rdf_uri_from_xsd_uri($ref)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="concat('#',self:property_name($schema/xsd:attribute[string(./@name)=string($ref)],$not_specified))"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="start" select="'&lt;ox:DatatypePropertyInfo&gt;&#10;&#9;&#9;'"/>
		<xsl:variable name="end" select="'&lt;/ox:DatatypePropertyInfo&gt;&#10;&#9;'"/>
		<xsl:variable name="in" select="concat('&lt;ox:DatatypePropertyInfoType rdf:about=&quot;',$name,'&quot;/&gt;&#10;&#9;')"/>
		<xsl:value-of select="concat($start,$in,$end)"/>
	</xsl:function>
	<!-- Function that produces complex type information for owl2xml -->
	<xsl:function name="self:ct_info" as="xsd:string">
		<xsl:param name="ct"/>
		<xsl:param name="schema"/>
		<xsl:param name="named_simple_type_names"/>
		<xsl:param name="xsd_namespaces"/>
		<xsl:param name="is_empty_namespace_xsd"/>
		<xsl:param name="equivalent_target_namespaces"/>
		<xsl:variable name="name" select="$ct/@name"/>
		<xsl:variable name="start" select="concat('&lt;ox:ComplexTypeInfoType rdf:ID=&quot;', $name,'&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:ComplexTypeInfoType&gt;&#10;&#9;'"/>
		<xsl:variable name="id" select="concat('&lt;ox:typeID&gt;',$name,'&lt;/ox:typeID&gt;&#10;&#9;')"/>
		<xsl:variable name="att_info">
			<xsl:for-each select="$ct/xsd:attribute,$ct/xsd:simpleContent/xsd:extension/xsd:attribute,$ct/xsd:complexContent/xsd:extension/xsd:attribute">
				<xsl:value-of select="self:att_info(.,$name,$schema)[1]"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="att_info_nested_Unnamed">
			<xsl:for-each select="$ct/xsd:attribute,$ct/xsd:simpleContent/xsd:extension/xsd:attribute,$ct/xsd:complexContent/xsd:extension/xsd:attribute">
				<xsl:value-of select="self:att_info(.,$name,$schema)[2]"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="el_dp_info">
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:sequence,$ct/xsd:sequence,$ct/xsd:complexContent/xsd:extension/xsd:choice,$ct/xsd:choice">
				<xsl:value-of select="self:container_dp_element_info(.,$name,'',$schema,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
			</xsl:for-each>
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:group,$ct/xsd:group">
				<xsl:variable name="group_name" select="./@ref"/>
				<xsl:variable name="group" select="$schema_element/xsd:group[string(./@name)=$group_name]"/>
				<xsl:for-each select="$group/xsd:sequence,$group/xsd:choice">
					<xsl:value-of select="self:container_dp_element_info(.,$name,$group_name,$schema,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="att_g_info">
			<xsl:for-each select="$ct/xsd:attributeGroup,$ct/xsd:simpleContent/xsd:extension/xsd:attributeGroup,$ct/xsd:complexContent/xsd:extension/xsd:attributeGroup">
				<xsl:variable name="ag_name" select="./@ref"/>
				<xsl:variable name="actual_grp" select="$schema/xsd:attributeGroup[string(./@name)=string($ag_name)]"/>
				<xsl:for-each select="$actual_grp/xsd:attribute">
					<xsl:value-of select="self:group_att_info_ref(.,$ag_name,$schema)"/>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="el_info">
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:sequence,$ct/xsd:sequence,$ct/xsd:complexContent/xsd:extension/xsd:choice,$ct/xsd:choice">
				<xsl:value-of select="self:container_element_info(.,$name,$schema)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="seq_info">
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:sequence,$ct/xsd:sequence">
				<xsl:value-of select="self:element_container(self:sequence_info(.,position(),position(),'',1,1,$name,$schema))"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="cho_info">
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:choice,$ct/xsd:choice">
				<xsl:value-of select="self:element_container(self:choice_info(.,position(),position(),'',1,1,$name,$schema))"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="is_simple_type_descendant" select="self:is_simple_type(string($ct/xsd:simpleContent/xsd:extension/@base),$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean($ct/xsd:simpleContent/xsd:extension/xsd:simpleType))"/>
		<xsl:variable name="sc">
			<xsl:for-each select="$ct/xsd:simpleContent/xsd:extension[not(string(./@base)='') and $is_simple_type_descendant]">
				<xsl:variable name="sc_name" select="concat('content__',replace(./@base,':','_'))"/>
				<xsl:value-of select="self:sc_att_info(.,$name)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="group_info">
			<xsl:for-each select="$ct/xsd:complexContent/xsd:extension/xsd:group,$ct/xsd:group">
				<xsl:value-of select="self:group_info(true(),.,position(),position(),$name,$schema)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="assert_info">
			<xsl:for-each select="$ct/xsd:assert">
				<xsl:value-of select="self:assert_info(./@test,./@xpathDefaultNamespace,./xsd:annotation,$name,position())"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:value-of select="concat($start, $id, string($att_info), string($att_g_info), string($sc), string($seq_info), string($cho_info), string($el_dp_info),string($group_info),string($assert_info),$end,$el_info,$att_info_nested_Unnamed)"/>
	</xsl:function>
	
	<!-- Function that produces complex type information for owl2xml -->
	<xsl:function name="self:st_info">
		<xsl:param name="st"/>
		<xsl:param name="schema"/>
		<xsl:param name="preancestor"/>
		<xsl:param name="ancestor"/>
		<xsl:param name="nested_types"/>
		<xsl:param name="position"/>
		<xsl:variable name="name">
			<xsl:choose>
				<xsl:when test="$st/@name">
					<xsl:value-of select="$st/@name"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:choose>
						<xsl:when test="$position">
							<xsl:value-of select="concat(self:unnamed_datatype_name($preancestor,$ancestor),'_',$position)"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="self:unnamed_datatype_name($preancestor,$ancestor)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="final" select="if ($st/@final) then ($st/@final) else ''"/>
		<xsl:variable name="start" select="concat('&lt;ox:SimpleTypeInfoType rdf:ID=&quot;', $name,'_si','&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="end" select="'&lt;/ox:SimpleTypeInfoType&gt;&#10;&#9;'"/>
		<xsl:variable name="id" select="concat('&lt;ox:typeID&gt;',$name,'&lt;/ox:typeID&gt;&#10;&#9;')"/>
		<xsl:variable name="classID" select="concat('&lt;ox:classID&gt;',$name,'&lt;/ox:classID&gt;&#10;&#9;')"/>
		<xsl:variable name="final" select="if ($st/@final) then concat('&lt;ox:final&gt;',$final,'&lt;/ox:final&gt;&#10;&#9;') else ''"/>
		<xsl:variable name="stType" select="$st/child::node()[ local-name()='restriction'],$st/child::node()[ local-name()='union'],$st/child::node()[ local-name()='list']"/>
	

		<xsl:variable name="definitionType" select="concat('&lt;ox:definitionType&gt;',local-name($stType),'&lt;/ox:definitionType&gt;&#10;&#9;')"/>
		<xsl:variable name="current_st" select="concat($start,$classID, $id, string($definitionType),$final, $end)"/>
		<xsl:choose>
			<xsl:when test="$st/xsd:restriction/xsd:simpleType">
				<xsl:value-of select="self:st_info($st/xsd:restriction/xsd:simpleType,$schema,$ancestor,$name,concat($current_st,$nested_types),'')"/>
			</xsl:when>
			<xsl:when test="$st/xsd:union/xsd:simpleType">
				<xsl:variable name="num_union_list" select="count($st/xsd:union/xsd:simpleType)"/>
				
				<xsl:variable name="union_list">
					<xsl:for-each select="1 to $num_union_list">
						<xsl:variable name="i" select="."/>
						<xsl:variable name="item" select="$st/xsd:union/xsd:simpleType[$i]"/>
						<xsl:value-of select="self:st_info($item,$schema,$ancestor,$name,'',$i)"/>
					</xsl:for-each>
				</xsl:variable>
				<xsl:value-of select="concat($current_st,$union_list)"/>
			</xsl:when>
			<xsl:when test="$st/xsd:list/xsd:simpleType">
				<xsl:value-of select="self:st_info($st/xsd:list/xsd:simpleType,$schema,$ancestor,$name,concat($current_st,$nested_types),'')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat($current_st,$nested_types)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<!-- Function that produces owl:Ontology from the xml schema -->
	<xsl:function name="self:owl2xml_ontology" as="xsd:string">
		<xsl:variable name="ontology_start" select="string('&#10;&#9;&lt;owl:Ontology rdf:about=&quot;&quot;&gt;&#10;&#9;&#9;')"/>
		<xsl:variable name="ontology_end" select="string('&lt;/owl:Ontology&gt;')"/>
		<xsl:variable name="import" select="string('&lt;owl:imports rdf:resource=&quot;&amp;ox;&quot;/&gt;&#10;&#9;&#9;')"/>
		<xsl:value-of select="concat(string($ontology_start),$import,self:comment('Ontology containing OWL to XML Rules'),string($ontology_end),string('&#10;&#9;'))"/>
	</xsl:function>
	<!-- Function that copies unnamed simple types in unnamed complex types-->
	<xsl:function name="self:copy_unnamed_simple_type_in_unnamed_complex_type">
		<xsl:param name="complex_type"/>
		<xsl:param name="c_name"/>
		<xsl:for-each select="$complex_type/xsd:complexContent/xsd:extension/xsd:choice/xsd:element/xsd:complexType, $complex_type/xsd:complexContent/xsd:extension/xsd:sequence/xsd:element/xsd:complexType, $complex_type/xsd:choice/xsd:element/xsd:complexType, $complex_type/xsd:sequence/xsd:element/xsd:complexType">
			<xsl:variable name="ct_name" select="self:unnamed_datatype_name($c_name,parent::node()/@name)"/>
			<xsl:for-each select="./xsd:attribute, ./xsd:complexContent/xsd:extension/xsd:attribute, ./xsd:simpleContent/xsd:extension/xsd:attribute">
				<xsl:variable name="at_name" select="@name"/>
				<xsl:for-each select="./xsd:simpleType[string(./@name)='']">
					<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type_with_name(.,self:unnamed_datatype_name($ct_name,$at_name))"/>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:for-each select="./xsd:sequence/xsd:element, ./xsd:complexContent/xsd:extension/xsd:sequence/xsd:element,./xsd:choice/xsd:element, ./xsd:complexContent/xsd:extension/xsd:choice/xsd:element">
				<xsl:variable name="el_name" select="@name"/>
				<xsl:for-each select="./xsd:simpleType[string(./@name)='']">
					<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type_with_name(.,self:unnamed_datatype_name($ct_name,$el_name))"/>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="self:copy_unnamed_simple_type_in_unnamed_complex_type(.,$c_name)"/>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that copies unnamed simple types from sequences/choices  -->
	<xsl:function name="self:copy_container_xsd_types">
		<xsl:param name="container"/>
		<xsl:param name="c_name"/>
		<xsl:for-each select="$container/xsd:element">
			<xsl:variable name="el_name" select="@name"/>
			<xsl:for-each select="./xsd:simpleType[string(./@name)='']">
				<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type_with_name(.,self:unnamed_datatype_name($c_name,$el_name))"/>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:for-each select="$container/xsd:sequence,$container/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:copy_container_xsd_types(.,$c_name)"/>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that copies unnamed simple types from sequences/choices  -->
	<xsl:function name="self:copy_group_container_xsd_types">
		<xsl:param name="container"/>
		<xsl:param name="g_name"/>
		<xsl:for-each select="$container/xsd:element">
			<xsl:variable name="el_name" select="@name"/>
			<xsl:for-each select="./xsd:simpleType[string(./@name)='']">
				<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type_with_name(.,self:unnamed_datatype_name($not_specified, concat($el_name,'_',$g_name)))"/>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:for-each select="$container/xsd:sequence,$container/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:copy_group_container_xsd_types(.,$g_name)"/>
		</xsl:for-each>
	</xsl:function>
	<!-- Function that copies unnamed simple types -->
	<xsl:function name="self:copy_unnamed_xsd_type">
		<xsl:param name="named_complex_type"/>
		<xsl:variable name="c_name" select="$named_complex_type/@name"/>
		<xsl:for-each select="$named_complex_type/xsd:attribute, $named_complex_type/xsd:complexContent/xsd:extension/xsd:attribute,$named_complex_type/xsd:simpleContent/xsd:extension/xsd:attribute">
			<xsl:variable name="at_name" select="@name"/>
			<xsl:for-each select="./xsd:simpleType[string(./@name)='']">
				<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type_with_name(.,self:unnamed_datatype_name($c_name,$at_name))"/>
			</xsl:for-each>
		</xsl:for-each>
		<xsl:for-each select="$named_complex_type/xsd:sequence, $named_complex_type/xsd:complexContent/xsd:extension/xsd:sequence, $named_complex_type/xsd:choice, $named_complex_type/xsd:complexContent/xsd:extension/xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:copy_container_xsd_types(.,$c_name)"/>
		</xsl:for-each>
		<xsl:value-of disable-output-escaping="yes" select="self:copy_unnamed_simple_type_in_unnamed_complex_type($named_complex_type,$c_name)"/>
	</xsl:function>
	<!-- Function that copies overrides to owl2xml -->
	<xsl:function name="self:override" as="xsd:string">
		<xsl:param name="override_node"/>
		<xsl:variable name="override_children">
			<xsl:value-of disable-output-escaping="yes" select="self:copy_xsd_type($override_node)"/>
		</xsl:variable>
		<xsl:variable name="override_schemaLocation" select="$override_node/@schemaLocation"/>
		<xsl:variable name="override_type" select="local-name($override_node)"/>
		<xsl:variable name="ox_start">
			<xsl:value-of select="concat(string('&lt;ox:OverrideInfoType rdf:about=&quot;'),string('schema_'),string($override_schemaLocation),string('&quot;&gt;&#10;&#9;&#9;'))"/>
		</xsl:variable>
		<xsl:variable name="ox_end">
			<xsl:value-of select="string('&lt;/ox:OverrideInfoType&gt;')"/>
		</xsl:variable>
		<xsl:variable name="xmlLiteral_start">
			<xsl:value-of select="string('&lt;rdf:XMLLiteral&gt;')"/>
		</xsl:variable>
		<xsl:variable name="xmlLiteral_end">
			<xsl:value-of select="string('&lt;/rdf:XMLLiteral&gt;')"/>
		</xsl:variable>
		<xsl:variable name="schemaLocation_start">
			<xsl:value-of select="string('&lt;ox:schemaLocation&gt;')"/>
		</xsl:variable>
		<xsl:variable name="schemaLocation_end">
			<xsl:value-of select="string('&lt;/ox:schemaLocation&gt;')"/>
		</xsl:variable>
		<xsl:variable name="overrideType_start">
			<xsl:value-of select="string('&lt;ox:overrideType&gt;')"/>
		</xsl:variable>
		<xsl:variable name="overrideType_end">
			<xsl:value-of select="string('&lt;/ox:overrideType&gt;')"/>
		</xsl:variable>
		<xsl:value-of select="concat(string($ox_start),string($schemaLocation_start),string($override_schemaLocation),string($schemaLocation_end),string($overrideType_start),string($override_type),string($overrideType_end),string($xmlLiteral_start),string($override_children),string($xmlLiteral_end),string($ox_end))"/>
	</xsl:function>
	<!-- ###############################################################-->
	<!-- ######					Template Definitions			  ######-->
	<!-- ###############################################################-->
	<!-- Top-Level Template -->
	<xsl:template match="/xsd:schema">
		<xsl:result-document href="main.owl" validation="strip">
			<!-- Entity Definitions -->
			<xsl:value-of disable-output-escaping="yes" select="self:entity_definition(.)"/>
			<!-- RDF element and namespace declarations -->
			<xsl:value-of disable-output-escaping="yes" select="string('&lt;rdf:RDF')"/>
			<xsl:for-each select="namespace::*">
				<xsl:value-of disable-output-escaping="yes" select="self:namespace_declaration($target_namespace,.)"/>
			</xsl:for-each>
			<xsl:value-of disable-output-escaping="yes" select="concat(' xmlns:owl=&quot;&amp;owl;&quot; xmlns:rdf=&quot;&amp;rdf;&quot; xmlns:rdfs=&quot;&amp;rdfs;&quot; ','&gt;')"/>
			<!-- owl:Ontology Definition -->
			<xsl:value-of disable-output-escaping="yes" select="self:ontology_from_schema(.)"/>
			<!-- rdfs:Datatype Definitions -->
			<xsl:value-of disable-output-escaping="yes" select="self:xml_comment('Datatype Definitions')"/>
			<!--xsl:value-of disable-output-escaping="yes" select="self:datatype_from_name('NMTOKEN','xsd')"/-->
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_from_name('ID','xsd')"/>
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_from_name('IDREF','xsd')"/>
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_from_name('IDREFS','xsd')"/>
			<xsl:apply-templates select="/xsd:schema/xsd:simpleType"/>
			<!-- owl:Class Definitions -->
			<xsl:value-of disable-output-escaping="yes" select="self:xml_comment('Class Definitions')"/>
			<!-- Define properties for all attributes - elements -->
			<xsl:variable name="properties">
				<xsl:for-each-group select="./xsd:complexType//xsd:attribute[string(@ref)='' and not(string(@type)='')],./xsd:complexType//xsd:element[string(@ref)='' and not(string(@type)='')], ./xsd:element/xsd:complexType//xsd:attribute[string(@ref)='' and not(string(@type)='')], ./xsd:element/xsd:complexType//xsd:element[string(@ref)='' and not(string(@type)='')]" group-by="@name">
					<xsl:for-each-group select="current-group()" group-by="@type">
						<xsl:variable name="is_simple_type" as="xsd:boolean" select="self:is_simple_type(@type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean(false()))  "/>
						<xsl:variable name="TempID" select="self:property_name(.,@type)"/>
						<xsl:variable name="keyrefRange" select="self:getHashTableValue($properties_referTo_hashtable,$TempID)"/>
						<xsl:choose>
							<xsl:when test="not($keyrefRange='')">
								<xsl:value-of disable-output-escaping="yes" select="self:object_property_wo_domain_no_UN(., $schema_element, $equivalent_target_namespaces)"/>
							</xsl:when>
							<xsl:when test="$is_simple_type=true()">
								<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_wo_domain_not_UN(.,$equivalent_target_namespaces)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of disable-output-escaping="yes" select="self:object_property_wo_domain_no_UN(., $schema_element, $equivalent_target_namespaces)"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:for-each-group>
				</xsl:for-each-group>
			</xsl:variable>
			<xsl:value-of disable-output-escaping="yes" select="$properties"/>
			<!-- Apply the rest of the templates -->
			<xsl:apply-templates select="/xsd:schema/xsd:complexType,/xsd:schema/xsd:element,/xsd:schema/xsd:attribute,/xsd:schema/xsd:attributeGroup,/xsd:schema/xsd:group"/>
			<xsl:value-of disable-output-escaping="yes" select="string('&lt;/rdf:RDF&gt;&#10;')"/>
		</xsl:result-document>
		<xsl:result-document href="owl2xml.owl" validation="strip">
			<xsl:value-of disable-output-escaping="yes" select="concat(string('&#10;&lt;!DOCTYPE rdf:RDF [&#10;'),
			string('&#9;&lt;!ENTITY xsd &quot;http://www.w3.org/2001/XMLSchema#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY owl &quot;http://www.w3.org/2002/07/owl#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY rdf &quot;http://www.w3.org/1999/02/22-rdf-syntax-ns#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY rdfs &quot;http://www.w3.org/2000/01/rdf-schema#&quot;&gt;&#10;'),
			string('&#9;&lt;!ENTITY ox &quot;http://127.0.0.1:8080/ontologies/OWL2XMLRules/OWL2XMLRules#&quot;&gt;&#10;]&gt;&#10;'))"/>
			<xsl:value-of disable-output-escaping="yes" select="string('&lt;rdf:RDF xmlns:owl=&quot;&amp;owl;&quot; xmlns:rdf=&quot;&amp;rdf;&quot; xmlns:rdfs=&quot;&amp;rdfs;&quot; xmlns:ox=&quot;&amp;ox;&quot;&gt;')"/>
			<xsl:value-of disable-output-escaping="yes" select="self:owl2xml_ontology()"/>
			<xsl:for-each select="/xsd:schema/xsd:complexType">
				<xsl:value-of disable-output-escaping="yes" select="self:ct_info(.,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
			</xsl:for-each>
			<xsl:for-each select="/xsd:schema/xsd:simpleType">
				<xsl:value-of disable-output-escaping="yes" select="self:st_info(.,$schema_element,$not_specified,$not_specified,'','')"/>
			</xsl:for-each>
			<xsl:for-each select="/xsd:schema/xsd:attribute">
				<xsl:value-of disable-output-escaping="yes" select="self:top_att_info(.,$schema_element)"/>
			</xsl:for-each>
			<xsl:for-each select="/xsd:schema/xsd:attributeGroup">
				<xsl:variable name="ag_name" select="@name"/>				
				<xsl:for-each select="./xsd:attribute">
					<xsl:value-of disable-output-escaping="yes" select="self:att_from_group_info(.,$ag_name,$schema_element)"/>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:for-each select="/xsd:schema/xsd:group">
				<xsl:variable name="group_name" select="@name"/>
				<xsl:for-each select="./xsd:sequence,./xsd:choice">
					<xsl:value-of disable-output-escaping="yes" select="self:group_container_info(.,$group_name,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
				</xsl:for-each>
			</xsl:for-each>
			<xsl:for-each select="/xsd:schema/xsd:element">
				<xsl:value-of disable-output-escaping="yes" select="self:top_element_info(.,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces)"/>
			</xsl:for-each>
			<xsl:apply-templates select="/xsd:schema/xsd:override"/>
			<xsl:value-of disable-output-escaping="yes" select="string('&lt;/rdf:RDF&gt;&#10;')"/>
		</xsl:result-document>
		</xsl:template> 
	<!-- Template for the model group representation -->
	<xsl:template match="//xsd:group">
		<xsl:variable name="group_name" select="./@name"/>
		<xsl:for-each select="./xsd:sequence,./xsd:choice">
			<xsl:value-of disable-output-escaping="yes" select="self:transform_group($group_name,.,$schema_element,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd, $equivalent_target_namespaces)"/>
		</xsl:for-each>
	</xsl:template>
	<!-- Template for the attributeGroup representation -->
	<xsl:template match="//xsd:attributeGroup">
		<xsl:variable name="ag_name" select="./@name"/>
		<xsl:for-each select="./xsd:attribute">
			<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_attribute_group(.,$equivalent_target_namespaces,$ag_name)"/>
		</xsl:for-each>
	</xsl:template>
	<!-- Template for the attribute representation -->
	<xsl:template match="//xsd:attribute">
		<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_top_attribute(.,$equivalent_target_namespaces)"/>
	</xsl:template>
	<!-- Template for the element representation -->
	<xsl:template match="//xsd:element">
		<xsl:variable name="type" select="./@type"/>
		<xsl:variable name="is_simple_type" select="self:is_simple_type($type,$named_simple_type_names,$xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces, boolean(./xsd:simpleType))  "/>
		<xsl:choose>
			<xsl:when test="$is_simple_type">
				<xsl:value-of disable-output-escaping="yes" select="self:datatype_property_from_top_element(.,$equivalent_target_namespaces,$schema_element)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of disable-output-escaping="yes" select="self:object_property_from_top_element(.,$schema_element, $equivalent_target_namespaces)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- Template for the complexType representation -->
	<xsl:template match="//xsd:complexType">
		<xsl:variable name="class_name">
			<xsl:value-of select="@name"/>
		</xsl:variable>
		<xsl:value-of disable-output-escaping="yes" select="self:deep_class_from_complex_type(.,$named_simple_type_names, $xsd_namespaces,$is_empty_namespace_xsd,$equivalent_target_namespaces,$class_name,$schema_element)"/>
	</xsl:template>
	<!-- Template for the simpleType representation -->
	<xsl:template match="//xsd:simpleType">
		<xsl:variable name="result_list" select="self:datatype_from_simple_type2(.,$not_specified,$not_specified,'','')"/>
		<xsl:value-of disable-output-escaping="yes" select="concat($result_list[1],$result_list[2])"/>
	</xsl:template>
	<xsl:template match="//xsd:override">
		<xsl:value-of disable-output-escaping="yes" select="self:override(.)"/>
	</xsl:template>
</xsl:stylesheet>