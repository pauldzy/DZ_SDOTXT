# DZ_SDOTXT
Utilities for the conversion and inspection of Oracle Spatial objects as text.
For the most up-to-date documentation see the auto-build  [dz_sdotxt_deploy.pdf](https://github.com/pauldzy/DZ_SDOTXT/blob/master/dz_sdotxt_deploy.pdf).

Generally there are few reasons for you to want to manifest Oracle Spatial objects as SQL text.  So you should only be using this code if you need to generate an example for an OTN posting or Oracle SR, or if you are exchanging a very modest amount of data with a colleague who has limited access to Oracle.  Overwhelmingly the proper way to exchange Oracle data is via datapump.  

See the [DZ_TESTDATA] (https://github.com/pauldzy/DZ_TESTDATA) project as an example of what this repository can do.

## Installation
Simply execute the deployment script into the schema of your choice.  Then execute the code using either the same or a different schema.  All procedures and functions are publically executable and utilize AUTHID CURRENT_USER for permissions handling.
