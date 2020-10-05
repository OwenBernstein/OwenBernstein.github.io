---
layout: post
title: Incumbency - October. 27, 2020
---

One key aspect of elections, especially presidential elections, are the advantages afforded to the incumbent. Presidential incumbents are more nationally recognized, receive more press coverage, and have **the power to allocate federal funds.** In fact, in their 2012 paper “The Influence of Federal Spending on Presidential Elections,” Douglas Kriner and Andrew Reeves find that an increase in federal spending increases the incumbent's vote share at the state level. **In this post, I will examine the effects of incumbency and develop a new national vote share model.** 

## Incumbent Advantage

Since 1948, when incumbent candidates run for president they have won **73%** of the time. Only George HW Bush, Gerald Ford, and Jimmy Carter have lost when running as an incumbent. Furthermore, incumbent candidates have won, on average, **53% of the two party popular vote.** While many explanations for the impressive performance of incumbent candidates have been offered, one of the most convincing is the incumbent's ability to influence voters by facilitating federal funding. 

![picture](../images/grant_spending_barplot.png)

This graph shows that in general, swing states receive more federal funding than non-swing (core) states. However, during election years when the incumbent is up for reelection, federal grant funding in swing states increases significantly from **around 150 to 180 million dollars.** This prominent difference suggests that when up for reelection, incumbent candidates attempt to influence critical swing state voters by increasing federal grant funding. To measure the effect of these efforts, I will examine how an incumbent's two party vote share changed from one election to the next in response to federal grant spending increases in the same time frame. 

![picture](../images/vs_graphs_incumbent.png)

These graphs suggest a surprising trend. Not only does it appear that increasing federal funding to a state does not increase the incumbent's vote share, it even appears that in 1992 and 2004 increasing grants actually harmed the incumbent. While these results are certainly not intuitive, it may be that incumbents intentionally spend more money in states they are afraid to lose or perhaps the apparent trends are not statistically significant. To determine the validity of these results, I will apply a more statistical model to vote share and federal grant spending.