<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td>
      <div class="heading2">
        Pathway annotation
      </div>
      <div class="body">
        <DL>
          <P>
      The Pathway collaborators are...
          </P>
          <DT><I>Rattus Norvegicus</I></DT>
          <DD>
            Pathway annotations for <I>Rattus Norvegicus</I> gene products assigned by <a href="http://rgd.mcw.edu/">Pathway Ontology</a><BR/>
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
            All gene/PW annotation pairs from <i>Rattus Norvegicus</i>
            <im:querylink text="(browse)" skipBuilder="true">
<query name="" model="genomic" view="Gene Gene.pwAnnotation">
  <node path="Gene" type="Gene">
  </node>
  <node path="Gene.organism" type="Organism">
  </node>
  <node path="Gene.organism.name" type="String">
    <constraint op="=" value="Rattus Norvegicus" description="" identifier="" code="A">
    </constraint>
  </node>
</query>
            </im:querylink>
            <im:querylink text="(export)" skipBuilder="true">
<query name="" model="genomic" view="Gene.identifier Gene.primaryIdentifier Gene.symbol Gene.pwAnnotation.identifier Gene.pwAnnotation.name Gene.pwAnnotation.qualifier">
  <node path="Gene" type="Gene">
  </node>
  <node path="Gene.organism" type="Organism">
  </node>
  <node path="Gene.organism.name" type="String">
    <constraint op="=" value="Rattus Norvegicus" description="" identifier="" code="A">
    </constraint>
  </node>
</query>
            </im:querylink>
          </li>
        </ul>
      </div>
    </td>
  </tr>
</table>
