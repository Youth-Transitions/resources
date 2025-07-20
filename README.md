# Longitudinal Education Outcomes

This user guide presents guidance on preparing data from the Longitudinal Education Outcomes (LEO) database to study the post-16 activities of young people. It is designed to accompany the [user guide for LEO](https://khub.net/group/longitudinal-education-outcomes-via-ons-srs-research-community), which can be accessed by becoming a member of the LEO research community.

## Component datasets

Tracking the activities of young people at age 16 and beyond in LEO involves working with several component datasets:

- [School Census](https://github.com/Youth-Transitions/user-guide/datasets/School-Census.md) provides details of enrolments in state-funded schools.
- [PLAMS](https://github.com/Youth-Transitions/user-guide/datasets/PLAMS.md) provides details of the post-16 qualifications being studied by students enrolled in state-funded mainstream schools (does not cover special schools).
- [ILR](https://github.com/Youth-Transitions/user-guide/datasets/ILR.md) provides details of enrolments and qualifications being studied by students enrolled in further education providers (e.g. Colleges and work-based learning providers), including higher level technical qualifications.
- [HESA](https://github.com/Youth-Transitions/user-guide/datasets/HESA.md) provides details of enrolments and qualifications being studied by students enrolled in higher education institutions including qualifications at level 3 and below being studied in HEIs.
- [NCCIS](https://github.com/Youth-Transitions/user-guide/datasets/NCCIS.md) provides information on the post-16 activities being undertaken by young people and recorded by local authorities, including details of individuals known to be not in education, employment and training (NEET) by local authorities.
- [Employment](https://github.com/Youth-Transitions/user-guide/datasets/Employment.md) provides dates of spells in employment.
- [Benefits](https://github.com/Youth-Transitions/user-guide/datasets/Benefits.md) provides dates during which state benefits were received. Can be used to identify individuals who were active in the labour market but unemployed.

## Scripts

Alongside the guide, we present exemplar SQL scripts. The scripts have been developed on projects we have carried out using LEO iteration 2. As each LEO project uses a specific subset of variables, you might need to amend the scripts to add additional variables or remove those that your project doesn't have access to. This will be the case with sensitive data items that have to be requested (e.g. ethnic background in School Census).
