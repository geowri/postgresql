#!/bin/bash

# Verifica se todos os argumentos foram fornecidos
if [ "$#" -ne 4 ]; then
  echo "Erro: Número incorreto de argumentos."
  echo "Uso correto: $0 <usuario_postgres> <nome_do_banco> <schema> <diretorio_dos_csvs>"
  echo "Exemplo: $0 lucas teste1 dados_nacionais /home/lucas/Scripts/csv"
  exit 1
fi

# Atribui os parâmetros passados na linha de comando às variáveis
USER=$1  # Usuário do PostgreSQL
DBNAME=$2  # Nome do banco de dados
SCHEMA=$3  # Nome do schema para onde as tabelas CSV serão importadas
CSV_DIR=$4  # Diretório principal que contém os subdiretórios com os arquivos CSV

# Verifica se o schema existe no banco de dados e o cria, caso contrário
psql -d $DBNAME -U $USER -c "CREATE SCHEMA IF NOT EXISTS $SCHEMA;"

# Loop através de todos os subdiretórios e encontrar os arquivos CSV
find "$CSV_DIR" -type f -name "*.csv" | while read file; do
  # Extrai o nome do diretório (nome da tabela) e o nome do arquivo CSV sem extensão
  dirname=$(basename "$(dirname "$file")")  # Nome do diretório (que deve ser igual ao nome da tabela)
  filename=$(basename "$file" .csv)  # Nome do arquivo CSV sem a extensão .csv

  # Verifica se o diretório e o arquivo possuem o mesmo nome
  if [ "$dirname" == "$filename" ]; then
    echo "Importando CSV $file para a tabela $SCHEMA.$filename..."

    # Cria a tabela no PostgreSQL usando o nome do arquivo CSV (se necessário)
    head -1 "$file" | sed 's/,/ text,/g' | sed 's/$/ text/' > temp.sql
    echo "CREATE TABLE IF NOT EXISTS $SCHEMA.$filename ($(cat temp.sql));" | psql -d $DBNAME -U $USER

    # Importa os dados do CSV para a tabela criada
    psql -d $DBNAME -U $USER -c "\COPY $SCHEMA.$filename FROM '$file' CSV HEADER"

    # Remove o arquivo temporário usado para criar a tabela
    rm temp.sql
  else
    echo "Aviso: O diretório ($dirname) e o arquivo ($filename) não correspondem. Ignorando..."
  fi
done

echo "Importação completa!"

