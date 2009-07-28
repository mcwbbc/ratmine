<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td>
      <div class="heading2">
        Mammalian Phenotype annotation
      </div>
      <div class="body">
        <DL>
          <P>
      The Mammalian Phenotype collaborators are...
          </P>
          <DT><I>Rattus Norvegicus</I></DT>
          <DD>
            MP annotations for <I>Rattus Norvegicus</I> gene products assigned by <a href="http://www.informatics.jax.org/searches/MP_form.shtml">MGI</a><BR/>
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
            All gene/MP annotation pairs from <i>Rattus Norvegicus</i>
            <im:querylink text="(browse)" skipBuilder="true">
<query name="" model="genomic" view="Gene Gene.mpAnnotation">
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
<query name="" model="genomic" view="Gene.identifier Gene.primaryIdentifier Gene.symbol Gene.mpAnnotation.identifier Gene.mpAnnotation.name Gene.mpAnnotation.qualifier">
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
