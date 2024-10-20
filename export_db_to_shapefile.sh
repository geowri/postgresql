#!/bin/bash

# Verifica se todos os argumentos foram fornecidos
if [ "$#" -ne 4 ]; then
  echo "Erro: Número incorreto de argumentos."
  echo "Uso correto: $0 <usuario_postgres> <nome_do_banco> <schema> <diretorio_de_exportacao>"
  echo "Exemplo: $0 lucas geowri dados_nacionais /home/lucas/exportacoes"
  exit 1
fi

# Atribui os parâmetros passados na linha de comando às variáveis
USER=$1  # Usuário do PostgreSQL
DBNAME=$2  # Nome do banco de dados
SCHEMA=$3  # Nome do schema que contém as tabelas
EXPORT_DIR=$4  # Caminho principal onde os shapefiles serão salvos

# Verifica se o diretório de exportação existe, e o cria se não existir
if [ ! -d "$EXPORT_DIR" ]; then
  echo "Diretório $EXPORT_DIR não existe. Criando..."
  mkdir -p "$EXPORT_DIR"
fi

# Conectar ao banco de dados e obter a lista de tabelas com geometria no schema
tables=$(psql -d $DBNAME -U $USER -t -c "SELECT f_table_name FROM geometry_columns WHERE f_table_schema = '$SCHEMA';")

# Loop para exportar cada tabela
for table in $tables; do
  table=$(echo $table | xargs)  # Remove espaços em branco extras
  TABLE_DIR="$EXPORT_DIR/$table"  # Define o diretório específico para cada tabela
  
  # Cria o diretório para a tabela, se não existir
  mkdir -p "$TABLE_DIR"
  
  echo "Exportando tabela $table para o diretório $TABLE_DIR..."
  
  # Exporta o shapefile para o diretório correspondente
  pgsql2shp -f "$TABLE_DIR/$table" "$DBNAME" "SELECT * FROM $SCHEMA.$table"
done

echo "Exportação completa!"

