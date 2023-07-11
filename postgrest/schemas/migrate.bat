@REM Conéctate a la base de datos por defecto (por ejemplo, postgres)
set PGPASSWORD=%anarkia41
psql -U postgres -d postgres -c "SELECT 'Connected to default database';"

@REM Crea la base de datos "gym" si no existe
psql -U postgres -d postgres -c "CREATE DATABASE gym;"
psql -U postgres -d postgres -c "SELECT 'Created database gym if it does not exist';"

@REM Conéctate a la base de datos "gym"
psql -U postgres -d gym -c "SELECT 'Connected to gym database';"

@REM Itera sobre todos los archivos .sql en la carpeta actual
for %%f in (*.sql) do (
    @REM Ejecuta el archivo en psql
    echo running %%f
    psql -U postgres -d gym -f %%f
)