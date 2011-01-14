package org.intermine.bio.web.widget;

/*
 * Copyright (C) 2002-2009 FlyMine
 *
 * This code may be freely distributed and modified under the
 * terms of the GNU Lesser General Public Licence.  This should
 * be distributed with the code.  See the LICENSE file for more
 * information or http://www.gnu.org/copyleft/lesser.html.
 *
 */
import java.util.Arrays;

import org.intermine.api.profile.InterMineBag;
import org.intermine.objectstore.ObjectStore;
import org.intermine.pathquery.Constraints;
import org.intermine.pathquery.PathQuery;
import org.intermine.web.logic.widget.WidgetURLQuery;


/**
 * {@inheritDoc}
 * @author Julie Sullivan
 * @updated Andrew Vallejos
 */
public class PwStatURLQuery implements WidgetURLQuery
{
    //private static final Logger LOG = Logger.getLogger(GoStatURLQuery.class);
    private ObjectStore os;
    private InterMineBag bag;
    private String key;

    /**
     * @param os object store
     * @param key go terms user selected
     * @param bag bag page they were on
     */
    public PwStatURLQuery(ObjectStore os, InterMineBag bag, String key) {
        this.bag = bag;
        this.key = key;
        this.os = os;
    }

    /**
     * {@inheritDoc}
     */
    public PathQuery generatePathQuery(boolean showAll) {

        PathQuery q = new PathQuery(os.getModel());
        String bagType = bag.getType();

        String prefix = ("Protein".equals(bagType) ? "Protein.genes" : "Gene");

        if ("Protein".equals(bagType)) {
            q.addViews("Protein.primaryAccession");
        }

        q.addViews(prefix + ".primaryIdentifier",
            prefix + ".symbol",
            prefix + ".organism.name",
            prefix + ".pwAnnotation.ontologyTerm.identifier",
            prefix + ".pwAnnotation.ontologyTerm.name",
            prefix + ".pwAnnotation.ontologyTerm.relations.parentTerm.identifier",
            prefix + ".pwAnnotation.ontologyTerm.relations.parentTerm.name");

        q.addConstraint(Constraints.in(bagType, bag.getName()));

        // can't be a NOT relationship!
        q.addConstraint(Constraints.isNull(prefix + ".pwAnnotation.qualifier"));

        if (!showAll) {
	        String[] keys = key.split(",");
	        q.addConstraint(Constraints.oneOfValues(prefix + ".pwAnnotation.ontologyTerm.parents.identifier",
	                Arrays.asList(key)));
   		}
        return q;
    }
}
