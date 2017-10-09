<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib tagdir="/WEB-INF/tags" prefix="im" %>

<table width="100%">
  <tr>
    <td valign="top" rowspan="2">
      <div class="heading2">
        API test data
      </div>
      <div class="body">
        <DL>
          <DT><A href="http://www.ebi.uniprot.org/index.shtml">UniProt
          Knowledgebase (UniProtKB)</A></DT>
          <DD>
            All proteins from the <A
            href="http://www.ebi.uniprot.org/index.shtml">UniProt
            Knowledgebase</A> (version 7.5) for the following organisms have
            been loaded:
            <UL>
              <LI><I>Plasmodium falciparum (isolate 3D7)</I></LI>
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
  </tr>
</table>
