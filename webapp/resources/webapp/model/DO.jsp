<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td>
      <div class="heading2">
        DO annotation
      </div>
      <div class="body">
        <DL>
          <P>
      The DO collaborators are...
          </P>
          <DT><I>Rattus Norvegicus</I></DT>
          <DD>
            Disease annotations for <I>Rattus Norvegicus</I> gene products assigned by <a href="http://rgd.mcw.edu">Rat Genome Database</a><BR/>
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
            <im:querylink text="All gene/DO annotation pairs from <i>Rattus Norvegicus</i>(browse)" skipBuilder="true">
<query name="" model="genomic" view="Gene.primaryIdentifier Gene.symbol Gene.doAnnotation.ontologyTerm.identifier Gene.doAnnotation.ontologyTerm.name Gene.doAnnotation.ontologyTerm.description" sortOrder="Gene.primaryIdentifier asc">
  <node path="Gene" type="Gene">
  </node>
  <node path="Gene.doAnnotation" type="DOAnnotation">
  </node>
  <node path="Gene.doAnnotation.ontologyTerm" type="DOTerm">
  </node>
</query>
            </im:querylink>

          </li>
        </ul>
      </div>
    </td>
  </tr>
</table>
