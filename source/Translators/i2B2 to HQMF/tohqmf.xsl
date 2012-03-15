<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns="urn:hl7-org:v3" version="1.0">
  <xsl:import href="time.xsl"/>
  <xsl:output indent="yes"/>
  <!-- 
    create a variable to access I2B2 Concepts.  In production
    this would be accessed via a web service request
  -->
  <xsl:variable name="concepts" select="document('concepts.xml')"/>

  <!-- Create an OID for the document -->
  <xsl:variable name="OID"
    >2.16.840.1.113883.3.1619.5148.3</xsl:variable>
  <!-- Create a variable called docOID that will be used
    as the OID for the HQMF document being generated.  It is created
    from a root OID (see above), and nowOID.
    
    nowOID is a variable created by time.xsl that contains the
    current timestamp in OID format.  Adding it to the end of an
    existing OID creates a new OID -->
  <xsl:variable name="docOID">
    <xsl:value-of select="$OID"/>
    <xsl:text>.</xsl:text>
    <xsl:value-of select="$nowOID"/>
  </xsl:variable>

  <!-- This template processes the query_definition element
    found in an I2B2 query request 
  -->
  <xsl:template match="//query_definition">
    <xsl:if
      test="//result_output_list/result_output/@name != 'patient_count_xml'">
      <!-- if asking for something other than patient counts, terminate with
        an error -->
      <xsl:message terminate="yes">Cannot map <xsl:value-of
          select="//result_output_list/result_output/@name"/> to HQMF.
      </xsl:message>
    </xsl:if>
    <!-- Create the quality measure document header with appropriate values -->
    <QualityMeasureDocument xmlns="urn:hl7-org:v3"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      classCode="DOC">
      <typeId root="2.16.840.1.113883.1.3" extension="POQM_HD00001"/>
      <id root="{$docOID}.1"/>
      <code code="57024-2" codeSystem="2.16.840.1.113883.6.1"/>
      <!-- take the title from the query_name field -->
      <title><xsl:value-of select='//query_name'/></title>
      <statusCode code="completed"/>
      <setId root="{$docOID}"/>
      <versionNumber value="1"/>
      <author typeCode="AUT" contextControlCode="OP">
        <assignedPerson classCode="ASSIGNED"/>
      </author>
      <custodian typeCode="CST">
        <assignedPerson classCode="ASSIGNED"/>
      </custodian>

      <!-- TBD: This needs to be able to be set from a query, to
        control start and end date for a measure.  But right now,
        the date range can only be set for a panel, not for the
        entire query.  Not sure how to handle this.
        -->
      <controlVariable>
        <localVariableName>MeasurePeriod</localVariableName>
        <measurePeriod>
          <id root="0" extension="StartDate"/>
          <value>
            <width unit="a" value="1"/>
          </value>
        </measurePeriod>
      </controlVariable>
      <component>
        <measureDescriptionSection>
          <title>Measure Description Section</title>
          <text><xsl:value-of select='//query_name'/></text>
        </measureDescriptionSection>
      </component>

      <component>
        <dataCriteriaSection>
          <code code="57025-9" codeSystem="2.16.840.1.113883.6.1"/>
          <title>Data Criteria Section</title>
          <text>This section describes the data criteria.</text>
          <!-- This chunk of definitions is fixed data that is used
            to tie query criteria into an implementation data model
          -->
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Demographics"/>
            </observationDefinition>
          </definition>
          <definition>
            <encounterDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Encounters"/>
            </encounterDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Problems"/>
            </observationDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Allergies"/>
            </observationDefinition>
          </definition>
          <definition>
            <procedureDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Procedures"/>
            </procedureDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Results"/>
            </observationDefinition>
          </definition>
          <definition>
            <observationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Vitals"/>
            </observationDefinition>
          </definition>
          <definition>
            <substanceAdministrationDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1"
                extension="Medications"/>
            </substanceAdministrationDefinition>
          </definition>
          <definition>
            <supplyDefinition>
              <id root="2.16.840.1.113883.3.1619.5148.1" extension="RX"
              />
            </supplyDefinition>
          </definition>
          
          <!-- Create items for each panel in the query 
          -->
          <xsl:apply-templates select="panel/item">
            <!-- ordered by panel number -->
            <xsl:sort select="../panel_number" data-type="number"
              order="ascending"/>
          </xsl:apply-templates>
        </dataCriteriaSection>
      </component>

      <component>
        <populationCriteriaSection>
          <code code="57026-7" codeSystem="2.16.840.1.113883.6.1"/>
          <title>Population Criteria Section</title>
          <text>This section describes the Initial Patient Population,
            Numerator, Denominator, Denominator Exceptions, and Measure
            Populations</text>
          <!-- an I2B2 Query defines only the initial patient population,
            there are no numerators or denominators 
          -->
          <entry>
            <patientPopulationCriteria>
              <id root="{$docOID}" extension="IPP"/>
              <!-- The population criteria is generated by processing
                each panel in order.
              -->
              <xsl:apply-templates select="panel">
                <xsl:sort select="panel_number" data-type="number"
                  order="ascending"/>
              </xsl:apply-templates>
            </patientPopulationCriteria>
          </entry>
        </populationCriteriaSection>
      </component>
    </QualityMeasureDocument>
  </xsl:template>

  <!-- override XSL default rules for text() nodes -->
  <xsl:template match="text()"/>
  <xsl:template match="text()" mode="bytype"/>

  <!-- create a local variable name from a text string in
    the I2B2 ontology. 
    Inserts leading _ if it begins with a number
    Translates >=, <=, >, < and = into GE, LE, GT, LT and EQ respectively
    Replaces other special characters with _
    Adds a value to create a unique name.
  -->
  <xsl:template name="get-localVariable-name">
    <xsl:param name="string" select="normalize-space(item_name)"/>
    <xsl:variable name="unique" select="generate-id(item_name)"/>
    <xsl:variable name="name">
      <!-- Insert leading _ if starts with a number -->
      <xsl:if test="contains('1234567890',substring($string,1,1))">
        <xsl:text>_</xsl:text>
      </xsl:if>
      <!-- Translates >=, <=, >, < and = into GE, LE, GT, LT and EQ respectively -->
      <xsl:choose>
        <xsl:when test="contains($string,'&gt;=')">
          <xsl:value-of select="substring-before($string,'&gt;=')"/>
          <xsl:text>GE</xsl:text>
          <xsl:value-of select="substring-after($string,'&gt;=')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&lt;=')">
          <xsl:value-of select="substring-before($string,'&lt;=')"/>
          <xsl:text>LE</xsl:text>
          <xsl:value-of select="substring-after($string,'&lt;=')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&gt;')">
          <xsl:value-of select="substring-before($string,'&gt;')"/>
          <xsl:text>GT</xsl:text>
          <xsl:value-of select="substring-after($string,'&gt;')"/>
        </xsl:when>
        <xsl:when test="contains($string,'&lt;')">
          <xsl:value-of select="substring-before($string,'&lt;')"/>
          <xsl:text>LT</xsl:text>
          <xsl:value-of select="substring-after($string,'&lt;')"/>
        </xsl:when>
        <xsl:when test="contains($string,'=')">
          <xsl:value-of select="substring-before($string,'=')"/>
          <xsl:text>EQ</xsl:text>
          <xsl:value-of select="substring-after($string,'=')"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$string"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!-- Replaces other special characters with _ -->
    <xsl:value-of
      select="translate(translate(normalize-space($name),':()%',''),' ','_')"/>
    <!-- Ensures uniqueness of the variable name -->
    <xsl:text>_</xsl:text>
    <xsl:value-of select="$unique"/>
  </xsl:template>

  <!-- creates entries for each panel item in the dataCriteriaSection
    Each entry appears in the format:    
    <entry>
      <localVariableName>_18-34_years_old_N100A3</localVariableName>
      Actual content handled by separate templates where mode='bytype'
    </entry>
  -->
  <xsl:template match="panel/item">
    <entry>
      <!-- create the variable name, which is used in two places -->
      <xsl:variable name="name">
        <xsl:call-template name="get-localVariable-name"/>
      </xsl:variable>
      <!-- In here it is used the localVariableName -->
      <localVariableName>
        <xsl:value-of select="$name"/>
      </localVariableName>
      <!-- 
        Extract various parts of the ontology from item_key -->
      -->
      <xsl:variable name="key"
        select="substring-after(normalize-space(item_key),'\i2b2\')"/>
      <xsl:variable name="type"
        select="substring-before($key,&quot;\&quot;)"/>
      <xsl:variable name="subtype"
        select="substring-before(substring-after($key,&quot;\&quot;),&quot;\&quot;)"/>
      
      <!-- call on ontology specific templates with the ontology parts and 
        name of the entry as parameters -->
      <xsl:apply-templates select="." mode="bytype">
        <xsl:with-param name="key" select="$key"/>
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="subtype" select="$subtype"/>
        <xsl:with-param name="name" select="$name"/>
      </xsl:apply-templates>
    </entry>
  </xsl:template>
  
  <!-- This template handls items coming from the Demographics ontology in I2B2
    It generates an observationCriteria element, 
    gives the item the appropriate id generated by the OID unique to this document and the identifier name generated
    by the panel/item template,    
    Maps the ontology to the appropriate SNOMED Code (or barfs if it doesn't 
    recognized the demographic)
    Maps panel dates to effectiveTime, 
    and sets value to the appropriate type and content
    
    An example is given below:
    <observationCriteria>
      <id extension="_18-34_years_old_N100A3"
        root="2.16.840.1.113883.3.1619.5148.3.20120214.165226983"/>
      <code displayName="Current Chronological Age"
        codeSystem="2.16.840.1.113883.6.96" code="424144002"/>
      <effectiveTime>
        <low value="20110101"/>
        <high value="20111231"/>
        </effectiveTime>
      <value xsi:type="IVL_PQ">
        <low unit="a" inclusive="true" value="18"/>
        <high unit="a" inclusive="false" value="35"/>
      </value>
      <definition>
        <observationReference moodCode="DEF">
          <id extension="Demographics"
          root="2.16.840.1.113883.3.1619.5148.1"/>
        </observationReference>
      </definition>
    </observationCriteria>
  -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_DEMO\i2b2\Demographics')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    <observationCriteria>
      <!-- create the ID from docOID and name.  This pattern is followed for all
        criteria -->
      <id root="{$docOID}" extension="{$name}"/>
      
      <!-- Create the code element for the demographic -->
      <code code="" codeSystem="2.16.840.1.113883.6.96" codeSystemName="SNOMED CT" 
        displayName="">
        <!-- Mapping from I2B2 Ontology to SNOMED CT 
        I2B2 Term            SNOMED Code  Display Name            Type
        Age	                 424144002  Current Chronological Age	IVL_PQ
        Gender 	             263495000  Gender                    CE or ST
        Race	               103579009  Race                      CE or ST
        Ethnicity	           364699009  Ethnic Group              CE or ST
        Marital Status       125680007  Marital Status	          CE or ST
        Religious Preference 160538000  Religious Affiliation     CE or ST
        Postal Code          184102003  Patient Postal Code       CE or ST
        City                 433178008  City of Residence         CE or ST
        State                N/A        State/Province of Residence	CE or ST
        -->
        <xsl:choose>
          <xsl:when test="$subtype='Age'">
            <xsl:attribute name="displayName">
              <xsl:text>Current Chronological Age</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">424144002</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Gender'">
            <xsl:attribute name="displayName">Gender</xsl:attribute>
            <xsl:attribute name="code">263495000</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Race'">
            <xsl:attribute name="displayName">Race</xsl:attribute>
            <xsl:attribute name="code">103579009</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Marital Status'">
            <xsl:attribute name="displayName">
              <xsl:text>Marital Status</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">125680007</xsl:attribute>
          </xsl:when>
          <xsl:when test="$subtype ='Religion'">
            <xsl:attribute name="displayName">
              <xsl:text>Religious Preference</xsl:text>
            </xsl:attribute>
            <xsl:attribute name="code">160538000</xsl:attribute>
          </xsl:when>
          <!-- TBD: Zip Codes mapped to State, City or Postal Code -->
          <xsl:otherwise>
            <xsl:message terminate="yes"> Cannot Map <xsl:value-of
                select="$subtype"/> to HQMF Demographics </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </code>
      <!-- Set effectiveTime for the observation from panel dates -->
      <xsl:if test="../panel_date_from|../panel_date_to">
        <effectiveTime>
          <xsl:apply-templates
            select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      
      <xsl:choose>
        <!-- If it's an age, map values -->
        <xsl:when test="$subtype='Age'">
          <xsl:choose>
            <!-- Handle Age >= X -->
            <xsl:when test="contains(item_name,'gt;=')">
              <xsl:variable name="age"
                select="substring-before(substring-after(item_name,'= '),' ')"/>
              <value xsi:type="IVL_PQ">
                <low value="{normalize-space($age)}" inclusive="true"
                  unit="a"/>
              </value>
            </xsl:when>
            <!-- Handle Age = X -->
            <xsl:when test="contains(item_name,'=')">
              <xsl:variable name="age"
                select="substring-before(substring-after(item_name,'= '),' ')"/>
              <value xsi:type="IVL_PQ">
                <low value="{normalize-space($age)}" inclusive="true"
                  unit="a"/>
                <high value="{normalize-space($age)+1}"
                  inclusive="false" unit="a"/>
              </value>
            </xsl:when>
            <!-- process age ranges -->
            <xsl:when test="contains(item_name,'-')">
              <xsl:variable name="agelow"
                select="substring-before(item_name,'-')"/>
              <xsl:variable name="agehigh"
                select="substring-before(substring-after(item_name,'-'),' ')"/>
              <value xsi:type="IVL_PQ">
                <low value="{normalize-space($agelow)}" inclusive="true"
                  unit="a"/>
                <high value="{normalize-space($agehigh)+1}"
                  inclusive="false" unit="a"/>
              </value>
            </xsl:when>
            <xsl:otherwise>
              <!-- don't recognize age format -->
              <xsl:message terminate="yes">Cannot Parse Age Range for
                  <xsl:value-of select="item_key"/> to HQMF Demographics
              </xsl:message>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <!-- TBD: Map Gender codes -->
        <xsl:when test="$subtype ='Gender'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <!-- TBD: Map Race codes -->
        <xsl:when test="$subtype ='Race'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <!-- TBD: Map Marital Status codes -->
        <xsl:when test="$subtype ='Marital Status'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <!-- TBD: Map Religion codes -->
        <xsl:when test="$subtype ='Religion'">
          <value xsi:type="CD" value=""/>
        </xsl:when>
        <!-- TBD: Zip Codes mapped to State, City or Postal Code -->
        <xsl:otherwise>
          <value xsi:type="AD">
            <city/>
            <state/>
            <zipCode/>
          </value>
        </xsl:otherwise>
      </xsl:choose>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1"
            extension="Demographics"/>
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>
  
  <!-- Handle diagnoses 
    This template handls items coming from the Diagnoses ontology in I2B2
    It generates an observationCriteria element, 
    gives the item the appropriate id generated by the OID unique to this document and the identifier name generated
    by the panel/item template,
    Maps panel dates to effectiveTime, 
    Locates the code from the ontology and puts it in value
    
    An example is given below:
    <observationCriteria>
      <id extension="Diabetes_mellitus_N1011B"
        root="2.16.840.1.113883.3.1619.5148.3.20120214.165226983"/>
      <effectiveTime>
        <low value="20100101"/>
        <high value="20111231"/>
      </effectiveTime>
      <value codeSystemName="ICD-9-CM"
        codeSystem="2.16.840.1.113883.6.103"
        displayName="Diabetes Melitus"
        code="250" xsi:type="CD"/>
      <definition>
        <observationReference moodCode="DEF">
          <id extension="Problems"
            root="2.16.840.1.113883.3.1619.5148.1"/>
        </observationReference>
      </definition>
    </observationCriteria>
    
  -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_DIAG\i2b2\Diagnoses')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    
    <!-- locate the concept from the I2B2 ontology.  For now, this just pulls
      from a document.  Later, it should pull the ontology XML out of a RESTful
      API call that might look like this:
      http://i2b2.org/ontology?key=ontologyKey
      
      When that API is implemented, concept should come from:
      document(concat('http://i2b2.org/ontology?key=',current()/item_key))/concept
    -->
    <xsl:variable name="concept"
      select="$concepts//concept[key = normalize-space(current()/item_key)]"/>
    
    <!-- extract the code from the I2B2 concept XML -->
    <xsl:variable name="code"
      select="substring-after($concept/basecode,':')"/>
    
    <observationCriteria>
      <id root="{$docOID}" extension="{$name}"/>
      <xsl:if test="../panel_date_from|../panel_date_to">
        <effectiveTime>
          <xsl:apply-templates
            select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      <xsl:choose>
        <!-- if there is a basecode, output the ICD-9-CM code -->
          
        <xsl:when test="$concept/basecode">
          <value xsi:type="CD" code="{$code}"
            displayName="{substring-before('(',concat($concept/name,'('))"
            codeSystem="2.16.840.1.113883.6.103"
            codeSystemName="ICD-9-CM"/>
        </xsl:when>
        <!-- otherswise, there is no Root concept, so we change this (For now)
          to the I2B2 concept, and use the OID below to represent the I2B2 ontology
          Because the ontology paths in I2B2 contain spaces, we change them to + signs
          because HL7 doesn't like space characters in codes.
          Ideally, this would be changed into a valueSet that could be accessed
          from the I2B2 ontology cell.  I don't know if I2B2 ontology entries have
          a numeric identifier that could be used in the construction of value set
          identifiers, but if there was such a value, this could be done rather easily.
        -->
        <xsl:otherwise>
          <value xsi:type="CD"
            code="{translate(normalize-space(item_key),' ','+')}"
            codeSystem="2.16.840.1.113883.3.1619.5148.19.1"/>
        </xsl:otherwise>
      </xsl:choose>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1"
            extension="Problems"/>
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>
  
  <!-- Handle Lab Results
  This template handls items coming from the Lab Results ontology in I2B2
  It generates an observationCriteria element, 
  gives the item the appropriate id generated by the OID unique to this document and the identifier name generated
  by the panel/item template,
  Locates the code from the ontology and puts it in code
  Maps panel dates to effectiveTime, 
  Generates the value test.
  
  An example is given below:
  
    <observationCriteria>
      <id extension="HGB_A1C_LOINC4548-4_GE_9_N1014B"
        root="2.16.840.1.113883.3.1619.5148.3.20120214.165226983"/>
      <code codeSystemName="LOINC"
        codeSystem="2.16.840.1.113883.6.1"
        displayName="HGB_A1C"
        code="4548-4"/>
      <effectiveTime>
        <low value="20110101"/>
        <high value="20111231"/>
      </effectiveTime>
      <value xsi:type="IVL_PQ">
        <low inclusive="true" unit="%" value="9"/>
      </value>
      <definition>
        <observationReference moodCode="DEF">
          <id extension="Results"
            root="2.16.840.1.113883.3.1619.5148.1"/>
        </observationReference>
      </definition>
    </observationCriteria>
  
  -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_LABS\i2b2\Labtests')]">
    <xsl:param name="type"/>
    <xsl:param name="subtype"/>
    <xsl:param name="name"/>
    <xsl:variable name="concept"
      select="$concepts//concept[key = normalize-space(current()/item_key)]"/>
    <xsl:variable name="code"
      select="substring-after($concept/basecode,':')"/>
    <observationCriteria>
      <id root="{$docOID}" extension="{$name}"/>
      <xsl:choose>
        <xsl:when test="$concept/basecode">
          <code code="{$code}"
            displayName="{substring-before('(',concat($concept/name,'('))}"
            codeSystem="2.16.840.1.113883.6.1" codeSystemName="LOINC"
          />
        </xsl:when>
        <xsl:otherwise>
          <code code="{translate(normalize-space(item_key),' ','+')}"
            codeSystem="2.16.840.1.113883.3.1619.5148.19.1"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="../panel_date_from|../panel_date_to">
        <effectiveTime>
          <xsl:apply-templates
            select="../panel_date_from|../panel_date_to"/>
        </effectiveTime>
      </xsl:if>
      <xsl:apply-templates select="constrain_by_value"/>
      <definition>
        <observationReference moodCode="DEF">
          <id root="2.16.840.1.113883.3.1619.5148.1" extension="Results"
          />
        </observationReference>
      </definition>
    </observationCriteria>
  </xsl:template>

  <!-- generate <low> and <high> elements in 
    <effectiveTime> based on panel_date values 
    -->
  <xsl:template match="panel_date_from|panel_date_to">
    <!-- set the element name to low if from panel_date_from, otherwise use <high> -->
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="self::panel_date_from">low</xsl:when>
        <xsl:otherwise>high</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:element name="{$name}">
      <xsl:attribute name="value">
        <!-- Put the date in ISO (HL7) format -->
        <xsl:value-of
          select="concat(substring(.,1,4),substring(.,6,2),substring(.,9,2))"
        />
      </xsl:attribute>
    </xsl:element>
  </xsl:template>

  <!-- deal with constrain_by_value on lab results -->
  <xsl:template
    match="constrain_by_value[value_type = 'NUMBER']">
    <xsl:variable name="unit" select="value_unit_of_measure"/>
    <!-- Use IVL_PQ for NUMBERs -->
    <value xsi:type="IVL_PQ">
      <xsl:choose>
        <xsl:when test="value_operator = 'EQ'">
          <xsl:attribute name="xsi:type">PQ</xsl:attribute>
          <xsl:attribute name="unit">
            <xsl:value-of select="$unit"/>
          </xsl:attribute>
          <xsl:attribute name="value">
            <xsl:value-of select="value_constraint"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="value_operator = 'GT'">
          <low value="{value_constraint}" unit="{$unit}"
            inclusive="false"/>
        </xsl:when>
        <xsl:when test="value_operator = 'GE'">
          <low value="{value_constraint}" unit="{$unit}"
            inclusive="true"/>
        </xsl:when>
        <xsl:when test="value_operator = 'LT'">
          <high value="{value_constraint}" unit="{$unit}"
            inclusive="false"/>
        </xsl:when>
        <xsl:when test="value_operator = 'LE'">
          <high value="{value_constraint}" unit="{$unit}"
            inclusive="true"/>
        </xsl:when>
        <xsl:when test="value_operator = &quot;BETWEEN&quot;">
          <low
            value="{substring-before(value_constraint,' and ')}"
            unit="{$unit}"/>
          <high
            value="{substring-after(value_constraint,' and ')}"
            unit="{$unit}"/>
        </xsl:when>
      </xsl:choose>
    </value>
  </xsl:template>
  
  <!-- Deal with non-numeric value tests by reporting an error -->
  <xsl:template
    match="constrain_by_value[value_type != 'NUMBER']">
    <xsl:message terminate="yes"> Cannot Parse Value for <xsl:value-of
        select="value_type"/> types </xsl:message>
  </xsl:template>
  
  <!-- TBD: handle Medications -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_MEDS\i2b2\Medications')]"> </xsl:template>
  <!-- TBD: handle Procedures -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_PROC\i2b2\Procedures')]"> </xsl:template>
  <!-- TBD: handle Encounters -->
  <xsl:template mode="bytype"
    match="item[starts-with(item_key,'\\i2b2_VISIT\i2b2\Visit Details')]"> </xsl:template>
  
  <!-- If you have an item that doesn't map, and you 
    don't know how to handle it, report an error
  -->
  <xsl:template mode="bytype" match="item">
    <xsl:message terminate="yes"> Cannot Map <xsl:value-of
        select="item_key"/> to HQMF Criteria </xsl:message>
  </xsl:template>

  <!-- 
    Generate the population criteria from the panels.
    All panels are ANDed together 
    If the panel is inverted each item in it must be false
    Otherwise, at least one item in it must be true.
  -->
  <xsl:template match="panel">
    <xsl:choose>
      <xsl:when test="invert = '1'">
        <!-- If the panel is inverted each item in it must be false -->
        <precondition>
          <allFalse>
            <xsl:apply-templates select="item" mode="criteria"/>
          </allFalse>
        </precondition>
      </xsl:when>
      <!-- If there is more than one item in the panel,
        Or them together using atLeastOneTrue 
      -->
      <xsl:when test="count(item) &gt; 1">
        <precondition>
          <atLeastOneTrue>
            <xsl:apply-templates select="item" mode="criteria"/>
          </atLeastOneTrue>
        </precondition>
      </xsl:when>
      <!-- If there is only one item in the panel, no need to 
        Or it with other items.
      -->
      <xsl:otherwise>
        <xsl:apply-templates select="item" mode="criteria"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Now generate items in the Patient Population 
    Each item produces a precondition in the following form:
    <precondition>
      <observationReference>
        <id extension="name" root="docOID"/>
      </observationReference>
    </precondition>
    
    The name of the reference element is set based on the ontology item_key
    The id of the reference is based upon it's name.
  -->
  <xsl:template match="item" mode="criteria">
    <xsl:variable name="name">
      <xsl:call-template name="get-localVariable-name"/>
    </xsl:variable>
    <xsl:variable name="elem-name">
      <!-- The name of the reference element is set based on the ontology item_key -->
      <xsl:choose>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DEMO\i2b2\Demographics')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DIAG\i2b2\Diagnoses')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_LABS\i2b2\Labtests')">
          <xsl:text>observationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_MEDS\i2b2\Medications')">
          <xsl:text>substanceAdministrationReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_DEMO\i2b2\Procedures')">
          <xsl:text>procedureReference</xsl:text>
        </xsl:when>
        <xsl:when
          test="starts-with(item_key,'\\i2b2_VISIT\i2b2\Visit Details')">
          <xsl:text>encounterReference</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes"> Cannot Map <xsl:value-of
            select="item_key"/> to HQMF Criteria </xsl:message>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <precondition>
      <xsl:element name="{$elem-name}">
        <id root="{$docOID}" extension="{$name}">
          <xsl:attribute name="extension">
            <xsl:call-template name="get-localVariable-name"/>
          </xsl:attribute>
        </id>
      </xsl:element>
    </precondition>
  </xsl:template>
</xsl:stylesheet>
