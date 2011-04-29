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
        <!--insert hidden here -->
	  <h4>
		<a href="javascript:toggleDiv('hiddenDiv1');">
		<img id='hiddenDiv1Toggle' src="images/disclosed.gif"/>
			Interaction datasets...
		</a>
	  </h4>

	  <div id="hiddenDiv1" class="dataSetDescription">
      <p>
      RatMine has interaction datasets for <i>R. norvigicus</i> from:
      </p>
      <ul>
        <li><a href="http://thebiogrid.org" target="_new">BioGrid</a></li>
		 		<li> <a href="http://www.ebi.ac.uk/intact/">IntAct</a></li>
			</ul>
		</div>
		<!-- done hidden -->
      </div>
    </td>
    <td width="40%" valign="top">
      <div class="body">
        <ul>
          <li>
            <im:querylink text="All <i>Rattus norvegicus</i> interactions (browse)" skipBuilder="true">
              <query name="" model="genomic" view="Interaction.experiment.publication.pubMedId Interaction.gene.symbol Interaction.role Interaction.interactingGenes.symbol Interaction.type.identifier" sortOrder="Interaction.experiment.publication.pubMedId asc">
							</query>
            </im:querylink>
          </li>
					<li>
						<im:querylink text="All BioGrid Interactions (browse)" skipBuilder="true">
							<query name="" model="genomic" view="Interaction.experiment.publication.pubMedId Interaction.gene.symbol Interaction.role Interaction.interactingGenes.symbol Interaction.type.identifier" sortOrder="Interaction.experiment.publication.pubMedId asc">
							  <constraint path="Interaction.dataSets.name" op="=" value="BioGRID interaction data set"/>
							</query>
						</im:querylink>
					</li>
					<li>
						<im:querylink text="All IntAct Interactions (browse)" skipBuilder="true">
							<query name="" model="genomic" view="Interaction.experiment.publication.pubMedId Interaction.gene.symbol Interaction.role Interaction.interactingGenes.symbol Interaction.type.identifier" sortOrder="Interaction.experiment.publication.pubMedId asc">
							  <constraint path="Interaction.dataSets.name" op="=" value="IntAct data set"/>
							</query>
						</im:querylink>
					</li>
        </ul>
      </div>
    </td>
  </tr>
</table>
