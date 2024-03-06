-- Compilation of objects (Mastersaf DW database)

######################################################################################################
1st Step


Attached file folder "SYS"

-> Here, we have the file to be executed as SYSDBA in the instance, to grant the grants
-> Make sure that grants are passed on to the correct user (owner of the MASTERSAF DW application = msaf_prod)

file: grants_mastersaf.sql




######################################################################################################
2nd step

Attached file folder "MSAF_PROD"
-> Here we have all the objects that make up the customization
-> Connected to SQLPLUS with the user owner of the MASTERSAF application, execute the build script "apply_custom.sql"Connected to SQLPLUS with the user owner of the MASTERSAF application, execute the build script "apply_custom.sql"

SQL> @apply_custom.sql


If errors occur during execution, share the log with the details.


########################################################################################################


