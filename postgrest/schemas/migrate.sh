#!/bin/bash

# Conéctate a la base de datos por defecto (por ejemplo, postgres)
PGPASSWORD="$pass" psql -U postgres -d postgres -c "SELECT 'Connected to default database';"

# Crea la base de datos "gym" si no existe
PGPASSWORD="$pass" psql -U postgres -d postgres -c "CREATE DATABASE gym;"
PGPASSWORD="$pass" psql -U postgres -d postgres -c "SELECT 'Created database gym if it does not exist';"

# Conéctate a la base de datos "gym"
PGPASSWORD="$pass" psql -U postgres -d gym -c "SELECT 'Connected to gym database';"

# Itera sobre todos los archivos .sql en el directorio actual
for file in *.sql; do
  # Ejecuta el archivo en psql
  echo "running $file"
  PGPASSWORD="$pass" psql -U postgres -d gym -f "$file"
done
