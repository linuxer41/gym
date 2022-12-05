@REM read all .sql files in this folder and run in psql

@REM iterate over all files in this folder

for %%f in (*.sql) do (
    @REM run the file in psql
    echo running %%f
    set PGPASSWORD=%anarkia41
    psql -U linuxer -d postgrest -f %%f
)
