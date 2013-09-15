<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
	xmlns:atom="http://www.w3.org/2005/Atom" 
	xmlns:dc="http://purl.org/dc/elements/1.1/" 
	xmlns:date="http://exslt.org/dates-and-times"
	xmlns:str="http://exslt.org/strings"
	version="1.0">
	<xsl:output method="xml" encoding="utf-8"/>
	<xsl:template match="/">
		<rss version="2.0">
			<channel>
				<title>Track post item</title>
				<link>http://www.russianpost.ru/rp/servise/ru/home/postuslug/trackingpo</link>
				<xsl:variable name="now" select="date:date-time()"/>
				<lastBuildDate><xsl:value-of select="substring(date:day-name($now), 1, 3)"/>, <xsl:value-of select="concat(date:day-in-month($now), ' ', substring(date:month-name($now), 1, 3), ' ', date:year($now), ' ', str:replace(str:replace(date:time($now), '+', ' +'), '-', '- '))"/></lastBuildDate>
				<description>
					<xsl:value-of select="'&lt;![CDATA['" disable-output-escaping="yes"/>
					<xsl:copy-of select='//h2[.="Результат поиска:"]/following-sibling::table[1]'/>
					<xsl:value-of select="']]&gt;'" disable-output-escaping="yes"/>
				</description>
				<atom:link href="{$url}" rel="self" type="application/rss+xml" />
				<xsl:for-each select="//table[@class='pagetext']/tbody/tr">
					<xsl:variable name="date_raw" select="td[2]"/>
					<xsl:variable name="day" select="substring-before($date_raw, '.')"/>
					<xsl:variable name="month" select="substring-before(substring-after(substring-before($date_raw, ' '), '.'), '.')"/>
					<xsl:variable name="year" select="substring-after(substring-after(substring-before($date_raw, ' '), '.'), '.')"/>
					<xsl:variable name="hour" select="substring-before(substring-after($date_raw, ' '), ':')"/>
					<xsl:variable name="minute" select="substring-after($date_raw, ':')"/>
					<xsl:variable name="dcdate"><xsl:value-of select="$year"/>-<xsl:value-of select="$month"/>-<xsl:value-of select="$day"/>T<xsl:value-of select="$hour"/>:<xsl:value-of select="$minute"/>:00-00:00</xsl:variable>

					<item>
						<title><xsl:value-of select="td[1]"/></title>
						<guid isPermaLink="false"><xsl:value-of select="$dcdate"/>.html</guid>
						<link><xsl:value-of select="$item_root"/>/item/<xsl:value-of select="$dcdate"/>.html</link>
						<dc:date><xsl:value-of select="$dcdate"/></dc:date>
						<dc:creator><xsl:value-of select="td[4]"/></dc:creator>
						<author><xsl:value-of select="td[4]"/></author>
						<description>
							<xsl:value-of select="'&lt;![CDATA[&lt;table style=&quot;background-color: #EEE&quot;&gt;'" disable-output-escaping="yes"/>
							<xsl:copy-of select='../../thead'/>
							<xsl:value-of select="'&lt;tbody&gt;'" disable-output-escaping="yes"/>
							<xsl:copy-of select='.'/>
							<xsl:value-of select="'&lt;/tbody&gt;&lt;/table&gt;]]&gt;'" disable-output-escaping="yes"/>
						</description>
					</item>
				</xsl:for-each>
			</channel>
		</rss>
	</xsl:template>
</xsl:stylesheet>
