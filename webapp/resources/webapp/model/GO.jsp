<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td>
      <div class="heading2">
        GO annotation
      </div>
      <div class="body">
        <DL>
          <P>
      The GO collaborators are developing three structured, controlled
      vocabularies (ontologies) that describe gene products in terms of
      their associated biological processes, cellular components and
      molecular functions in a species-independent manner.
          </P>
          <DT><I>Rattus Norvegicus</I></DT>
          <DD>
            GO annotations for <I>Rattus Norvegicus</I> gene products assigned by <a href="http://rgd.mcw.edu">RGD</a><BR/>
          </DD>
        </DL>
      </div>
    </td>
    <td width="40%" valign="top">
      <div class="heading2">
        Bulk download
      </div>
      <div class="body">
        <ul>
          <li>
            <im:querylink text="All gene/GO annotation pairs from <i>Rattus Norvegicus</i>" skipBuilder="true">
<query name="" model="genomic" view="Gene.primaryIdentifier Gene.symbol Gene.name Gene.goAnnotation.ontologyTerm.name Gene.goAnnotation.ontologyTerm.description" sortOrder="Gene.primaryIdentifier asc">
  <node path="Gene" type="Gene">
  </node>
  <node path="Gene.goAnnotation" type="GOAnnotation">
  </node>
  <node path="Gene.goAnnotation.ontologyTerm" type="GOTerm">
  </node>
</query>
            </im:querylink>
          </li>
        </ul>
      </div>
    </td>
  </tr>
</table>
