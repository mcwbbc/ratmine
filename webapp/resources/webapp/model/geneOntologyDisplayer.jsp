<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib uri="/WEB-INF/struts-tiles.tld" prefix="tiles" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>
<%@ taglib uri="http://jakarta.apache.org/taglibs/string-1.1" prefix="str" %>


<!-- geneOntologyDisplayer.jsp -->
<div class="basic-table">
<h3>Gene Ontology</h3>

<c:choose>
  <c:when test="${!empty noGoMessage }">
  GO Annotations from Metabolic Mine:
  <!-- You need to import the IMBedding client library - this is hosted at intermine.org for your convenience: -->
<script src="http://www.intermine.org/lib/imbedding/0.2/imbedding.js" type="text/javascript"></script>

<!-- We also need to import a stylesheet - you can choose from light, dark or bold-->
<link rel="stylesheet" type="text/css" title="light" href="http://intermine.org/lib/imbedding/0.2/style/light.css">

<!-- You need to set a place holder element in your page to hold the resultant table - this can also hold apology text/content -->
<div id="queryplaceholder"><p class="apology">${noGoMessage}</p></div>

	<script type="text/javascript" charset="utf=8">
		IMBedding.loadTemplate(
		{	name: "Gene_GO",
			constraint1: "Gene",
			op1: "LOOKUP",
			value1: "${object.symbol}",
			extra1: "${object.organism.shortName}",
			code1: "A"
		},
		'#queryplaceholder',
		{baseUrl: 'http://www.metabolicmine.org/beta'}
		);
	</script>
  </c:when>
  <c:otherwise>

    <table>
    <c:forEach items="${goTerms}" var="parentEntry">
      <c:set var="parentTerm" value="${parentEntry.key}" />
        <thead>
        	<tr><th colspan="2">${parentTerm}</th></tr>
        </thead>
        <tbody>
	      <tr>
	        <c:choose>
	          <c:when test="${empty parentEntry.value}">
	            <tr>
	              <td class="smallnote" colspan="2"><i>No terms in this category.</i></td>
	            </tr>
	          </c:when>
	          <c:otherwise>
	            <c:forEach items="${parentEntry.value}" var="entry">
	              <tr>
	                <td>
	                  <c:set var="term" value="${entry.key}" />
	                  <html:link href="/${WEB_PROPERTIES['webapp.path']}/report.do?id=${term.id}" title="${term.description}">
	                  <c:out value="${term.name}"/>
	                  </html:link>&nbsp;<im:helplink text="${term.description}"/>
	                </td>
	                <td>
	                  <c:set var="evidence" value="${entry.value}" />
		              <c:forEach items="${entry.value}" var="evidence">
		                <c:out value="${evidence}"/><c:if test="${!empty codes[evidence] }">&nbsp;<im:helplink text="${codes[evidence]}"/>
		                </c:if>
		                &nbsp;
		              </c:forEach>
	                </td>
	              </tr>
	            </c:forEach>
	          </c:otherwise>
	        </c:choose>
	      </tr>
        </tbody>
    </c:forEach>
    </table>

  </c:otherwise>
</c:choose>
</div>
<!-- /geneOntologyDisplayer.jsp -->
