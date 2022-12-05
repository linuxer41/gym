# read all .sql files in this folder and run in psql

# get all .sql files in this folder
echo "Getting all .sql files in this folder"
for file in *.sql
do
    # run each file in psql
    echo "Running $file"
    PGPASSWORD=anarkia41
    psql -U postgres -d postgrest -f $file
done
