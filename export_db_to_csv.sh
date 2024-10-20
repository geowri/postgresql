#!/bin/bash

# Verifica se todos os argumentos foram fornecidos
if [ "$#" -ne 4 ]; then
  echo "Erro: Número incorreto de argumentos."
  echo "Uso correto: $0 <usuario_postgres> <nome_do_banco> <schema> <diretorio_de_exportacao>"
  exit 1
fi

# Atribui os parâmetros passados na linha de comando às variáveis
USER=$1  # Usuário do PostgreSQL
DBNAME=$2  # Nome do banco de dados
SCHEMA=$3  # Nome do schema que contém as tabelas
EXPORT_DIR=$4  # Caminho onde os arquivos CSV serão salvos

# Verifica se o diretório de exportação existe, e o cria se não existir
if [ ! -d "$EXPORT_DIR" ]; then
  echo "Diretório $EXPORT_DIR não existe. Criando..."
  mkdir -p "$EXPORT_DIR"
fi

# Conectar ao banco de dados e obter a lista de tabelas sem geometria no schema
non_geom_tables=$(psql -d $DBNAME -U $USER -t -c "
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = '$SCHEMA' 
AND table_name NOT IN (SELECT f_table_name FROM geometry_columns WHERE f_table_schema = '$SCHEMA');")

# Loop para exportar tabelas sem geometria como CSV
for table in $non_geom_tables; do
  table=$(echo $table | xargs)  # Remove espaços em branco extras
  TABLE_DIR="$EXPORT_DIR/$table"  # Define o diretório específico para os arquivos CSV
  
  # Cria o diretório para a tabela, se não existir
  mkdir -p "$TABLE_DIR"
  
  echo "Exportando tabela sem geometria $table para o diretório $TABLE_DIR..."
  
  # Exporta a tabela sem geometria para CSV
  psql -d $DBNAME -U $USER -c "\COPY (SELECT * FROM $SCHEMA.$table) TO '$TABLE_DIR/$table.csv' CSV HEADER"
done

echo "Exportação de tabelas sem geometria completa!"

