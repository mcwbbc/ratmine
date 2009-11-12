<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td valign="top" rowspan="2">
      <div class="heading2">
        Current data
      </div>
      <div class="body">
        <DL>
          <DT><A href="http://www.uniprot.org/">UniProt
          Knowledgebase (UniProtKB)</A></DT>
          <DD>
            All proteins from the <A
            href="http://www.uniprot.org/">UniProt
            Knowledgebase</A> for the following organisms have
            been loaded:
            <UL>
              <LI><I>Rattus Norvegicus</I></LI>
            </UL>
            For each protein record in UniProt for each species the following
            information is extracted:
            <UL>
              <LI>Entry name</LI>
              <LI>Primary accession number</LI>
              <LI>Secondary accession number</LI>
              <LI>Protein name</LI>
              <LI>Comments</LI>
              <LI>Publications</LI>
              <LI>Sequence</LI>
              <LI>Gene ORF name</LI>
            </UL>
          </DD>
        </DL>
      </div>
    </td>
    <td valign="top">
      <div class="heading2">
        Bulk download
      </div>
      <div class="body">
        <ul>
          <li>
            <span style="white-space:nowrap">
              <im:querylink text="<i>Rattus norvegicus</i> proteins and corresponding genes(browse)" skipBuilder="true">
                <query name="" model="genomic" view="Protein.primaryAccession Protein.genes.symbol" sortOrder="Protein.primaryAccession asc">
					<node path="Protein" type="Protein">
					</node>
					<node path="Protein.organism" type="Organism">
					</node>
					<node path="Protein.organism.name" type="String">
					<constraint op="=" value="Rattus norvegicus" description="" identifier="" code="A" extraValue="">
					</constraint>
					</node>
					<node path="Protein.genes" type="Gene">
					</node>
                </query>
              </im:querylink>
            </span>
          </li>
        </ul>
      </div>
    </td>
  </tr>
</table>
