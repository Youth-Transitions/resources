In LEO, School Census is provided as a series of tables, one table per term per year. Prior to 2006, School Census was known as PLASC and collected annually.

In addition to School Census, you may also have:

PRU Census: Which provided details of pupils on roll in Pupil Referral Units (PRUs) between 2010 and 2013, at which point PRUs were included in School Census.

Alternative Provision (AP) Census: Which provides details of pupils who are funded by local authorities but who are educated outside the state-funded school (mainstream, special, AP) sector.

We typically load all the School Census tables we use for a LEO project (plus PRU Census and AP Census tables) into a single table. 

We first create a table to hold the details (see fft.census_details.sql)

We then load the source data into fft.census_details using (ADD SCRIPT HERE)

You may need to adapt the load script depending on which sensitive data items you have requested for your project.

We subsequently use this table for three main purposes:

1. To select cohorts to study
2. To create school history measures (e.g. age first observed with special educational needs (SEN), % of terms eligible for free school meals)
3. To extract the dates between which pupils were on roll in the state-school system.

