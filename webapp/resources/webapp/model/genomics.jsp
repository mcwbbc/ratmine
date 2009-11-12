<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td valign="top">
      <div class="heading2">
        Data sets
      </div>
    </td>
    <td valign="top">
      <div class="heading2">
        Bulk download
      </div>
    </td>
  </tr>
  <tr>
    <td>
      <div class="body">
        <p>
          <a href="/">RatMine</a> contains <i>Rattus Norvegicus</i> genome
          data from:
        </p>
        <ul>
          <li>
            <a href="http://hgdownload.cse.ucsc.edu/goldenPath/rn4/bigZips/">
              Fasta sequences for <i>Rattus Norvegicus</i></a>
          </li>
          <li>
            <a href="http://rgd.mcw.edu">
              GFF3 for <i>Rattus Norvegicus</i> genome features provided by RGD</a>
          </li>
        </ul>
      </div>
    </td>
    <td width="40%" valign="top">
      <div class="body">
        <ul>
          <li>
            <im:querylink text="All <i>Rattus norvegicus</i> genes (browse)" skipBuilder="true">
              <query name="" model="genomic" view="Gene.secondaryIdentifier Gene.name Gene.primaryIdentifier Gene.symbol Gene.chromosome.identifier Gene.chromosomeLocation.start Gene.chromosomeLocation.end">
                <node path="Gene" type="Gene">
                </node>
                <node path="Gene.organism" type="Organism">
                </node>
                <node path="Gene.organism.name" type="String">
                  <constraint op="=" value="Rattus norvegicus" description="" identifier="" code="A">
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
