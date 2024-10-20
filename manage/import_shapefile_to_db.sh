#!/bin/bash

# Verifica se todos os argumentos foram fornecidos
if [ "$#" -ne 4 ]; then
  echo "Erro: Número incorreto de argumentos."
  echo "Uso correto: $0 <usuario_postgres> <nome_do_banco> <schema> <diretorio_dos_shapefiles>"
  exit 1
fi

# Atribui os parâmetros passados na linha de comando às variáveis
USER=$1  # Usuário do PostgreSQL
DBNAME=$2  # Nome do banco de dados
SCHEMA=$3  # Nome do schema para onde os shapefiles serão importados
SHAPEFILES_DIR=$4  # Diretório principal que contém os subdiretórios com os shapefiles

# Verifica se o schema existe no banco de dados e o cria, caso contrário
psql -d $DBNAME -U $USER -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA;"

# Loop através de todos os subdiretórios e encontrar os shapefiles
find "$SHAPEFILES_DIR" -type f -name "*.shp" | while read file; do
  # Extrai o nome do diretório (nome do shapefile) e o nome do arquivo .shp sem extensão
  dirname=$(basename "$(dirname "$file")")  # Nome do diretório (que deve ser igual ao nome do shapefile)
  filename=$(basename "$file" .shp)  # Nome do arquivo shapefile sem a extensão .shp

  # Verifica se o diretório e o arquivo possuem o mesmo nome
  if [ "$dirname" == "$filename" ]; then
    # Extrai o SRID original do shapefile a partir do arquivo .prj, se disponível
    srid=$(gdalsrsinfo -o epsg "$file" 2>/dev/null | grep -o -E '[0-9]+')

    if [ -z "$srid" ]; then
      echo "Não foi possível identificar o SRID para $file. Usando SRID padrão."
      srid=4326  # Define SRID padrão caso não encontre o original
    fi

    echo "Importando shapefile $file (SRID original: $srid) para a tabela $SCHEMA.$filename..."

    # Usa shp2pgsql para reprojetar o shapefile de seu SRID original para 4326
    shp2pgsql -I -s $srid:4326 "$file" "$SCHEMA.$filename" | psql -d $DBNAME -U $USER
  else
    echo "Aviso: O diretório ($dirname) e o arquivo ($filename) não correspondem. Ignorando..."
  fi
done

echo "Importação completa!"

