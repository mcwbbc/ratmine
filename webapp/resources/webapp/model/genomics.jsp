

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
          <a href="/ratmine">RatMine</a> <i>Rattus Norvegicus</i> genome
          data from:
        </p>
        <ul>
          <li>
            <a href="http://www.rgd.mcw.edu/">
              Fasta sequences for <i>R. norvegicus</i></a>
          </li>
          <li>
            <a href="http://www.rgd.mcw.edu/">
              GFF3 for <i>R.norvegicus</i> genome features</a>
          </li>
        </ul>
      </div>
    </td>
    <td width="40%" valign="top">
      <div class="body">
        <ul>
          <li>
            <im:querylink text="All <i>R. norvegicus</i> genes identifiers, chromosome positions and chromosome identifiers" skipBuilder="true">
<query name="" model="genomic" view="Gene.primaryIdentifier Gene.secondaryIdentifier Gene.organism.shortName Gene.chromosome.primaryIdentifier Gene.chromosomeLocation.start Gene.chromosomeLocation.end" sortOrder="Gene.primaryIdentifier asc">
</query>
            </im:querylink>
          </li>
        </ul>
      </div>
    </td>
  </tr>
</table>
