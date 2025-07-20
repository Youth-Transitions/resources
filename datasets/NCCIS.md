The National Client Caseload Information System (NCCIS) records the monthly post-16 activities in which young people are engaged. The data is assembled from returns from local authorities, which have statutory duties to help young people resident in their areas (even if educated in a different local authority) engage in education and training.

NCCIS was first introduced in 2010/11.

The population coverage has changed over time:

2010-2015: 16-19 year olds (or 16-24 with LDD) resident in each local authority area

2015-2017: 16-19 year olds (or 16-25 with SEND)

2017-2021: 16-17 year olds (or 18-24 with SEND)

SEND refers to young people with either
- An EHC Plan
- A statement of SEN
- A Learning Difficulty Assessment (LDA)

Pupils with SEND whose needs are met by schools and colleges but without one of the above are not in scope of the NCCIS SEND definition.

The period covered by LEO spans two SEN codes of practice. Statements (for pupils in schools) and LDAs (for those in colleges) were phased out from the start of 2013/14 and replaced by EHC Plans.

The key data items in NCCIS are

- ACADYR (academic year)
- MonthNo (month)
- Current_Activity_Code
- Current_Activity_Start_Date

Months are coded 1-12 and represent calendar months. We typically recode these so the order adheres to the academic year starting in September and ending in August (i.e. we recode September to be month 1 and August to be month 12).

The activity codes are as follows:

**For those who have not yet reached the compulsory school leaving age:**
110 Registered at a school or other educational establishment in the area
120 Educated at home
130 Custodial Sentence
140 Not registered at a school or other educational establishment
150 Current Situation not known

**Education**
210 FTE - School Sixth Form
220 FTE - Sixth Form College
230 FTE - Further Education
240 FTE - Higher Education
250 Part time Education
260 Gap Year students
270 FTE - Other
280 Special post 16 institution
290 Custodial Institution (juvenille offender)

**Employment**
310 Apprenticeship
320 Full time employment with study (regulated qualification)
330 Employment without training
340 Employment with training (other)
350 Temporary employment
360 Part time Employment
380 Self-employment
381 Self-employment combined with study (regulated qualification)

**Training**
410 EFA/SFA funded WBL
430 Other training
440 DWP Training through the Work Programme (DWP training and support programme from April 2020).
450 Traineeship
460 Supported Internships

**Re-engagement**
530 Reengagement provision

**NEET (active)**
540 Working not for reward
550 Working not for reward combined with part time study
610 Those not yet ready for work or learning
615 Start date agreed (other)
616 Start Date agreed (RPA compliant)
619 Seeking employment, education or training

**NEET (inactive)**
620 Young carers
630 Teenage parents
640 Illness
650 Pregnancy
660 Religious grounds
670 Those who are currently unlikely to be economically active
680 Other reason

**Other**
710 Custody - young adult offender
720 Refugees/Asylum seekers

**Not known**
810 Current situation not known
820 Cannot Be Contacted
830 Refused to disclose activity

The SQL script collapses monthly records into spells. For example, in the case of a pupil who has 12 consecutive monthly records showing that they were in education, we collapse these into a single spell with a duration of 12 months.

Add in some stuff about spell_type_code and person resolution