<?xml version="1.0" encoding="iso-8859-1" standalone="no"?>
<!--
ca-regional-2-2.xsl
-->

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xlink="http://www.w3.org/1999/xlink"
	xmlns:hcsc_ectd="hcsc_ectd"
>
	<xsl:output method="html" encoding="UTF-8" indent="no"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>
					CA Module 1 - schema version <xsl:value-of select="//@schema-version"/>
				</title>
				<style type="text/css">
					h1, h2, h3, h4 {margin-top:3pt ; margin-bottom:0pt}
					ul {margin-bottom:0pt ; margin-top:0pt}
				</style>
			</head>
			<body>
				<center>
					<h1>CA Module 1</h1>
					<small>
						schema version <xsl:value-of select="//@schema-version"/>
					</small>
				</center>
				<xsl:apply-templates select="hcsc_ectd:hcsc_ectd/hcsc_ectd:ectd-regulatory-transaction-information"/>
				<br/>
				<xsl:apply-templates select="hcsc_ectd:hcsc_ectd/hcsc_ectd:m1-administrative-and-product-information"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="*|@*" mode="data">
		<xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="hcsc_ectd:ectd-regulatory-transaction-information">
		<center>
			<table width="90%" border="1px" frame="border" rules="groups" cellpadding="2" cellspacing="0">
				<tr>
					<td colspan="2">
						<h3>eCTD Regulatory Transaction Information</h3>
					</td>
				</tr>
				<tr>
					<td width="25%">Applicant: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:applicant" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Product Name: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:product-name" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Dossier Identifier: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:dossier-identifier" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Dossier Type: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:dossier-type" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Regulatory Activity Type: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:regulatory-activity-type" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Regulatory Activity Lead: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:regulatory-activity-lead" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Sequence Number: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:sequence-number" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Sequence Description: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:sequence-description" mode="data"/>
					</td>
				</tr>
				<tr>
					<td>Related Sequence Number: </td>
					<td>
						<xsl:apply-templates select="hcsc_ectd:related-sequence-number" mode="data"/>
					</td>
				</tr>
			</table>
		</center>
	</xsl:template>

	<xsl:template match="hcsc_ectd:m1-administrative-and-product-information">
		<center>
			<table width="90%" cellpadding="5" cellspacing="2">
				
				<tr>
					<td colspan="2">
						<h2>Administrative and Product Information</h2>
					</td>
				</tr>
				
				<tr>
					<td width="5%" valign="top">
						<h3>1.0</h3>
					</td>
					<td width="95%">
						<h3>Correspondence</h3>
					</td>
				</tr>
				
				<tr>
					<td valign="top">
						<h4>1.0.1</h4>
					</td>
					<td>
						<h4>Cover Letter</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-1-cover-letter"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.2</h4>
					</td>
					<td>
						<h4>Life Cycle Management Table</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-2-life-cycle-management-table"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.3</h4>
					</td>
					<td>
						<h4>Copy of Health Canada issued correspondence</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-3-copy-of-health-canada-issued-correspondence"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.4</h4>
					</td>
					<td>
						<h4>Health Canada Solicited Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-4-health-canada-solicited-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.5</h4>
					</td>
					<td>
						<h4>Meeting Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-5-meeting-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.6</h4>
					</td>
					<td>
						<h4>Request for Reconsideration Documentation</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-6-request-for-reconsideration-documentation"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.0.7</h4>
					</td>
					<td>
						<h4>General Note to Reviewer</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-0-7-general-note-to-reviewer"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.2</h3>
					</td>
					<td>
						<h3>Administrative Information</h3>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.2.1</h4>
					</td>
					<td>
						<h4>Application Forms</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-1-application-forms"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.2</h4>
					</td>
					<td>
						<h4>Fee Forms</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-2-fee-forms"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.3</h4>
					</td>
					<td>
						<h4>Certification and Attestation Forms</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-3-certification-and-attestation-forms"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.4</h4>
					</td>
					<td>
						<h4>Intellectual Property Information</h4>
					</td>
				</tr>
				
				<tr>
					<td valign="top">
						<h5>1.2.4.1</h5>
					</td>
					<td>
						<h5>Patent Information</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-4-1-patent-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.4.2</h5>
					</td>
					<td>
						<h5>Data Protection Information</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-4-2-data-protection-information"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.2.5</h4>
					</td>
					<td>
						<h4>Compliance and Site Information</h4>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h5>1.2.5.1</h5>
					</td>
					<td>
						<h5>Clinical Trial Site Information Form</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-1-clinical-trial-site-information-form"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.2</h5>
					</td>
					<td>
						<h5>Establishment Licensing</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-2-establishment-licensing"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.3</h5>
					</td>
					<td>
						<h5>Good Clinical Practices</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-3-good-clinical-practices"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.4</h5>
					</td>
					<td>
						<h5>Good Laboratory Practices</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-4-good-laboratory-practices"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.5</h5>
					</td>
					<td>
						<h5>Good Manufacturing Practices</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-5-good-manufacturing-practices"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.6</h5>
					</td>
					<td>
						<h5>Good Pharmacovigilance Practices</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-6-good-pharmacovigilance-practices"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.2.5.7</h5>
					</td>
					<td>
						<h5>Other Compliance And Site Information Documents</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-5-7-other-compliance-and-site-information-documents"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.2.6</h4>
					</td>
					<td>
						<h4>Authorization for Sharing Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-6-authorization-for-sharing-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.7</h4>
					</td>
					<td>
						<h4>International Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-7-international-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.8</h4>
					</td>
					<td>
						<h4>Post-Authorization Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-8-post-authorization-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.2.9</h4>
					</td>
					<td>
						<h4>Other Administrative Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-2-9-other-administrative-information"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.3</h3>
					</td>
					<td>
						<h3>Product Information</h3>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.3.1</h4>
					</td>
					<td>
						<h4>Product Monograph</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-1-product-monograph"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.2</h4>
					</td>
					<td>
						<h4>Inner and Outer Labels</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-2-inner-and-outer-labels"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.3</h4>
					</td>
					<td>
						<h4>Non-Canadian Labelling</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-3-non-canadian-labelling"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.4</h4>
					</td>
					<td>
						<h4>Investigator's Brochure</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-4-investigators-brochure"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.5</h4>
					</td>
					<td>
						<h4>Reference Product Labelling</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-5-reference-product-labelling"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.6</h4>
					</td>
					<td>
						<h4>Certified Product Information Document</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-6-certified-product-information-document"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.7</h4>
					</td>
					<td>
						<h4>Look-alike/Sound-alike Assessment</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-7-look-alike-sound-alike-assessment"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.3.8</h4>
					</td>
					<td>
						<h4>Pharmacovigilance Information</h4>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h5>1.3.8.1</h5>
					</td>
					<td>
						<h5>Pharmacovigilance Plan</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-8-1-pharmacovigilance-plan"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.3.8.2</h5>
					</td>
					<td>
						<h5>Risk Management Plan</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-8-2-risk-management-plan"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.3.8.3</h5>
					</td>
					<td>
						<h5>Risk Communications</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-8-3-risk-communications"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h5>1.3.8.4</h5>
					</td>
					<td>
						<h5>Other Pharmacovigilance Information</h5>
						<xsl:apply-templates select="//hcsc_ectd:m1-3-8-4-other-pharmacovigilance-information"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.4</h3>
					</td>
					<td>
						<h3>Health Canada Summaries</h3>
					</td>
				</tr>
				
				<tr>
					<td valign="top">
						<h4>1.4.1</h4>
					</td>
					<td>
						<h4>PSEAT-CTA</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-4-1-pseat-cta"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.4.2</h4>
					</td>
					<td>
						<h4>Comprehensive Summary: Bioequivalence</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-4-2-comprehensive-summary-bioequivalence"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.4.3</h4>
					</td>
					<td>
						<h4>Multidisciplinary Tabular Summaries</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-4-3-multidisciplinary-tabular-summaries"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.5</h3>
					</td>
					<td>
						<h3>Environmental Assessment Statement</h3>
						<xsl:apply-templates select="//hcsc_ectd:m1-5-environmental-assessment-statement"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.6</h3>
					</td>
					<td>
						<h3>Regional Clinical Information</h3>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.6.1</h4>
					</td>
					<td>
						<h4>Comparative Bioavailability Information</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-6-1-comparative-bioavailability-information"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.6.2</h4>
					</td>
					<td>
						<h4>Company Core Data Sheets</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-6-2-company-core-data-sheets"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.6.3</h4>
					</td>
					<td>
						<h4>Priority Review Requests</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-6-3-priority-review-requests"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.6.4</h4>
					</td>
					<td>
						<h4>Notice of Compliance with Conditions</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-6-4-notice-of-compliance-with-conditions"/>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h3>1.7</h3>
					</td>
					<td>
						<h3>Clinical Trial Information</h3>
					</td>
				</tr>

				<tr>
					<td valign="top">
						<h4>1.7.1</h4>
					</td>
					<td>
						<h4>Study Protocol</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-7-1-study-protocol"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.7.2</h4>
					</td>
					<td>
						<h4>Informed Consent Forms</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-7-2-informed-consent-forms"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.7.3</h4>
					</td>
					<td>
						<h4>Canadian Research Ethics Board (REB) Refusals</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-7-3-canadian-research-ethics-board-refusals"/>
					</td>
				</tr>
				<tr>
					<td valign="top">
						<h4>1.7.4</h4>
					</td>
					<td>
						<h4>Information on Prior-related Applications</h4>
						<xsl:apply-templates select="//hcsc_ectd:m1-7-4-information-on-prior-related-applications"/>
					</td>
				</tr>
			</table>
		</center>
	</xsl:template>

	<xsl:template match="hcsc_ectd:leaf">
		<ul type="square">
			<li>
				<xsl:element name="a">
					<xsl:attribute name="href">
						<xsl:value-of select="@xlink:href"/>
					</xsl:attribute>
					<xsl:value-of select="hcsc_ectd:title"/>
				</xsl:element>
				<font color="red">
					[<xsl:value-of select="@operation"/>]
				</font>
			</li>
		</ul>
	</xsl:template>

	<xsl:template match="hcsc_ectd:node-extension">
		<li>
			<xsl:apply-templates select="hcsc_ectd:title" mode="data"/>
			<ul type="square">
				<xsl:apply-templates select="hcsc_ectd:leaf | hcsc_ectd:node-extension"/>
			</ul>
		</li>
	</xsl:template>

</xsl:stylesheet>