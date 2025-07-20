In LEO, researchers are provided with the Longitudinal Individualised Learner Record (LILR).

This is assembled (outside of LEO) from individual LEO datasets. Some preprocessing has already taken place to add some useful derived fields and to use include variables that are consistent over time (where possible).

Source ILR contains four tables:

1. Learner provides information about individual learners. However, these are not necessarily distinct real-world individuals. An individual who attends multiple FE providers across multiple years will have multiple learner records.
2. Aims provides information about the programmes and learning aims that learners are pursuing in the FE sector. This includes work experience and enrichment as well as formal qualifications
3. LARS provides reference data about learning aims, including type, level and subject. Many fields are also present in the aims file
4. Providers reference data (not usually provided in LEO) contains reference data about providers e.g. type (FE College/ work-based learning provider, local authority etc.)

The first stage of the aims processing is simply to load the data into a format that makes working with the data easier. This involves:

1. Adding person identifiers
2. Putting indexes on the identifiers (to make joining to other tables more efficient)
3. Setting appropriate (and minimal) data types for each variable

We tend to work with a subset of the variables provided in ILR. These have tended to be sufficient for most of the work we have done with ILR in the past but there will almost certainly be occasions when other variables might come in useful.

Our main use of ILR has typically been to track post-16 education and training in the FE sector. A combination of PLAMS and School Census can be used to do similar for the school sector. 

It can also be used alongside HESA data to track post-19 education and training.